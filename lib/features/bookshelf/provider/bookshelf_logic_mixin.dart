import 'package:shared_preferences/shared_preferences.dart';
import 'bookshelf_provider_base.dart';
import 'package:legado_reader/core/models/book_group.dart';
import 'package:legado_reader/core/models/book.dart';

/// BookshelfProvider 的 UI 狀態與分組邏輯擴展
mixin BookshelfLogicMixin on BookshelfProviderBase {
  void toggleViewMode() {
    isGridView = !isGridView;
    SharedPreferences.getInstance().then((p) => p.setBool('bookshelf_is_grid', isGridView));
    notifyListeners();
  }

  void toggleShowLastUpdate() {
    showLastUpdate = !showLastUpdate;
    SharedPreferences.getInstance().then((p) => p.setBool('bookshelf_show_last_update', showLastUpdate));
    notifyListeners();
  }

  void toggleBatchMode({String? initialSelectedUrl}) {
    isBatchMode = !isBatchMode;
    selectedBookUrls.clear();
    if (isBatchMode && initialSelectedUrl != null) selectedBookUrls.add(initialSelectedUrl);
    notifyListeners();
  }

  void toggleSelect(String url) {
    selectedBookUrls.contains(url) ? selectedBookUrls.remove(url) : selectedBookUrls.add(url);
    notifyListeners();
  }

  void selectAll() {
    selectedBookUrls.length == books.length ? selectedBookUrls.clear() : selectedBookUrls.addAll(books.map((b) => b.bookUrl));
    notifyListeners();
  }

  Future<void> loadGroups() async {
    groups = await groupDao.getAll();
    if (groups.isEmpty) {
      await groupDao.initDefaultGroups();
      groups = await groupDao.getAll();
    }
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    for (var url in selectedBookUrls) {
      await bookDao.deleteByUrl(url);
      await chapterDao.deleteByBook(url);
    }
    isBatchMode = false; selectedBookUrls.clear();
    (this as dynamic).loadBooks();
  }

  Future<void> moveSelectedToGroup(int groupId) async {
    for (var url in selectedBookUrls) {
      final book = books.cast<Book?>().firstWhere((b) => b?.bookUrl == url, orElse: () => null);
      if (book != null) {
        book.group = groupId;
        await bookDao.upsert(book);
      }
    }
    isBatchMode = false; selectedBookUrls.clear();
    (this as dynamic).loadBooks();
  }

  Future<void> batchUpdateGroup(Set<String> urls, int groupId) async {
    for (var url in urls) {
      final book = await bookDao.getByUrl(url);
      if (book != null) {
        book.group = groupId;
        await bookDao.upsert(book);
      }
    }
    isBatchMode = false; selectedBookUrls.clear();
    (this as dynamic).loadBooks();
  }

  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    final item = groups.removeAt(oldIndex);
    groups.insert(newIndex, item);
    await groupDao.updateOrder(groups);
    notifyListeners();
  }

  Future<void> updateGroupVisibility(int groupId, bool visible) async {
    final group = groups.cast<BookGroup?>().firstWhere((g) => g?.id == groupId, orElse: () => null);
    if (group != null) { group.show = visible; await groupDao.upsert(group); notifyListeners(); }
  }

  Future<void> createGroup(String name) async {
    await groupDao.upsert(BookGroup(groupId: 0, groupName: name, order: groups.length));
    await loadGroups();
  }

  Future<void> renameGroup(int id, String name) async {
    final group = groups.cast<BookGroup?>().firstWhere((g) => g?.id == id, orElse: () => null);
    if (group != null) { group.name = name; await groupDao.upsert(group); notifyListeners(); }
  }

  Future<void> deleteGroup(int id) async {
    await groupDao.deleteById(id);
    await loadGroups();
  }
}

