import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/replace_rule.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/runtime/read_book_controller.dart';

// ── Fake DAOs ────────────────────────────────────────────────────────────────

class _FakeBookDao implements BookDao {
  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos,
  ) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChapterDao implements ChapterDao {
  @override
  Future<List<BookChapter>> getChapters(String bookUrl) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeReplaceRuleDao implements ReplaceRuleDao {
  @override
  Future<List<ReplaceRule>> getEnabled() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookSourceDao implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookmarkDao implements BookmarkDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void _setupDi() {
  for (final unregister in [
    () {
      if (getIt.isRegistered<BookDao>()) getIt.unregister<BookDao>();
    },
    () {
      if (getIt.isRegistered<ChapterDao>()) getIt.unregister<ChapterDao>();
    },
    () {
      if (getIt.isRegistered<ReplaceRuleDao>()) {
        getIt.unregister<ReplaceRuleDao>();
      }
    },
    () {
      if (getIt.isRegistered<BookSourceDao>()) {
        getIt.unregister<BookSourceDao>();
      }
    },
    () {
      if (getIt.isRegistered<BookmarkDao>()) getIt.unregister<BookmarkDao>();
    },
  ]) {
    unregister();
  }
  getIt.registerLazySingleton<BookDao>(() => _FakeBookDao());
  getIt.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
  getIt.registerLazySingleton<ReplaceRuleDao>(() => _FakeReplaceRuleDao());
  getIt.registerLazySingleton<BookSourceDao>(() => _FakeBookSourceDao());
  getIt.registerLazySingleton<BookmarkDao>(() => _FakeBookmarkDao());
}

Book _makeBook() => Book(
      bookUrl: 'http://test.com/book',
      name: 'Test Book',
      author: 'Author',
      origin: 'local',
      durChapterIndex: 0,
      durChapterPos: 0,
    );

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _setupDi();
  });

  setUp(() {
    // Mock flutter_tts / audio_service platform channels
    // so TTS calls don't crash in tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_service.methods'),
      (call) async => null,
    );
  });

  group('ReadBookController lifecycle', () {
    test('可以建立並立即 dispose，不會拋例外', () {
      final controller = ReadBookController(book: _makeBook());
      expect(() => controller.dispose(), returnsNormally);
    });

    test('dispose 後 isDisposed 為 true', () {
      final controller = ReadBookController(book: _makeBook());
      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    test('dispose 後 lifecycle 為 disposed', () {
      final controller = ReadBookController(book: _makeBook());
      controller.dispose();
      expect(controller.lifecycle, equals(ReaderLifecycle.disposed));
    });

    test('dispose 後呼叫 notifyListeners 不會拋例外', () {
      final controller = ReadBookController(book: _makeBook());
      controller.dispose();
      // ReaderProviderBase.notifyListeners() 有 isDisposed 保護
      expect(() => controller.notifyListeners(), returnsNormally);
    });

    test('初始狀態：lifecycle 為 loading', () {
      final controller = ReadBookController(book: _makeBook());
      expect(controller.lifecycle, equals(ReaderLifecycle.loading));
      controller.dispose();
    });

    test('初始狀態：isReady 為 false', () {
      final controller = ReadBookController(book: _makeBook());
      expect(controller.isReady, isFalse);
      controller.dispose();
    });

    test('dispose 後 isLoading 中的章節集合仍可安全讀取', () {
      final controller = ReadBookController(book: _makeBook());
      controller.dispose();
      expect(() => controller.loadingChapters.isEmpty, returnsNormally);
    });
  });
}
