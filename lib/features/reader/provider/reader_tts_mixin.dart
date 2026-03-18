import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'reader_content_mixin.dart';
import 'reader_progress_mixin.dart';

/// ReaderProvider 的 TTS 朗讀擴展
/// 負責：TTS 控制、高亮追蹤、預取機制、章節邊界銜接
mixin ReaderTtsMixin on ReaderProviderBase, ReaderSettingsMixin, ReaderContentMixin, ReaderProgressMixin {
  int _currentTtsBaseOffset = 0; // 當前朗讀塊在章節中的起始偏移量
  bool stopAfterChapter = false;
  /// 取消旗標：stopTts() 後設為 true，防止 pending 的 nextChapter().then() 繼續執行
  bool _ttsCancelled = false;
  List<({int ttsOffset, int chapterOffset})> _ttsTextOffsetMap = [];

  // 預取下一頁內容，消除銜接停頓
  String? _prefetchedTtsText;
  List<({int ttsOffset, int chapterOffset})>? _prefetchedOffsetMap;
  int _prefetchedBaseOffset = 0;

  int _ttsStart = -1;
  int _ttsEnd = -1;
  int get ttsStart => _ttsStart;
  int get ttsEnd => _ttsEnd;

  /// TTS 正在朗讀的章節索引：用於跨章節滾動模式中過濾高亮，防止多章節重複高亮
  int _ttsChapterIndex = -1;
  int get ttsChapterIndex => _ttsChapterIndex;

  // TTS 高亮快取：避免 progressUpdate 每次觸發都重新遍歷所有頁面行
  int _lastTtsHighlightStart = -1;
  int _lastTtsHighlightEnd = -1;

  // TTS 章節邊界預取：消除章節切換時的銜接停頓
  String? _prefetchedChapterTtsText;
  List<({int ttsOffset, int chapterOffset})>? _prefetchedChapterOffsetMap;
  int _prefetchedChapterBaseOffset = 0;

  StreamSubscription? audioEventSub;

  /// TTS 絕對錨點：記住「目前讀到哪個章節的哪個字元之後」
  /// 完全不依賴 currentPageIndex，使用者滑動頁面不會影響這兩個值
  int _ttsAnchorChapterIdx = -1;
  int _ttsAnchorEndCharPos = 0;

  /// 預取頁的錨點資訊（供 _onTtsComplete 推進主錨點使用）
  int _prefetchedAnchorChapterIdx = -1;
  int _prefetchedAnchorEndCharPos = 0;

  /// 預取下一章節的錨點資訊
  int _prefetchedChapterAnchorChapterIdx = -1;
  int _prefetchedChapterAnchorEndCharPos = 0;

  void initTtsListener() {
    TTSService().addListener(_onTtsProgressUpdate);
  }

  void listenAudioEvents() {
    audioEventSub?.cancel();
    audioEventSub = TTSService().audioEvents.listen((event) {
      switch (event) {
        case 'onPlay':
          if (!TTSService().isPlaying) toggleTts();
          break;
        case 'onPause':
          if (TTSService().isPlaying) TTSService().pause();
          break;
        case 'onStop':
          _ttsStart = -1;
          _ttsEnd = -1;
          notifyListeners();
          break;
        case 'onSkipToNext':
          nextPageOrChapter();
          break;
        case 'onSkipToPrevious':
          prevPageOrChapter();
          break;
        case 'onComplete':
          _onTtsComplete();
          break;
      }
    });
  }

  void _onTtsProgressUpdate() {
    if (!TTSService().isPlaying || _ttsTextOffsetMap.isEmpty) return;

    final rawStart = TTSService().currentWordStart;

    // 查表：將 TTS 字串位置映射到章節字元位置
    int chapterBase = _currentTtsBaseOffset;
    for (final entry in _ttsTextOffsetMap.reversed) {
      if (rawStart >= entry.ttsOffset) {
        chapterBase = entry.chapterOffset + (rawStart - entry.ttsOffset);
        break;
      }
    }

    // 快取命中：chapterBase 仍在上次高亮段落範圍內，跳過全頁掃描
    if (_lastTtsHighlightStart >= 0 &&
        chapterBase >= _lastTtsHighlightStart &&
        chapterBase < _lastTtsHighlightEnd) {
      return;
    }

    // 以段落為單位高亮（對標 Android upPageAloudSpan：整段一起標記）
    // 只掃描屬於目前 TTS 章節的頁面，避免跨章節時重複高亮相同 chapterPosition
    int hlStart = chapterBase;
    int hlEnd = chapterBase + 1;
    for (final page in pages) {
      if (_ttsChapterIndex >= 0 && page.chapterIndex != _ttsChapterIndex) continue;
      
      // Phase 1：頁面級 Skip (O(N) 降維優化)
      if (page.lines.isNotEmpty) {
        final lastTextLine = page.lines.lastWhere((l) => l.image == null, orElse: () => page.lines.last);
        final pageEnd = lastTextLine.chapterPosition + lastTextLine.text.length;
        if (chapterBase >= pageEnd) continue; // 目標在更後面的頁面

        final firstTextLine = page.lines.firstWhere((l) => l.image == null, orElse: () => page.lines.first);
        final pageStart = firstTextLine.chapterPosition;
        if (chapterBase < pageStart) break; // 已超過目標，安全跳出迴圈
      }

      int? targetParagraphNum;
      for (final line in page.lines) {
        if (line.image != null) continue;
        final lEnd = line.chapterPosition + line.text.length;
        if (chapterBase >= line.chapterPosition && chapterBase < lEnd) {
          targetParagraphNum = line.paragraphNum;
          break;
        }
      }
      if (targetParagraphNum != null) {
        final paraLines = page.lines
            .where((l) => l.paragraphNum == targetParagraphNum && l.image == null)
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

    if (_ttsStart != hlStart || _ttsEnd != hlEnd) {
      _ttsStart = hlStart;
      _ttsEnd = hlEnd;
      notifyListeners();
    }
  }

  /// 抽取文本與偏移映射建構邏輯，供 start 與 prefetch 共用
  (String, List<({int ttsOffset, int chapterOffset})>) prepareTtsData(List<TextLine> lines) {
    final buffer = StringBuffer();
    final map = <({int ttsOffset, int chapterOffset})>[];
    int ttsPos = 0;
    int lastParagraphNum = -1;

    final List<TextLine> filteredLines = lines.where((l) => l.image == null).toList();

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

  void _prefetchNextPage() {
    final nextIdx = _findNextTtsPageIdx();
    if (nextIdx < 0) {
      _prefetchedTtsText = null;
      _prefetchedAnchorChapterIdx = -1;
      _prefetchedAnchorEndCharPos = 0;
      // 錨點章節已無下一頁：嘗試預取下一章節第一頁的 TTS 文本
      _prefetchNextChapterTts();
      return;
    }
    final nextPage = pages[nextIdx];
    if (nextPage.lines.isEmpty) return;

    final (text, map) = prepareTtsData(nextPage.lines);
    _prefetchedTtsText = text;
    _prefetchedOffsetMap = map;
    final firstTextLine = nextPage.lines.firstWhere((l) => l.image == null, orElse: () => nextPage.lines.first);
    _prefetchedBaseOffset = firstTextLine.chapterPosition;
    final lastTextLine = nextPage.lines.lastWhere((l) => l.image == null, orElse: () => nextPage.lines.last);
    _prefetchedAnchorChapterIdx = nextPage.chapterIndex;
    _prefetchedAnchorEndCharPos = lastTextLine.chapterPosition + lastTextLine.text.length;
  }

  /// 預取下一章節第一頁的 TTS 文本，消除章節切換時的停頓
  void _prefetchNextChapterTts() {
    // Bug 4 修復：使用 TTS 絕對錨點章節（而非 currentChapterIndex），
    // 防止捲動模式下 currentChapterIndex 因 UI 滑動而漂移
    final anchorChapter = _ttsAnchorChapterIdx >= 0 ? _ttsAnchorChapterIdx : _ttsChapterIndex;
    final nextChapterIdx = anchorChapter + 1;
    if (nextChapterIdx >= chapters.length) return;

    final nextPages = chapterCache[nextChapterIdx];
    if (nextPages == null || nextPages.isEmpty) return;

    final firstPage = nextPages.first;
    final visibleLines = firstPage.lines.where((l) => l.image == null).toList();
    if (visibleLines.isEmpty) return;

    final (text, map) = prepareTtsData(firstPage.lines);
    _prefetchedChapterTtsText = text;
    _prefetchedChapterOffsetMap = map;
    _prefetchedChapterBaseOffset = visibleLines.first.chapterPosition;
    _prefetchedChapterAnchorChapterIdx = nextChapterIdx;
    _prefetchedChapterAnchorEndCharPos = visibleLines.last.chapterPosition + visibleLines.last.text.length;
  }

  /// 根據 TTS 絕對錨點，從 pages[] 中搜尋下一個應朗讀的頁面索引。
  /// 返回 -1 代表錨點章節中已無更多頁（需切換至下一章節）。
  int _findNextTtsPageIdx() {
    if (_ttsAnchorChapterIdx < 0) return -1;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      if (page.chapterIndex != _ttsAnchorChapterIdx) continue;
      if (page.lines.isEmpty) continue;
      final firstTextLine = page.lines.firstWhere(
          (l) => l.image == null, orElse: () => page.lines.first);
      if (firstTextLine.chapterPosition >= _ttsAnchorEndCharPos) return i;
      // 頁面結尾超過錨點：錨點落在此頁中間（partial read），繼續讀此頁
      final lastTextLine = page.lines.lastWhere(
          (l) => l.image == null, orElse: () => page.lines.last);
      if (lastTextLine.chapterPosition + lastTextLine.text.length > _ttsAnchorEndCharPos) return i;
    }
    return -1;
  }

  void _onTtsComplete() {
    if (_ttsCancelled) return;

    // 根據 TTS 絕對錨點找下一頁，完全不依賴 currentPageIndex（Bug 1、2、3 根治）
    final nextIdx = _findNextTtsPageIdx();

    if (nextIdx >= 0) {
      // 有下一頁：推進並開始朗讀
      _lastTtsHighlightStart = -1;
      _lastTtsHighlightEnd = -1;

      // 分頁模式：更新 UI 頁碼並跳轉；滾動模式不動（UI 由捲動事件驅動）
      if (pageTurnMode != PageAnim.scroll) {
        currentPageIndex = nextIdx;
        jumpPageController.add(nextIdx);
      }

      if (_prefetchedTtsText != null && _prefetchedOffsetMap != null &&
          _prefetchedAnchorChapterIdx >= 0) {
        // 快速路徑：使用預取好的數據，消除銜接停頓
        final textToSpeak = _prefetchedTtsText!;
        _currentTtsBaseOffset = _prefetchedBaseOffset;
        _ttsTextOffsetMap = _prefetchedOffsetMap!;
        _ttsChapterIndex = _prefetchedAnchorChapterIdx;
        // 推進主錨點至剛消費的預取頁
        _ttsAnchorChapterIdx = _prefetchedAnchorChapterIdx;
        _ttsAnchorEndCharPos = _prefetchedAnchorEndCharPos;
        // 清除已消費的預取
        _prefetchedTtsText = null;
        _prefetchedOffsetMap = null;
        _prefetchedAnchorChapterIdx = -1;
        _prefetchedAnchorEndCharPos = 0;
        TTSService().speak(textToSpeak);
        _prefetchNextPage(); // 以更新後的錨點預取下下頁
      } else {
        _startTts();
      }
    } else {
      // 錨點章節已無下一頁：優先使用章節邊界預取文本，減少停頓
      final chapterPrefetchText = _prefetchedChapterTtsText;
      final chapterPrefetchMap = _prefetchedChapterOffsetMap;
      final chapterPrefetchBase = _prefetchedChapterBaseOffset;
      final chapterPrefetchAnchorChapterIdx = _prefetchedChapterAnchorChapterIdx;
      final chapterPrefetchAnchorEndCharPos = _prefetchedChapterAnchorEndCharPos;
      _prefetchedChapterTtsText = null;
      _prefetchedChapterOffsetMap = null;
      _prefetchedChapterAnchorChapterIdx = -1;
      _prefetchedChapterAnchorEndCharPos = 0;

      nextChapter().then((_) {
        if (_ttsCancelled) return;
        if (stopAfterChapter) {
          stopAfterChapter = false;
          TTSService().stop();
        } else {
          _lastTtsHighlightStart = -1;
          _lastTtsHighlightEnd = -1;
          if (chapterPrefetchText != null && chapterPrefetchMap != null &&
              chapterPrefetchAnchorChapterIdx >= 0) {
            _currentTtsBaseOffset = chapterPrefetchBase;
            _ttsTextOffsetMap = chapterPrefetchMap;
            _ttsChapterIndex = chapterPrefetchAnchorChapterIdx;
            // 推進主錨點到新章節第一頁
            _ttsAnchorChapterIdx = chapterPrefetchAnchorChapterIdx;
            _ttsAnchorEndCharPos = chapterPrefetchAnchorEndCharPos;
            TTSService().speak(chapterPrefetchText);
            _prefetchNextPage();
          } else {
            _startTts();
          }
        }
      });
    }
  }

  // --- TTS 跳轉與功能核心 ---
  void nextPageOrChapter() {
    _ttsCancelled = false;
    // Bug 7 修復：清除可能過時的預取快取，防止 _onTtsComplete 使用舊資料
    _prefetchedTtsText = null;
    _prefetchedOffsetMap = null;
    _prefetchedAnchorChapterIdx = -1;
    _prefetchedAnchorEndCharPos = 0;
    // 優先從 TTS 錨點找下一頁，錨點無效時退回 currentPageIndex
    final nextIdx = _ttsAnchorChapterIdx >= 0 ? _findNextTtsPageIdx() : -1;
    if (nextIdx >= 0) {
      onPageChanged(nextIdx);
      _startTts();
    } else if (currentPageIndex < pages.length - 1) {
      onPageChanged(currentPageIndex + 1);
      _startTts();
    } else {
      nextChapter().then((_) {
        if (!_ttsCancelled) _startTts();
      });
    }
    notifyListeners();
  }

  void prevPageOrChapter() {
    _ttsCancelled = false;
    // Bug 7 修復：清除可能過時的預取快取
    _prefetchedTtsText = null;
    _prefetchedOffsetMap = null;
    _prefetchedAnchorChapterIdx = -1;
    _prefetchedAnchorEndCharPos = 0;
    // 使用 TTS 錨點找上一頁：搜尋同章節中起點 < 目前 TTS 起始位置的最後一頁
    int prevIdx = -1;
    if (_ttsAnchorChapterIdx >= 0) {
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        if (page.chapterIndex != _ttsAnchorChapterIdx) continue;
        if (page.lines.isEmpty) continue;
        final firstTextLine = page.lines.firstWhere(
            (l) => l.image == null, orElse: () => page.lines.first);
        if (firstTextLine.chapterPosition < _currentTtsBaseOffset) {
          prevIdx = i;
        } else {
          break;
        }
      }
    }
    if (prevIdx >= 0) {
      onPageChanged(prevIdx);
      _startTts();
    } else if (currentPageIndex > 0) {
      onPageChanged(currentPageIndex - 1);
      _startTts();
    } else {
      prevChapter().then((_) {
        if (!_ttsCancelled) _startTts();
      });
    }
    notifyListeners();
  }

  void setStopAfterChapter(bool val) {
    stopAfterChapter = val;
    notifyListeners();
  }

  void stopTts() {
    _ttsCancelled = true; // 取消所有 pending 的 nextChapter().then() 回調
    TTSService().stop();
    _ttsStart = -1;
    _ttsEnd = -1;
    _ttsChapterIndex = -1;
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _prefetchedTtsText = null;
    _prefetchedOffsetMap = null;
    _prefetchedChapterTtsText = null;
    _prefetchedChapterOffsetMap = null;
    // 重置絕對錨點
    _ttsAnchorChapterIdx = -1;
    _ttsAnchorEndCharPos = 0;
    _prefetchedAnchorChapterIdx = -1;
    _prefetchedAnchorEndCharPos = 0;
    _prefetchedChapterAnchorChapterIdx = -1;
    _prefetchedChapterAnchorEndCharPos = 0;
    notifyListeners();
  }

  void startTtsFromLine(int lineIndex) {
    _ttsCancelled = false; // 重置取消旗標
    TTSService().stop(); // 切換行時需徹底重新建構塊
    _ttsStart = -1;
    _ttsEnd = -1;
    _ttsChapterIndex = -1;
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    // 清除舊預取，確保 _onTtsComplete 不會用過時快取（Bug 7 防護）
    _prefetchedTtsText = null;
    _prefetchedOffsetMap = null;
    _prefetchedAnchorChapterIdx = -1;
    _prefetchedAnchorEndCharPos = 0;
    _startTts(startLineIndex: lineIndex);
    notifyListeners();
  }

  void toggleTts() {
    if (TTSService().isPlaying) {
      TTSService().pause();
    } else if (_ttsStart >= 0) {
      TTSService().resume(); // 恢復
    } else {
      if (pages.isEmpty || isLoading) return; // 頁面未就緒時不啟動
      _ttsCancelled = false; // 重置取消旗標，開始新一輪朗讀
      _startTts();
    }
    notifyListeners();
  }

  void _startTts({int startLineIndex = -1}) async {
    if (_ttsCancelled) return; // 取消旗標已設，不啟動新朗讀
    if (pages.isEmpty) return;
    // TTS 與自動翻頁互斥（透過 stopAutoPage callback）
    onTtsStartCallback?.call();

    // 決定起始頁與起始行
    int pageIdx = currentPageIndex.clamp(0, pages.length - 1);
    int lineIdx = startLineIndex >= 0 ? startLineIndex : 0;

    // 捲動模式且未指定特定行：從視口頂端可見行開始，而非頁首
    if (pageTurnMode == PageAnim.scroll && startLineIndex < 0) {
      (pageIdx, lineIdx) = _getScrollModeTtsStart();
    }

    if (pageIdx >= pages.length) return;
    final page = pages[pageIdx];
    if (page.lines.isEmpty) return;

    final linesToRead = page.lines.sublist(lineIdx).where((l) => l.image == null).toList();
    if (linesToRead.isEmpty) {
      // 純圖片頁面：自動跳到下一頁重試
      if (currentPageIndex < pages.length - 1) {
        currentPageIndex++;
        _startTts();
      }
      return;
    }

    final (text, map) = prepareTtsData(linesToRead);
    if (text.trim().isEmpty) return;

    // 重置高亮快取，確保新一輪朗讀正確高亮第一段；設定朗讀章節以防跨章多重高亮
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _ttsChapterIndex = page.chapterIndex;
    _currentTtsBaseOffset = linesToRead.first.chapterPosition;
    _ttsTextOffsetMap = map;
    // 設定 TTS 絕對錨點：記住「讀到哪章哪個字元之後」，不再依賴 currentPageIndex
    _ttsAnchorChapterIdx = page.chapterIndex;
    _ttsAnchorEndCharPos = linesToRead.last.chapterPosition + linesToRead.last.text.length;

    await TTSService().speak(text);
    TTSService().updateMediaInfo(title: book.name, author: book.author);
    _prefetchNextPage(); // 開始朗讀當前頁後，立即預取下一頁（含跨章節邊界）
    notifyListeners();
  }

  /// 捲動模式：從目前視口頂端可見行開始 TTS，而非從當前「頁」的第一行
  (int pageIdx, int lineIdx) _getScrollModeTtsStart() {
    if (pages.isEmpty) return (0, 0);
    final headOffset = scrollHeadOffset;
    double cumHeight = 0;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
      for (int j = 0; j < page.lines.length; j++) {
        final line = page.lines[j];
        if (line.image != null) continue;
        final lineAbsBottom = headOffset + cumHeight + line.lineBottom;
        if (lineAbsBottom > lastScrollY) return (i, j);
      }
      cumHeight += pageHeight;
    }
    return (currentPageIndex.clamp(0, pages.length - 1), 0);
  }

  /// TTS 啟動時的回調，供 ReaderProvider 注入自動翻頁停止邏輯
  VoidCallback? onTtsStartCallback;

  /// 重置 TTS 高亮快取（重新分頁後呼叫）
  void resetTtsHighlightCache() {
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
  }

  /// 儲存 TTS 進度（退出時使用）
  void saveTtsProgress() {
    if (TTSService().isPlaying || _ttsStart >= 0) {
      TTSService().stop();
      if (_ttsStart >= 0) {
        book.durChapterIndex = currentChapterIndex;
        book.durChapterPos = _ttsStart;
        final title = chapters.isNotEmpty && currentChapterIndex < chapters.length
            ? chapters[currentChapterIndex].title : '';
        book.durChapterTitle = title;
        unawaited(bookDao.updateProgress(book.bookUrl, currentChapterIndex, title, _ttsStart));
      } else {
        saveProgress(currentChapterIndex, currentPageIndex);
      }
    }
  }

  /// TTS 是否正在運作（播放中或有高亮）
  bool get isTtsActive => TTSService().isPlaying || _ttsStart >= 0;
}
