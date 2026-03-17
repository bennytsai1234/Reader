import 'dart:async';
import 'package:legado_reader/core/models/http_tts.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// HttpTtsDao - SQLite 實作 (對標 Android HttpTTSDao.kt)
class HttpTtsDao extends DriftCompatDao<HttpTTS> {
  HttpTtsDao(AppDatabase appDatabase) : super(appDatabase, 'http_tts');

  /// 獲取所有 TTS 規則 (對標 Android: all)
  Future<List<HttpTTS>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'name ASC',
    );
    return maps.map((m) => HttpTTS.fromJson(m)).toList();
  }

  /// 獲取總數
  Future<int> getCount() async {
    final client = await db;
    return driftFirstIntValue(await client.rawQuery('SELECT COUNT(*) FROM $tableName')) ?? 0;
  }

  /// 根據 ID 獲取
  Future<HttpTTS?> getById(int id) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HttpTTS.fromJson(maps.first);
  }

  /// 獲取規則名稱
  Future<String?> getName(int id) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['name'] as String?;
  }

  /// 插入或更新單個規則 (UPSERT)
  Future<void> upsert(HttpTTS tts) async {
    await insertOrUpdate(tts.toJson());
  }

  /// 插入或更新別名，兼容舊代碼
  Future<void> insertOrUpdateTTS(HttpTTS tts) => upsert(tts);

  /// 批量插入或更新
  Future<void> insertOrUpdateAll(List<HttpTTS> ttsList) async {
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var tts in ttsList) {
        batch.insert(
          tableName,
          tts.toJson(),
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

  /// 刪除預設規則
  Future<void> deleteDefault() async {
    await deleteRows('id < 0');
  }
}
