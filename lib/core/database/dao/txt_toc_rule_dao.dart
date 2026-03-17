import 'package:legado_reader/core/models/txt_toc_rule.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// TxtTocRuleDao - SQLite 實作 (對標 Android TxtTocRuleDao.kt)
class TxtTocRuleDao extends DriftCompatDao<TxtTocRule> {
  TxtTocRuleDao(AppDatabase appDatabase) : super(appDatabase, 'txt_toc_rules');

  /// 獲取所有目錄規則 (對標 Android: all)
  Future<List<TxtTocRule>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'serialNumber ASC',
    );
    return maps.map((m) => TxtTocRule.fromJson(m)).toList();
  }

  /// 獲取所有啟用的目錄規則 (對標 Android: enabled)
  Future<List<TxtTocRule>> getEnabled() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'enable = 1',
      orderBy: 'serialNumber ASC',
    );
    return maps.map((m) => TxtTocRule.fromJson(m)).toList();
  }

  /// 插入或更新單個規則 (UPSERT)
  Future<void> upsert(TxtTocRule rule) async {
    await insertOrUpdate(rule.toJson());
  }

  /// 批量更新
  Future<void> insertOrUpdateAll(List<TxtTocRule> rules) async {
    if (rules.isEmpty) return;
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

  /// 根據 ID 刪除
  Future<void> deleteById(int id) async {
    await deleteRows('id = ?', [id]);
  }

  /// 刪除規則別名，兼容舊代碼
  Future<void> deleteRule(int id) => deleteById(id);
}
