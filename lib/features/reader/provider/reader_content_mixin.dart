import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/engine/chapter_provider.dart';
import 'package:legado_reader/core/services/local_book_service.dart';
import 'package:legado_reader/core/engine/reader/content_processor.dart' as engine;
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/book/book_content.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';



/// ReaderProvider 的內容加載與分頁邏輯擴展
mixin ReaderContentMixin on ReaderProviderBase, ReaderSettingsMixin {
  Future<void> doPaginate({bool fromEnd = false}) async {
    if (viewSize == null || viewSize!.width <= 0 || viewSize!.height <= 0 || chapters.isEmpty) {
      debugPrint('Reader: Paginate skipped - viewSize: $viewSize, chapters empty: ${chapters.isEmpty}');
      return;
    }
    
    // 避免重複執行
    if (_isPaginating) return;
    _isPaginating = true;
    
    loadingChapters.add(currentChapterIndex);
    notifyListeners();

    try {
      final currentTheme = AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];

      final chapter = chapters[currentChapterIndex];
      final chapterSize = chapters.length;
      final currentViewSize = viewSize!;
      
      debugPrint('Reader: Paginate start for index $currentChapterIndex, content length: ${content.length}');

      final ts = TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold, color: currentTheme.textColor, letterSpacing: letterSpacing);
      final cs = TextStyle(fontSize: fontSize, height: lineHeight, color: currentTheme.textColor, letterSpacing: letterSpacing);

      // 直接在主 Isolate 執行分頁，避免 Isolate 無法存取 dart:ui 的問題
      pages = ChapterProvider.paginate(
        content: content,
        chapter: chapter,
        chapterIndex: currentChapterIndex,
        chapterSize: chapterSize,
        viewSize: currentViewSize,
        titleStyle: ts,
        contentStyle: cs,
        paragraphSpacing: paragraphSpacing,
        textIndent: textIndent,
        textFullJustify: textFullJustify,
      );
      
      debugPrint('Reader: Paginate complete, total pages: ${pages.length}');

      currentPageIndex = fromEnd ? (pages.length - 1).clamp(0, 999) : 0;
      jumpPageController.add(currentPageIndex);
    } catch (e, stack) {
      debugPrint('Reader: Paginate fatal error: $e\n$stack');
    } finally {
      loadingChapters.remove(currentChapterIndex);
      _isPaginating = false;
    }

  }

  Future<void> loadChapter(int i, {bool fromEnd = false}) async {
    if (i < 0 || i >= chapters.length) return;
    
    // 如果已經在載入中或已在緩存，直接處理
    if (loadingChapters.contains(i)) return;

    final bool isScrollMode = (pageTurnMode == 2);
    final bool isNeighbor = (i == currentChapterIndex + 1 || i == currentChapterIndex - 1);
    final bool shouldMerge = isScrollMode && isNeighbor && pages.isNotEmpty;

    if (chapterCache.containsKey(i)) {
      _performChapterTransition(i, fromEnd, shouldMerge);
      return;
    }

    loadingChapters.add(i);
    // 只有在非無縫合併且當前頁面為空時，才立即通知 UI 顯示轉圈
    if (!shouldMerge || pages.isEmpty) {
      notifyListeners();
    }

    try {
      final res = await fetchChapterData(i);
      chapterContentCache[i] = res.content;
      chapterCache.remove(i);
      
      final newPages = await _paginateInternal(i);
      chapterCache[i] = newPages;

      _performChapterTransition(i, fromEnd, shouldMerge);

      final title = chapters[i].title;
      unawaited(bookDao.updateProgress(book.bookUrl, i, title, currentPageIndex));

      // 載入完成後，如果還有其他鄰章沒加載，背景加載之
      if (isScrollMode) {
        _checkAndPreloadNeighbor();
      }
    } catch (e) {
      debugPrint('Reader: Load chapter $i failed: $e');
    } finally {
      loadingChapters.remove(i);
      notifyListeners();
    }
  }

  void _checkAndPreloadNeighbor() {
    // 檢查目前 pages 列表開頭和結尾的章節索引
    final firstIdx = pages.firstOrNull?.chapterIndex;
    final lastIdx = pages.lastOrNull?.chapterIndex;
    
    if (firstIdx != null && firstIdx > 0 && !chapterCache.containsKey(firstIdx - 1)) {
      unawaited(loadChapter(firstIdx - 1, fromEnd: true));
    }
    if (lastIdx != null && lastIdx < chapters.length - 1 && !chapterCache.containsKey(lastIdx + 1)) {
      unawaited(loadChapter(lastIdx + 1));
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
         } else {
           final double addedHeight = _calculatePagesHeight(newPages);
           pages = [...newPages, ...pages];
           scrollOffsetController.add(-addedHeight);
         }
         _trimPagesWindow();
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
    }
    notifyListeners();
  }

  double _calculatePagesHeight(List<TextPage> pageList) {
    double total = 0;
    for (final page in pageList) {
      final double h = page.lines.isEmpty ? 0 : page.lines.last.lineBottom + 40.0;
      total += h + 24.0;
    }
    return total;
  }

  void _trimPagesWindow() {
    final chapterIndexes = pages.map((p) => p.chapterIndex).toSet().toList()..sort();
    if (chapterIndexes.length > 5) {
      if (currentChapterIndex == chapterIndexes.last) {
        final firstChapter = chapterIndexes.first;
        pages.removeWhere((p) => p.chapterIndex == firstChapter);
      } else if (currentChapterIndex == chapterIndexes.first) {
        final lastChapter = chapterIndexes.last;
        pages.removeWhere((p) => p.chapterIndex == lastChapter);
      }
    }
  }

  Future<List<TextPage>> _paginateInternal(int i) async {
    final currentTheme = AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];
    final ts = TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold, color: currentTheme.textColor, letterSpacing: letterSpacing);
    final cs = TextStyle(fontSize: fontSize, height: lineHeight, color: currentTheme.textColor, letterSpacing: letterSpacing);
    
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
        if (source == null) {
          source = await sourceDao.getByUrl(book.origin);
        }
        if (source != null) {
          try {
            raw = await service.getContent(source!, book, chapter);
            if (raw != null && raw.isNotEmpty) {
              await chapterDao.saveContent(chapter.url, raw);
            } else {
              raw = '章節內容為空 (可能解析規則有誤)';
            }
          } catch (e) {
            raw = '加載章節失敗: $e';
          }
        } else {
          raw = '找不到對應書源: ${book.origin} (請檢查書源是否已被刪除)';
        }

      }
    }
    debugPrint('Reader: Raw content loaded, length: ${raw?.length}');
    final rules = await replaceDao.getEnabled();
    final rulesJson = rules.map((r) => r.toJson()).toList();
    
    final BookContent bookContent = await engine.ContentProcessor.process(
      book: book, chapter: chapter, rawContent: raw ?? '無內容', 
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






