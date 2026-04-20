import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/engine/reader_perf_trace.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';

enum ReadAloudState { idle, speaking, paused, transitioning }

class ReadAloudSession {
  final int chapterIndex;
  final String text;
  final int baseOffset;
  final List<({int ttsOffset, int chapterOffset})> offsetMap;
  ReadAloudSession? prefetchedNext;

  ReadAloudSession({
    required this.chapterIndex,
    required this.text,
    required this.baseOffset,
    required this.offsetMap,
    this.prefetchedNext,
  });
}

class ReadAloudController extends ChangeNotifier {
  final TTSService _tts;
  final Future<void> Function() nextChapter;
  final Future<void> Function({bool fromEnd}) prevChapter;
  final Future<void> Function() nextPage;
  final Future<void> Function() prevPage;
  final bool Function() canMoveToNextPage;
  final bool Function() canMoveToPrevPage;
  final void Function(int pageIndex) requestJumpToPage;
  final void Function({
    required int chapterIndex,
    required double alignment,
    required double localOffset,
  })
  requestJumpToChapter;
  final ReaderChapter? Function(int chapterIndex) chapterOf;
  final int Function() currentChapterIndex;
  final int Function() visibleChapterIndex;
  final int Function() currentCharOffset;
  final int Function() visibleCharOffset;
  final bool Function() isScrollMode;
  final void Function() onStateChanged;
  final void Function(String title, String author) updateMediaInfo;

  ReadAloudController({
    required TTSService tts,
    required this.nextChapter,
    required this.prevChapter,
    required this.nextPage,
    required this.prevPage,
    required this.canMoveToNextPage,
    required this.canMoveToPrevPage,
    required this.requestJumpToPage,
    required this.requestJumpToChapter,
    required this.chapterOf,
    required this.currentChapterIndex,
    required this.visibleChapterIndex,
    required this.currentCharOffset,
    required this.visibleCharOffset,
    required this.isScrollMode,
    required this.onStateChanged,
    required this.updateMediaInfo,
  }) : _tts = tts;

  ReadAloudState _state = ReadAloudState.idle;
  ReadAloudSession? _session;
  int _opVersion = 0;
  int _ttsStart = -1;
  int _ttsEnd = -1;
  int _ttsWordStart = -1;
  int _ttsWordEnd = -1;
  int _anchorChapterIdx = -1;
  int _lastHighlightStart = -1;
  int _lastHighlightEnd = -1;
  bool _suppressStopReset = false;
  bool _stopAfterChapter = false;
  StreamSubscription? _audioEventSub;

  int get ttsStart => _ttsStart;
  int get ttsEnd => _ttsEnd;
  int get ttsWordStart => _ttsWordStart;
  int get ttsWordEnd => _ttsWordEnd;
  int get ttsChapterIndex => _session?.chapterIndex ?? -1;
  bool get isActive =>
      _state != ReadAloudState.idle || _tts.isPlaying || _ttsStart >= 0;
  bool get isPlaying => _tts.isPlaying;
  bool get stopAfterChapter => _stopAfterChapter;

  void setStopAfterChapter(bool value) {
    _stopAfterChapter = value;
    notifyController();
  }

  void attach() {
    _tts.addListener(_onTtsProgressUpdate);
    _audioEventSub?.cancel();
    _audioEventSub = _tts.audioEvents.listen((event) {
      switch (event) {
        case 'onPlay':
          if (!_tts.isPlaying) toggle();
          break;
        case 'onPause':
          if (_tts.isPlaying) {
            _state = ReadAloudState.paused;
            _tts.pause();
            notifyController();
          }
          break;
        case 'onStop':
          if (_suppressStopReset) {
            _suppressStopReset = false;
            break;
          }
          _resetState();
          notifyController();
          break;
        case 'onSkipToNext':
          unawaited(nextPageOrChapter());
          break;
        case 'onSkipToPrevious':
          unawaited(prevPageOrChapter());
          break;
        case 'onComplete':
          unawaited(_onComplete());
          break;
      }
    });
  }

  void detach() {
    _tts.removeListener(_onTtsProgressUpdate);
    _audioEventSub?.cancel();
    _audioEventSub = null;
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }

  void notifyController() {
    onStateChanged();
    notifyListeners();
  }

  int _begin(ReadAloudState state) {
    _opVersion++;
    _state = state;
    return _opVersion;
  }

