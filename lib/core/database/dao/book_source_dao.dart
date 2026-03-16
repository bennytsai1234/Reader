import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/book_source_part.dart';
import '../app_database.dart';

/// BookSourceDao - SQLite 實作 (對標 Android BookSourceDao.kt)
class BookSourceDao extends BaseDao<BookSource> {
  BookSourceDao(AppDatabase appDatabase) : super(appDatabase, 'book_sources');

  // --- 局部查詢 (Part) ---

  /// 獲取局部查詢的列名 (對位 Android BookSourcePart)
  List<String> get _partColumns => [
    'bookSourceUrl',
    'bookSourceName',
    'bookSourceGroup',
    'customOrder',
    'enabled',
    'enabledExplore',
    'lastUpdateTime',
    'respondTime',
    'weight',
    '(loginUrl IS NOT NULL AND loginUrl != "") AS hasLoginUrl',
    '(exploreUrl IS NOT NULL AND exploreUrl != "") AS hasExploreUrl',
    '(searchUrl IS NOT NULL AND searchUrl != "") AS hasSearchUrl',
    '(ruleBookInfo IS NOT NULL AND ruleBookInfo != "" AND ruleBookInfo != "null") AS hasBookInfoRule',
    '(ruleToc IS NOT NULL AND ruleToc != "" AND ruleToc != "null") AS hasTocRule',
    '(ruleContent IS NOT NULL AND ruleContent != "" AND ruleContent != "null") AS hasContentRule',
  ];

