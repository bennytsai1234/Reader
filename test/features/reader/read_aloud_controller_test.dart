import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/read_aloud_controller.dart';

class FakeTtsService extends ChangeNotifier implements TTSService {
  final StreamController<String> _audioEvents =
      StreamController<String>.broadcast();
  final List<String> spokenTexts = <String>[];
  bool _isPlaying = false;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;

  @override
  bool get isPlaying => _isPlaying;

  @override
  int currentWordStart = -1;

  @override
  int currentWordEnd = -1;

  @override
  String currentSpokenText = '';

  @override
  Stream<String> get audioEvents => _audioEvents.stream;

  @override
  Future<void> speak(String text) async {
    spokenTexts.add(text);
    currentSpokenText = text;
    currentWordStart = -1;
    currentWordEnd = -1;
    _isPlaying = true;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _isPlaying = false;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    _isPlaying = false;
  }

  @override
  Future<void> resume() async {
    resumeCount++;
    _isPlaying = true;
  }

  void emitProgress(int start, int end) {
    currentWordStart = start;
    currentWordEnd = end;
    notifyListeners();
  }

  Future<void> emitAudioEvent(String event) async {
    _audioEvents.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> disposeStreams() async {
    await _audioEvents.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReaderChapter buildChapter({
  required int index,
  required String title,
  required List<String> paragraphs,
}) {
  final pages = <TextPage>[];
  var chapterPosition = 0;
  for (var pageIndex = 0; pageIndex < paragraphs.length; pageIndex++) {
    final text = paragraphs[pageIndex];
    final mid = (text.length / 2).ceil();
    final first = text.substring(0, mid);
    final second = text.substring(mid);
    pages.add(
      TextPage(
        index: pageIndex,
        title: title,
        chapterIndex: index,
        pageSize: paragraphs.length,
        lines: [
          TextLine(
            text: first,
            width: 100,
            height: 20,
            chapterPosition: chapterPosition,
            lineTop: 0,
            lineBottom: 20,
            paragraphNum: pageIndex + 1,
          ),
          TextLine(
            text: second,
            width: 100,
            height: 20,
            chapterPosition: chapterPosition + first.length,
            lineTop: 20,
            lineBottom: 40,
            paragraphNum: pageIndex + 1,
            isParagraphEnd: true,
          ),
        ],
      ),
    );
    chapterPosition += text.length;
  }
  return ReaderChapter(
    chapter: BookChapter(title: title, index: index, url: 'chapter-$index'),
    index: index,
    title: title,
    pages: pages,
  );
}

Future<void> flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('ReadAloudController', () {
    test('同一行內 progress 會保留行高亮並更新詞位置', () async {
      final fakeTts = FakeTtsService();
      final chapters = <int, ReaderChapter>{
        0: buildChapter(
          index: 0,
          title: 'Chapter 0',
          paragraphs: ['AAAAABBBBB', 'CCCCCDDDDD'],
        ),
      };
      var stateChanges = 0;
      var pageJumpRequests = 0;

      final controller = ReadAloudController(
        tts: fakeTts,
        nextChapter: () async {},
        prevChapter: ({bool fromEnd = true}) async {},
        nextPage: () async {},
        prevPage: () async {},
        canMoveToNextPage: () => true,
        canMoveToPrevPage: () => false,
        requestJumpToPage: (_) {
          pageJumpRequests++;
        },
        requestJumpToChapter:
            ({
              required int chapterIndex,
              required double alignment,
              required double localOffset,
            }) {},
        chapterOf: (chapterIndex) => chapters[chapterIndex],
        currentChapterIndex: () => 0,
        visibleChapterIndex: () => 0,
        currentCharOffset: () => 0,
        visibleCharOffset: () => 0,
        isScrollMode: () => false,
        onStateChanged: () {
          stateChanges++;
        },
        updateMediaInfo: (_, __) {},
      );

      controller.attach();
      controller.toggle();
      await flushAsync();

      fakeTts.emitProgress(0, 3);
      await flushAsync();

      final firstStart = controller.ttsStart;
      final firstEnd = controller.ttsEnd;
      final firstWordStart = controller.ttsWordStart;
      final firstWordEnd = controller.ttsWordEnd;
      final firstStateChanges = stateChanges;
      final firstPageJumpRequests = pageJumpRequests;

      fakeTts.emitProgress(3, 4);
      await flushAsync();

      expect(controller.ttsStart, firstStart);
      expect(controller.ttsEnd, firstEnd);
      expect(controller.ttsWordStart, isNot(firstWordStart));
      expect(controller.ttsWordEnd, isNot(firstWordEnd));
      expect(stateChanges, greaterThan(firstStateChanges));
      expect(pageJumpRequests, firstPageJumpRequests);

      controller.detach();
      await fakeTts.disposeStreams();
    });

    test('nextPageOrChapter 在有下一頁時翻頁，否則切章', () async {
      final fakeTts = FakeTtsService();
      final chapters = <int, ReaderChapter>{
        0: buildChapter(
          index: 0,
          title: 'Chapter 0',
          paragraphs: ['AAAAABBBBB', 'CCCCCDDDDD'],
        ),
        1: buildChapter(
          index: 1,
          title: 'Chapter 1',
          paragraphs: ['EEEEFFFFGG'],
        ),
      };
      var currentPageIndex = 0;
      var currentChapterIndex = 0;
      var currentCharOffset = 0;
      var nextPageCalls = 0;
      var nextChapterCalls = 0;

      final controller = ReadAloudController(
        tts: fakeTts,
        nextChapter: () async {
          nextChapterCalls++;
          currentChapterIndex = 1;
          currentPageIndex = 0;
          currentCharOffset = 0;
        },
        prevChapter: ({bool fromEnd = true}) async {},
        nextPage: () async {
          nextPageCalls++;
          currentPageIndex = 1;
          currentCharOffset = 10;
        },
        prevPage: () async {},
        canMoveToNextPage: () => currentPageIndex == 0,
        canMoveToPrevPage: () => currentPageIndex > 0,
        requestJumpToPage: (_) {},
        requestJumpToChapter:
            ({
              required int chapterIndex,
              required double alignment,
              required double localOffset,
            }) {},
        chapterOf: (chapterIndex) => chapters[chapterIndex],
        currentChapterIndex: () => currentChapterIndex,
        visibleChapterIndex: () => currentChapterIndex,
        currentCharOffset: () => currentCharOffset,
        visibleCharOffset: () => currentCharOffset,
        isScrollMode: () => false,
        onStateChanged: () {},
        updateMediaInfo: (_, __) {},
      );

      controller.attach();
      controller.toggle();
      await flushAsync();

      await controller.nextPageOrChapter();
      await flushAsync();

      expect(nextPageCalls, 1);
      expect(nextChapterCalls, 0);
      expect(currentPageIndex, 1);

      await controller.nextPageOrChapter();
      await flushAsync();

      expect(nextPageCalls, 1);
      expect(nextChapterCalls, 1);
      expect(currentChapterIndex, 1);

      controller.detach();
      await fakeTts.disposeStreams();
    });

    test('prevPageOrChapter 在有上一頁時翻頁，否則切章', () async {
      final fakeTts = FakeTtsService();
      final chapters = <int, ReaderChapter>{
        0: buildChapter(
          index: 0,
          title: 'Chapter 0',
          paragraphs: ['AAAAABBBBB'],
        ),
        1: buildChapter(
          index: 1,
          title: 'Chapter 1',
          paragraphs: ['CCCCCDDDDD', 'EEEEFFFFGG'],
        ),
      };
      var currentPageIndex = 1;
      var currentChapterIndex = 1;
      var currentCharOffset = 10;
      var prevPageCalls = 0;
      var prevChapterCalls = 0;

      final controller = ReadAloudController(
        tts: fakeTts,
        nextChapter: () async {},
        prevChapter: ({bool fromEnd = true}) async {
          prevChapterCalls++;
          currentChapterIndex = 0;
          currentPageIndex = 0;
          currentCharOffset = 0;
        },
        nextPage: () async {},
        prevPage: () async {
          prevPageCalls++;
          currentPageIndex = 0;
          currentCharOffset = 0;
        },
        canMoveToNextPage: () => true,
        canMoveToPrevPage: () => currentPageIndex > 0,
        requestJumpToPage: (_) {},
        requestJumpToChapter:
            ({
              required int chapterIndex,
              required double alignment,
              required double localOffset,
            }) {},
        chapterOf: (chapterIndex) => chapters[chapterIndex],
        currentChapterIndex: () => currentChapterIndex,
        visibleChapterIndex: () => currentChapterIndex,
        currentCharOffset: () => currentCharOffset,
        visibleCharOffset: () => currentCharOffset,
        isScrollMode: () => false,
        onStateChanged: () {},
        updateMediaInfo: (_, __) {},
      );

      controller.attach();
      controller.toggle();
      await flushAsync();

      await controller.prevPageOrChapter();
      await flushAsync();

      expect(prevPageCalls, 1);
      expect(prevChapterCalls, 0);
      expect(currentPageIndex, 0);

      await controller.prevPageOrChapter();
      await flushAsync();

      expect(prevPageCalls, 1);
      expect(prevChapterCalls, 1);
      expect(currentChapterIndex, 0);

      controller.detach();
      await fakeTts.disposeStreams();
    });

    test('prefetched handoff 會在章節完成後接續下一章', () async {
      final fakeTts = FakeTtsService();
      final chapters = <int, ReaderChapter>{
        0: buildChapter(
          index: 0,
          title: 'Chapter 0',
          paragraphs: ['AAAAABBBBB'],
        ),
        1: buildChapter(
          index: 1,
          title: 'Chapter 1',
          paragraphs: ['CCCCCDDDDD'],
        ),
      };
      var currentChapterIndex = 0;
      var nextChapterCalls = 0;

      final controller = ReadAloudController(
        tts: fakeTts,
        nextChapter: () async {
          nextChapterCalls++;
          currentChapterIndex = 1;
        },
        prevChapter: ({bool fromEnd = true}) async {},
        nextPage: () async {},
        prevPage: () async {},
        canMoveToNextPage: () => false,
        canMoveToPrevPage: () => false,
        requestJumpToPage: (_) {},
        requestJumpToChapter:
            ({
              required int chapterIndex,
              required double alignment,
              required double localOffset,
            }) {},
        chapterOf: (chapterIndex) => chapters[chapterIndex],
        currentChapterIndex: () => currentChapterIndex,
        visibleChapterIndex: () => currentChapterIndex,
        currentCharOffset: () => 0,
        visibleCharOffset: () => 0,
        isScrollMode: () => false,
        onStateChanged: () {},
        updateMediaInfo: (_, __) {},
      );

      controller.attach();
      controller.toggle();
      await flushAsync();

      expect(fakeTts.spokenTexts, hasLength(1));
      expect(controller.ttsChapterIndex, 0);

      await fakeTts.emitAudioEvent('onComplete');
      await flushAsync();

      expect(nextChapterCalls, 1);
      expect(fakeTts.spokenTexts, hasLength(2));
      expect(controller.ttsChapterIndex, 1);
      expect(controller.isActive, isTrue);

      controller.detach();
      await fakeTts.disposeStreams();
    });

    test('slide 模式 progress 會跳到對應頁並更新高亮', () async {
      final fakeTts = FakeTtsService();
      final chapters = <int, ReaderChapter>{
        0: buildChapter(
          index: 0,
          title: 'Chapter 0',
          paragraphs: ['AAAAABBBBB', 'CCCCCDDDDD'],
        ),
      };
      final pageJumpRequests = <int>[];

      final controller = ReadAloudController(
        tts: fakeTts,
        nextChapter: () async {},
        prevChapter: ({bool fromEnd = true}) async {},
        nextPage: () async {},
        prevPage: () async {},
        canMoveToNextPage: () => true,
        canMoveToPrevPage: () => false,
        requestJumpToPage: pageJumpRequests.add,
        requestJumpToChapter:
            ({
              required int chapterIndex,
              required double alignment,
              required double localOffset,
            }) {},
        chapterOf: (chapterIndex) => chapters[chapterIndex],
        currentChapterIndex: () => 0,
        visibleChapterIndex: () => 0,
        currentCharOffset: () => 0,
        visibleCharOffset: () => 0,
        isScrollMode: () => false,
        onStateChanged: () {},
        updateMediaInfo: (_, __) {},
      );

      controller.attach();
      controller.toggle();
      await flushAsync();

      fakeTts.emitProgress(14, 16);
      await flushAsync();

      expect(controller.ttsChapterIndex, 0);
      expect(controller.ttsStart, greaterThanOrEqualTo(0));
      expect(controller.ttsEnd, greaterThan(controller.ttsStart));
      expect(
        controller.ttsWordStart,
        greaterThanOrEqualTo(controller.ttsStart),
      );
      expect(controller.ttsWordEnd, greaterThan(controller.ttsWordStart));
      expect(pageJumpRequests, [1]);

      controller.detach();
      await fakeTts.disposeStreams();
    });

    test('跨章 handoff 後第一筆 progress 仍會產生下一章高亮', () async {
      final fakeTts = FakeTtsService();
      final chapters = <int, ReaderChapter>{
        0: buildChapter(
          index: 0,
          title: 'Chapter 0',
          paragraphs: ['AAAAABBBBB'],
        ),
        1: buildChapter(
          index: 1,
          title: 'Chapter 1',
          paragraphs: ['CCCCCDDDDD', 'EEEEFFFFGG'],
        ),
      };
      var currentChapterIndex = 0;

      final controller = ReadAloudController(
        tts: fakeTts,
        nextChapter: () async {
          currentChapterIndex = 1;
        },
        prevChapter: ({bool fromEnd = true}) async {},
        nextPage: () async {},
        prevPage: () async {},
        canMoveToNextPage: () => false,
        canMoveToPrevPage: () => false,
        requestJumpToPage: (_) {},
        requestJumpToChapter:
            ({
              required int chapterIndex,
              required double alignment,
              required double localOffset,
            }) {},
        chapterOf: (chapterIndex) => chapters[chapterIndex],
        currentChapterIndex: () => currentChapterIndex,
        visibleChapterIndex: () => currentChapterIndex,
        currentCharOffset: () => 0,
        visibleCharOffset: () => 0,
        isScrollMode: () => false,
        onStateChanged: () {},
        updateMediaInfo: (_, __) {},
      );

      controller.attach();
      controller.toggle();
      await flushAsync();

      await fakeTts.emitAudioEvent('onComplete');
      await flushAsync();

      fakeTts.emitProgress(0, 2);
      await flushAsync();

      expect(controller.ttsChapterIndex, 1);
      expect(controller.ttsStart, 0);
      expect(controller.ttsEnd, 5);
      expect(controller.ttsWordStart, 0);
      expect(controller.ttsWordEnd, 2);

      controller.detach();
      await fakeTts.disposeStreams();
    });

    test('空章節啟動 TTS 會安全回退到 idle', () async {
      final fakeTts = FakeTtsService();
      final chapters = <int, ReaderChapter>{
        0: ReaderChapter(
          chapter: BookChapter(title: 'Empty', index: 0, url: 'chapter-0'),
          index: 0,
          title: 'Empty',
          pages: const [],
        ),
      };

      final controller = ReadAloudController(
        tts: fakeTts,
        nextChapter: () async {},
        prevChapter: ({bool fromEnd = true}) async {},
        nextPage: () async {},
        prevPage: () async {},
        canMoveToNextPage: () => false,
        canMoveToPrevPage: () => false,
        requestJumpToPage: (_) {},
        requestJumpToChapter:
            ({
              required int chapterIndex,
              required double alignment,
              required double localOffset,
            }) {},
        chapterOf: (chapterIndex) => chapters[chapterIndex],
        currentChapterIndex: () => 0,
        visibleChapterIndex: () => 0,
        currentCharOffset: () => 0,
        visibleCharOffset: () => 0,
        isScrollMode: () => false,
        onStateChanged: () {},
        updateMediaInfo: (_, __) {},
      );

      controller.attach();
      controller.toggle();
      await flushAsync();

      expect(controller.isActive, isFalse);
      expect(fakeTts.spokenTexts, isEmpty);

      controller.detach();
      await fakeTts.disposeStreams();
    });

    test('handoff 到空下一章時會安全回退到 idle', () async {
      final fakeTts = FakeTtsService();
      final chapters = <int, ReaderChapter>{
        0: buildChapter(
          index: 0,
          title: 'Chapter 0',
          paragraphs: ['AAAAABBBBB'],
        ),
        1: ReaderChapter(
          chapter: BookChapter(title: 'Empty', index: 1, url: 'chapter-1'),
          index: 1,
          title: 'Empty',
          pages: const [],
        ),
      };
      var currentChapterIndex = 0;

      final controller = ReadAloudController(
        tts: fakeTts,
        nextChapter: () async {
          currentChapterIndex = 1;
        },
        prevChapter: ({bool fromEnd = true}) async {},
        nextPage: () async {},
        prevPage: () async {},
        canMoveToNextPage: () => false,
        canMoveToPrevPage: () => false,
        requestJumpToPage: (_) {},
        requestJumpToChapter:
            ({
              required int chapterIndex,
              required double alignment,
              required double localOffset,
            }) {},
        chapterOf: (chapterIndex) => chapters[chapterIndex],
        currentChapterIndex: () => currentChapterIndex,
        visibleChapterIndex: () => currentChapterIndex,
        currentCharOffset: () => 0,
        visibleCharOffset: () => 0,
        isScrollMode: () => false,
        onStateChanged: () {},
        updateMediaInfo: (_, __) {},
      );

      controller.attach();
      controller.toggle();
      await flushAsync();

      await fakeTts.emitAudioEvent('onComplete');
      await flushAsync();

      expect(controller.isActive, isFalse);
      expect(controller.ttsStart, -1);
      expect(controller.ttsEnd, -1);

      controller.detach();
      await fakeTts.disposeStreams();
    });
  });
}
