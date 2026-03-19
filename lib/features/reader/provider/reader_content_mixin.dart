import 'dart:async';
import 'package:flutter/material.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/engine/chapter_provider.dart';
import 'package:legado_reader/core/services/local_book_service.dart';
import 'package:legado_reader/core/engine/reader/content_processor.dart' as engine;
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:legado_reader/core/models/book/book_content.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/core/constant/page_anim.dart';



/// ReaderProvider 的內容加載與分頁邏輯擴展
mixin ReaderContentMixin on ReaderProviderBase, ReaderSettingsMixin {
  bool _isPaginating = false;

  /// 替換規則快取：閱讀會話中規則不變，避免每章重複查詢資料庫
  List<Map<String, dynamic>>? _cachedRulesJson;

  /// 靜默預載排序 Queue 與執行狀態
  final List<int> _preloadQueue = [];
  bool _isPreloadingQueueActive = false;

  /// 當前目標視窗的章節索引集合
  Set<int> _targetWindowIndices = {};

  /// 章節加載 Completer：協調主加載與靜默預載入，避免同一章節並發重複請求
  final Map<int, Completer<void>> _loadCompleters = {};

  /// 重新分頁時的進度恢復回調
  /// 由 ReaderProgressMixin 注入，避免 (this as dynamic) 呼叫
  int Function(double scrollY)? getCharOffsetForScrollYFn;
  void Function({int? charOffset, int? pageIndex, bool isRestoringJump})? jumpToPositionFn;
  void Function()? applyPendingRestoreFn;

  (TextStyle, TextStyle) _buildTextStyles() {
    final currentTheme = AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];
    final ts = TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold, color: currentTheme.textColor, letterSpacing: letterSpacing);
    final cs = TextStyle(fontSize: fontSize, height: lineHeight, color: currentTheme.textColor, letterSpacing: letterSpacing);
    return (ts, cs);
  }

  /// 最後一次已知的滾動位置（由 ReaderProgressMixin 的 lastScrollY 同步）
  double _lastKnownScrollY = 0.0;
  set lastKnownScrollY(double v) => _lastKnownScrollY = v;

  Future<void> doPaginate({bool fromEnd = false}) async {
    final chapterContent = chapterContentCache[currentChapterIndex];
    if (viewSize == null || viewSize!.width <= 0 || viewSize!.height <= 0 || chapters.isEmpty || chapterContent == null || chapterContent.isEmpty) {
      return;
    }
    
    if (_isPaginating) return;
    _isPaginating = true;
    
    loadingChapters.add(currentChapterIndex);
    notifyListeners();

    try {
      // 關鍵修復：在重新分頁前，記住當前看到的字元位置
      final int oldCharOffset = getCharOffsetForScrollYFn?.call(_lastKnownScrollY) ?? 0;

      final (ts, cs) = _buildTextStyles();
      pages = await ChapterProvider.paginate(
        content: chapterContent,
        chapter: chapters[currentChapterIndex],
        chapterIndex: currentChapterIndex,
        chapterSize: chapters.length,
        viewSize: viewSize!,
        titleStyle: ts,
        contentStyle: cs,
        paragraphSpacing: paragraphSpacing,
        textIndent: textIndent,
        textFullJustify: textFullJustify,
      );
      // 同步更新快取，讓後續 loadChapter 快取命中時能取到最新分頁結果
      chapterCache[currentChapterIndex] = pages;

      if (fromEnd) {
        currentPageIndex = (pages.length - 1).clamp(0, 999);
        jumpToPositionFn?.call(pageIndex: currentPageIndex);
      } else {
        // 重新分頁後，嘗試尋回剛才看到的那個字元，而不是直接跳回第 0 頁
        jumpToPositionFn?.call(charOffset: oldCharOffset);
      }
    } catch (e, stack) {
      debugPrint('Reader: Paginate fatal error: $e\n$stack');
    } finally {
      loadingChapters.remove(currentChapterIndex);
      _isPaginating = false;
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> loadChapter(int i, {bool fromEnd = false}) async {
    if (i < 0 || i >= chapters.length) return;
    if (loadingChapters.contains(i)) return;

    // 捲動模式下「鄰近」是相對於已載入頁面的邊界章節，而非 currentChapterIndex
    // （currentChapterIndex 是當前可見章節，可能在已載入多章節的中間）
    final int firstLoadedIdx = pages.firstOrNull?.chapterIndex ?? currentChapterIndex;
    final int lastLoadedIdx = pages.lastOrNull?.chapterIndex ?? currentChapterIndex;
    final bool isNeighbor = (i == lastLoadedIdx + 1 || i == firstLoadedIdx - 1);
    final bool shouldMerge = isNeighbor && pages.isNotEmpty;

    if (chapterCache.containsKey(i)) {
      _performChapterTransition(i, fromEnd, shouldMerge);
      _preloadNeighborChaptersSilently();
      if (!isDisposed) notifyListeners(); // 緩存路徑：執行完跳轉後通知一次
      return;
    }

    // 若同一章節正在靜默預載入中，等待其完成後直接使用緩存，避免重複網路請求
    if (silentLoadingChapters.contains(i)) {
      final completer = _loadCompleters[i];
      if (completer != null) {
        loadingChapters.add(i);
        if (!isDisposed) notifyListeners();
        await completer.future;
        loadingChapters.remove(i);
        if (isDisposed) return;
        if (chapterCache.containsKey(i)) {
          // Fix7: await 後重新計算 shouldMerge——靜默合併可能在等待期間改變了 pages 邊界
          final int firstNow = pages.firstOrNull?.chapterIndex ?? currentChapterIndex;
          final int lastNow  = pages.lastOrNull?.chapterIndex  ?? currentChapterIndex;
          final bool mergeNow = pages.isNotEmpty && (i == lastNow + 1 || i == firstNow - 1);
          _performChapterTransition(i, fromEnd, mergeNow);
          _preloadNeighborChaptersSilently();
          if (!isDisposed) notifyListeners();
          return;
        }
        // 靜默載入失敗（異常）則繼續正常流程
      }
    }

    loadingChapters.add(i);
    if (!shouldMerge || pages.isEmpty) {
      if (!isDisposed) notifyListeners();
    }

    try {
      final res = await fetchChapterData(i);
      if (isDisposed) return;
      _saveContentCache(i, res.content);
      chapterCache.remove(i);

      final newPages = await _paginateInternal(i);
      if (isDisposed) return;

      if (newPages.isEmpty) {
        // viewSize 尚未就緒：內容已快取在 chapterContentCache，
        // setViewSize() 時 doPaginate() 會重新分頁，不要存空快取以免干擾後續 loadChapter
        return;
      }
      chapterCache[i] = newPages;

      // Fix7: await _paginateInternal 後重新計算 shouldMerge，
      // 靜默合併可能在等待期間改變了 pages 邊界（尤其 Fix1 移除 isLoading 後更容易觸發）
      final int firstAfter = pages.firstOrNull?.chapterIndex ?? currentChapterIndex;
      final int lastAfter  = pages.lastOrNull?.chapterIndex  ?? currentChapterIndex;
      final bool shouldMergeAfter = pages.isNotEmpty && (i == lastAfter + 1 || i == firstAfter - 1);
      _performChapterTransition(i, fromEnd, shouldMergeAfter);
      _preloadNeighborChaptersSilently();
    } catch (e) {
      debugPrint('Reader: Load chapter $i failed: $e');
    } finally {
      loadingChapters.remove(i);
      if (!isDisposed) notifyListeners(); // 網絡路徑：統一在 finally 內通知一次（清除 loading 並更新內容）
    }
  }

  /// 更新章節視窗（固定 5 章）
  /// [centerIndex]：目標中心章節
  void updateChapterWindow(int centerIndex) {
    if (chapters.isEmpty) return;

    // 1. 計算目標視窗範圍 [L, R]
    final int windowSize = 5;
    int left = (centerIndex - 2).clamp(0, (chapters.length - windowSize).clamp(0, chapters.length - 1));
    int right = (left + windowSize - 1).clamp(0, chapters.length - 1);
    
    // 重新校準 left（處理末尾章節不足 5 章的情況）
    if (right == chapters.length - 1) {
       left = (right - windowSize + 1).clamp(0, chapters.length - 1);
    }

    final Set<int> newWindow = {};
    for (int i = left; i <= right; i++) {
      newWindow.add(i);
    }

    if (_targetWindowIndices.length == newWindow.length && _targetWindowIndices.containsAll(newWindow)) {
      return; // 視窗未變動
    }

    _targetWindowIndices = newWindow;
    debugPrint('Reader: Target window updated to $_targetWindowIndices (center: $centerIndex)');

    // 2. 執行剪裁：移除視窗外的章節
    _trimPagesWindowStrict();

    // 3. 觸發預載：填充視窗內的缺失章節
    _preloadNeighborChaptersSilently();
  }

  void _preloadNeighborChaptersSilently() {
    if (chapters.isEmpty) return;

    // 如果未設定視窗（例如初始化時），則使用預設邏輯（當前章節前後 2 章）
    if (_targetWindowIndices.isEmpty) {
      final int start = (currentChapterIndex - 2).clamp(0, chapters.length - 1);
      final int end = (currentChapterIndex + 2).clamp(0, chapters.length - 1);
      for (int i = start; i <= end; i++) {
        _targetWindowIndices.add(i);
      }
    }

    // Fix3: 佇列活躍時不清空整個佇列（避免 worker 的下一個 target 被腰斬），
    // 只替換 pending 部分（index 1 之後），保留正在執行的第一項。
    if (!_isPreloadingQueueActive) {
      _preloadQueue.clear();
    } else if (_preloadQueue.length > 1) {
      _preloadQueue.removeRange(1, _preloadQueue.length);
    }

    final List<int> candidates = [];
    // 找出視窗內遺漏的章節
    for (final idx in _targetWindowIndices) {
      if (!chapterCache.containsKey(idx) && !loadingChapters.contains(idx) && !silentLoadingChapters.contains(idx)) {
        candidates.add(idx);
      }
    }

    // 依照距離 currentChapterIndex 從近到遠排序，自動體現閱讀方向優先權
    candidates.sort((a, b) => (a - currentChapterIndex).abs().compareTo((b - currentChapterIndex).abs()));

    // 只把不重複的 candidate 加入佇列（避免與正在執行的項目重複）
    for (final c in candidates) {
      if (!_preloadQueue.contains(c)) _preloadQueue.add(c);
    }

    _processPreloadQueue();
  }

  Future<void> _processPreloadQueue() async {
    if (_isPreloadingQueueActive || _preloadQueue.isEmpty) return;
    _isPreloadingQueueActive = true;

    while (_preloadQueue.isNotEmpty) {
      if (isDisposed) break;
      final target = _preloadQueue.removeAt(0);

      // 如果已因為其他動作（如使用者手動點擊）被載入則跳過
      if (chapterCache.containsKey(target) || loadingChapters.contains(target)) continue;
      
      await _preloadChapterSilently(target);
    }

    _isPreloadingQueueActive = false;
  }

  Future<void> _preloadChapterSilently(int i) async {
    if (i < 0 || i >= chapters.length) return;
    if (loadingChapters.contains(i) || silentLoadingChapters.contains(i) || chapterCache.containsKey(i)) return;

    silentLoadingChapters.add(i);
    final completer = Completer<void>();
    _loadCompleters[i] = completer;
    try {
      final res = await fetchChapterData(i);
      if (isDisposed) return;
      _saveContentCache(i, res.content);
      final newPages = await _paginateInternal(i);
      if (isDisposed) return;
      chapterCache[i] = newPages;

      // 靜默預合併：滾動模式下，直接鄰居章節預載完成後自動合併到 pages，
      // 使用者滾到邊界時內容已就位，無需等待載入。
      if (_shouldSilentMerge(i)) {
        _performChapterTransition(i, false, true);
        if (!isDisposed) notifyListeners();
      }
    } catch (e) {
      debugPrint('Reader: Preload chapter $i failed: $e');
    } finally {
      silentLoadingChapters.remove(i);
      _loadCompleters.remove(i);
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// 外部（如 ReaderProvider）觸發靜默預載的公開入口，
  /// 會更新鄰居列表並啟動佇列，統一走靜默路徑（不加入 loadingChapters，不顯示轉圈）。
  void triggerSilentPreload() => _preloadNeighborChaptersSilently();

  /// 判斷預載章節是否應靜默合併
  /// 條件：滾動模式 + 直接鄰居 + 尚未合併 + 非恢復中 + 未達窗口上限
  bool _shouldSilentMerge(int i) {
    if (pageTurnMode != PageAnim.scroll) return false;
    if (pages.isEmpty) return false;
    if (isRestoring || isPaginating) return false;
    
    // 只合併在目標視窗內的章節
    if (!_targetWindowIndices.contains(i)) return false;

    // 已存在則不需合併
    if (pages.any((p) => p.chapterIndex == i)) return false;

    // 必須是當前已加載範圍的直接鄰居才執行合併（確保 ScrollView 連續性）
    final firstIdx = pages.first.chapterIndex;
    final lastIdx = pages.last.chapterIndex;
    return (i == firstIdx - 1) || (i == lastIdx + 1);
  }

  void _performChapterTransition(int targetIndex, bool fromEnd, bool shouldMerge) {
    if (!chapterCache.containsKey(targetIndex)) return;
    final newPages = chapterCache[targetIndex]!;
    final bool isScrollMode = (pageTurnMode == PageAnim.scroll);
    
    if (shouldMerge) {
      final bool alreadyExists = pages.any((p) => p.chapterIndex == targetIndex);
      final bool isMovingDown = targetIndex > currentChapterIndex;

      if (!alreadyExists) {
         final int originalChapterIndex = currentChapterIndex;
         currentChapterIndex = targetIndex; // 暫時更新，讓後續邏輯可取得 targetIndex
         if (isMovingDown) {
           pages = [...pages, ...newPages];
           // Fix2: 傳入 originalChapterIndex 作為 trim 的距離計算基準，
           // 避免使用「暫時目標值」導致驅逐掉用戶正在閱讀的章節。
           _trimPagesWindow(pivotHint: originalChapterIndex);
         } else {
           final int addedPageCount = newPages.length;
           pages = [...newPages, ...pages];
           // Fix2: 同上，向上合併也使用 originalChapterIndex 作為基準
           _trimPagesWindow(pivotHint: originalChapterIndex);

           // 關鍵修復：滾動模式下，viewport 未移動，使用者仍在看原本章節。
           // 恢復 currentChapterIndex，讓 _updateScrollPageIndex 在後續滾動事件中自然更新。
           if (isScrollMode) {
             currentChapterIndex = originalChapterIndex;
           }

           if (!isScrollMode) {
             if (fromEnd) {
               // 往前翻：使用者期望看到新章節的最後一頁（e.g. 滑動到上一章末尾）
               currentPageIndex = pages.lastIndexWhere((p) => p.chapterIndex == targetIndex);
             } else {
               // 正常合併：補償前方插入，保持使用者視覺位置不動
               currentPageIndex += addedPageCount;
             }
             jumpPageController.add(currentPageIndex);
           }
         }
      } else {
         currentChapterIndex = targetIndex;
      }

      if (isScrollMode) {
        // 滾動模式：不主動設定 currentPageIndex。
        // viewport 位置由 ScrollController 控制，currentPageIndex 由
        // _updateScrollPageIndex() 在下次滾動事件中根據 virtualY 自然更新。
        // 這避免了合併後的短暫不一致窗口（currentChapterIndex 指向原章節，
        // 但 currentPageIndex 卻指向新合併章節的首/末頁）。
      } else if (!alreadyExists) {
        // slide 模式 + 新章節：currentPageIndex 已在上方 !alreadyExists 區塊設定並觸發 jump，不再覆蓋
      } else {
        // slide 模式 + alreadyExists
        if (fromEnd || !isMovingDown) {
          currentPageIndex = pages.lastIndexWhere((p) => p.chapterIndex == targetIndex);
        } else {
          currentPageIndex = pages.indexWhere((p) => p.chapterIndex == targetIndex);
        }
      }
    } else {
      pages = newPages;
      currentChapterIndex = targetIndex;
      pivotChapterIndex = targetIndex; // 重置錨點章節
      // 正在恢復進度時，交由 applyPendingRestore 處理定位
      if (!isRestoring) {
        final targetPage = fromEnd ? (pages.length - 1).clamp(0, 9999) : 0;
        jumpToPositionFn?.call(pageIndex: targetPage);
      }
    }
  }

  /// 修剪頁面視窗至最多 5 個章節
  /// 只清除 chapterCache（分頁結果），保留 chapterContentCache（原始內容），回翻時不需重新下載
  /// [pivotHint]：驅逐距離的計算基準章節（預設為 currentChapterIndex）。
  /// 在 _performChapterTransition 中 currentChapterIndex 已被暫設為 targetIndex，
  /// 應傳入 originalChapterIndex（用戶實際可見章節）以確保驅逐方向正確。
  /// 嚴格視窗剪裁：移除不在 _targetWindowIndices 內的章節
  void _trimPagesWindowStrict() {
    if (_targetWindowIndices.isEmpty) return;

    final List<int> loadedChapterIndexes = pages.map((p) => p.chapterIndex).toSet().toList()..sort();
    final List<int> toRemove = [];

    for (final idx in loadedChapterIndexes) {
      if (!_targetWindowIndices.contains(idx)) {
        // 保護 pivotChapterIndex 不被驅逐，除非目標視窗真的不包含它（通常是跳轉時）
        if (idx == pivotChapterIndex && _targetWindowIndices.contains(pivotChapterIndex)) {
          continue;
        }
        toRemove.add(idx);
      }
    }

    if (toRemove.isEmpty) return;

    debugPrint('Reader: Trimming indices $toRemove from scroll window');

    for (final idx in toRemove) {
      final bool isBelow = idx < (pages.firstOrNull?.chapterIndex ?? 0);
      final int removedCount = pages.where((p) => p.chapterIndex == idx).length;

      pages.removeWhere((p) => p.chapterIndex == idx);
      chapterCache.remove(idx);

      // 如果移除的是當前顯示範圍上方的章節，需要補償 currentPageIndex 防止索引漂移
      // （僅適用於非滾動模式，滾動模式交由 viewport 自然處理，但保留邏輯以防萬一）
      if (isBelow && removedCount > 0) {
        currentPageIndex = (currentPageIndex - removedCount).clamp(0, pages.isEmpty ? 0 : pages.length - 1);
      }
    }
    
    if (!isDisposed) notifyListeners();
  }

  /// 舊有的距離驅逐法保留介面，但內容改為呼叫新剪裁邏輯
  void _trimPagesWindow({int? pivotHint}) {
    _trimPagesWindowStrict();
  }

  /// 距離驅逐法的最高容量：防堵歷史記憶體洩漏
  void _saveContentCache(int index, String content) {
    chapterContentCache[index] = content;
    const maxSize = 15; // 限制至多保留 15 個章節的原始字串
    if (chapterContentCache.length > maxSize) {
      // Fix4: 找最遠章節時必須排除 index 本身，防止「存入即驅逐」的自毀式競速：
      // 若 index 是距 currentChapterIndex 最遠的章節（如在第 133 章時存入第 1 章），
      // 不排除 index 會使 chapterContentCache[index] 剛存入就被移除，
      // 緊接著 _paginateInternal(index) 的 chapterContentCache[index]! 拋 Null。
      final candidates = chapterContentCache.keys.where((k) => k != index);
      if (candidates.isNotEmpty) {
        final farthest = candidates.reduce((a, b) =>
          (a - currentChapterIndex).abs() > (b - currentChapterIndex).abs() ? a : b
        );
        chapterContentCache.remove(farthest);
      }
    }
  }

  Future<List<TextPage>> _paginateInternal(int i) async {
    if (viewSize == null || viewSize!.width <= 0 || viewSize!.height <= 0) return [];
    // Fix5: 防範 _saveContentCache 驅逐競速：若內容已被移除就安全返回空列表，
    // 而非用 ! 拋出 Null check operator 崩潰。
    final content = chapterContentCache[i];
    if (content == null) {
      debugPrint('Reader: _paginateInternal($i) skipped — content evicted from cache');
      return [];
    }
    final (ts, cs) = _buildTextStyles();
    return await ChapterProvider.paginate(
      content: content,
      chapter: chapters[i],
      chapterIndex: i,
      chapterSize: chapters.length,
      viewSize: viewSize!,
      titleStyle: ts,
      contentStyle: cs,
      paragraphSpacing: paragraphSpacing,
      textIndent: textIndent,
      textFullJustify: textFullJustify,
    );
  }

  void onPageChanged(int i) {
    if (i < 0 || i >= pages.length) return;
    final page = pages[i];
    
    if (currentChapterIndex != page.chapterIndex) {
      currentChapterIndex = page.chapterIndex;
      updateChapterWindow(currentChapterIndex);
      notifyListeners();
    }

    if (currentPageIndex != i) {
      currentPageIndex = i;
      notifyListeners();
      
      final title = chapters.isNotEmpty ? chapters[currentChapterIndex].title : '';
      unawaited(bookDao.updateProgress(book.bookUrl, page.chapterIndex, title, page.index));
    }
  }


  Future<({String content, List<dynamic> pages})> fetchChapterData(int i) async {
    final chapter = chapters[i];
    debugPrint('Reader: Fetching content for chapter $i: ${chapter.title}');
    var raw = await chapterDao.getContent(chapter.url);
    if (raw == null) {
      if (book.origin == 'local') {
        debugPrint('Reader: Loading from local file: ${book.bookUrl}');
        raw = await LocalBookService().getContent(book, chapter);
      } else {
        source ??= await sourceDao.getByUrl(book.origin);
        try {
          raw = await service.getContent(source!, book, chapter);
          if (raw.isNotEmpty) {
            await chapterDao.saveContent(chapter.url, raw);
          } else {
            raw = '章節內容為空 (可能解析規則有誤)';
          }
        } catch (e) {
          raw = '加載章節失敗: $e';
        }
      }
    }
    debugPrint('Reader: Raw content loaded, length: ${raw.length}');
    // 替換規則在閱讀會話中不變，快取第一次查詢結果
    _cachedRulesJson ??= (await replaceDao.getEnabled()).map((r) => r.toJson()).toList().cast<Map<String, dynamic>>();
    final rulesJson = _cachedRulesJson!;
    
    final BookContent bookContent = await engine.ContentProcessor.process(
      book: book, chapter: chapter, rawContent: raw, 
      rulesJson: rulesJson,
      chineseConvertType: chineseConvert, reSegmentEnabled: true,
    );


    debugPrint('Reader: Content processed, final length: ${bookContent.content.length}');
    return (content: bookContent.content, pages: []); 
  }

  void nextPage() {
    if (currentPageIndex < pages.length - 1) {
      currentPageIndex++; notifyListeners();
      jumpPageController.add(currentPageIndex);
    } else {
      nextChapter();
    }
  }

  void prevPage() {
    if (currentPageIndex > 0) {
      currentPageIndex--; notifyListeners();
      jumpPageController.add(currentPageIndex);
    } else {
      prevChapter();
    }
  }

  Future<void> nextChapter() async { 
    final lastPage = pages.lastOrNull;
    final int target = (lastPage?.chapterIndex ?? currentChapterIndex) + 1;
    if (target < chapters.length) await loadChapter(target); 
  }
  
  Future<void> prevChapter({bool fromEnd = true}) async {
    final firstPage = pages.firstOrNull;
    final int target = (firstPage?.chapterIndex ?? currentChapterIndex) - 1;
    if (target >= 0) await loadChapter(target, fromEnd: fromEnd);
  }
}
