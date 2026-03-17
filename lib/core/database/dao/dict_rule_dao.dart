import 'dart:async';
import 'package:legado_reader/core/models/dict_rule.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// DictRuleDao - SQLite 實作 (對標 Android DictRuleDao.kt)
class DictRuleDao extends DriftCompatDao<DictRule> {
  DictRuleDao(AppDatabase appDatabase) : super(appDatabase, 'dict_rules');

  /// 獲取所有字典規則 (對標 Android: all)
  Future<List<DictRule>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'sortNumber ASC',
    );
    return maps.map((m) => DictRule.fromJson(m)).toList();
  }

  /// 獲取所有啟用的規則 (對標 Android: enabled)
  Future<List<DictRule>> getEnabled() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'enabled = 1',
      orderBy: 'sortNumber ASC',
    );
    return maps.map((m) => DictRule.fromJson(m)).toList();
  }

  /// 根據名稱獲取
  Future<DictRule?> getByName(String name) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DictRule.fromJson(maps.first);
  }

  /// 插入或更新單個規則 (UPSERT)
  Future<void> upsert(DictRule rule) async {
    await insertOrUpdate(rule.toJson());
  }

  /// 插入或更新別名，兼容舊代碼
  Future<void> insertOrUpdateRule(DictRule rule) => upsert(rule);

  /// 批量插入或更新
  Future<void> insertOrUpdateAll(List<DictRule> rules) async {
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var rule in rules) {
        batch.insert(
          tableName,
          rule.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 根據名稱刪除
  Future<void> deleteByName(String name) async {
    await deleteRows('name = ?', [name]);
  }
}
