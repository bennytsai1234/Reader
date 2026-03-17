import 'package:legado_reader/core/models/read_record.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// ReadRecordDao - SQLite 實作 (對標 Android ReadRecordDao.kt)
class ReadRecordDao extends DriftCompatDao<ReadRecord> {
  ReadRecordDao(AppDatabase appDatabase) : super(appDatabase, 'read_records');

  /// 獲取所有閱讀記錄 (對標 Android: allTime)
  Future<List<ReadRecord>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'readTime DESC',
    );
    return maps.map((m) => ReadRecord.fromJson(m)).toList();
  }

  /// getAll 的別名
  Future<List<ReadRecord>> getAllTime() => getAll();

  /// 獲取顯示用的紀錄 (對標 Android: allShow)
  Future<List<ReadRecord>> getAllShow() => getAll();

  /// 根據書名獲取紀錄 (對標 Android: getReadRecord)
  Future<ReadRecord?> getByBookName(String bookName) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookName = ?',
      whereArgs: [bookName],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ReadRecord.fromJson(maps.first);
  }

  /// 搜尋紀錄 (對標 Android: search)
  Future<List<ReadRecord>> search(String key) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookName LIKE ?',
      whereArgs: ['%$key%'],
      orderBy: 'readTime DESC',
    );
    return maps.map((m) => ReadRecord.fromJson(m)).toList();
  }

  /// 插入或更新單個紀錄 (UPSERT)
  Future<void> upsert(ReadRecord record) async {
    await insertOrUpdate(record.toJson());
  }

  /// 插入別名，兼容舊代碼
  Future<void> insert(ReadRecord record) => upsert(record);

  /// 批量更新
  Future<void> insertAll(List<ReadRecord> records) async {
    if (records.isEmpty) return;
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var record in records) {
        batch.insert(
          tableName,
          record.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 根據名稱刪除 (對標 Android: deleteByName)
  Future<void> deleteByName(String bookName) async {
    await deleteRows('bookName = ?', [bookName]);
  }

  /// 清空別名
  Future<int> clearAll() => super.clearAll();
}
