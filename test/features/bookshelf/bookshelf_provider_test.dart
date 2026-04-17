import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_group_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_group.dart';
import 'package:inkpage_reader/features/bookshelf/bookshelf_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake DAOs
// ---------------------------------------------------------------------------

class _FakeBookDao extends Fake implements BookDao {
  List<Book> shelf = [];

  @override
  Future<List<Book>> getAllInBookshelf() async => shelf;

  @override
  Future<List<Book>> getBooksInGroup(int groupId) async =>
      shelf.where((b) => (b.group & groupId) != 0).toList();

  @override
  Future<Book?> getByUrl(String url) async =>
      shelf.cast<Book?>().firstWhere((b) => b?.bookUrl == url, orElse: () => null);

  @override
  Future<void> upsert(Book book) async {
    shelf.removeWhere((b) => b.bookUrl == book.bookUrl);
    shelf.add(book);
  }

  @override
  Future<void> deleteByUrl(String url) async =>
      shelf.removeWhere((b) => b.bookUrl == url);
}

class _FakeGroupDao extends Fake implements BookGroupDao {
  List<BookGroup> groups = [];

  @override
  Future<List<BookGroup>> getAll() async => groups;

  @override
  Future<void> initDefaultGroups() async {}

  @override
  Future<void> upsert(BookGroup group) async {
    groups.removeWhere((g) => g.id == group.id);
    groups.add(group);
  }

  @override
  Future<void> deleteById(int id) async => groups.removeWhere((g) => g.id == id);

  @override
  Future<void> updateOrder(List<BookGroup> ordered) async {
    groups = ordered;
  }
}

class _FakeSourceDao extends Fake implements BookSourceDao {
  @override
  Future<List<BookSource>> getEnabled() async => [];
}

class _FakeChapterDao extends Fake implements ChapterDao {
  @override
  Future<void> deleteByBook(String bookUrl) async {}
}

// ---------------------------------------------------------------------------
// 測試
// ---------------------------------------------------------------------------

BookshelfProvider _makeProvider() => BookshelfProvider();

void main() {
  late _FakeBookDao fakeBookDao;
  late _FakeGroupDao fakeGroupDao;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeBookDao = _FakeBookDao();
    fakeGroupDao = _FakeGroupDao();

    final getIt = GetIt.instance;
    getIt.registerLazySingleton<BookDao>(() => fakeBookDao);
    getIt.registerLazySingleton<BookGroupDao>(() => fakeGroupDao);
    getIt.registerLazySingleton<BookSourceDao>(() => _FakeSourceDao());
    getIt.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
  });

  tearDown(() async => GetIt.instance.reset());

  group('BookshelfProvider - 分組選擇', () {
    test('初始 currentGroupId 為 -1（全部）', () {
      final p = _makeProvider();
      expect(p.currentGroupId, -1);
    });

    test('setGroup 更新 currentGroupId', () async {
      final p = _makeProvider();
      p.setGroup(2);
      expect(p.currentGroupId, 2);
    });

    test('createGroup 會分配下一個可用 bit mask', () async {
      fakeGroupDao.groups = [
        BookGroup(groupId: 1, groupName: 'A'),
        BookGroup(groupId: 2, groupName: 'B'),
      ];
      final p = _makeProvider();
      await Future.delayed(Duration.zero);
      await p.createGroup('C');
      expect(fakeGroupDao.groups.any((g) => g.groupId == 4), isTrue);
    });

    test('deleteGroup 會從書籍上移除對應 group mask', () async {
      fakeGroupDao.groups = [BookGroup(groupId: 2, groupName: 'B')];
      fakeBookDao.shelf = [
        Book(
          bookUrl: 'http://a.com',
          name: 'A',
          author: 'Au',
          origin: 'o',
          originName: 'on',
          group: 2,
          isInBookshelf: true,
        ),
      ];
      final p = _makeProvider();
      await Future.delayed(Duration.zero);
      await p.deleteGroup(2);
      expect(fakeBookDao.shelf.single.group, 0);
    });
  });

  group('BookshelfProvider - 批次模式', () {
    test('預設不在批次模式', () {
      final p = _makeProvider();
      expect(p.isBatchMode, isFalse);
    });

    test('toggleBatchMode 切換狀態', () {
      final p = _makeProvider();
      p.toggleBatchMode();
      expect(p.isBatchMode, isTrue);
      p.toggleBatchMode();
      expect(p.isBatchMode, isFalse);
    });

    test('toggleBatchMode(initialSelectedUrl) 帶入初始選取', () {
      final p = _makeProvider();
      p.toggleBatchMode(initialSelectedUrl: 'http://a.com');
      expect(p.selectedBookUrls, contains('http://a.com'));
    });

    test('toggleSelect 加入與移除', () {
      final p = _makeProvider();
      p.toggleBatchMode();
      p.toggleSelect('http://a.com');
      expect(p.selectedBookUrls, contains('http://a.com'));
      p.toggleSelect('http://a.com');
      expect(p.selectedBookUrls, isEmpty);
    });
  });

  group('BookshelfProvider - 書架書籍載入', () {
    test('loadBooks 從 DAO 取得書籍', () async {
      fakeBookDao.shelf = [
        Book(bookUrl: 'http://a.com', name: 'A', author: 'Au', origin: 'o', originName: 'on'),
      ];
      final p = _makeProvider();
      await Future.delayed(Duration.zero); // 等 constructor async 完成
      expect(p.books, hasLength(1));
    });

    test('removeFromBookshelf 刪除書籍並重新載入', () async {
      fakeBookDao.shelf = [
        Book(bookUrl: 'http://a.com', name: 'A', author: 'Au', origin: 'o', originName: 'on'),
      ];
      final p = _makeProvider();
      await Future.delayed(Duration.zero);
      await p.removeFromBookshelf('http://a.com');
      expect(p.books, isEmpty);
    });
  });

  group('BookshelfProvider - selectAll', () {
    test('selectAll 選取所有書籍，再次呼叫則清空', () async {
      fakeBookDao.shelf = [
        Book(bookUrl: 'http://a.com', name: 'A', author: 'Au', origin: 'o', originName: 'on'),
        Book(bookUrl: 'http://b.com', name: 'B', author: 'Au', origin: 'o', originName: 'on'),
      ];
      final p = _makeProvider();
      await Future.delayed(Duration.zero);
      p.toggleBatchMode();
      p.selectAll();
      expect(p.selectedBookUrls, hasLength(2));
      p.selectAll();
      expect(p.selectedBookUrls, isEmpty);
    });
  });
}
