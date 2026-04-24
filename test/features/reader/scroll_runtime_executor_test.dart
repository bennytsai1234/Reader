import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/view/scroll_execution_adapter.dart';
import 'package:inkpage_reader/features/reader/view/scroll_restore_runner.dart';
import 'package:inkpage_reader/features/reader/view/scroll_runtime_executor.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBookDao implements BookDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChapterDao implements ChapterDao {
  @override
  Future<List<BookChapter>> getChapters(String bookUrl) async =>
      <BookChapter>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeReplaceRuleDao implements ReplaceRuleDao {
  @override
  Future<List<ReplaceRule>> getEnabled() async => <ReplaceRule>[];

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

class _RecordingReaderProvider extends ReaderProvider {
  _RecordingReaderProvider()
    : super(
        book: Book(
          bookUrl: 'http://test.com/book',
          name: 'Test Book',
          author: 'Author',
          origin: 'local',
          durChapterIndex: 0,
          durChapterPos: 12,
        ),
      );

  int? abortedNavigationToken;
  ReaderCommandReason? abortedNavigationReason;
  int? deferredRestoreToken;

  @override
  bool matchesPendingScrollRestore(int token) => token == 99;

  @override
  void abortNavigation(int token, ReaderCommandReason reason) {
    abortedNavigationToken = token;
    abortedNavigationReason = reason;
  }

  @override
  void deferPendingScrollRestore(int token) {
    deferredRestoreToken = token;
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _setupDi();
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

  test(
    'restore exhaustion aborts restore navigation instead of deferring restore',
    () {
      final provider = _RecordingReaderProvider();
      final executor = ScrollRuntimeExecutor(
        provider: provider,
        itemScrollController: ItemScrollController(),
        pageKeys: const {},
        scrollExecution: const ScrollExecutionAdapter(pageKeys: {}),
        scrollRestoreRunner: const ScrollRestoreRunner(),
        isMounted: () => true,
        viewportHeight: () => 600,
      );

      executor.restoreScrollPosition(
        chapterIndex: 0,
        localOffset: 120,
        token: 99,
        navigationToken: 42,
        retries: 0,
      );

      expect(provider.abortedNavigationToken, 42);
      expect(provider.abortedNavigationReason, ReaderCommandReason.restore);
      expect(provider.deferredRestoreToken, isNull);
      provider.dispose();
    },
  );

  test('restore exhaustion defers while target chapter is still loading', () {
    final provider = _RecordingReaderProvider()..loadingChapters.add(0);
    var didDefer = false;
    var didCancel = false;

    const ScrollRestoreRunner().run(
      provider: provider,
      chapterIndex: 0,
      localOffset: 120,
      token: 99,
      retries: 0,
      isMounted: () => true,
      isScrollControllerAttached: () => true,
      ensureChapterVisible: () {},
      deferRestore: () {
        didDefer = true;
      },
      cancelRestore: () {
        didCancel = true;
      },
      onCompleted: () {
        fail('restore should not complete without content');
      },
      scrollToChapterLocalOffset: ({
        required int chapterIndex,
        required double localOffset,
        required bool animate,
      }) {
        fail('restore should not scroll without content');
      },
      ensureChapterCached: (_) async {},
      hasTargetPageContext: (_) => false,
    );

    expect(didDefer, isTrue);
    expect(didCancel, isFalse);
    provider.dispose();
  });
}
