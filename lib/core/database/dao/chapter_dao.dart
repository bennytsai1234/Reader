import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/chapter.dart';
import '../app_database.dart';

/// ChapterDao - SQLite 實作 (對標 Android BookChapterDao.kt)
class ChapterDao extends BaseDao<BookChapter> {
  ChapterDao(AppDatabase appDatabase) : super(appDatabase, 'chapters');

  /// 搜尋章節標題 (對標 Android: search)
  Future<List<BookChapter>> search(String bookUrl, String key, {int? start, int? end}) async {
    final client = await db;
    String where = 'bookUrl = ? AND title LIKE ?';
    List<dynamic> whereArgs = [bookUrl, '%$key%'];
    
    if (start != null && end != null) {
      where += ' AND `index` >= ? AND `index` <= ?';
      whereArgs.addAll([start, end]);
    }
    
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: '`index` ASC',
    );
    return maps.map((m) => BookChapter.fromJson(m)).toList();
  }

  /// 獲取指定書籍的所有章節 (對標 Android: getChapterList)
  Future<List<BookChapter>> getChapterList(String bookUrl, {int? start, int? end}) async {
    final client = await db;
    String where = 'bookUrl = ?';
    List<dynamic> whereArgs = [bookUrl];

    if (start != null && end != null) {
      where += ' AND `index` >= ? AND `index` <= ?';
      whereArgs.addAll([start, end]);
    }

    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: '`index` ASC',
    );
    return maps.map((m) => BookChapter.fromJson(m)).toList();
  }

  /// getChapterList 的別名，相容舊代碼
  Future<List<BookChapter>> getByBookUrl(String bookUrl) => getChapterList(bookUrl);
  Future<List<BookChapter>> getChapters(String bookUrl) => getChapterList(bookUrl);

  /// 根據 URL 和索引獲取單一章節 (對標 Android: getChapter)
  Future<BookChapter?> getChapter(String bookUrl, int index) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookUrl = ? AND `index` = ?',
      whereArgs: [bookUrl, index],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookChapter.fromJson(maps.first);
  }

  /// getChapter 的別名
  Future<BookChapter?> getChapterByIndex(String bookUrl, int index) => getChapter(bookUrl, index);

  /// 根據標題獲取單一章節 (對標 Android: getChapter)
  Future<BookChapter?> getChapterByTitle(String bookUrl, String title) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookUrl = ? AND title = ?',
      whereArgs: [bookUrl, title],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookChapter.fromJson(maps.first);
  }

  /// 獲取章節數量 (對標 Android: getChapterCount)
  Future<int> getChapterCount(String bookUrl) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE bookUrl = ?',
      [bookUrl]
    );
    return Sqflite.firstIntValue(maps) ?? 0;
  }

  /// 根據 URL 獲取單一章節 (對標 Android: getChapter by url)
  Future<BookChapter?> getByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookChapter.fromJson(maps.first);
  }

  /// 儲存章節內容 (對標 Android: saveContent)
  Future<void> saveContent(String url, String content) async {
    final client = await db;
    await client.update(
      tableName,
      {'content': content},
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  /// 更新字數 (對標 Android: upWordCount)
  Future<void> updateWordCount(String bookUrl, String url, String wordCount) async {
    final client = await db;
    await client.update(
      tableName,
      {'wordCount': wordCount},
      where: 'bookUrl = ? AND url = ?',
      whereArgs: [bookUrl, url],
    );
  }

  /// 獲取章節內容 (對標 Android: getContent)
  Future<String?> getContent(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['content'],
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['content'] as String?;
  }

  /// 插入單個章節
  Future<void> upsert(BookChapter chapter) async {
    await insertOrUpdate(chapter.toJson());
  }

  /// 批量插入章節 (對標 Android: insert)
  Future<void> insertChapters(List<BookChapter> chapters) async {
    if (chapters.isEmpty) return;
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var chapter in chapters) {
        batch.insert(
          tableName,
          chapter.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 刪除書籍的所有章節 (對標 Android: delByBook)
  Future<void> deleteByBookUrl(String bookUrl) async {
    await delete('bookUrl = ?', [bookUrl]);
  }

  /// 檢查章節內容是否已存在
  Future<bool> hasContent(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['content'],
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return false;
    final content = maps.first['content'] as String?;
    return content != null && content.isNotEmpty;
  }

  /// 清空章節內容
  Future<void> deleteContentByBook(String bookUrl) async {
    final client = await db;
    await client.update(tableName, {'content': null}, where: 'bookUrl = ?', whereArgs: [bookUrl]);
  }

  /// 刪除書籍所有章節的別名
  Future<void> deleteByBook(String bookUrl) => deleteByBookUrl(bookUrl);

  /// 清空所有章節內容
  Future<void> clearAllContent() async {
    final client = await db;
    await client.update(tableName, {'content': null});
  }

  /// 獲取所有章節內容總大小
  Future<int> getTotalContentSize() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      'SELECT SUM(LENGTH(content)) as total FROM $tableName'
    );
    if (maps.isEmpty || maps.first['total'] == null) return 0;
    return maps.first['total'] as int;
  }
}
