import 'dart:async';
import 'package:legado_reader/core/models/cache.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// CacheDao - 快取資料表操作 (對標 Android CacheDao.kt)
class CacheDao extends DriftCompatDao<Cache> {
  CacheDao(AppDatabase appDatabase) : super(appDatabase, 'cache');

  /// 根據 Key 獲取快取
  Future<Cache?> get(String key) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '`key` = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Cache.fromJson(maps.first);
  }

  /// 獲取有效的快取值 (對標 Android: getValue)
  Future<String?> getValue(String key, int now) async {
    final cache = await get(key);
    if (cache != null) {
      if (cache.deadline == 0 || cache.deadline > now) {
        return cache.value;
      }
    }
    return null;
  }

  /// 插入或更新快取 (UPSERT)
  Future<void> upsert(Cache cache) async {
    await insertOrUpdate(cache.toJson());
  }

  /// 插入或更新別名，兼容舊代碼
  @override
  Future<int> insertOrUpdate(Map<String, dynamic> row) async {
    final client = await db;
    return await client.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 刪除指定快取
  Future<void> deleteByKey(String key) async {
    await deleteRows('`key` = ?', [key]);
  }

  /// 刪除書源相關變量 (對標 Android: deleteSourceVariables)
  Future<void> deleteSourceVariables(String key) async {
    final client = await db;
    await client.delete(
      tableName,
      where: "`key` LIKE 'v_${key}_%' OR `key` = ? OR `key` = ? OR `key` = ?",
      whereArgs: ['userInfo_$key', 'loginHeader_$key', 'sourceVariable_$key'],
    );
  }

  /// 清除過期快取 (對標 Android: clearDeadline)
  Future<void> clearDeadline(int now) async {
    final client = await db;
    await client.delete(
      tableName,
      where: 'deadline > 0 AND deadline < ?',
      whereArgs: [now],
    );
  }
}
