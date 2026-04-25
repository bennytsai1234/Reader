import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/features/reader/engine/reader_perf_trace.dart';
import 'package:inkpage_reader/features/reader/runtime/models/read_aloud_segment.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_position.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine.dart';

enum ReadAloudState { idle, speaking, paused, transitioning }

class ReadAloudSession {
  final int chapterIndex;
  final List<ReadAloudSegment> segments;
  int currentSegmentIndex;
  ReadAloudSession? prefetchedNext;

  ReadAloudSession({
    required this.chapterIndex,
    required this.segments,
    this.currentSegmentIndex = 0,
    this.prefetchedNext,
  });

  ReadAloudSegment? get currentSegment {
    if (currentSegmentIndex < 0 || currentSegmentIndex >= segments.length) {
      return null;
    }
    return segments[currentSegmentIndex];
  }

  bool moveToNextSegment() {
    if (currentSegmentIndex + 1 >= segments.length) {
      return false;
    }
    currentSegmentIndex += 1;
    return true;
  }

  int get totalSpeakLength =>
      segments.fold(0, (sum, segment) => sum + segment.text.length);
}

class ReadAloudController extends ChangeNotifier {
  final ReaderTtsEngine _ttsEngine;
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
    required ReaderTtsEngine ttsEngine,
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
  }) : _ttsEngine = ttsEngine;

  ReadAloudState _state = ReadAloudState.idle;
  ReadAloudSession? _session;
  int _opVersion = 0;
  ReaderTtsPosition? _currentTtsPosition;
  int _anchorChapterIdx = -1;
  int _lastHighlightStart = -1;
  int _lastHighlightEnd = -1;
  bool _suppressStopReset = false;
  bool _stopAfterChapter = false;
  StreamSubscription<ReaderTtsEngineEvent>? _engineEventSub;

  ReaderTtsPosition? get currentTtsPosition => _currentTtsPosition;
  int get ttsStart => _currentTtsPosition?.highlightStart ?? -1;
  int get ttsEnd => _currentTtsPosition?.highlightEnd ?? -1;
  int get ttsWordStart => _currentTtsPosition?.wordStart ?? -1;
  int get ttsWordEnd => _currentTtsPosition?.wordEnd ?? -1;
  int get ttsChapterIndex =>
      _currentTtsPosition?.chapterIndex ?? _session?.chapterIndex ?? -1;
  Set<int> get retainedChapterIndexes {
    final retained = <int>{};
    final activeChapterIndex =
        _session?.chapterIndex ?? _currentTtsPosition?.chapterIndex;
    if (activeChapterIndex != null && activeChapterIndex >= 0) {
      retained.add(activeChapterIndex);
    }
    final prefetchedChapterIndex = _session?.prefetchedNext?.chapterIndex;
    if (prefetchedChapterIndex != null && prefetchedChapterIndex >= 0) {
      retained.add(prefetchedChapterIndex);
    }
    return retained;
  }

  bool get isActive =>
      _state != ReadAloudState.idle ||
      _ttsEngine.isPlaying ||
      _currentTtsPosition != null;
  bool get isPlaying => _ttsEngine.isPlaying;
  bool get stopAfterChapter => _stopAfterChapter;

  void setStopAfterChapter(bool value) {
    _stopAfterChapter = value;
    notifyController();
  }

  void attach() {
    _engineEventSub?.cancel();
    _engineEventSub = _ttsEngine.events.listen(_onEngineEvent);
  }

  void detach() {
    _engineEventSub?.cancel();
    _engineEventSub = null;
  }

  @override
  void dispose() {
    detach();
    unawaited(_ttsEngine.dispose());
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
    required List<ReadAloudSegment> segments,
    int currentSegmentIndex = 0,
    ReadAloudSession? prefetchedNext,
  }) {
    _session = ReadAloudSession(
      chapterIndex: chapterIndex,
      segments: segments,
      currentSegmentIndex: currentSegmentIndex,
      prefetchedNext: prefetchedNext,
    );
  }

  void _resetState({
    bool stopPlayback = false,
    bool suppressStopReset = false,
  }) {
    _state = ReadAloudState.idle;
    _opVersion++;
    _currentTtsPosition = null;
    _lastHighlightStart = -1;
    _lastHighlightEnd = -1;
    _session = null;
    _anchorChapterIdx = -1;
    if (stopPlayback) {
      _suppressStopReset = suppressStopReset;
      unawaited(_ttsEngine.stop());
    }
  }

  void stop() {
    _resetState(stopPlayback: true);
    notifyController();
  }

  void toggle() {
    if (_ttsEngine.isPlaying) {
      _state = ReadAloudState.paused;
      _ttsEngine.pause();
      notifyController();
      return;
    }
    if (_state == ReadAloudState.paused ||
        (_session != null && _currentTtsPosition != null)) {
      final version = _begin(ReadAloudState.speaking);
      final resumeChapterIndex =
          ttsChapterIndex >= 0
              ? ttsChapterIndex
              : (isScrollMode()
                  ? visibleChapterIndex()
                  : currentChapterIndex());
      final resumeCharOffset =
          ttsWordStart >= 0
              ? ttsWordStart
              : (ttsStart >= 0
                  ? ttsStart
                  : (isScrollMode()
                      ? visibleCharOffset()
                      : currentCharOffset()));
      unawaited(
        _start(
          operationVersion: version,
          startChapterIndex: resumeChapterIndex,
          startCharOffset: resumeCharOffset,
        ),
      );
      notifyController();
      return;
    }
    final version = _begin(ReadAloudState.speaking);
    final targetChapterIndex =
        isScrollMode() ? visibleChapterIndex() : currentChapterIndex();
    final targetChapter = chapterOf(targetChapterIndex);
    final startOffset =
        isScrollMode() ? visibleCharOffset() : currentCharOffset();
    unawaited(
      _start(
        operationVersion: version,
        startChapterIndex: targetChapterIndex,
        startCharOffset:
            startOffset >= 0
                ? startOffset
                : (targetChapter?.firstPage == null
                    ? 0
                    : targetChapter!.firstCharOffset(targetChapter.firstPage!)),
      ),
    );
    notifyController();
  }

  @Deprecated('Use startFromOffset instead.')
  void startFromLine(int lineIndex) {
    final targetChapterIndex =
        isScrollMode() ? visibleChapterIndex() : currentChapterIndex();
    final targetChapter = chapterOf(targetChapterIndex);
    if (targetChapter == null || targetChapter.isEmpty) return;
    final textLines = targetChapter.pages
        .expand((page) => page.lines)
        .where((line) => line.image == null)
        .toList(growable: false);
    if (lineIndex < 0 || lineIndex >= textLines.length) return;
    startFromOffset(
      chapterIndex: targetChapterIndex,
      charOffset: textLines[lineIndex].chapterPosition,
    );
  }

  void startFromOffset({int? chapterIndex, required int charOffset}) {
    _resetState(stopPlayback: true, suppressStopReset: true);
    final version = _begin(ReadAloudState.speaking);
    unawaited(
      _start(
        operationVersion: version,
        startChapterIndex: chapterIndex,
        startCharOffset: charOffset,
      ),
    );
    notifyController();
  }

  Future<void> _start({
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

    final startCharPos =
        startCharOffset ??
        (isScrollMode() ? visibleCharOffset() : currentCharOffset());

    final result = targetChapter.buildParagraphReadAloudSegments(
      startCharOffset: startCharPos,
    );
    if (result == null || result.segments.isEmpty) {
      _failCurrentStart(version);
      return;
    }
    if (!_isCurrent(version)) return;

    _lastHighlightStart = -1;
    _lastHighlightEnd = -1;
    _setSession(chapterIndex: targetChapterIndex, segments: result.segments);
    _anchorChapterIdx = targetChapterIndex;

    await _speakCurrentSegment(
      version: version,
      traceLabel: 'tts speak chapter $targetChapterIndex',
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
    final result = chapter.buildParagraphReadAloudSegments(
      startCharOffset:
          chapter.firstPage == null
              ? 0
              : chapter.firstCharOffset(chapter.firstPage!),
    );
    if (result == null || result.segments.isEmpty) return;
    _session?.prefetchedNext = ReadAloudSession(
      chapterIndex: nextIdx,
      segments: result.segments,
    );
    ReaderPerfTrace.mark(
      'tts prefetched next chapter $nextIdx segments=${result.segments.length} textLength=${_session?.prefetchedNext?.totalSpeakLength ?? 0}',
    );
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

  Future<void> _speakCurrentSegment({
    required int version,
    required String traceLabel,
  }) async {
    final session = _session;
    final segment = session?.currentSegment;
    if (session == null || segment == null || !_isCurrent(version)) return;
    final chapter = chapterOf(session.chapterIndex);
    if (chapter == null) return;
    _applyTtsPosition(
      chapter: chapter,
      segment: segment,
      chapterBase: segment.chapterStart,
      chapterWordEnd: segment.chapterStart + 1,
    );
    await ReaderPerfTrace.measureAsync(
      '$traceLabel segment ${session.currentSegmentIndex}',
      () => _ttsEngine.speak(segment.text),
    );
  }

  void _applyTtsPosition({
    required ReaderChapter chapter,
    ReadAloudSegment? segment,
    required int chapterBase,
    required int chapterWordEnd,
  }) {
    final safeWordEnd =
        chapterWordEnd <= chapterBase ? chapterBase + 1 : chapterWordEnd;
    final line =
        chapter.lineAtCharOffset(chapterBase) ??
        chapter.lineAtCharOffset(safeWordEnd - 1);
    final highlightStart = line?.chapterPosition ?? chapterBase;
    final highlightEnd =
        line == null ? safeWordEnd : line.chapterPosition + line.text.length;
    final lineChanged =
        _lastHighlightStart != highlightStart ||
        _lastHighlightEnd != highlightEnd;

    if (_lastHighlightStart >= 0 &&
        _lastHighlightStart == highlightStart &&
        _lastHighlightEnd == highlightEnd &&
        ttsWordStart == chapterBase &&
        ttsWordEnd == safeWordEnd) {
      return;
    }

    final locatedLine = chapter.locateLineAtCharOffset(highlightStart);
    final resolvedPageIndex =
        locatedLine?.pageIndex ??
        segment?.pageIndex ??
        chapter.getPageIndexByCharIndex(highlightStart);
    final resolvedLineIndex =
        locatedLine?.lineIndex ?? segment?.lineIndex ?? -1;
    final localOffset = chapter.localOffsetFromCharOffset(highlightStart);
    final position = ReaderTtsPosition(
      chapterIndex: chapter.index,
      pageIndex: resolvedPageIndex,
      lineIndex: resolvedLineIndex,
      highlightStart: highlightStart,
      highlightEnd: highlightEnd,
      wordStart: chapterBase,
      wordEnd: safeWordEnd,
      localOffset: localOffset,
      followKey: Object.hash(chapter.index, highlightStart, highlightEnd),
    );

    _lastHighlightStart = highlightStart;
    _lastHighlightEnd = highlightEnd;
    _currentTtsPosition = position;

    if (!isScrollMode()) {
      final targetPageIndex = position.pageIndex;
      final visiblePageIndex =
          currentChapterIndex() == ttsChapterIndex
              ? chapter.getPageIndexByCharIndex(currentCharOffset())
              : -1;
      if (lineChanged && visiblePageIndex != targetPageIndex) {
        _jumpToChapterOffset(
          chapter: chapter,
          chapterOffset: chapterBase,
          pageIndex: targetPageIndex,
        );
      }
    }
    notifyController();
  }

  void _onEngineEvent(ReaderTtsEngineEvent event) {
    if (event is ReaderTtsEngineProgress) {
      _onTtsProgressUpdate(wordStart: event.wordStart, wordEnd: event.wordEnd);
      return;
    }
    if (event is ReaderTtsEngineCompleted) {
      unawaited(_onComplete());
      return;
    }
    if (event is! ReaderTtsEngineCommand) return;

    switch (event.action) {
      case ReaderTtsEngineCommandAction.play:
        if (!_ttsEngine.isPlaying) toggle();
        return;
      case ReaderTtsEngineCommandAction.pause:
        if (_ttsEngine.isPlaying) {
          _state = ReadAloudState.paused;
          _ttsEngine.pause();
          notifyController();
        }
        return;
      case ReaderTtsEngineCommandAction.stop:
        if (_suppressStopReset) {
          _suppressStopReset = false;
          return;
        }
        _resetState();
        notifyController();
        return;
      case ReaderTtsEngineCommandAction.skipToNext:
        unawaited(nextPageOrChapter());
        return;
      case ReaderTtsEngineCommandAction.skipToPrevious:
        unawaited(prevPageOrChapter());
        return;
    }
  }

  void _onTtsProgressUpdate({required int wordStart, required int wordEnd}) {
    final session = _session;
    final segment = session?.currentSegment;
    if (!_ttsEngine.isPlaying || session == null || segment == null) return;
    final rawStart = wordStart;
    final rawEnd = wordEnd;
    if (rawStart < 0) return;

    final normalizedStart = rawStart.clamp(0, segment.text.length).toInt();
    final normalizedEnd = rawEnd.clamp(0, segment.text.length).toInt();
    final chapterBase = segment.chapterOffsetForTtsOffset(normalizedStart);
    final chapterWordEnd =
        normalizedEnd <= normalizedStart
            ? (chapterBase + 1 <= segment.chapterEnd
                ? chapterBase + 1
                : segment.chapterEnd)
            : segment
                .chapterOffsetForTtsOffset(normalizedEnd)
                .clamp(chapterBase + 1, segment.chapterEnd)
                .toInt();

    final chapter = chapterOf(ttsChapterIndex);
    if (chapter == null) return;
    _applyTtsPosition(
      chapter: chapter,
      segment: segment,
      chapterBase: chapterBase,
      chapterWordEnd: chapterWordEnd,
    );
  }

  Future<void> _onComplete() async {
    if (_state != ReadAloudState.speaking) return;
    final version = _opVersion;
    if (_session?.moveToNextSegment() ?? false) {
      await _speakCurrentSegment(
        version: version,
        traceLabel: 'tts speak chapter ${_session!.chapterIndex}',
      );
      if (_isCurrent(version)) {
        notifyController();
      }
      return;
    }

    _state = ReadAloudState.transitioning;
    try {
      _currentTtsPosition = null;
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
          segments: prefetched.segments,
          currentSegmentIndex: prefetched.currentSegmentIndex,
        );
        _state = ReadAloudState.speaking;
        await _speakCurrentSegment(
          version: version,
          traceLabel: 'tts handoff speak chapter ${prefetched.chapterIndex}',
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
    await _ttsEngine.stop();
    if (isScrollMode()) {
      final chapterIndex =
          ttsChapterIndex >= 0 ? ttsChapterIndex : visibleChapterIndex();
      final chapter = chapterOf(chapterIndex);
      final currentOffset =
          ttsWordStart >= 0
              ? ttsWordStart
              : (ttsStart >= 0 ? ttsStart : visibleCharOffset());
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
    await _ttsEngine.stop();
    if (isScrollMode()) {
      final chapterIndex =
          ttsChapterIndex >= 0 ? ttsChapterIndex : visibleChapterIndex();
      final chapter = chapterOf(chapterIndex);
      final currentOffset =
          ttsWordStart >= 0
              ? ttsWordStart
              : (ttsStart >= 0 ? ttsStart : visibleCharOffset());
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
    if (_ttsEngine.isPlaying || ttsStart >= 0 || ttsWordStart >= 0) {
      final savedStart = ttsWordStart >= 0 ? ttsWordStart : ttsStart;
      final chapterIndex =
          ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex();
      await _ttsEngine.stop();
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
