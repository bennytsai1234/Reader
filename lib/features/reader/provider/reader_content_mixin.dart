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
    
    isLoading = true;
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
      isLoading = false;
      _isPaginating = false;
      notifyListeners();
    }

  }

  bool _isPaginating = false;


  Future<void> loadChapter(int i, {bool fromEnd = false}) async {
    if (i < 0 || i >= chapters.length) return;
    
    if (chapterCache.containsKey(i)) {
      currentChapterIndex = i;
      pages = chapterCache[i]!;
      content = chapterContentCache[i]!;
      currentPageIndex = fromEnd ? (pages.length - 1).clamp(0, 999) : 0;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 50), () {
        jumpPageController.add(currentPageIndex);
        scrollOffsetController.add(fromEnd ? 999999.0 : 0.0);
      });
      return;

    }

    isLoading = true; 
    pages = []; // 清空舊頁面以顯示載入中
    notifyListeners();

    
    try {
      final res = await fetchChapterData(i);
      content = res.content;
      currentChapterIndex = i;
      chapterContentCache[i] = content;
      
      // 清除目前章節的快取，確保重新分頁
      chapterCache.remove(i);
      
      await doPaginate(fromEnd: fromEnd);
      
      chapterCache[i] = pages;

      // 更新進度
      final title = chapters[i].title;
      unawaited(bookDao.updateProgress(book.bookUrl, i, title, currentPageIndex));

      // 預加載下一章 (對標 Android ReadBookViewModel.preLoadNext)
      if (i < chapters.length - 1) {
        unawaited(_preloadChapter(i + 1));
      }
    } catch (e) {
      content = '加載失敗: $e'; 
    } finally {
      isLoading = false; 
      notifyListeners();
      // 分頁完成後，如果是捲動模式，通知 UI 跳轉到對應位置
      scrollOffsetController.add(fromEnd ? 999999.0 : 0.0);
    }

  }

  void onPageChanged(int i) {
    if (currentPageIndex != i) {
      currentPageIndex = i;
      notifyListeners();
      // 非同步更新進度到資料庫 (章節索引 + 標題 + 頁碼)
      final title = chapters.isNotEmpty ? chapters[currentChapterIndex].title : '';
      unawaited(bookDao.updateProgress(book.bookUrl, currentChapterIndex, title, i));
    }
  }


  Future<void> _preloadChapter(int i) async {
    if (chapterCache.containsKey(i) || isPreloading) return;
    isPreloading = true;
    try {
      final res = await fetchChapterData(i);
      chapterContentCache[i] = res.content;
      // 在後台執行分頁 (這裡可以進一步優化為 compute)
      // 但為了簡單先緩存內容
    } catch (_) {}
    finally { isPreloading = false; }
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

  Future<void> nextChapter() async { if (currentChapterIndex < chapters.length - 1) await loadChapter(currentChapterIndex + 1); }
  Future<void> prevChapter() async { if (currentChapterIndex > 0) await loadChapter(currentChapterIndex - 1, fromEnd: true); }
}