  bool _isCurrent(int version) =>
      _state != ReadAloudState.idle && _opVersion == version;

  void _setSession({
    required int chapterIndex,
    required String text,
    required int baseOffset,
    required List<({int ttsOffset, int chapterOffset})> offsetMap,
    ReadAloudSession? prefetchedNext,
  }) {
    _session = ReadAloudSession(
      chapterIndex: chapterIndex,
      text: text,
      baseOffset: baseOffset,
      offsetMap: offsetMap,
      prefetchedNext: prefetchedNext,
    );
  }

  void _resetState({
    bool stopPlayback = false,
    bool suppressStopReset = false,
  }) {
    _state = ReadAloudState.idle;
    _opVersion++;
    _ttsStart = -1;
    _ttsEnd = -1;
    _ttsWordStart = -1;
    _ttsWordEnd = -1;
    _lastHighlightStart = -1;
    _lastHighlightEnd = -1;
    _session = null;
    _anchorChapterIdx = -1;
    if (stopPlayback) {
      _suppressStopReset = suppressStopReset;
      _tts.stop();
    }
  }

  void stop() {
    _resetState(stopPlayback: true);
    notifyController();
  }

  void toggle() {
    if (_tts.isPlaying) {
      _state = ReadAloudState.paused;
      _tts.pause();
      notifyController();
      return;
    }
    if (_state == ReadAloudState.paused ||
        (_session != null && _ttsStart >= 0)) {
      _state = ReadAloudState.speaking;
      _tts.resume();
      notifyController();
      return;
    }
    final version = _begin(ReadAloudState.speaking);
    final targetChapterIndex =
        isScrollMode() ? visibleChapterIndex() : currentChapterIndex();
    final targetChapter = chapterOf(targetChapterIndex);
    final startOffset =
        targetChapter?.firstPage == null
            ? 0
            : targetChapter!.firstCharOffset(targetChapter.firstPage!);
    unawaited(
      _start(
        operationVersion: version,
        startChapterIndex: targetChapterIndex,
        startCharOffset: startOffset,
      ),
    );
    notifyController();
  }

  void startFromLine(int lineIndex) {
    _resetState(stopPlayback: true, suppressStopReset: true);
    final version = _begin(ReadAloudState.speaking);
    unawaited(_start(startLineIndex: lineIndex, operationVersion: version));
    notifyController();
  }

  Future<void> _start({
    int startLineIndex = -1,
    int? operationVersion,
    int? startChapterIndex,
    int? startCharOffset,
  }) async {
    final version = operationVersion ?? _begin(ReadAloudState.speaking);
    if (!_isCurrent(version)) return;

    final targetChapterIndex =
        startChapterIndex ??
        (isScrollMode() ? visibleChapterIndex() : currentChapterIndex());
    final targetChapter = chapterOf(targetChapterIndex);
    if (targetChapter == null || targetChapter.isEmpty) {
      _failCurrentStart(version);
      return;
    }

    final pages = targetChapter.pages;
    final startCharPos =
        startLineIndex >= 0
            ? pages
                .expand((page) => page.lines)
                .where((line) => line.image == null)
                .elementAt(startLineIndex)
                .chapterPosition
            : (startCharOffset ??
                (isScrollMode() ? visibleCharOffset() : currentCharOffset()));

    final data = targetChapter.buildReadAloudData(
      startCharOffset: startCharPos,
    );
    if (data == null || data.text.trim().isEmpty) {
      _failCurrentStart(version);
      return;
    }
    if (!_isCurrent(version)) return;

    _lastHighlightStart = -1;
    _lastHighlightEnd = -1;
    _setSession(
      chapterIndex: targetChapterIndex,
      text: data.text,
      baseOffset: data.baseOffset,
      offsetMap: data.offsetMap,
    );
    _anchorChapterIdx = targetChapterIndex;

    await ReaderPerfTrace.measureAsync(
      'tts speak chapter $targetChapterIndex',
      () => _tts.speak(data.text),
    );
    if (!_isCurrent(version)) return;
    updateMediaInfo('', '');
    _prefetchNextChapter();
    notifyController();
  }

