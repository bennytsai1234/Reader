import 'dart:async';
import 'package:legado_reader/core/models/search_keyword.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// SearchKeywordDao - 搜尋關鍵字操作 (對標 Android SearchKeywordDao.kt)
class SearchKeywordDao extends DriftCompatDao<SearchKeyword> {
  SearchKeywordDao(AppDatabase appDatabase) : super(appDatabase, 'search_keywords');

  /// 獲取所有關鍵字 (對標 Android: all)
  Future<List<SearchKeyword>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
    );
    return maps.map((m) => SearchKeyword.fromJson(m)).toList();
  }

  /// 獲取熱門關鍵字
  Future<List<SearchKeyword>> getByUsage() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'usage DESC',
    );
    return maps.map((m) => SearchKeyword.fromJson(m)).toList();
  }

  /// 獲取最近使用的關鍵字
  Future<List<SearchKeyword>> getByTime() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'lastUseTime DESC',
    );
    return maps.map((m) => SearchKeyword.fromJson(m)).toList();
  }

  /// 搜尋關鍵字
  Future<List<SearchKeyword>> search(String key) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'word LIKE ?',
      whereArgs: ['%$key%'],
      orderBy: 'usage DESC',
    );
    return maps.map((m) => SearchKeyword.fromJson(m)).toList();
  }

  /// 根據關鍵字獲取 (對標 Android: get)
  Future<SearchKeyword?> getByWord(String word) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'word = ?',
      whereArgs: [word],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SearchKeyword.fromJson(maps.first);
  }

  /// 插入或更新關鍵字 (UPSERT)
  Future<void> upsert(SearchKeyword keyword) async {
    await insertOrUpdate(keyword.toJson());
  }

  /// 插入別名，兼容舊代碼
  Future<void> insert(SearchKeyword keyword) => upsert(keyword);

  /// 刪除指定關鍵字
  Future<void> deleteKeyword(SearchKeyword keyword) async {
    await deleteRows('word = ?', [keyword.word]);
  }

  /// 清空所有關鍵字
  Future<void> deleteAll() async {
    await clearAll();
  }
}
