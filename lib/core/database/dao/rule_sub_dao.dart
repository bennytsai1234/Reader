import 'dart:async';
import 'package:legado_reader/core/models/rule_sub.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// RuleSubDao - 訂閱規則操作 (對標 Android RuleSubDao.kt)
class RuleSubDao extends DriftCompatDao<RuleSub> {
  RuleSubDao(AppDatabase appDatabase) : super(appDatabase, 'rule_subs');

  /// 獲取所有訂閱規則 (對標 Android: all)
  Future<List<RuleSub>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: '`order` ASC',
    );
    return maps.map((m) => RuleSub.fromJson(m)).toList();
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

  /// 根據 URL 尋找訂閱
  Future<RuleSub?> findByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RuleSub.fromJson(maps.first);
  }

  /// 插入或更新訂閱 (UPSERT)
  Future<void> upsert(RuleSub sub) async {
    await insertOrUpdate(sub.toJson());
  }

  /// 刪除訂閱
  Future<void> deleteSub(RuleSub sub) async {
    await deleteRows('url = ?', [sub.url]);
  }
}
