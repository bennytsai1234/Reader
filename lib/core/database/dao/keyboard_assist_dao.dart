import 'dart:async';
import 'package:legado_reader/core/models/keyboard_assist.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// KeyboardAssistDao - 鍵盤輔助操作 (對標 Android KeyboardAssistsDao.kt)
class KeyboardAssistDao extends DriftCompatDao<KeyboardAssist> {
  KeyboardAssistDao(AppDatabase appDatabase) : super(appDatabase, 'keyboard_assists');

  /// 獲取所有鍵盤輔助 (對標 Android: all)
  Future<List<KeyboardAssist>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'serialNo ASC',
    );
    return maps.map((m) => KeyboardAssist.fromJson(m)).toList();
  }

  /// 根據類型獲取 (對標 Android: getByType)
  Future<List<KeyboardAssist>> getByType(int type) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'serialNo ASC',
    );
    return maps.map((m) => KeyboardAssist.fromJson(m)).toList();
  }

  /// 獲取最大序號
  Future<int> getMaxSerialNo() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['serialNo'],
      orderBy: 'serialNo DESC',
      limit: 1,
    );
    if (maps.isEmpty) return 0;
    return maps.first['serialNo'] as int;
  }

  /// 插入或更新單個輔助 (UPSERT)
  Future<void> upsert(KeyboardAssist assist) async {
    await insertOrUpdate(assist.toJson());
  }

  /// 刪除指定輔助
  Future<void> deleteAssist(KeyboardAssist assist) async {
    await deleteRows('`key` = ?', [assist.key]);
  }
}
