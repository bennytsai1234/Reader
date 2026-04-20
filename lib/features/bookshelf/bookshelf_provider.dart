import 'dart:async';

import 'package:inkpage_reader/core/engine/app_event_bus.dart';

import 'provider/bookshelf_provider_base.dart';
import 'provider/bookshelf_logic_mixin.dart';
import 'provider/bookshelf_update_mixin.dart';
import 'provider/bookshelf_import_mixin.dart';

class BookshelfProvider extends BookshelfProviderBase
    with BookshelfLogicMixin, BookshelfUpdateMixin, BookshelfImportMixin {
  StreamSubscription<AppEvent>? _bookshelfSub;

  BookshelfProvider() {
    loadUiPreferences();
    loadBooks();
    loadGroups();
    _bookshelfSub = AppEventBus()
        .onName(AppEventBus.upBookshelf)
        .listen((_) => unawaited(loadBooks()));
  }

  @override
  Future<void> loadBooks() async {
    isLoading = true;
    notifyListeners();
    try {
      if (currentGroupId == -1) {
        books = await bookDao.getAllInBookshelf();
      } else if (currentGroupId == 0) {
        books = await bookDao.getBooksInGroup(0);
      } else {
        // Bitwise logic usually, but here we'll follow simple match for now
        final all = await bookDao.getAllInBookshelf();
        books = all.where((b) => (b.group & currentGroupId) != 0).toList();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<int, int> get groupCounts {
    final counts = <int, int>{};
    // 這裡需要計算各分組書籍數量，先做一個基礎實作
    counts[-1] = books.length;
    return counts;
  }

  Future<void> removeFromBookshelf(String url) async {
    await bookDao.deleteByUrl(url);
    await loadBooks();
  }

  void setGroup(int groupId) {
    currentGroupId = groupId;
    loadBooks();
  }

  @override
  void dispose() {
    _bookshelfSub?.cancel();
    super.dispose();
  }
}
