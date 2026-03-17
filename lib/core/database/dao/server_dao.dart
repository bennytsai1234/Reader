import 'dart:async';
import 'package:legado_reader/core/models/server.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// ServerDao - 伺服器資料存取對象 (對標 Android ServerDao.kt)
class ServerDao extends DriftCompatDao<Server> {
  ServerDao(AppDatabase appDatabase) : super(appDatabase, 'servers');

  /// 獲取所有伺服器 (對標 Android: all)
  Future<List<Server>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'sortNumber ASC',
    );
    return maps.map((m) => Server.fromJson(m)).toList();
  }

  /// 根據 ID 獲取 (對標 Android: get)
  Future<Server?> getById(int id) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Server.fromJson(maps.first);
  }

  /// 插入或更新伺服器 (UPSERT)
  Future<void> upsert(Server server) async {
    await insertOrUpdate(server.toJson());
  }

  /// 插入別名，兼容舊代碼
  Future<void> insert(Server server) => upsert(server);

  /// 根據 ID 刪除
  Future<void> deleteById(int id) async {
    await deleteRows('id = ?', [id]);
  }

  /// 刪除預設伺服器
  Future<void> deleteDefault() async {
    await deleteRows('id < 0');
  }
}
