import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/database/dao/book_group_dao.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/database/dao/read_record_dao.dart';
import 'package:legado_reader/core/database/dao/dict_rule_dao.dart';
import 'package:legado_reader/core/database/dao/http_tts_dao.dart';
import 'package:legado_reader/core/database/dao/txt_toc_rule_dao.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/dict_rule.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/replace_rule.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/models/read_record.dart';
import 'package:legado_reader/core/models/book_group.dart';
import 'package:legado_reader/core/models/http_tts.dart';
import 'package:legado_reader/core/models/txt_toc_rule.dart';
import 'package:legado_reader/core/di/injection.dart';

/// RestoreService - 統一恢復調度器
/// (原 Android help/storage/Restore.kt)
class RestoreService {
  static final RestoreService _instance = RestoreService._internal();
  factory RestoreService() => _instance;
  RestoreService._internal();

  final BookDao _bookDao = getIt<BookDao>();
  final BookSourceDao _sourceDao = getIt<BookSourceDao>();
  final ReplaceRuleDao _ruleDao = getIt<ReplaceRuleDao>();
  final BookGroupDao _groupDao = getIt<BookGroupDao>();
  final BookmarkDao _bookmarkDao = getIt<BookmarkDao>();
  final ReadRecordDao _recordDao = getIt<ReadRecordDao>();
  final DictRuleDao _dictRuleDao = getIt<DictRuleDao>();
  final HttpTtsDao _httpTtsDao = getIt<HttpTtsDao>();
  final TxtTocRuleDao _txtTocRuleDao = getIt<TxtTocRuleDao>();

  /// 從備份包 (ZIP) 恢復所有數據
  Future<bool> restoreFromZip(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (!file.isFile) continue;
        final data = utf8.decode(file.content as List<int>, allowMalformed: true);
        try {
          final dynamic decoded = jsonDecode(data);
          if (decoded is List) {
            await _importData(file.name, decoded);
          }
        } catch (e) {
          debugPrint('Restore failed for ${file.name}: $e');
        }
      }
      return true;
    } catch (e) {
      debugPrint('Restore from ZIP failed: $e');
      return false;
    }
  }

  Future<void> _importData(String fileName, List<dynamic> list) async {
    for (var item in list) {
      if (item is Map<String, dynamic>) {
        switch (fileName) {
          case 'books.json':
          case 'bookshelf.json':
            await _bookDao.upsert(Book.fromJson(item));
            break;
          case 'bookSources.json':
          case 'bookSource.json':
            await _sourceDao.upsert(BookSource.fromJson(item));
            break;
          case 'replaceRules.json':
          case 'replaceRule.json':
            await _ruleDao.upsert(ReplaceRule.fromJson(item));
            break;
          case 'bookGroups.json':
          case 'bookGroup.json':
            await _groupDao.upsert(BookGroup.fromJson(item));
            break;
          case 'bookmarks.json':
          case 'bookmark.json':
            await _bookmarkDao.upsert(Bookmark.fromJson(item));
            break;
          case 'readRecords.json':
          case 'readRecord.json':
            await _recordDao.upsert(ReadRecord.fromJson(item));
            break;
          case 'dictRule.json':
            await _dictRuleDao.upsert(DictRule.fromJson(item));
            break;
          case 'httpTts.json':
            await _httpTtsDao.upsert(HttpTTS.fromJson(item));
            break;
          case 'txtTocRule.json':
            await _txtTocRuleDao.upsert(TxtTocRule.fromJson(item));
            break;
          case 'config.json':
            final prefs = await SharedPreferences.getInstance();
            for (final key in item.keys) {
              dynamic val = item[key];
              if (val is String) {
                await prefs.setString(key, val);
              } else if (val is int) {
                await prefs.setInt(key, val);
              } else if (val is bool) {
                await prefs.setBool(key, val);
              } else if (val is double) {
                await prefs.setDouble(key, val);
              }
            }
            break;
        }
      }
    }
  }
}


