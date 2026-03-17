import 'dart:async';
import 'package:legado_reader/core/models/book_group.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// BookGroupDao - 書籍群組資料表操作 (對標 Android BookGroupDao.kt)
class BookGroupDao extends DriftCompatDao<BookGroup> {
  BookGroupDao(AppDatabase appDatabase) : super(appDatabase, 'book_groups');

  /// 根據 ID 獲取分組
  Future<BookGroup?> getById(int id) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'groupId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookGroup.fromJson(maps.first);
  }

  /// 根據名稱獲取分組
  Future<BookGroup?> getByName(String groupName) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'groupName = ?',
      whereArgs: [groupName],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookGroup.fromJson(maps.first);
  }

  /// 獲取所有分組 (對標 Android: all)
  Future<List<BookGroup>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: '`order` ASC',
    );
    return maps.map((m) => BookGroup.fromJson(m)).toList();
  }

  /// 獲取所有現存 ID 的聯集 (位元 OR 總和)
  Future<int> getIdsSum() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['groupId'],
      where: 'groupId > 0',
    );
    return maps.fold<int>(0, (sum, item) => sum | (item['groupId'] as int));
  }

  /// 獲取最大排序值
  Future<int> getMaxOrder() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['`order`'],
      orderBy: '`order` DESC',
      limit: 1,
    );
    if (maps.isEmpty) return 0;
    return maps.first['order'] as int;
  }

  /// 是否可以新增分組 (限制 64 個，因為 64 位整數限制)
  Future<bool> getCanAddGroup() async {
    final client = await db;
    final count = driftFirstIntValue(await client.rawQuery('SELECT COUNT(*) FROM $tableName WHERE groupId > 0')) ?? 0;
    return count < 64;
  }

  /// 獲取一個未使用的 ID (2 的冪次方)
  Future<int> getUnusedId() async {
    var id = 1;
    final idsSum = await getIdsSum();
    while ((id & idsSum) != 0 && id > 0) {
      id = id << 1;
    }
    return id;
  }

  /// 啟用分組
  Future<void> enableGroup(int groupId) async {
    final client = await db;
    await client.update(
      tableName,
      {'show': 1},
      where: 'groupId = ?',
      whereArgs: [groupId],
    );
  }

  /// 根據聯集 ID 獲取所有對應的分組名稱
  Future<List<String>> getGroupNames(int id) async {
    final list = await getAll();
    return list.where((g) => g.groupId > 0 && (g.groupId & id) > 0).map((g) => g.groupName).toList();
  }

  /// 插入或更新分組 (UPSERT)
  Future<void> upsert(BookGroup bookGroup) async {
    await insertOrUpdate(bookGroup.toJson());
  }

  /// 插入別名，兼容舊代碼
  Future<void> insert(BookGroup bookGroup) => upsert(bookGroup);

  /// 批量更新排序
  Future<void> updateOrder(List<BookGroup> list) async {
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var b in list) {
        batch.update(
          tableName,
          {'groupOrder': b.order},
          where: 'groupId = ?',
          whereArgs: [b.groupId],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 刪除分組
  Future<void> deleteById(int id) async {
    await deleteRows('groupId = ?', [id]);
  }

  /// 刪除分組實體別名
  Future<void> deleteGroup(BookGroup group) => deleteById(group.groupId);

  /// 初始化預設分組
  Future<void> initDefaultGroups() async {
    final defaultGroups = [
      BookGroup(groupId: 1, groupName: '現代言情', order: 0),
      BookGroup(groupId: 2, groupName: '東方玄幻', order: 1),
      BookGroup(groupId: 4, groupName: '名著經典', order: 2),
    ];
    for (var g in defaultGroups) {
      final existing = await getByName(g.groupName);
      if (existing == null) {
        await upsert(g);
      }
    }
  }
}
