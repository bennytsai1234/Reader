import 'dart:async';
import 'download_base.dart';
import 'download_scheduler.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/download_task.dart';
import 'package:inkpage_reader/core/engine/app_event_bus.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/services/chapter_content_preparation_pipeline.dart';
import 'package:inkpage_reader/core/services/reader_chapter_content_store.dart';

bool downloadTaskCountsPreStoredChapters({
  required DownloadTask task,
  required int chapterCountInRange,
}) {
  return task.totalCount >= chapterCountInRange;
}

/// DownloadService 的任務執行邏輯擴展
mixin DownloadExecutor on DownloadBase, DownloadScheduler {
  @override
  Future<void> processTask(DownloadTask task) async {
    task.status = 1;
    await downloadDao.updateProgress(task.bookUrl, status: 1);
    update();

    try {
      final book = await bookDao.getByUrl(task.bookUrl);
      if (book == null) {
        throw Exception('書籍不存在');
      }
      final source =
          book.origin == 'local' ? null : await sourceDao.getByUrl(book.origin);
      if (book.origin != 'local' && source == null) {
        throw Exception('書源不存在');
      }

      var chapters = await chapterDao.getChapters(task.bookUrl);
      if (chapters.isEmpty) {
        if (source == null) {
          throw Exception('章節目錄不存在');
        }
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

      final toDownload =
          chapters
              .where(
                (c) =>
                    c.index >= task.startChapterIndex &&
                    c.index <= task.endChapterIndex,
              )
              .toList();
      final countsPreStoredChapters = downloadTaskCountsPreStoredChapters(
        task: task,
        chapterCountInRange: toDownload.length,
      );
      final contentStore = ReaderChapterContentStore(
        chapterDao: chapterDao,
        contentDao: chapterContentDao,
      );
      final pipeline = ChapterContentPreparationPipeline(
        book: book,
        contentStore: contentStore,
        sourceDao: sourceDao,
        service: sourceService,
        getSource: () => source,
      );
      var poolCount = 0;
      for (var chapter in toDownload) {
        if (!isDownloading || task.status == 2) {
          break;
        }
        await checkPause();

        if (await contentStore.hasReadyContent(book: book, chapter: chapter)) {
          if (countsPreStoredChapters) {
            task.successCount++;
          }
          task.currentChapterIndex = chapter.index;
          await downloadDao.updateProgress(
            task.bookUrl,
            currentChapterIndex: chapter.index,
            successCount: task.successCount,
            errorCount: task.errorCount,
          );
          update();
          continue;
        }

        while (poolCount >= maxChapterConcurrent) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        poolCount++;
        _downloadChapter(
          pipeline: pipeline,
          source: source,
          chapter: chapter,
        ).then((success) {
          if (success) {
            task.successCount++;
          } else {
            task.errorCount++;
          }
          poolCount--;
          task.currentChapterIndex = chapter.index;
          downloadDao.updateProgress(
            task.bookUrl,
            currentChapterIndex: chapter.index,
            successCount: task.successCount,
            errorCount: task.errorCount,
          );
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
      AppLog.e(
        'Download task failed for ${task.bookName}: $e',
        error: e,
        stackTrace: stack,
      );
      if (task.status != 2) {
        task.status = 4;
        await downloadDao.updateProgress(task.bookUrl, status: 4);
      }
    }
    update();
  }

  static const int _maxRetries = 3;

  Future<bool> _downloadChapter({
    required ChapterContentPreparationPipeline pipeline,
    required BookSource? source,
    required BookChapter chapter,
  }) async {
    final result = await pipeline.prepare(
      chapterIndex: chapter.index,
      chapter: chapter,
      sourceOverride: source,
      forceRefresh: true,
      maxAttempts: _maxRetries,
    );
    return result.isReady;
  }
}
