import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/services/bookshelf_exchange_service.dart';
import 'package:inkpage_reader/core/services/event_bus.dart';
import 'bookshelf_provider_base.dart';

/// BookshelfProvider 的更新與網絡同步邏輯擴展
mixin BookshelfUpdateMixin on BookshelfProviderBase {
  Future<void> refreshBookshelf() async {
    final onlineBooks = books.where((b) => !b.isLocal).toList();
    if (onlineBooks.isEmpty) return;

    AppEventBus().fire(AppEvent('bookshelfRefreshStart'));
    var completed = 0;
    final updateTasks = <Future<void>>[];

    for (var book in onlineBooks) {
      updateTasks.add(Future(() async {
        try {
          final source = await sourceDao.getByUrl(book.origin);
          if (source != null) {
            final info = await service.getBookInfo(source, book);
            final chapters = await service.getChapterList(source, info);
            if (chapters.length > book.totalChapterNum) {
              info.lastCheckCount = chapters.length - book.totalChapterNum;
              info.latestChapterTitle = chapters.last.title;
              info.latestChapterTime = DateTime.now().millisecondsSinceEpoch;
            }
            await bookDao.upsert(info);
            await chapterDao.insertChapters(chapters);
          }
        } catch (_) {}
        completed++;
        updatingCount = onlineBooks.length - completed;
        notifyListeners();
      }));
    }

    await Future.wait(updateTasks);
    updatingCount = 0;
    loadBooks();
    AppEventBus().fire(AppEvent('bookshelfRefreshEnd'));
  }

  Future<void> importBookshelfFromUrl(String url) async {
    isLoading = true; notifyListeners();
    try {
      await BookshelfExchangeService().importFromUrl(url);
      await loadBooks();
    } finally { isLoading = false; notifyListeners(); }
  }
}
