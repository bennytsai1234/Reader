import 'dart:async';
import 'package:legado_reader/core/models/search_book.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// SearchBookDao - 搜尋書籍快取操作 (對標 Android SearchBookDao.kt)
class SearchBookDao extends DriftCompatDao<SearchBook> {
  SearchBookDao(AppDatabase appDatabase) : super(appDatabase, 'search_books');

  /// 根據 URL 獲取搜尋書籍 (對標 Android: getSearchBook)
  Future<SearchBook?> getSearchBook(String bookUrl) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SearchBook.fromJson(maps.first);
  }

  /// 根據名稱與作者尋找第一個結果 (對標 Android: getFirstByNameAuthor)
  Future<SearchBook?> getFirstByNameAuthor(String name, String author) async {
    final client = await db;
    // 透過 JOIN book_sources 確保來源是存在的
    final List<Map<String, dynamic>> maps = await client.rawQuery('''
      SELECT sb.* FROM search_books sb
      INNER JOIN book_sources bs ON sb.origin = bs.bookSourceUrl
      WHERE sb.name = ? AND sb.author = ?
      ORDER BY bs.customOrder ASC
      LIMIT 1
    ''', [name, author]);
    
    if (maps.isEmpty) return null;
    return SearchBook.fromJson(maps.first);
  }

  /// 獲取指定書籍的所有搜尋結果
  Future<List<SearchBook>> getSearchBooks(String name, String author) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery('''
      SELECT sb.* FROM search_books sb
      INNER JOIN book_sources bs ON sb.origin = bs.bookSourceUrl
      WHERE sb.name = ? AND sb.author = ?
      ORDER BY bs.customOrder ASC
    ''', [name, author]);
    return maps.map((m) => SearchBook.fromJson(m)).toList();
  }

  /// 換源搜尋 (對標 Android: changeSourceSearch)
  Future<List<SearchBook>> changeSourceSearch(
    String name, 
    String author, 
    String key, 
    String sourceGroup
  ) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery('''
      SELECT sb.* FROM search_books sb
      INNER JOIN book_sources bs ON sb.origin = bs.bookSourceUrl
      WHERE sb.name = ? AND sb.author = ? 
      AND bs.enabled = 1
      AND bs.bookSourceGroup LIKE ?
      AND (sb.originName LIKE ? OR sb.latestChapterTitle LIKE ?)
      ORDER BY bs.customOrder ASC
    ''', [name, author, '%$sourceGroup%', '%$key%', '%$key%']);
    
    return maps.map((m) => SearchBook.fromJson(m)).toList();
  }

  /// 獲取有封面的啟用源搜尋結果 (對標 Android: getEnabledHasCover)
  Future<List<SearchBook>> getEnabledHasCover(String name, String author) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery('''
      SELECT sb.* FROM search_books sb
      INNER JOIN book_sources bs ON sb.origin = bs.bookSourceUrl
      WHERE sb.name = ? AND sb.author = ? 
      AND bs.enabled = 1
      AND sb.coverUrl IS NOT NULL AND sb.coverUrl != ''
      ORDER BY bs.customOrder ASC
    ''', [name, author]);
    
    return maps.map((m) => SearchBook.fromJson(m)).toList();
  }

  /// 插入搜尋書籍 (UPSERT)
  Future<void> upsert(SearchBook searchBook) async {
    await insertOrUpdate(searchBook.toJson());
  }

  /// 批量插入
  Future<void> insertList(List<SearchBook> searchBooks) async {
    if (searchBooks.isEmpty) return;
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var sb in searchBooks) {
        batch.insert(
          tableName,
          sb.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 清除特定書籍的搜尋快取 (對標 Android: clear)
  Future<void> clearCache(String name, String author) async {
    await deleteRows('name = ? AND author = ?', [name, author]);
  }

  /// 清除過期快取 (對標 Android: clearExpired)
  Future<void> clearExpired(int time) async {
    await deleteRows('addTime < ?', [time]);
  }

  /// 清空所有
  Future<int> clearAll() => super.clearAll();
}
