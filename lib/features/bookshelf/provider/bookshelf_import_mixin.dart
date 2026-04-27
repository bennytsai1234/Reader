import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/services/book_cover_storage_service.dart';
import 'package:inkpage_reader/core/services/local_book_service.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'bookshelf_provider_base.dart';

/// BookshelfProvider 的本地書籍匯入邏輯擴展
mixin BookshelfImportMixin on BookshelfProviderBase {
  Future<bool> importLocalBookPath(String path) async {
    final bookUrl = 'local://$path';
    final existingBook = await bookDao.getByUrl(bookUrl);
    if (existingBook != null && existingBook.isInBookshelf) return true;

    isLoading = true;
    notifyListeners();

    try {
      final result = await LocalBookService().importBook(path);
      if (result != null) {
        result.book.syncTime =
            result.book.syncTime == 0
                ? DateTime.now().millisecondsSinceEpoch
                : result.book.syncTime;
        await BookCoverStorageService().ensureBookCoverStored(result.book);
        await bookDao.upsert(result.book);
        await chapterDao.insertChapters(result.chapters);
        await loadBooks();
        return true;
      }
      return false;
    } catch (e) {
      AppLog.e('匯入本地書籍失敗: $e', error: e);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Book> importBookFromUrl(String url) async {
    final normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) {
      throw ArgumentError('網址不能為空');
    }

    isLoading = true;
    notifyListeners();
    try {
      final sources =
          (await sourceDao.getEnabled())
              .where((source) => source.isReadingEnabledByRuntime)
              .toList();
      final orderedSources = _prioritizeSourcesForUrl(sources, normalizedUrl);
      Object? lastError;

      for (final source in orderedSources) {
        try {
          final seed = Book(
            bookUrl: normalizedUrl,
            tocUrl: normalizedUrl,
            origin: source.bookSourceUrl,
            originName: source.bookSourceName,
            name: normalizedUrl,
            isInBookshelf: true,
            syncTime: DateTime.now().millisecondsSinceEpoch,
          );
          final hydrated = await service.getBookInfo(source, seed);
          hydrated.isInBookshelf = true;
          hydrated.origin = source.bookSourceUrl;
          hydrated.originName = source.bookSourceName;
          if (hydrated.syncTime == 0) {
            hydrated.syncTime = DateTime.now().millisecondsSinceEpoch;
          }
          final chapters = await service.getChapterList(source, hydrated);
          if (hydrated.bookUrl.isEmpty || hydrated.name.trim().isEmpty) {
            throw StateError('解析結果缺少書籍資訊');
          }
          if (chapters.isEmpty) {
            throw StateError('解析結果沒有章節');
          }
          for (var i = 0; i < chapters.length; i++) {
            chapters[i].index = i;
            chapters[i].bookUrl = hydrated.bookUrl;
          }
          hydrated.totalChapterNum = chapters.length;
          hydrated.latestChapterTitle = chapters.last.title;
          await BookCoverStorageService().ensureBookCoverStored(hydrated);
          await bookDao.upsert(hydrated);
          await chapterDao.insertChapters(chapters);
          await loadBooks();
          return hydrated;
        } catch (e) {
          lastError = e;
          AppLog.w('添加網址書籍失敗，來源 ${source.bookSourceName}: $e');
        }
      }

      throw StateError(
        lastError == null ? '沒有可用書源可以解析此網址' : '解析網址失敗: $lastError',
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<BookSource> _prioritizeSourcesForUrl(
    List<BookSource> sources,
    String url,
  ) {
    final matched = <BookSource>[];
    final others = <BookSource>[];
    for (final source in sources) {
      final pattern = source.bookUrlPattern?.trim();
      if (pattern == null || pattern.isEmpty) {
        others.add(source);
        continue;
      }
      try {
        if (RegExp(pattern).hasMatch(url)) {
          matched.add(source);
        } else {
          others.add(source);
        }
      } catch (_) {
        others.add(source);
      }
    }
    return [...matched, ...others];
  }
}
