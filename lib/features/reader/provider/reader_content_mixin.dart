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

/// ReaderProvider 的內容加載與分頁邏輯擴展
mixin ReaderContentMixin on ReaderProviderBase, ReaderSettingsMixin {
  Future<void> doPaginate({bool fromEnd = false}) async {
    if (viewSize == null || chapters.isEmpty) return;
    
    isLoading = true;
    notifyListeners();

    final currentTheme = AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];
    final ts = TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold, color: currentTheme.textColor, letterSpacing: letterSpacing);
    final cs = TextStyle(fontSize: fontSize, height: lineHeight, color: currentTheme.textColor, letterSpacing: letterSpacing);
    
    final chapter = chapters[currentChapterIndex];
    final chapterSize = chapters.length;
    final currentViewSize = viewSize!;
    
    pages = await compute((_) => ChapterProvider.paginate(
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
      padding: 16.0
    ), null);

    currentPageIndex = fromEnd ? (pages.length - 1).clamp(0, 999) : 0;
    jumpPageController.add(currentPageIndex);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadChapter(int i, {bool fromEnd = false}) async {
    if (i < 0 || i >= chapters.length) return;
    
    if (chapterCache.containsKey(i)) {
      currentChapterIndex = i;
      pages = chapterCache[i]!;
      content = chapterContentCache[i]!;
      currentPageIndex = fromEnd ? (pages.length - 1).clamp(0, 999) : 0;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 50), () => jumpPageController.add(currentPageIndex));
      return;
    }

    isLoading = true; 
    notifyListeners();
    
    try {
      final res = await fetchChapterData(i);
      content = res.content;
      currentChapterIndex = i;
      chapterContentCache[i] = content;
      
      await doPaginate(fromEnd: fromEnd);
      
      chapterCache[i] = pages;
    } catch (e) {
      content = '加載失敗: $e'; 
    } finally {
      isLoading = false; 
      notifyListeners();
    }
  }

  Future<({String content, List<dynamic> pages})> fetchChapterData(int i) async {
    final chapter = chapters[i];
    var raw = await chapterDao.getContent(chapter.url);
    if (raw == null) {
      if (book.origin == 'local') {
        raw = await LocalBookService().getContent(book, chapter);
      } else {
        if (source == null) {
          final all = await sourceDao.getAll();
          source = all.cast<BookSource?>().firstWhere((s) => s?.bookSourceUrl == book.origin, orElse: () => null);
        }
        if (source != null) {
          raw = await service.getContent(source!, book, chapter);
          await chapterDao.saveContent(chapter.url, raw);
        } else {
          raw = '找不到對應書源: ${book.origin}';
        }
      }
    }
    final rules = await replaceDao.getEnabled();
    final BookContent bookContent = await engine.ContentProcessor.process(
      book: book, chapter: chapter, rawContent: raw, rules: rules,
      chineseConvertType: chineseConvert, reSegmentEnabled: true,
    );
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
