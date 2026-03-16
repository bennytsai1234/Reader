import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'bookshelf_provider_base.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/local_book/txt_parser.dart';
import 'package:legado_reader/core/services/epub_service.dart';
import 'package:legado_reader/core/services/resource_service.dart';
import 'package:legado_reader/core/services/encoding_detect.dart';

/// BookshelfProvider 的本地書籍匯入邏輯擴展
mixin BookshelfImportMixin on BookshelfProviderBase {
  Future<void> importLocalBookPath(String path) async {
    final file = File(path);
    final ext = path.split('.').last.toLowerCase();
    final bookUrl = 'local://${file.path}';

    final existingBook = await bookDao.getByUrl(bookUrl);
    if (existingBook != null && existingBook.isInBookshelf) return;

    isLoading = true; notifyListeners();

    try {
      if (ext == 'txt') {
        final result = await compute((_) async {
          final parser = TxtParser(file);
          return await parser.splitChapters();
        }, null);

        final List<Map<String, dynamic>> chaptersData = result.chapters;
        final String detectedCharset = result.charset;


        final book = Book(
          bookUrl: bookUrl, 
          name: p.basenameWithoutExtension(path), 
          author: '本地', 
          origin: 'local', 
          originName: '本地', 
          isInBookshelf: true, 
          type: 0,
          charset: detectedCharset,
        );
        await bookDao.upsert(book);
        
        final bookChapters = <BookChapter>[];
        for (var i = 0; i < chaptersData.length; i++) {
          bookChapters.add(BookChapter(
            url: '$bookUrl#$i', 
            title: chaptersData[i]['title'] ?? '第 $i 章', 
            bookUrl: bookUrl, 
            index: i,
            start: chaptersData[i]['start'],
            end: chaptersData[i]['end'],
          ));
        }
        await chapterDao.insertChapters(bookChapters);
      } else if (ext == 'epub') {
        final meta = await EpubService().parseMetadata(file);

        final book = Book(
          bookUrl: bookUrl, 
          name: meta.title, 
          author: meta.author, 
          origin: 'local', 
          originName: '本地', 
          isInBookshelf: true, 
          type: 1,
          coverUrl: meta.coverBytes != null ? 'memory://$bookUrl' : null,
        );
        if (meta.coverBytes != null) {
          ResourceService().setMemoryResource('memory://$bookUrl', meta.coverBytes!);
        }
        await bookDao.upsert(book);
        
        final bookChapters = <BookChapter>[];
        for (var i = 0; i < meta.chapters.length; i++) {
          bookChapters.add(BookChapter(
            url: meta.chapters[i]['href'] ?? '', 
            title: meta.chapters[i]['title'] ?? '第 $i 章', 
            bookUrl: bookUrl, 
            index: i,
          ));
        }
        await chapterDao.insertChapters(bookChapters);
      }
      (this as dynamic).loadBooks();
    } catch (e) { debugPrint('匯入本地書籍失敗: $e'); } 
    finally { isLoading = false; notifyListeners(); }
  }
}

