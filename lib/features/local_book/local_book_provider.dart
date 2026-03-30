import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:legado_reader/core/local_book/epub_parser.dart';
import 'package:legado_reader/core/local_book/txt_parser.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/services/app_log_service.dart';

class LocalBookProvider extends ChangeNotifier {
  final BookDao _bookDao = getIt<BookDao>();
  final ChapterDao _chapterDao = getIt<ChapterDao>();
  final JavascriptRuntime _jsRuntime = getJavascriptRuntime();
  bool _isImporting = false;

  bool get isImporting => _isImporting;

  @override
  void dispose() {
    _jsRuntime.dispose();
    super.dispose();
  }

  /// 深度還原：利用 JS 解析檔名獲取書名與作者
  Future<Map<String, String>> _parseFileName(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final jsCode = prefs.getString('book_import_file_name_js') ?? '';
    
    if (jsCode.isEmpty) {
      return {'name': p.basenameWithoutExtension(fileName), 'author': ''};
    }

    try {
      final fullJs = '''
        var src = "$fileName";
        var name = "";
        var author = "";
        $jsCode
        JSON.stringify({name: name, author: author});
      ''';
      final result = _jsRuntime.evaluate(fullJs);
      final map = Map<String, dynamic>.from(jsonDecode(result.stringResult));
      return {
        'name': map['name']?.toString() ?? p.basenameWithoutExtension(fileName),
        'author': map['author']?.toString() ?? '',
      };
    } catch (e) {
      AppLog.e('JS 檔名解析失敗: $e');
      return {'name': p.basenameWithoutExtension(fileName), 'author': ''};
    }
  }

  Future<bool> importFile(String path) async {
    _isImporting = true;
    notifyListeners();

    final file = File(path);
    final ext = p.extension(path).toLowerCase();
    
    final info = await _parseFileName(p.basename(path));

    try {
      if (ext == '.txt') {
        final parser = TxtParser(file);
        await parser.load();
        final result = await parser.splitChapters();
        await _importTxt(file, info['name']!, info['author']!, result.chapters, result.charset);

      } else if (ext == '.epub') {
        await _importEpub(file);
      }
      return true;
    } catch (e) {
      AppLog.e('匯入本地書籍失敗 ($path): $e');
      return false;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> _importTxt(File file, String name, String author, List<Map<String, dynamic>> chaptersData, String charset) async {
    final book = Book(
      bookUrl: 'local://${file.path}',
      name: name,
      author: author,
      origin: 'local',
      originName: '本地',
      isInBookshelf: true,
      charset: charset,
    );


    await _bookDao.upsert(book);

    final chapters = <BookChapter>[];
    
    // 深度還原：分批寫入資料庫，防止大量匯入導致的 UI 凍結或 OOM
    // 注意：批量過大會觸發 Android CursorWindow 溢出，此處設定為 10
    const batchSize = 10;
    
    for (var i = 0; i < chaptersData.length; i++) {
      final item = chaptersData[i];
      final chapter = BookChapter(
        url: 'local://${file.path}#$i',
        title: item['title'] ?? '第 $i 章',
        index: i,
        bookUrl: book.bookUrl,
        content: item['content'] ?? '',
        start: item['start'],
        end: item['end'],
      );
      chapters.add(chapter);
      
      if (chapters.length >= batchSize) {
        await _chapterDao.insertChapters(List.from(chapters));
        chapters.clear();
        // 釋放執行權，維持 UI 響應
        await Future.delayed(Duration.zero);
      }
    }
    
    if (chapters.isNotEmpty) {
      await _chapterDao.insertChapters(chapters);
    }
  }

  Future<void> _importEpub(File file) async {
    final parser = EpubParser(file);
    await parser.load();
    final chaptersData = parser.getChapters();

    final book = Book(
      bookUrl: 'local://${file.path}',
      name: parser.title,
      author: parser.author,
      origin: 'local',
      originName: '本地',
      isInBookshelf: true,
    );

    await _bookDao.upsert(book);

    final chapters = <BookChapter>[];
    const batchSize = 100;

    for (var i = 0; i < chaptersData.length; i++) {
      final item = chaptersData[i];
      final href = item['href'] ?? '';
      final content = parser.getChapterContent(href);
      final chapter = BookChapter(
        url: href,
        title: item['title'] ?? '第 $i 章',
        index: i,
        bookUrl: book.bookUrl,
        content: content,
      );
      chapters.add(chapter);
      
      if (chapters.length >= batchSize) {
        await _chapterDao.insertChapters(List.from(chapters));
        chapters.clear();
      }
    }
    
    if (chapters.isNotEmpty) {
      await _chapterDao.insertChapters(chapters);
    }
  }
}


