import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';


import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/services/epub_service.dart';
import 'package:fast_gbk/fast_gbk.dart';

/// LocalBookService - 本地書籍內容獲取服務
class LocalBookService {
  static final LocalBookService _instance = LocalBookService._internal();
  factory LocalBookService() => _instance;
  LocalBookService._internal();

  /// 獲取本地書籍章節內容
  Future<String> getContent(Book book, BookChapter chapter) async {
    final path = book.bookUrl.replaceFirst('local://', '');
    final file = File(path);
    if (!await file.exists()) return '檔案不存在: $path';


    final ext = path.split('.').last.toLowerCase();
    if (ext == 'txt') {
      // 根據章節索引 (start, end) 指標讀取 TXT 部分內容 (對標 Android ReadLocalBook.kt)
      if (chapter.start != null && chapter.end != null) {
        final accessFile = await file.open(mode: FileMode.read);
        try {
          final start = chapter.start!;
          final end = chapter.end!;
          debugPrint('LocalBookService: Reading bytes from $start to $end (length: ${end - start})');
          await accessFile.setPosition(start);
          final bytes = await accessFile.read(end - start);
          return _decodeBytes(bytes, book.charset ?? 'utf-8');
        } finally {
          await accessFile.close();
        }
      }
      debugPrint('LocalBookService: Missing offsets for chapter ${chapter.title}');
      return '本地 TXT 索引缺失，請重新匯入';

    } else if (ext == 'epub') {
      return await EpubService().getChapterContent(file, chapter.url);
    }
    return '不支援的本地格式: $ext';
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

