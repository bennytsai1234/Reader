import 'dart:async';

import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';

import 'reader_content_mixin.dart';
import 'reader_progress_mixin.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';

enum TtsState { idle, speaking, paused, transitioning }

enum AudioEvent {
  onPlay,
  onPause,
  onStop,
  onSkipToNext,
  onSkipToPrevious,
  onComplete;

  static AudioEvent? fromString(String value) {
    for (final e in values) {
      if (e.name == value) return e;
    }
    return null;
  }
}

class TtsSession {
  final int chapterIndex;
  final String text;
  final int baseOffset;
  final List<({int ttsOffset, int chapterOffset})> offsetMap;
  TtsSession? prefetchedNext;

  TtsSession({
    required this.chapterIndex,
    required this.text,
    required this.baseOffset,
    required this.offsetMap,
    this.prefetchedNext,
  });
}

mixin ReaderTtsMixin
    on
        ReaderProviderBase,
        ReaderSettingsMixin,
        ReaderContentMixin,
        ReaderProgressMixin {
  bool stopAfterChapter = false;
  TtsState _ttsState = TtsState.idle;
  TtsSession? _ttsSession;
  bool _suppressStopReset = false;
  int _ttsOperationVersion = 0;
  int _ttsStart = -1;
  int _ttsEnd = -1;
  int get ttsStart => _ttsStart;
  int get ttsEnd => _ttsEnd;
  int get ttsChapterIndex => _ttsSession?.chapterIndex ?? -1;
  int _lastTtsHighlightStart = -1;
  int _lastTtsHighlightEnd = -1;
  StreamSubscription? audioEventSub;
  int _ttsAnchorChapterIdx = -1;

  int get _currentTtsBaseOffset => _ttsSession?.baseOffset ?? 0;
  List<({int ttsOffset, int chapterOffset})> get _ttsTextOffsetMap =>
      _ttsSession?.offsetMap ?? const [];
  bool get _isTtsIdle => _ttsState == TtsState.idle;
  bool get _isTtsSpeaking => _ttsState == TtsState.speaking;
  bool _isCurrentTtsOperation(int version) =>
      !_isTtsIdle && _ttsOperationVersion == version;

  int _beginTtsOperation(TtsState state) {
    _ttsOperationVersion++;
    _ttsState = state;
    return _ttsOperationVersion;
  }

  void _setCurrentSession({
    required int chapterIndex,
    required String text,
    required int baseOffset,
    required List<({int ttsOffset, int chapterOffset})> offsetMap,
    TtsSession? prefetchedNext,
  }) {
    _ttsSession = TtsSession(
      chapterIndex: chapterIndex,
      text: text,
      baseOffset: baseOffset,
      offsetMap: offsetMap,
      prefetchedNext: prefetchedNext,
    );
  }

  void _resetTtsState({
    bool stopPlayback = false,
    bool suppressStopReset = false,
    bool clearAnchors = true,
    TtsState state = TtsState.idle,
  }) {
    _ttsState = state;
    _ttsOperationVersion++;
    if (stopPlayback) {
      _suppressStopReset = suppressStopReset;
      TTSService().stop();
    }
    _ttsStart = -1;
    _ttsEnd = -1;
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _ttsSession = null;
    if (clearAnchors) {
      _ttsAnchorChapterIdx = -1;
    }
  }

  void initTtsListener() {
    TTSService().addListener(_onTtsProgressUpdate);
  }

  void disposeTtsListener() {
    TTSService().removeListener(_onTtsProgressUpdate);
  }

  void listenAudioEvents() {
    audioEventSub?.cancel();
    audioEventSub = TTSService().audioEvents.listen((event) {
      final audioEvent = AudioEvent.fromString(event);
      if (audioEvent == null) {
        AppLog.w('Unknown audio event: $event');
        return;
      }
      switch (audioEvent) {
        case AudioEvent.onPlay:
          if (!TTSService().isPlaying) toggleTts();
        case AudioEvent.onPause:
          if (TTSService().isPlaying) {
            _ttsState = TtsState.paused;
            TTSService().pause();
          }
        case AudioEvent.onStop:
          if (_suppressStopReset) {
            _suppressStopReset = false;
            return;
          }
          _resetTtsState();
          notifyListeners();
        case AudioEvent.onSkipToNext:
          unawaited(nextPageOrChapter());
        case AudioEvent.onSkipToPrevious:
          unawaited(prevPageOrChapter());
        case AudioEvent.onComplete:
          unawaited(_onTtsComplete());
      }
    });
  }

  void _onTtsProgressUpdate() {
    if (!TTSService().isPlaying || _ttsTextOffsetMap.isEmpty) return;
    final rawStart = TTSService().currentWordStart;
    if (rawStart < 0) return;

    var chapterBase = _currentTtsBaseOffset;
    for (final entry in _ttsTextOffsetMap.reversed) {
      if (rawStart >= entry.ttsOffset) {
        chapterBase = entry.chapterOffset + (rawStart - entry.ttsOffset);
        break;
      }
    }

    if (_lastTtsHighlightStart >= 0 &&
        chapterBase >= _lastTtsHighlightStart &&
        chapterBase < _lastTtsHighlightEnd) {
      return;
    }

    final pages = chapterPagesCache[ttsChapterIndex] ?? const <TextPage>[];
    var hlStart = chapterBase;
    var hlEnd = chapterBase + 1;
    for (final page in pages) {
      int? targetParagraphNum;
      for (final line in page.lines) {
        if (line.image != null) continue;
        final lineEnd = line.chapterPosition + line.text.length;
        if (chapterBase >= line.chapterPosition && chapterBase < lineEnd) {
          targetParagraphNum = line.paragraphNum;
          break;
        }
      }
      if (targetParagraphNum != null) {
        final paraLines = page.lines
            .where((line) =>
                line.paragraphNum == targetParagraphNum && line.image == null)
            .toList();
        if (paraLines.isNotEmpty) {
          hlStart = paraLines.first.chapterPosition;
          hlEnd = paraLines.last.chapterPosition + paraLines.last.text.length;
        }
        break;
      }
    }

    _lastTtsHighlightStart = hlStart;
    _lastTtsHighlightEnd = hlEnd;

    var needsNotify = false;
    if (_ttsStart != hlStart || _ttsEnd != hlEnd) {
      _ttsStart = hlStart;
      _ttsEnd = hlEnd;
      needsNotify = true;
    }

    if (pageTurnMode != PageAnim.scroll) {
      final pageIndex =
          ChapterPositionResolver.findPageIndexByCharOffset(pages, chapterBase);
      final globalIndex = slidePages.indexWhere(
        (page) => page.chapterIndex == ttsChapterIndex && page.index == pageIndex,
      );
      if (globalIndex >= 0 && currentPageIndex != globalIndex) {
        currentPageIndex = globalIndex;
        requestJumpToPage(globalIndex);
        needsNotify = true;
      }
    } else {
      requestJumpToChapter(
        chapterIndex: ttsChapterIndex,
        alignment: ChapterPositionResolver.charOffsetToAlignment(
          pages,
          chapterBase,
        ),
        localOffset: ChapterPositionResolver.charOffsetToLocalOffset(
          pages,
          chapterBase,
        ),
      );
      needsNotify = true;
    }

    if (needsNotify) notifyListeners();
  }

  (String, List<({int ttsOffset, int chapterOffset})>) prepareTtsData(
    List<TextLine> lines,
  ) {
    final buffer = StringBuffer();
    final map = <({int ttsOffset, int chapterOffset})>[];
    var ttsPos = 0;
    var lastParagraphNum = -1;
    final filteredLines = lines.where((line) => line.image == null).toList();
    for (final line in filteredLines) {
      if (lastParagraphNum != -1 && line.paragraphNum != lastParagraphNum) {
        buffer.write('\n');
        ttsPos += 1;
      }
      map.add((ttsOffset: ttsPos, chapterOffset: line.chapterPosition));
      buffer.write(line.text);
      ttsPos += line.text.length;
      lastParagraphNum = line.paragraphNum;
    }
    return (buffer.toString(), map);
  }

  void _prefetchNextChapterTts() {
    final anchorChapter =
        _ttsAnchorChapterIdx >= 0 ? _ttsAnchorChapterIdx : ttsChapterIndex;
    final nextChapterIdx = anchorChapter + 1;
    if (nextChapterIdx >= chapters.length) return;
    final nextPages = chapterPagesCache[nextChapterIdx];
    if (nextPages == null || nextPages.isEmpty) return;
    final allLines = <TextLine>[];
    for (final page in nextPages) {
      allLines.addAll(page.lines);
    }
    final visibleLines = allLines.where((line) => line.image == null).toList();
    if (visibleLines.isEmpty) return;
    final (text, map) = prepareTtsData(allLines);
    _ttsSession?.prefetchedNext = TtsSession(
      chapterIndex: nextChapterIdx,
      text: text,
      baseOffset: visibleLines.first.chapterPosition,
      offsetMap: map,
    );
  }

  Future<void> _onTtsComplete() async {
    if (!_isTtsSpeaking) return;
    final operationVersion = _ttsOperationVersion;
    _ttsState = TtsState.transitioning;
    try {
      _ttsStart = -1;
      _ttsEnd = -1;
      _lastTtsHighlightStart = -1;
      _lastTtsHighlightEnd = -1;
      final prefetchedSession = _ttsSession?.prefetchedNext;
      await nextChapter();
      if (!_isCurrentTtsOperation(operationVersion)) return;

      if (stopAfterChapter) {
        stopAfterChapter = false;
        _resetTtsState(stopPlayback: true);
        return;
      }

      if (prefetchedSession != null) {
        _ttsAnchorChapterIdx = prefetchedSession.chapterIndex;
        _setCurrentSession(
          chapterIndex: prefetchedSession.chapterIndex,
          text: prefetchedSession.text,
          baseOffset: prefetchedSession.baseOffset,
          offsetMap: prefetchedSession.offsetMap,
        );
        _ttsState = TtsState.speaking;
        await TTSService().speak(prefetchedSession.text);
        if (!_isCurrentTtsOperation(operationVersion)) return;
        _prefetchNextChapterTts();
      } else {
        await _startTts(operationVersion: operationVersion);
      }
      notifyListeners();
    } catch (e) {
      AppLog.e('TTS: nextChapter failed in _onTtsComplete: $e', error: e);
      _resetTtsState();
    }
  }

  Future<void> nextPageOrChapter() async {
    final operationVersion = _beginTtsOperation(TtsState.transitioning);
    _suppressStopReset = true;
    TTSService().stop();

    if (pageTurnMode == PageAnim.scroll) {
      await nextChapter();
      if (_isCurrentTtsOperation(operationVersion)) {
        await _startTts(operationVersion: operationVersion);
      }
      notifyListeners();
      return;
    }

    final curIdx = currentPageIndex;
    if (curIdx >= 0 && curIdx < slidePages.length - 1) {
      onPageChanged(curIdx + 1);
      await _startTts(operationVersion: operationVersion);
      notifyListeners();
      return;
    }

    try {
      await nextChapter();
      if (_isCurrentTtsOperation(operationVersion)) {
        await _startTts(operationVersion: operationVersion);
      }
    } catch (e) {
      AppLog.e('TTS: nextPageOrChapter failed: $e', error: e);
      _resetTtsState();
    }
    notifyListeners();
  }

  Future<void> prevPageOrChapter() async {
    final operationVersion = _beginTtsOperation(TtsState.transitioning);
    _suppressStopReset = true;
    TTSService().stop();

    if (pageTurnMode == PageAnim.scroll) {
      await prevChapter(fromEnd: false);
      if (_isCurrentTtsOperation(operationVersion)) {
        await _startTts(operationVersion: operationVersion);
      }
      notifyListeners();
      return;
    }

    final curIdx = currentPageIndex;
    if (curIdx > 0) {
      onPageChanged(curIdx - 1);
      await _startTts(operationVersion: operationVersion);
      notifyListeners();
      return;
    }

    try {
      await prevChapter();
      if (_isCurrentTtsOperation(operationVersion)) {
        await _startTts(operationVersion: operationVersion);
      }
    } catch (e) {
      AppLog.e('TTS: prevPageOrChapter failed: $e', error: e);
      _resetTtsState();
    }
    notifyListeners();
  }

  void setStopAfterChapter(bool val) {
    stopAfterChapter = val;
    notifyListeners();
  }

  void stopTts() {
    _resetTtsState(stopPlayback: true);
    notifyListeners();
  }

  void startTtsFromLine(int lineIndex) {
    _resetTtsState(stopPlayback: true, suppressStopReset: true);
    final operationVersion = _beginTtsOperation(TtsState.speaking);
    unawaited(
      _startTts(startLineIndex: lineIndex, operationVersion: operationVersion),
    );
    notifyListeners();
  }

  void toggleTts() {
    if (TTSService().isPlaying) {
      _ttsState = TtsState.paused;
      TTSService().pause();
    } else if (_ttsState == TtsState.paused ||
        (_ttsSession != null && _ttsStart >= 0)) {
      _ttsState = TtsState.speaking;
      TTSService().resume();
    } else {
      final pages = chapterPagesCache[currentChapterIndex] ?? const <TextPage>[];
      if (pages.isEmpty || isLoading) return;
      final operationVersion = _beginTtsOperation(TtsState.speaking);
      unawaited(_startTts(operationVersion: operationVersion));
    }
    notifyListeners();
  }

  Future<void> _startTts({
    int startLineIndex = -1,
    int? operationVersion,
  }) async {
    final activeOperationVersion =
        operationVersion ?? _beginTtsOperation(TtsState.speaking);
    if (!_isCurrentTtsOperation(activeOperationVersion)) return;
    _ttsState = TtsState.speaking;
    onTtsStartCallback?.call();

    final targetChapterIndex =
        pageTurnMode == PageAnim.scroll ? visibleChapterIndex : currentChapterIndex;
    final allChapterPages =
        chapterPagesCache[targetChapterIndex] ?? const <TextPage>[];
    if (allChapterPages.isEmpty) return;

    final startCharPos = startLineIndex >= 0
        ? allChapterPages
                .expand((page) => page.lines)
                .where((line) => line.image == null)
                .elementAt(startLineIndex)
                .chapterPosition
        : (pageTurnMode == PageAnim.scroll
            ? ChapterPositionResolver.localOffsetToCharOffset(
                allChapterPages,
                visibleChapterLocalOffset,
              )
            : ChapterPositionResolver.getCharOffsetForPage(
                allChapterPages,
                ChapterPositionResolver.findPageIndexByCharOffset(
                  allChapterPages,
                  book.durChapterPos,
                ),
              ));

    final linesToRead = <TextLine>[];
    for (final page in allChapterPages) {
      for (final line in page.lines) {
        if (line.image != null) continue;
        if (line.chapterPosition >= startCharPos) {
          linesToRead.add(line);
        }
      }
    }
    if (linesToRead.isEmpty) return;

    final (text, map) = prepareTtsData(linesToRead);
    if (text.trim().isEmpty) return;
    if (!_isCurrentTtsOperation(activeOperationVersion)) return;

    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _setCurrentSession(
      chapterIndex: targetChapterIndex,
      text: text,
      baseOffset: linesToRead.first.chapterPosition,
      offsetMap: map,
    );
    _ttsAnchorChapterIdx = targetChapterIndex;

    await TTSService().speak(text);
    if (!_isCurrentTtsOperation(activeOperationVersion)) return;
    TTSService().updateMediaInfo(title: book.name, author: book.author);
    _prefetchNextChapterTts();
    notifyListeners();
  }

  VoidCallback? onTtsStartCallback;

  void resetTtsHighlightCache() {
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
  }

  void saveTtsProgress() {
    if (TTSService().isPlaying || _ttsStart >= 0) {
      final savedTtsStart = _ttsStart;
      final progressChapterIndex =
          ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex;
      TTSService().stop();
      _resetTtsState();
      if (savedTtsStart >= 0) {
        book.durChapterIndex = progressChapterIndex;
        book.durChapterPos = savedTtsStart;
        final title = chapters.isNotEmpty &&
                progressChapterIndex < chapters.length
            ? chapters[progressChapterIndex].title
            : '';
        book.durChapterTitle = title;
        unawaited(bookDao.updateProgress(
          book.bookUrl,
          progressChapterIndex,
          title,
          savedTtsStart,
        ));
      } else {
        saveProgress(currentChapterIndex, currentPageIndex);
      }
    }
  }

  bool get isTtsActive =>
      _ttsState != TtsState.idle || TTSService().isPlaying || _ttsStart >= 0;
}
