import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:legado_reader/core/services/app_log_service.dart';

import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/services/epub_service.dart';
import 'package:fast_gbk/fast_gbk.dart';

/// LocalBookService - 本地書籍內容獲取服務
class LocalBookService {
  static final LocalBookService _instance = LocalBookService._internal();
  factory LocalBookService() => _instance;
  LocalBookService._internal();

  RandomAccessFile? _txtAccessFile;
  String? _txtAccessFilePath;
  Future<void> _txtReadChain = Future<void>.value();

  /// 獲取本地書籍章節內容
  Future<String> getContent(Book book, BookChapter chapter) async {
    final path = book.bookUrl.replaceFirst('local://', '');
    final file = File(path);
    if (!await file.exists()) return '檔案不存在: $path';


    final ext = path.split('.').last.toLowerCase();
    if (ext == 'txt') {
      // 根據章節索引 (start, end) 指標讀取 TXT 部分內容 (對標 Android ReadLocalBook.kt)
      if (chapter.start != null && chapter.end != null) {
        return _queueTxtRead(() async {
          final accessFile = await _getTxtAccessFile(file, path);
          final start = chapter.start!;
          final end = chapter.end!;
          AppLog.d('LocalBookService: Reading bytes from $start to $end (length: ${end - start})');
          await accessFile.setPosition(start);
          final bytes = await accessFile.read(end - start);
          return _decodeBytes(bytes, book.charset ?? 'utf-8');
        });
      }
      AppLog.d('LocalBookService: Missing offsets for chapter ${chapter.title}');
      return '本地 TXT 索引缺失，請重新匯入';

    } else if (ext == 'epub') {
      return await EpubService().getChapterContent(file, chapter.url);
    }
    return '不支援的本地格式: $ext';
  }

  Future<T> _queueTxtRead<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _txtReadChain = _txtReadChain.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<RandomAccessFile> _getTxtAccessFile(File file, String path) async {
    if (_txtAccessFile != null && _txtAccessFilePath == path) {
      return _txtAccessFile!;
    }
    if (_txtAccessFile != null) {
      await _txtAccessFile!.close();
      _txtAccessFile = null;
      _txtAccessFilePath = null;
    }
    _txtAccessFile = await file.open(mode: FileMode.read);
    _txtAccessFilePath = path;
    return _txtAccessFile!;
  }

  String _decodeBytes(List<int> bytes, String charset) {
    try {
      final name = charset.toLowerCase();
      if (name == 'gbk' || name == 'gb2312' || name == 'gb18030') {
        return gbk.decode(bytes);
      }
      return utf8.decode(bytes);
    } catch (e) {
      // 降級處理：如果 UTF-8 失敗嘗試 GBK，反之亦然
      try {
        return gbk.decode(bytes);
      } catch (_) {
        return utf8.decode(bytes, allowMalformed: true);
      }
    }
  }
}