  void _prefetchNextChapter() {
    final anchor = _anchorChapterIdx >= 0 ? _anchorChapterIdx : ttsChapterIndex;
    final nextIdx = anchor + 1;
    final chapter = chapterOf(nextIdx);
    if (chapter == null || chapter.isEmpty) return;
    final data = chapter.buildReadAloudData(
      startCharOffset:
          chapter.firstPage == null
              ? 0
              : chapter.firstCharOffset(chapter.firstPage!),
    );
    if (data == null || data.text.trim().isEmpty) return;
    _session?.prefetchedNext = ReadAloudSession(
      chapterIndex: nextIdx,
      text: data.text,
      baseOffset: data.baseOffset,
      offsetMap: data.offsetMap,
    );
    ReaderPerfTrace.mark(
      'tts prefetched next chapter $nextIdx textLength=${data.text.length}',
    );
  }

  int _chapterOffsetFromTtsOffset(ReadAloudSession session, int rawStart) {
    var chapterOffset = session.baseOffset;
    for (final entry in session.offsetMap.reversed) {
      if (rawStart >= entry.ttsOffset) {
        chapterOffset = entry.chapterOffset + (rawStart - entry.ttsOffset);
        break;
      }
    }
    return chapterOffset;
  }

  void _jumpToChapterOffset({
    required ReaderChapter chapter,
    required int chapterOffset,
    int? pageIndex,
  }) {
    final resolvedPageIndex =
        pageIndex ?? chapter.getPageIndexByCharIndex(chapterOffset);
    if (isScrollMode()) {
      final anchor = chapter.resolveScrollAnchor(chapterOffset);
      requestJumpToChapter(
        chapterIndex: chapter.index,
        alignment: anchor.alignment,
        localOffset: anchor.localOffset,
      );
      return;
    }
    requestJumpToPage(resolvedPageIndex);
  }

  void _onTtsProgressUpdate() {
    if (!_tts.isPlaying || _session == null || _session!.offsetMap.isEmpty)
      return;
    final rawStart = _tts.currentWordStart;
    final rawEnd = _tts.currentWordEnd;
    if (rawStart < 0) return;

    final chapterBase = _chapterOffsetFromTtsOffset(_session!, rawStart);
    final chapterWordEnd =
        rawEnd <= rawStart
            ? chapterBase + 1
            : _chapterOffsetFromTtsOffset(
              _session!,
              rawEnd,
            ).clamp(chapterBase + 1, double.infinity).toInt();

    final chapter = chapterOf(ttsChapterIndex);
    if (chapter == null) return;
    final line = chapter.lineAtCharOffset(chapterBase);
    final highlightStart = line?.chapterPosition ?? chapterBase;
    final highlightEnd =
        line == null ? chapterWordEnd : line.chapterPosition + line.text.length;

    if (_lastHighlightStart >= 0 &&
        _lastHighlightStart == highlightStart &&
        _lastHighlightEnd == highlightEnd &&
        _ttsWordStart == chapterBase &&
        _ttsWordEnd == chapterWordEnd) {
      return;
    }

    _lastHighlightStart = highlightStart;
    _lastHighlightEnd = highlightEnd;
    _ttsStart = highlightStart;
    _ttsEnd = highlightEnd;
    _ttsWordStart = chapterBase;
    _ttsWordEnd = chapterWordEnd;

    if (!isScrollMode()) {
      final targetPageIndex = chapter.getPageIndexByCharIndex(chapterBase);
      final visiblePageIndex =
          currentChapterIndex() == ttsChapterIndex
              ? chapter.getPageIndexByCharIndex(currentCharOffset())
              : -1;
      if (visiblePageIndex == targetPageIndex) {
        notifyController();
        return;
      }
      _jumpToChapterOffset(
        chapter: chapter,
        chapterOffset: chapterBase,
        pageIndex: targetPageIndex,
      );
    }
    notifyController();
  }

  Future<void> _onComplete() async {
    if (_state != ReadAloudState.speaking) return;
    final version = _opVersion;
    _state = ReadAloudState.transitioning;
    try {
      _ttsStart = -1;
      _ttsEnd = -1;
      _ttsWordStart = -1;
      _ttsWordEnd = -1;
      _lastHighlightStart = -1;
      _lastHighlightEnd = -1;
      notifyController();
      final prefetched = _session?.prefetchedNext;
      await ReaderPerfTrace.measureAsync(
        'tts chapter handoff nextChapter',
        () => nextChapter(),
      );
      if (!_isCurrent(version)) return;
      if (_stopAfterChapter) {
        _stopAfterChapter = false;
        _resetState(stopPlayback: true);
        notifyController();
        return;
      }
      if (prefetched != null) {
        _anchorChapterIdx = prefetched.chapterIndex;
        _setSession(
          chapterIndex: prefetched.chapterIndex,
          text: prefetched.text,
          baseOffset: prefetched.baseOffset,
          offsetMap: prefetched.offsetMap,
        );
        _state = ReadAloudState.speaking;
        await ReaderPerfTrace.measureAsync(
          'tts handoff speak chapter ${prefetched.chapterIndex}',
          () => _tts.speak(prefetched.text),
        );
        if (!_isCurrent(version)) return;
        _prefetchNextChapter();
      } else {
        await _start(operationVersion: version);
        if (_state == ReadAloudState.idle) return;
      }
      notifyController();
    } catch (_) {
      _resetState();
      notifyController();
    }
  }

