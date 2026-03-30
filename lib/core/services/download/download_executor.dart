import 'dart:async';
import 'download_base.dart';
import 'download_scheduler.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/download_task.dart';
import 'package:legado_reader/core/engine/app_event_bus.dart';
import 'package:legado_reader/core/services/app_log_service.dart';

/// DownloadService 的任務執行邏輯擴展
mixin DownloadExecutor on DownloadBase, DownloadScheduler {
  Future<void> processTask(DownloadTask task) async {
    task.status = 1;
    await downloadDao.updateProgress(task.bookUrl, status: 1);
    update();

    try {
      final book = await bookDao.getByUrl(task.bookUrl);
      if (book == null) {
        throw Exception('書籍不存在');
      }
      final source = await sourceDao.getByUrl(book.origin);
      if (source == null) {
        throw Exception('書源不存在');
      }
      
      var chapters = await chapterDao.getChapters(task.bookUrl);
      if (chapters.isEmpty) {
        chapters = await sourceService.getChapterList(source, book);
        await chapterDao.insertChapters(chapters);
        // 更新任務實例
        final newTask = task.copyWith(
          totalCount: chapters.length,
          endChapterIndex: chapters.isNotEmpty ? chapters.last.index : 0,
        );
        final idx = tasks.indexOf(task);
        if (idx != -1) {
          tasks[idx] = newTask;
        }
        task = newTask;
      }

      final toDownload = chapters.where((c) => c.index >= task.startChapterIndex && c.index <= task.endChapterIndex).toList();
      var poolCount = 0;
      for (var chapter in toDownload) {
        if (!isDownloading || task.status == 2) {
          break;
        }
        await checkPause();
        
        if (await chapterDao.hasContent(chapter.url)) {
          task.successCount++;
          continue;
        }

        while (poolCount >= maxChapterConcurrent) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        poolCount++;
        _downloadChapter(book, source, task, chapter).then((success) {
          if (success) {
            task.successCount++;
          } else {
            task.errorCount++;
          }
          poolCount--;
          task.currentChapterIndex = chapter.index;
          downloadDao.updateProgress(task.bookUrl, currentChapterIndex: chapter.index, successCount: task.successCount, errorCount: task.errorCount);
          update();
        });
      }

      while (poolCount > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }

      if (task.status != 2) {
        task.status = 3;
        await downloadDao.updateProgress(task.bookUrl, status: 3);
        AppEventBus().fire(AppEventBus.upBookshelf, data: task.bookUrl);
      }
    } catch (e, stack) {
      AppLog.e('Download task failed for ${task.bookName}: $e', error: e, stackTrace: stack);
      if (task.status != 2) {
        task.status = 4;
        await downloadDao.updateProgress(task.bookUrl, status: 4);
      }
    }
    update();
  }

  static const int _maxRetries = 3;

  Future<bool> _downloadChapter(Book book, dynamic source, DownloadTask task, BookChapter chapter) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final content = await sourceService.getContent(source, book, chapter);
        if (content.isNotEmpty) {
          await chapterDao.saveContent(chapter.url, content);
          return true;
        }
        return false;
      } catch (e, stack) {
        AppLog.w('Chapter download failed (attempt ${attempt + 1}/$_maxRetries) '
            '- book: ${task.bookName}, chapter: ${chapter.title}: $e');
        if (attempt < _maxRetries - 1) {
          final delay = Duration(milliseconds: 500 * (1 << attempt));
          await Future.delayed(delay);
        } else {
          AppLog.e('Chapter download exhausted retries '
              '- book: ${task.bookName}, chapter: ${chapter.title}',
              error: e, stackTrace: stack);
        }
      }
    }
    return false;
  }
}

