import 'package:legado_reader/core/models/download_task.dart';
import 'download/download_base.dart';
import 'download/download_scheduler.dart';
import 'download/download_executor.dart';

export 'download/download_base.dart';
export 'download/download_scheduler.dart';
export 'download/download_executor.dart';

/// DownloadService - 書籍離線快取服務 (重構後)
/// (原 Android service/CacheBookService.kt)
class DownloadService extends DownloadBase with DownloadScheduler, DownloadExecutor {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  double get progress => totalProgress;

  DownloadService._internal() {
    _loadTasks();
    listenEvents();
  }

  /// 從資料庫恢復任務
  Future<void> _loadTasks() async {
    final unfinished = await downloadDao.getUnfinishedTasks();
    tasks.clear();
    tasks.addAll(unfinished);
    update();
    if (tasks.isNotEmpty && !isDownloading) {
      startDownloads();
    }
  }

  void pauseTask(String bookUrl) {
    final task = tasks.cast<DownloadTask?>().firstWhere((t) => t?.bookUrl == bookUrl, orElse: () => null);
    if (task != null) {
      task.status = 2;
      downloadDao.updateProgress(bookUrl, status: 2);
      update();
    }
  }

  void removeTask(String bookUrl) {
    tasks.removeWhere((t) => t.bookUrl == bookUrl);
    downloadDao.deleteByUrl(bookUrl);
    update();
  }

  void cancelDownloads() {
    isDownloading = false;
    for (var task in tasks) {
      if (task.status == 0 || task.status == 1) {
        task.status = 2;
        downloadDao.updateProgress(task.bookUrl, status: 2);
      }
    }
    update();
  }
}

