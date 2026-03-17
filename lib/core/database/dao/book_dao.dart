import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_group.dart';
import 'package:legado_reader/core/constant/book_type.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// BookDao - SQLite 實作 (對標 Android BookDao.kt)
class BookDao extends DriftCompatDao<Book> {
  BookDao(AppDatabase appDatabase) : super(appDatabase, 'books');

  /// 獲取所有書籍 (對標 Android: all)
  Future<List<Book>> getAll() async {
    final List<Map<String, dynamic>> maps = await queryAll();
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 獲取書架根目錄書籍 (對標 Android: flowRoot)
  /// 過濾條件：在書架上、非本地、且不屬於任何已存在的分組
  Future<List<Book>> getInRoot() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      '''SELECT * FROM $tableName 
         WHERE isInBookshelf = 1 
         AND (type & ?) = 0
         AND (`group` & (SELECT SUM(groupId) FROM book_groups WHERE groupId > 0)) = 0
         ORDER BY durChapterTime DESC''',
      [BookType.local]
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 根據書名清單獲取書籍 (對標 Android: findByName)
  Future<List<Book>> findByNames(List<String> names) async {
    if (names.isEmpty) return [];
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'name IN (${List.filled(names.length, '?').join(',')})',
      whereArgs: names,
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 根據分組 ID 獲取書籍 (對標 Android: flowByGroup)
  Future<List<Book>> getInGroup(int groupId) async {
    if (groupId == BookGroup.idAll) return getInBookshelf();
    if (groupId == BookGroup.idRoot) return getInRoot();
    if (groupId == BookGroup.idAudio) return getAudioBooks();
    if (groupId == BookGroup.idLocal) return getLocalBooks();
    if (groupId == BookGroup.idError) return getUpdateErrorBooks();
    
    // 處理特殊分組 ID (對標 Android BookDao.kt line 25)
    // 這些 ID 在 Android 中有特定的過濾邏輯，這裡我們轉向 getByUserGroup
    return getByUserGroup(groupId);
  }
  /// 獲取所有書架上的書籍 (對標 Android: flowAll)
  Future<List<Book>> getInBookshelf() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'isInBookshelf = 1',
      orderBy: 'durChapterTime DESC, `order` ASC',
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// getInBookshelf 的別名，相容舊代碼
  Future<List<Book>> getAllInBookshelf() => getInBookshelf();

  /// 獲取音訊書籍 (對標 Android: flowAudio)
  Future<List<Book>> getAudioBooks() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '(type & ?) > 0 AND isInBookshelf = 1',
      whereArgs: [BookType.audio],
      orderBy: 'durChapterTime DESC',
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 獲取本地書籍 (對標 Android: flowLocal)
  Future<List<Book>> getLocalBooks() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '(type & ?) > 0 AND isInBookshelf = 1',
      whereArgs: [BookType.local],
      orderBy: 'durChapterTime DESC',
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 獲取更新失敗書籍 (對標 Android: flowUpdateError)
  Future<List<Book>> getUpdateErrorBooks() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '(type & ?) > 0 AND isInBookshelf = 1',
      whereArgs: [BookType.updateError],
      orderBy: 'durChapterTime DESC',
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 獲取使用者分組書籍 (對標 Android: flowByUserGroup)
  Future<List<Book>> getByUserGroup(int groupMask) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '(`group` & ?) > 0 AND isInBookshelf = 1',
      whereArgs: [groupMask],
      orderBy: 'durChapterTime DESC',
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 獲取最後閱讀的書籍 (對標 Android: lastReadBook)
  Future<Book?> getLastReadBook() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'isInBookshelf = 1',
      orderBy: 'durChapterTime DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Book.fromJson(maps.first);
  }

  /// 根據 URL 獲取單一書籍 (對標 Android: getBook)
  Future<Book?> getByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Book.fromJson(maps.first);
  }

  /// 根據書名與作者獲取書籍
  Future<Book?> getByNameAndAuthor(String name, String author) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'name = ? AND author = ?',
      whereArgs: [name, author],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Book.fromJson(maps.first);
  }

  /// 獲取書架上正在使用的所有書源 URL (對標 Android: getAllUseBookSource)
  Future<List<String>> getAllUsedSourceUrls() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      '''SELECT DISTINCT origin FROM books 
         WHERE isInBookshelf = 1 
         AND origin NOT LIKE '${BookType.localTag}%' 
         AND origin NOT LIKE '${BookType.webDavTag}%'''
    );
    return maps.map((m) => m['origin'] as String).toList();
  }

  /// getByUserGroup 的別名，相容舊代碼
  Future<List<Book>> getBooksInGroup(int groupMask) => getByUserGroup(groupMask);

  /// 檢查本地檔案是否存在 (對標 Android: hasFile)
  Future<bool> hasFile(String fileName) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '''(type & ?) > 0 
                AND (originName = ? OR (origin != ? AND origin LIKE ?))''',
      whereArgs: [BookType.local, fileName, BookType.localTag, '%$fileName'],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// 搜尋書籍 (對標 Android: flowSearch)
  Future<List<Book>> search(String key) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '(name LIKE ? OR author LIKE ?) AND isInBookshelf = 1',
      whereArgs: ['%$key%', '%$key%'],
      orderBy: 'durChapterTime DESC',
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 檢查是否存在 (對標 Android: has)
  Future<bool> has(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['bookUrl'],
      where: 'bookUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// 插入或更新書籍 (UPSERT)
  Future<void> upsert(Book book) async {
    await insertOrUpdate(book.toJson());
  }

  /// 批量更新
  Future<void> upsertAll(List<Book> books) async {
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var book in books) {
        batch.insert(
          tableName,
          book.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 更新閱讀進度 (對標 Android Room @Query updateProgress)
  Future<void> updateProgress(String bookUrl, int chapterIndex, String? chapterTitle, int pos) async {
    final client = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await client.update(
      tableName,
      {
        'durChapterIndex': chapterIndex,
        'durChapterTitle': chapterTitle,
        'durChapterPos': pos,
        'durChapterTime': now,
      },
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
  }
  /// 根據 URL 刪除書籍
  Future<void> deleteByUrl(String url) async {
    final client = await db;
    await client.delete(
      tableName,
      where: 'bookUrl = ?',
      whereArgs: [url],
    );
  }

  /// 清理未在書架上的書籍 (對標 Android: deleteNotShelfBook)
  Future<void> deleteNotShelfBooks() async {
    final client = await db;
    await client.delete(
      tableName,
      where: 'isInBookshelf = 0',
    );
  }
}