  /// 獲取所有書源簡略信息 (對標 Android: allPart)
  Future<List<BookSourcePart>> getAllPart() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: _partColumns,
      orderBy: 'customOrder ASC, weight DESC',
    );
    return maps.map((m) => BookSourcePart.fromJson(m)).toList();
  }

  /// 搜尋局部書源 (對標 Android: flowSearch)
  Future<List<BookSourcePart>> searchPart(String searchKey) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: _partColumns,
      where: 'bookSourceName LIKE ? OR bookSourceGroup LIKE ? OR bookSourceUrl LIKE ? OR bookSourceComment LIKE ?',
      whereArgs: List.filled(4, '%$searchKey%'),
      orderBy: 'customOrder ASC',
    );
    return maps.map((m) => BookSourcePart.fromJson(m)).toList();
  }

  // --- 完整查詢 (Full) ---

  /// 獲取所有書源 (對標 Android: all)
  Future<List<BookSource>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'customOrder ASC, weight DESC',
    );
    return maps.map((m) => BookSource.fromJson(m)).toList();
  }

  /// 獲取所有啟用的書源 (對標 Android: allEnabled)
  Future<List<BookSource>> getEnabled() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'enabled = 1',
      orderBy: 'customOrder ASC, weight DESC',
    );
    return maps.map((m) => BookSource.fromJson(m)).toList();
  }

  /// 獲取具備發現功能的書源 (對標 Android: flowExplore)
  Future<List<BookSourcePart>> getExplorePart() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: _partColumns,
      where: 'enabledExplore = 1 AND exploreUrl IS NOT NULL AND exploreUrl != ""',
      orderBy: 'customOrder ASC',
    );
    return maps.map((m) => BookSourcePart.fromJson(m)).toList();
  }

  /// 獲取需登入的書源 (對標 Android: flowLogin)
  Future<List<BookSourcePart>> getLoginPart() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: _partColumns,
      where: 'loginUrl IS NOT NULL AND loginUrl != ""',
      orderBy: 'customOrder ASC',
    );
    return maps.map((m) => BookSourcePart.fromJson(m)).toList();
  }

  /// 獲取未分組書源 (對標 Android: flowNoGroup)
  Future<List<BookSourcePart>> getNoGroupPart() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: _partColumns,
      where: 'bookSourceGroup IS NULL OR bookSourceGroup = "" OR bookSourceGroup LIKE "%未分組%"',
      orderBy: 'customOrder ASC',
    );
    return maps.map((m) => BookSourcePart.fromJson(m)).toList();
  }

  /// 根據 URL 獲取單一書源 (對標 Android: getBookSource)
  Future<BookSource?> getByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookSourceUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookSource.fromJson(maps.first);
  }

  /// 根據 URL 獲取局部書源 (對標 Android: getBookSourcePart)
  Future<BookSourcePart?> getPartByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: _partColumns,
      where: 'bookSourceUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookSourcePart.fromJson(maps.first);
  }

  // --- 操作 (Operations) ---

  /// 插入或更新 (UPSERT)
  Future<void> upsert(BookSource source) async {
    await insertOrUpdate(source.toJson());
  }

  /// 批量更新書源 (對標 Android: insert)
  Future<void> upsertAll(List<BookSource> sources) async {
    if (sources.isEmpty) return;
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var source in sources) {
        batch.insert(
          tableName,
          source.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 批量啟用/禁用 (對標 Android: enable)
  Future<void> enableSources(List<String> urls, bool enable) async {
    if (urls.isEmpty) return;
    final client = await db;
    await client.update(
      tableName,
      {'enabled': enable ? 1 : 0},
      where: 'bookSourceUrl IN (${List.filled(urls.length, '?').join(',')})',
      whereArgs: urls,
    );
  }

  /// 批量更新排序 (對標 Android: upOrder)
  Future<void> updateOrder(String url, int order) async {
    final client = await db;
    await client.update(
      tableName,
      {'customOrder': order},
      where: 'bookSourceUrl = ?',
      whereArgs: [url],
    );
  }

  /// 根據 URL 刪除 (對標 Android: delete)
  Future<void> deleteByUrl(String url) async {
    final client = await db;
    await client.delete(tableName, where: 'bookSourceUrl = ?', whereArgs: [url]);
  }

  /// 批量刪除
  Future<void> deleteByUrls(List<String> urls) async {
    if (urls.isEmpty) return;
    final client = await db;
    await client.delete(
      tableName,
      where: 'bookSourceUrl IN (${List.filled(urls.length, '?').join(',')})',
      whereArgs: urls,
    );
  }

  // --- 分組處理 (Group Handling) ---

  /// 獲取所有獨特的分組 (對標 Android: allGroups)
  Future<List<String>> getAllGroups() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['bookSourceGroup'],
      where: 'bookSourceGroup IS NOT NULL AND bookSourceGroup != ""',
    );
    
    final groups = <String>{};
    for (var m in maps) {
      final gStr = m['bookSourceGroup'] as String;
      groups.addAll(gStr.split(RegExp(r'[,，\s]+')).where((s) => s.trim().isNotEmpty));
    }
    return groups.toList()..sort();
  }

  /// 重新命名分組 (對標 Android: renameGroup)
  Future<void> renameGroup(String oldName, String newName) async {
    final client = await db;
    // 這是一個複雜的操作，因為分組是逗號分隔的。這裡採集簡化邏輯：
    // 將包含 oldName 的分組取出，在 Dart 中處理後寫回。
    final maps = await client.query(
      tableName,
      where: 'bookSourceGroup LIKE ?',
      whereArgs: ['%$oldName%'],
    );

    await client.transaction((txn) async {
      for (var m in maps) {
        final gStr = m['bookSourceGroup'] as String;
        final updated = gStr.split(RegExp(r'[,，\s]+')).map((g) => g == oldName ? newName : g).join(',');
        await txn.update(tableName, {'bookSourceGroup': updated}, where: 'bookSourceUrl = ?', whereArgs: [m['bookSourceUrl']]);
      }
    });
  }

  /// 移除分組標籤 (對標 Android: removeGroupLabel)
  Future<void> removeGroupLabel(String groupLabel) async {
    final client = await db;
    final maps = await client.query(
      tableName,
      where: 'bookSourceGroup LIKE ?',
      whereArgs: ['%$groupLabel%'],
    );

    await client.transaction((txn) async {
      for (var m in maps) {
        final gStr = m['bookSourceGroup'] as String;
        final updated = gStr.split(RegExp(r'[,，\s]+')).where((g) => g != groupLabel).join(',');
        await txn.update(tableName, {'bookSourceGroup': updated.isEmpty ? null : updated}, where: 'bookSourceUrl = ?', whereArgs: [m['bookSourceUrl']]);
      }
    });
  }

  /// 調整排序號碼 (對標 Android: adjustSortNumber)
  Future<void> adjustSortNumbers() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['bookSourceUrl'],
      orderBy: 'customOrder ASC, bookSourceName ASC',
    );
    
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < maps.length; i++) {
        batch.update(
          tableName,
          {'customOrder': i},
          where: 'bookSourceUrl = ?',
          whereArgs: [maps[i]['bookSourceUrl']],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // --- 別名與相容性 ---
  Future<List<BookSource>> getAllFull() => getAll();
  Future<void> insertOrUpdateAll(List<BookSource> sources) => upsertAll(sources);
  Future<void> update(BookSource source) => upsert(source);
  
  /// 批量更新排序 (支持 BookSource 與 BookSourcePart)
  Future<void> updateCustomOrder(List<dynamic> sources) async {
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var s in sources) {
        batch.update(
          tableName,
          {'customOrder': s.customOrder},
          where: 'bookSourceUrl = ?',
          whereArgs: [s.bookSourceUrl],
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
