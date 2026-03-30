import 'dart:async';
import 'download_base.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/download_task.dart';
import 'package:legado_reader/core/engine/app_event_bus.dart';

/// DownloadService 的調度與任務管理邏輯擴展
mixin DownloadScheduler on DownloadBase {
  StreamSubscription? _refreshStartSub;
  StreamSubscription? _refreshEndSub;

  void listenEvents() {
    _refreshStartSub?.cancel();
    _refreshEndSub?.cancel();
    _refreshStartSub = AppEventBus().onName(AppEventBus.bookshelfRefreshStart).listen((_) {
      isBookshelfRefreshing = true;
      update();
    });
    _refreshEndSub = AppEventBus().onName(AppEventBus.bookshelfRefreshEnd).listen((_) {
      isBookshelfRefreshing = false;
      update();
    });
  }

  void disposeScheduler() {
    _refreshStartSub?.cancel();
    _refreshEndSub?.cancel();
    _refreshStartSub = null;
    _refreshEndSub = null;
  }

  Future<void> checkPriority() async {
    while (isBookshelfRefreshing) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> checkPause() async {
    await checkPriority();
    if (isPaused) {
      pauseCompleter ??= Completer<void>();
      await pauseCompleter!.future;
    }
  }

  void togglePause() {
    isPaused = !isPaused;
    if (!isPaused) {
      pauseCompleter?.complete();
      pauseCompleter = null;
    } else {
      pauseCompleter = Completer<void>();
    }
    update();
  }

  Future<void> addDownloadTask(Book book, List<BookChapter> chapters) async {
    if (chapters.isEmpty) {
      return;
    }
    final task = DownloadTask(
      bookUrl: book.bookUrl,
      bookName: book.name,
      startChapterIndex: chapters.first.index,
      endChapterIndex: chapters.last.index,
      totalCount: chapters.length,
      status: 0,
      lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
    );
    await downloadDao.upsert(task);
    final existingIndex = tasks.indexWhere((t) => t.bookUrl == book.bookUrl);
    if (existingIndex != -1) {
      tasks[existingIndex] = task;
    } else {
      tasks.add(task);
    }
    update();
    if (!isDownloading) {
      (this as dynamic).startDownloads();
    }
  }

  Future<void> startDownloads() async {
    if (isScheduling || isDownloading) {
      return;
    }
    isScheduling = true;
    try {
      isDownloading = true;
      update();
      while (tasks.any((t) => t.status == 0 || t.status == 1)) {
        final activeTasks = tasks.where((t) => t.status == 1).toList();
        if (activeTasks.length < maxConcurrent) {
          final nextTask = tasks.cast<DownloadTask?>().firstWhere((t) => t?.status == 0, orElse: () => null);
          if (nextTask != null) {
            (this as dynamic).processTask(nextTask);
          } else if (activeTasks.isEmpty) {
            break;
          }
        }
        await Future.delayed(const Duration(seconds: 1));
      }
      isDownloading = false;
      update();
    } finally {
      isScheduling = false;
    }
  }
}

