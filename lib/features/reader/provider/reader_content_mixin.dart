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



/// ReaderProvider 的內容加載與分頁邏輯擴展
mixin ReaderContentMixin on ReaderProviderBase, ReaderSettingsMixin {
  bool _isPaginating = false;

  /// 替換規則快取：閱讀會話中規則不變，避免每章重複查詢資料庫
  List<Map<String, dynamic>>? _cachedRulesJson;

  /// 章節加載 Completer：協調主加載與靜默預載入，避免同一章節並發重複請求
  final Map<int, Completer<void>> _loadCompleters = {};

  (TextStyle, TextStyle) _buildTextStyles() {
    final currentTheme = AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];
    final ts = TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold, color: currentTheme.textColor, letterSpacing: letterSpacing);
    final cs = TextStyle(fontSize: fontSize, height: lineHeight, color: currentTheme.textColor, letterSpacing: letterSpacing);
    return (ts, cs);
  }

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
      final (ts, cs) = _buildTextStyles();
      pages = ChapterProvider.paginate(
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
      
      currentPageIndex = fromEnd ? (pages.length - 1).clamp(0, 999) : 0;
      jumpPageController.add(currentPageIndex);
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

    final bool isScrollMode = (pageTurnMode == 2);
    final bool isNeighbor = (i == currentChapterIndex + 1 || i == currentChapterIndex - 1);
    final bool shouldMerge = isScrollMode && isNeighbor && pages.isNotEmpty;

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
          _performChapterTransition(i, fromEnd, shouldMerge);
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
      chapterContentCache[i] = res.content;
      chapterCache.remove(i);

      final newPages = await _paginateInternal(i);
      if (isDisposed) return;
      chapterCache[i] = newPages;

      _performChapterTransition(i, fromEnd, shouldMerge);

      // 更新 DB 與 in-memory book 物件，確保書架下次開書時使用最新章節位置
      // durChapterPos 儲存字元偏移量（0 = 章節起始），由 _saveProgress 在翻頁時精確更新
      book.durChapterIndex = currentChapterIndex;
      book.durChapterPos = 0;
      book.durChapterTitle = chapters[i].title;
      unawaited(bookDao.updateProgress(book.bookUrl, currentChapterIndex, chapters[i].title, 0));

      _preloadNeighborChaptersSilently();
    } catch (e) {
      debugPrint('Reader: Load chapter $i failed: $e');
    } finally {
      loadingChapters.remove(i);
      if (!isDisposed) notifyListeners(); // 網絡路徑：統一在 finally 內通知一次（清除 loading 並更新內容）
    }
  }

  void _preloadNeighborChaptersSilently() {
    final firstIdx = pages.firstOrNull?.chapterIndex;
    final lastIdx = pages.lastOrNull?.chapterIndex;

    if (firstIdx != null && firstIdx > 0 && !chapterCache.containsKey(firstIdx - 1)) {
      unawaited(_preloadChapterSilently(firstIdx - 1));
    }
    if (lastIdx != null && lastIdx < chapters.length - 1 && !chapterCache.containsKey(lastIdx + 1)) {
      unawaited(_preloadChapterSilently(lastIdx + 1));
    }
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
      chapterContentCache[i] = res.content;
      final newPages = await _paginateInternal(i);
      if (isDisposed) return;
      chapterCache[i] = newPages;
    } catch (e) {
      debugPrint('Reader: Preload chapter $i failed: $e');
    } finally {
      silentLoadingChapters.remove(i);
      _loadCompleters.remove(i);
      if (!completer.isCompleted) completer.complete();
    }
  }

  void _performChapterTransition(int targetIndex, bool fromEnd, bool shouldMerge) {
    if (!chapterCache.containsKey(targetIndex)) return;
    final newPages = chapterCache[targetIndex]!;
    
    if (shouldMerge) {
      final bool alreadyExists = pages.any((p) => p.chapterIndex == targetIndex);
      if (!alreadyExists) {
         if (targetIndex > currentChapterIndex) {
           pages = [...pages, ...newPages];
           final double topTrimHeight = _trimPagesWindow();
           // 從頂部移除頁面後，需向上補償等量捲動以維持視覺位置
           if (topTrimHeight > 0) scrollTrimAdjustController.add(topTrimHeight);
         } else {
           final double addedHeight = _calculatePagesHeight(newPages);
           pages = [...newPages, ...pages];
           final double topTrimHeight = _trimPagesWindow();
           // 預付頂部增加高度，再扣掉因 trim 從頂部移除的高度
           scrollOffsetController.add(-(addedHeight - topTrimHeight));
         }
      }
      
      if (targetIndex > currentChapterIndex) {
         currentPageIndex = pages.indexWhere((p) => p.chapterIndex == targetIndex);
      } else {
         currentPageIndex = pages.lastIndexWhere((p) => p.chapterIndex == targetIndex);
      }
      currentChapterIndex = targetIndex;
    } else {
      pages = newPages;
      currentChapterIndex = targetIndex;
      currentPageIndex = fromEnd ? (pages.length - 1).clamp(0, 9999) : 0;
      scrollOffsetController.add(fromEnd ? 999999.0 : 0.0);
      jumpPageController.add(currentPageIndex);
    }
    // 移除內部的 notifyListeners()，由調用者統一處理 (問題 3)
  }

  double _calculatePagesHeight(List<TextPage> pageList) {
    double total = 0;
    for (int i = 0; i < pageList.length; i++) {
      final page = pageList[i];
      final double h = page.lines.isEmpty ? 0 : page.lines.last.lineBottom + 40.0;
      total += h;
      if (i < pageList.length - 1) total += 24.0; // 修正 separator 計算 (問題 7)
    }
    return total;
  }

  /// 修剪頁面視窗至最多 5 個章節，回傳從頂部移除的總像素高度（供捲動補償）
  double _trimPagesWindow() {
    final chapterIndexes = pages.map((p) => p.chapterIndex).toSet().toList()..sort();
    double removedTopHeight = 0;
    while (chapterIndexes.length > 5) {
      final first = chapterIndexes.first;
      final last = chapterIndexes.last;
      final removeFirst = (currentChapterIndex - first).abs() >= (last - currentChapterIndex).abs();
      final toRemove = removeFirst ? first : last;

      if (removeFirst) {
        // 計算即將移除的頂部頁面高度（含其後方的 separator）
        final removedPages = pages.where((p) => p.chapterIndex == toRemove).toList();
        final h = _calculatePagesHeight(removedPages);
        // 加上移除章節與下一章節之間的 24px separator
        removedTopHeight += h + 24.0;
      }

      pages.removeWhere((p) => p.chapterIndex == toRemove);
      chapterCache.remove(toRemove);
      chapterContentCache.remove(toRemove);
      if (removeFirst) {
        chapterIndexes.removeAt(0);
      } else {
        chapterIndexes.removeLast();
      }
    }
    return removedTopHeight;
  }

  Future<List<TextPage>> _paginateInternal(int i) async {
    final (ts, cs) = _buildTextStyles();
    return ChapterProvider.paginate(
      content: chapterContentCache[i]!,
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
  
  Future<void> prevChapter() async { 
    final firstPage = pages.firstOrNull;
    final int target = (firstPage?.chapterIndex ?? currentChapterIndex) - 1;
    if (target >= 0) await loadChapter(target, fromEnd: true); 
  }
}






