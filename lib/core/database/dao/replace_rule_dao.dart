import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/replace_rule.dart';
import '../app_database.dart';

/// ReplaceRuleDao - SQLite 實作 (對標 Android ReplaceRuleDao.kt)
class ReplaceRuleDao extends BaseDao<ReplaceRule> {
  ReplaceRuleDao(AppDatabase appDatabase) : super(appDatabase, 'replace_rules');

  /// 獲取所有替換規則 (對標 Android: all)
  Future<List<ReplaceRule>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: '`order` ASC, name ASC',
    );
    return maps.map((m) => ReplaceRule.fromJson(m)).toList();
  }

  /// 獲取所有啟用的替換規則 (對標 Android: allEnabled)
  Future<List<ReplaceRule>> getEnabled() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'isEnabled = 1',
      orderBy: '`order` ASC',
    );
    return maps.map((m) => ReplaceRule.fromJson(m)).toList();
  }

  /// 獲取作用於正文且在範圍內的規則 (對標 Android: findEnabledByContentScope)
  Future<List<ReplaceRule>> findEnabledByContentScope(String name, String origin) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      '''SELECT * FROM $tableName WHERE isEnabled = 1 AND scopeContent = 1
         AND (scope LIKE ? OR scope LIKE ? OR scope IS NULL OR scope = "")
         AND (excludeScope IS NULL OR (excludeScope NOT LIKE ? AND excludeScope NOT LIKE ?))
         ORDER BY `order` ASC''',
      ['%$name%', '%$origin%', '%$name%', '%$origin%']
    );
    return maps.map((m) => ReplaceRule.fromJson(m)).toList();
  }

  /// 獲取作用於標題且在範圍內的規則 (對標 Android: findEnabledByTitleScope)
  Future<List<ReplaceRule>> findEnabledByTitleScope(String name, String origin) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      '''SELECT * FROM $tableName WHERE isEnabled = 1 AND scopeTitle = 1
         AND (scope LIKE ? OR scope LIKE ? OR scope IS NULL OR scope = "")
         AND (excludeScope IS NULL OR (excludeScope NOT LIKE ? AND excludeScope NOT LIKE ?))
         ORDER BY `order` ASC''',
      ['%$name%', '%$origin%', '%$name%', '%$origin%']
    );
    return maps.map((m) => ReplaceRule.fromJson(m)).toList();
  }

  /// 搜尋規則 (對標 Android: flowSearch)
  Future<List<ReplaceRule>> search(String key) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '`group` LIKE ? OR name LIKE ?',
      whereArgs: ['%$key%', '%$key%'],
      orderBy: '`order` ASC',
    );
    return maps.map((m) => ReplaceRule.fromJson(m)).toList();
  }

  /// 獲取所有獨特的分組 (對標 Android: allGroups)
  Future<List<String>> getAllGroups() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['`group`'],
      where: '`group` IS NOT NULL AND `group` != ""',
    );
    final groups = <String>{};
    for (var m in maps) {
      final gStr = m['group'] as String;
      groups.addAll(gStr.split(RegExp(r'[,，\s]+')).where((s) => s.trim().isNotEmpty));
    }
    return groups.toList()..sort();
  }

  /// 插入或更新 (UPSERT)
  Future<void> upsert(ReplaceRule rule) async {
    await insertOrUpdate(rule.toJson());
  }

  /// 批量插入
  Future<void> upsertAll(List<ReplaceRule> rules) async {
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

  /// 批量啟用/禁用 (對標 Android: enableAll)
  Future<void> enableAll(bool enable) async {
    final client = await db;
    await client.update(tableName, {'isEnabled': enable ? 1 : 0});
  }

  /// 更新單個啟用狀態
  Future<void> updateEnabled(int id, bool enabled) async {
    final client = await db;
    await client.update(
      tableName,
      {'isEnabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 根據 ID 刪除
  Future<void> deleteById(int id) async {
    await delete('id = ?', [id]);
  }

  /// 更新排序
  Future<void> updateOrder(int id, int order) async {
    final client = await db;
    await client.update(
      tableName,
      {'`order`': order},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
