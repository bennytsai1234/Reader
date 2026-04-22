import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_content_manager.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PaginationConfig makeConfig() {
    const style = TextStyle(fontSize: 16, height: 1.5);
    return const PaginationConfig(
      viewSize: Size(1000, 1200),
      titleStyle: style,
      contentStyle: style,
      textIndent: 0,
    );
  }

  List<BookChapter> makeChapters(int count) {
    return List.generate(
      count,
      (i) => BookChapter(title: 'chapter-$i', index: i),
    );
  }

  group('ChapterContentManager', () {
    test('getChapterPages 快取命中時不重複抓取', () async {
      int fetchCount = 0;
      final manager = ChapterContentManager(
        fetchFn: (index) async {
          fetchCount++;
          return FetchResult(content: 'content-$index');
        },
        chapters: makeChapters(3),
      );
      manager.updateConfig(makeConfig());

      final first = await manager.getChapterPages(1);
      final second = await manager.getChapterPages(1);

      expect(first, isNotEmpty);
      expect(identical(first, second), isTrue);
      expect(fetchCount, 1);

      manager.dispose();
    });

    test('updateWindow 會建立 5 章視窗並驅逐視窗外快取', () async {
      final manager = ChapterContentManager(
        fetchFn: (index) async => FetchResult(content: 'content-$index'),
        chapters: makeChapters(8),
      );
      manager.updateConfig(makeConfig());

      await manager.getChapterPages(0);
      await manager.getChapterPages(1);
      await manager.getChapterPages(6);

      manager.updateWindow(1);
      expect(manager.isChapterInWindow(0), isTrue);
      expect(manager.isChapterInWindow(1), isTrue);
      expect(manager.isChapterInWindow(2), isTrue);
      expect(manager.isChapterInWindow(3), isTrue);
      expect(manager.isChapterInWindow(4), isTrue);
      expect(manager.isChapterInWindow(5), isFalse);

      final evicted = manager.evictOutsideWindow();
      expect(evicted, {6});
      expect(manager.getCachedPages(6), isNull);
      expect(manager.getCachedPages(0), isNotNull);

      manager.dispose();
    });

    test('evictOutsideWindow 會保留 retained chapter cache', () async {
      final manager = ChapterContentManager(
        fetchFn: (index) async => FetchResult(content: 'content-$index'),
        chapters: makeChapters(8),
      );
      manager.updateConfig(makeConfig());
      manager.seedPages(1, _fakePages(1));
      manager.seedPages(6, _fakePages(6));
      manager.seedPages(7, _fakePages(7));

      manager.updateWindow(1, preload: false);
      final evicted = manager.evictOutsideWindow(retainedIndexes: {6});

      expect(evicted, {7});
      expect(manager.getCachedPages(1), isNotNull);
      expect(manager.getCachedPages(6), isNotNull);
      expect(manager.getCachedPages(7), isNull);

      manager.dispose();
    });

    test('onChapterReady 會通知預載完成章節', () async {
      final ready = <int>[];
      final completers = <int, Completer<FetchResult>>{};
      completers[2] = Completer<FetchResult>();

      final manager = ChapterContentManager(
        fetchFn: (index) {
          return (completers[index] ??= Completer<FetchResult>()).future;
        },
        chapters: makeChapters(6),
      );
      manager.updateConfig(makeConfig());

      final sub = manager.onChapterReady.listen(ready.add);
      manager.updateWindow(2);

      // 視窗中心章節會優先進入預載佇列，完成後應收到 ready 通知
      completers[2]!.complete(FetchResult(content: 'content-2'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(ready, contains(2));
      await sub.cancel();
      manager.dispose();
    });

    test('預載順序會優先靠近 window 中心的章節', () async {
      final fetchOrder = <int>[];
      final completers = <int, Completer<FetchResult>>{};

      final manager = ChapterContentManager(
        fetchFn: (index) {
          fetchOrder.add(index);
          return (completers[index] ??= Completer<FetchResult>()).future;
        },
        chapters: makeChapters(7),
      );
      manager.updateConfig(makeConfig());

      manager.updateWindow(3);

      expect(fetchOrder, isNotEmpty);
      expect(fetchOrder.first, 3);

      completers[3]!.complete(FetchResult(content: 'content-3'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(fetchOrder.length, greaterThanOrEqualTo(2));
      expect(fetchOrder[1], anyOf(2, 4));

      manager.dispose();
    });

    test('主動載入會等待同章節的靜默預載完成', () async {
      final completer = Completer<FetchResult>();
      final fetchOrder = <int>[];
      final manager = ChapterContentManager(
        fetchFn: (index) async {
          fetchOrder.add(index);
          return completer.future;
        },
        chapters: makeChapters(5),
      );
      manager.updateConfig(makeConfig());

      manager.updateWindow(2);
      final pagesFuture = manager.getChapterPages(2);

      expect(fetchOrder, [2]);
      expect(manager.activeLoadingChapters, contains(2));
      expect(manager.silentLoadingChapters, contains(2));

      completer.complete(FetchResult(content: 'content-2'));
      final pages = await pagesFuture;

      expect(pages, isNotEmpty);
      expect(fetchOrder.where((index) => index == 2).length, 1);

      manager.dispose();
    });

    test('repaginateAll 會使用新設定重建已快取章節', () async {
      final manager = ChapterContentManager(
        fetchFn:
            (index) async =>
                FetchResult(content: List.filled(120, 'chapter-$index').join()),
        chapters: makeChapters(3),
      );

      manager.updateConfig(
        const PaginationConfig(
          viewSize: Size(1000, 1200),
          titleStyle: TextStyle(fontSize: 16, height: 1.5),
          contentStyle: TextStyle(fontSize: 16, height: 1.5),
        ),
      );
      final firstPages = await manager.getChapterPages(1);

      manager.updateConfig(
        const PaginationConfig(
          viewSize: Size(220, 260),
          titleStyle: TextStyle(fontSize: 16, height: 1.5),
          contentStyle: TextStyle(fontSize: 16, height: 1.5),
        ),
      );
      await manager.repaginateAll();

      final repaginatedPages = manager.getCachedPages(1)!;
      expect(repaginatedPages.length, greaterThan(firstPages.length));

      manager.dispose();
    });

    test('repaginateForDisplay 會先保留舊 cache，commit 後才原子切換', () async {
      final manager = ChapterContentManager(
        fetchFn:
            (index) async =>
                FetchResult(content: List.filled(120, 'chapter-$index').join()),
        chapters: makeChapters(3),
      );

      manager.updateConfig(
        const PaginationConfig(
          viewSize: Size(1000, 1200),
          titleStyle: TextStyle(fontSize: 16, height: 1.5),
          contentStyle: TextStyle(fontSize: 16, height: 1.5),
        ),
      );
      final firstPages = await manager.getChapterPages(1);
      manager.updateWindow(1, preload: false);

      manager.updateConfig(
        const PaginationConfig(
          viewSize: Size(220, 260),
          titleStyle: TextStyle(fontSize: 16, height: 1.5),
          contentStyle: TextStyle(fontSize: 16, height: 1.5),
        ),
      );

      final ready = <int>[];
      final sub = manager.onChapterReady.listen(ready.add);
      await manager.repaginateForDisplay(
        centerChapterIndex: 1,
        isScrollMode: false,
      );

      expect(manager.hasPendingDisplayRepagination, isTrue);
      expect(identical(manager.getCachedPages(1), firstPages), isTrue);
      expect(ready, isEmpty);

      manager.commitPendingDisplayRepagination();
      final repaginatedPages = manager.getCachedPages(1)!;
      expect(repaginatedPages.length, greaterThan(firstPages.length));
      expect(identical(repaginatedPages, firstPages), isFalse);

      await sub.cancel();
      manager.dispose();
    });

    test('warmupWindow 會補抓目前視窗中尚未暖機的章節', () async {
      final fetchOrder = <int>[];
      final completers = <int, Completer<FetchResult>>{};
      final manager = ChapterContentManager(
        fetchFn: (index) {
          fetchOrder.add(index);
          return (completers[index] ??= Completer<FetchResult>()).future;
        },
        chapters: makeChapters(7),
      );
      manager.updateConfig(makeConfig());

      final initialLoad = manager.getChapterPages(3);
      expect(fetchOrder, [3]);
      completers[3]!.complete(FetchResult(content: 'chapter-3'));
      await initialLoad;

      fetchOrder.clear();
      manager.updateWindow(3, preloadRadius: 0);
      expect(fetchOrder, isEmpty, reason: 'bootstrap 階段不應額外預抓鄰章');

      manager.warmupWindow(3);
      expect(fetchOrder, isNotEmpty);
      expect(fetchOrder.first, anyOf(2, 4));

      for (final completer in completers.values) {
        if (!completer.isCompleted) {
          completer.complete(FetchResult(content: 'warmup'));
        }
      }

      manager.dispose();
    });

    test('空內容章節只抓取一次，不無限重試', () async {
      int fetchCount = 0;
      final manager = ChapterContentManager(
        fetchFn: (index) async {
          fetchCount++;
          return FetchResult(content: ''); // 空內容
        },
        chapters: makeChapters(3),
      );
      manager.updateConfig(makeConfig());

      final first = await manager.getChapterPages(0);
      final second = await manager.getChapterPages(0); // 不應再次抓取

      expect(first, isEmpty);
      expect(second, isEmpty);
      expect(fetchCount, 1, reason: '空內容應只抓取一次，不重試');

      manager.dispose();
    });

    test('updateConfig 清除快取後，進行中的分頁結果不應覆蓋快取', () async {
      final fetchStarted = Completer<void>();
      final fetchCanProceed = Completer<void>();

      final manager = ChapterContentManager(
        fetchFn: (index) async {
          fetchStarted.complete(); // signal: fetch has started
          await fetchCanProceed.future; // wait for test to call updateConfig
          return FetchResult(content: 'content-$index');
        },
        chapters: makeChapters(3),
      );
      manager.updateConfig(makeConfig());

      // Trigger loading (don't await)
      final fetchFuture = manager.getChapterPages(0);

      // Wait for fetch to start, then change config while fetch is in progress
      await fetchStarted.future;
      manager.updateConfig(makeConfig()); // version bump + cache clear

      // Allow fetch to complete
      fetchCanProceed.complete();
      await fetchFuture;

      // Result from old config should NOT be in cache after updateConfig cleared it
      expect(
        manager.getCachedPages(0),
        isNull,
        reason: 'updateConfig 後快取應被清除，進行中的舊分頁結果不應寫回',
      );

      manager.dispose();
    });

    test('enableWholeBookPreload 會把全書章節排進預載佇列', () async {
      final fetchOrder = <int>[];
      final completers = <int, Completer<FetchResult>>{};
      final manager = ChapterContentManager(
        fetchFn: (index) {
          fetchOrder.add(index);
          return (completers[index] ??= Completer<FetchResult>()).future;
        },
        chapters: makeChapters(6),
      );
      manager.updateConfig(makeConfig());

      final firstLoad = manager.getChapterPages(3);
      completers[3]!.complete(FetchResult(content: 'chapter-3'));
      await firstLoad;

      fetchOrder.clear();
      manager.enableWholeBookPreload(startIndex: 3);

      expect(manager.wholeBookPreloadEnabled, isTrue);
      for (int i = 0; i < 6; i++) {
        expect(manager.isChapterInWindow(i), isTrue);
      }
      expect(fetchOrder, isNotEmpty);
      expect(fetchOrder.first, anyOf(2, 4));

      for (final completer in completers.values) {
        if (!completer.isCompleted) {
          completer.complete(FetchResult(content: 'whole-book'));
        }
      }

      manager.dispose();
    });

    test(
      'prioritizeChapter 會保留 retained chapter，不驅逐 current neighborhood',
      () async {
        final manager = ChapterContentManager(
          fetchFn: (index) async => FetchResult(content: 'content-$index'),
          chapters: makeChapters(8),
        );
        manager.updateConfig(makeConfig());
        manager.seedPages(1, _fakePages(1));
        manager.seedPages(2, _fakePages(2));
        manager.seedPages(3, _fakePages(3));
        manager.seedPages(6, _fakePages(6));

        manager.prioritizeChapter(6, retainedIndexes: {0, 1, 2});

        expect(manager.getCachedPages(1), isNotNull);
        expect(manager.getCachedPages(2), isNotNull);
        expect(manager.getCachedPages(3), isNull);
        expect(manager.getCachedPages(6), isNotNull);

        manager.dispose();
      },
    );
  });
}

List<TextPage> _fakePages(int chapterIndex) {
  return <TextPage>[
    TextPage(
      index: 0,
      lines: const <TextLine>[],
      title: 'chapter-$chapterIndex',
      chapterIndex: chapterIndex,
    ),
  ];
}