  Future<void> nextPageOrChapter() async {
    final version = _begin(ReadAloudState.transitioning);
    _suppressStopReset = true;
    await _tts.stop();
    if (isScrollMode()) {
      final chapterIndex =
          ttsChapterIndex >= 0 ? ttsChapterIndex : visibleChapterIndex();
      final chapter = chapterOf(chapterIndex);
      final currentOffset =
          _ttsWordStart >= 0
              ? _ttsWordStart
              : (_ttsStart >= 0 ? _ttsStart : visibleCharOffset());
      final nextOffset = chapter?.nextPageStartCharOffset(currentOffset) ?? -1;
      final nextPageIndex =
          nextOffset >= 0 ? chapter!.getPageIndexByCharIndex(nextOffset) : -1;
      if (chapter != null && nextOffset >= 0 && nextPageIndex >= 0) {
        _jumpToChapterOffset(
          chapter: chapter,
          chapterOffset: nextOffset,
          pageIndex: nextPageIndex,
        );
        if (_isCurrent(version)) {
          await _start(
            operationVersion: version,
            startChapterIndex: chapterIndex,
            startCharOffset: nextOffset,
          );
        }
        notifyController();
        return;
      }
    } else if (canMoveToNextPage()) {
      await nextPage();
      if (_isCurrent(version)) {
        await _start(operationVersion: version);
      }
      notifyController();
      return;
    }

    await nextChapter();
    if (_isCurrent(version)) {
      await _start(operationVersion: version);
    }
    notifyController();
  }

  Future<void> prevPageOrChapter() async {
    final version = _begin(ReadAloudState.transitioning);
    _suppressStopReset = true;
    await _tts.stop();
    if (isScrollMode()) {
      final chapterIndex =
          ttsChapterIndex >= 0 ? ttsChapterIndex : visibleChapterIndex();
      final chapter = chapterOf(chapterIndex);
      final currentOffset =
          _ttsWordStart >= 0
              ? _ttsWordStart
              : (_ttsStart >= 0 ? _ttsStart : visibleCharOffset());
      final prevOffset = chapter?.prevPageStartCharOffset(currentOffset) ?? -1;
      final prevPageIndex =
          prevOffset >= 0 ? chapter!.getPageIndexByCharIndex(prevOffset) : -1;
      if (chapter != null && prevOffset >= 0 && prevPageIndex >= 0) {
        _jumpToChapterOffset(
          chapter: chapter,
          chapterOffset: prevOffset,
          pageIndex: prevPageIndex,
        );
        if (_isCurrent(version)) {
          await _start(
            operationVersion: version,
            startChapterIndex: chapterIndex,
            startCharOffset: prevOffset,
          );
        }
        notifyController();
        return;
      }
    } else if (canMoveToPrevPage()) {
      await prevPage();
      if (_isCurrent(version)) {
        await _start(operationVersion: version);
      }
      notifyController();
      return;
    }

    await prevChapter(fromEnd: false);
    if (_isCurrent(version)) {
      await _start(operationVersion: version);
    }
    notifyController();
  }

  Future<void> saveProgress({
    required void Function(int chapterIndex, int charOffset) persist,
  }) async {
    if (_tts.isPlaying || _ttsStart >= 0 || _ttsWordStart >= 0) {
      final savedStart = _ttsWordStart >= 0 ? _ttsWordStart : _ttsStart;
      final chapterIndex =
          ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex();
      await _tts.stop();
      _resetState();
      if (savedStart >= 0) {
        persist(chapterIndex, savedStart);
      }
    }
  }

  void _failCurrentStart(int version) {
    if (!_isCurrent(version)) return;
    _resetState(stopPlayback: true);
    notifyController();
  }
}
