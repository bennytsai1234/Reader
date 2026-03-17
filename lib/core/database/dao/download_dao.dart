import 'package:legado_reader/core/models/download_task.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// DownloadDao - 下載任務資料存取對象 (對標 Android DownloadDao.kt)
class DownloadDao extends DriftCompatDao<DownloadTask> {
  DownloadDao(AppDatabase appDatabase) : super(appDatabase, 'download_tasks');

  /// 獲取所有未完成的任務
  Future<List<DownloadTask>> getUnfinishedTasks() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'status != 3', // 假設 3 代表完成
      orderBy: 'addTime ASC',
    );
    return maps.map((m) => DownloadTask.fromJson(m)).toList();
  }

  /// 插入或更新任務 (UPSERT)
  Future<void> upsert(DownloadTask task) async {
    await insertOrUpdate(task.toJson());
  }

  /// 插入別名，兼容舊代碼
  Future<void> insertOrUpdateTask(DownloadTask task) => upsert(task);

  /// 更新任務進度
  Future<void> updateProgress(String bookUrl, {
    int? currentChapterIndex,
    int? status,
    int? successCount,
    int? errorCount,
  }) async {
    final client = await db;
    final Map<String, dynamic> updates = {};
    if (currentChapterIndex != null) updates['currentChapterIndex'] = currentChapterIndex;
    if (status != null) updates['status'] = status;
    if (successCount != null) updates['successCount'] = successCount;
    if (errorCount != null) updates['errorCount'] = errorCount;
    
    if (updates.isNotEmpty) {
      await client.update(
        tableName,
        updates,
        where: 'bookUrl = ?',
        whereArgs: [bookUrl],
      );
    }
  }

  /// 根據 URL 刪除任務
  Future<void> deleteByUrl(String bookUrl) async {
    await deleteRows('bookUrl = ?', [bookUrl]);
  }

  /// 清空已完成任務
  Future<void> clearFinished() async {
    await deleteRows('status = 3'); // 假設 3 代表完成
  }
}
