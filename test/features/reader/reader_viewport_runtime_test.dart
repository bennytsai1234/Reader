import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_scroll_viewport_settle_state.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_position.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBookDao implements BookDao {
  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos, {
    String? readerAnchorJson,
  }) async {}

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

class _FakeReaderProvider extends ReaderProvider {
  ReaderTtsPosition? fakeCurrentTtsPosition;
  bool fakePendingVisiblePlaceholderReanchor = false;
  bool fakeHasActiveNavigation = false;
  ReaderCommandReason? fakeActiveCommandReason;
  int pauseCalls = 0;
  int resumeCalls = 0;
  final List<bool> scrollInteractionStates = <bool>[];

  _FakeReaderProvider()
    : super(book: Book(bookUrl: 'book', name: 'Book', origin: 'local'));

  @override
  ReaderTtsPosition? get currentTtsPosition => fakeCurrentTtsPosition;

  @override
  bool get hasPendingVisiblePlaceholderReanchor =>
      fakePendingVisiblePlaceholderReanchor;

  @override
  bool get hasActiveNavigation => fakeHasActiveNavigation;

  @override
  ReaderCommandReason? get activeCommandReason => fakeActiveCommandReason;

  @override
  void pauseAutoPage() {
    pauseCalls += 1;
  }

  @override
  void resumeAutoPage() {
    resumeCalls += 1;
  }

  @override
  void setScrollInteractionActive(bool active) {
    scrollInteractionStates.add(active);
  }
}

void _setupDi() {
  if (getIt.isRegistered<BookDao>()) getIt.unregister<BookDao>();
  if (getIt.isRegistered<ChapterDao>()) getIt.unregister<ChapterDao>();
  if (getIt.isRegistered<ReplaceRuleDao>()) getIt.unregister<ReplaceRuleDao>();
  if (getIt.isRegistered<BookSourceDao>()) {
    getIt.unregister<BookSourceDao>();
  }
  if (getIt.isRegistered<BookmarkDao>()) getIt.unregister<BookmarkDao>();

  getIt.registerLazySingleton<BookDao>(() => _FakeBookDao());
  getIt.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
  getIt.registerLazySingleton<ReplaceRuleDao>(() => _FakeReplaceRuleDao());
  getIt.registerLazySingleton<BookSourceDao>(() => _FakeBookSourceDao());
  getIt.registerLazySingleton<BookmarkDao>(() => _FakeBookmarkDao());
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

  group('ReaderViewportRuntime', () {
    test('beginUserScroll 與 endUserScroll 會切換 auto page 與 interaction', () {
      final provider =
          _FakeReaderProvider()
            ..pageTurnMode = PageAnim.scroll
            ..showControls = false;
      final runtime = ReaderViewportRuntime(
        initialPageTurnMode: provider.pageTurnMode,
      );

      provider.autoPageProgressNotifier.value = 0.72;
      runtime.beginUserScroll(provider);
      runtime.endUserScroll(provider);

      expect(runtime.isUserScrolling, isFalse);
      expect(provider.pauseCalls, 1);
      expect(provider.resumeCalls, 1);
      expect(provider.autoPageProgressNotifier.value, 0.0);
      expect(provider.scrollInteractionStates, [true, false]);
      provider.dispose();
    });

    test('showControls 開啟時 endUserScroll 不會恢復 auto page', () {
      final provider =
          _FakeReaderProvider()
            ..pageTurnMode = PageAnim.scroll
            ..showControls = true;
      final runtime = ReaderViewportRuntime(
        initialPageTurnMode: provider.pageTurnMode,
      );

      runtime.beginUserScroll(provider);
      runtime.endUserScroll(provider);

      expect(provider.pauseCalls, 1);
      expect(provider.resumeCalls, 0);
      provider.dispose();
    });

    test(
      'handleProviderStateChanged 會在 mode switch 時清掉 scroll interaction',
      () {
        final provider = _FakeReaderProvider()..pageTurnMode = PageAnim.scroll;
        final runtime = ReaderViewportRuntime(
          initialPageTurnMode: provider.pageTurnMode,
        );

        runtime.beginUserScroll(provider);
        provider.pageTurnMode = PageAnim.slide;
        final update = runtime.handleProviderStateChanged(provider);

        expect(update.didModeChange, isTrue);
        expect(runtime.isUserScrolling, isFalse);
        expect(provider.scrollInteractionStates, [true, false]);
        provider.dispose();
      },
    );

    test('handleProviderStateChanged 會用 followKey 去重 follow 請求', () {
      final provider =
          _FakeReaderProvider()
            ..pageTurnMode = PageAnim.scroll
            ..fakeCurrentTtsPosition = const ReaderTtsPosition(
              chapterIndex: 0,
              pageIndex: 0,
              lineIndex: 0,
              highlightStart: 100,
              highlightEnd: 110,
              wordStart: 108,
              wordEnd: 109,
              localOffset: 120,
              followKey: 7001,
            );
      final runtime = ReaderViewportRuntime(
        initialPageTurnMode: provider.pageTurnMode,
      );

      final firstUpdate = runtime.handleProviderStateChanged(provider);
      final secondUpdate = runtime.handleProviderStateChanged(provider);
      provider.fakeCurrentTtsPosition = null;
      runtime.handleProviderStateChanged(provider);
      provider.fakeCurrentTtsPosition = const ReaderTtsPosition(
        chapterIndex: 0,
        pageIndex: 0,
        lineIndex: 0,
        highlightStart: 100,
        highlightEnd: 110,
        wordStart: 108,
        wordEnd: 109,
        localOffset: 120,
        followKey: 7001,
      );
      final thirdUpdate = runtime.handleProviderStateChanged(provider);

      expect(firstUpdate.shouldFollowTts, isTrue);
      expect(secondUpdate.shouldFollowTts, isFalse);
      expect(thirdUpdate.shouldFollowTts, isTrue);
      provider.dispose();
    });

    test(
      'handleProviderStateChanged 在 restore pending 期間會 hold 並抑制 TTS follow',
      () {
        final provider =
            _FakeReaderProvider()
              ..pageTurnMode = PageAnim.scroll
              ..fakeCurrentTtsPosition = const ReaderTtsPosition(
                chapterIndex: 0,
                pageIndex: 0,
                lineIndex: 0,
                highlightStart: 100,
                highlightEnd: 110,
                wordStart: 108,
                wordEnd: 109,
                localOffset: 120,
                followKey: 7002,
              );
        provider.registerPendingScrollRestore(chapterIndex: 2, localOffset: 48);
        final runtime = ReaderViewportRuntime(
          initialPageTurnMode: provider.pageTurnMode,
        );

        final update = runtime.handleProviderStateChanged(provider);

        expect(update.shouldHoldScrollUntilRestore, isFalse);
        expect(update.shouldFollowTts, isFalse);
        expect(
          update.viewportSettleState.phase,
          ReaderScrollViewportSettlePhase.pendingRestore,
        );
        provider.dispose();
      },
    );

    test(
      'handleProviderStateChanged 在 placeholder re-anchor pending 期間只抑制 TTS follow',
      () {
        final provider =
            _FakeReaderProvider()
              ..pageTurnMode = PageAnim.scroll
              ..fakePendingVisiblePlaceholderReanchor = true
              ..fakeCurrentTtsPosition = const ReaderTtsPosition(
                chapterIndex: 0,
                pageIndex: 0,
                lineIndex: 0,
                highlightStart: 100,
                highlightEnd: 110,
                wordStart: 108,
                wordEnd: 109,
                localOffset: 120,
                followKey: 7003,
              );
        final runtime = ReaderViewportRuntime(
          initialPageTurnMode: provider.pageTurnMode,
        );

        final update = runtime.handleProviderStateChanged(provider);

        expect(update.shouldHoldScrollUntilRestore, isFalse);
        expect(update.shouldFollowTts, isFalse);
        expect(
          update.viewportSettleState.phase,
          ReaderScrollViewportSettlePhase.pendingPlaceholderReanchor,
        );
        provider.dispose();
      },
    );

    test(
      'handleProviderStateChanged 在 active navigation pending 期間只抑制 TTS follow',
      () {
        final provider =
            _FakeReaderProvider()
              ..pageTurnMode = PageAnim.scroll
              ..fakeHasActiveNavigation = true
              ..fakeActiveCommandReason = ReaderCommandReason.settingsRepaginate
              ..fakeCurrentTtsPosition = const ReaderTtsPosition(
                chapterIndex: 0,
                pageIndex: 0,
                lineIndex: 0,
                highlightStart: 100,
                highlightEnd: 110,
                wordStart: 108,
                wordEnd: 109,
                localOffset: 120,
                followKey: 7004,
              );
        final runtime = ReaderViewportRuntime(
          initialPageTurnMode: provider.pageTurnMode,
        );

        final update = runtime.handleProviderStateChanged(provider);

        expect(update.shouldHoldScrollUntilRestore, isFalse);
        expect(update.shouldFollowTts, isFalse);
        expect(
          update.viewportSettleState.phase,
          ReaderScrollViewportSettlePhase.pendingNavigation,
        );
        expect(
          update.viewportSettleState.commandReason,
          ReaderCommandReason.settingsRepaginate,
        );
        provider.dispose();
      },
    );

    test('userScroll pending navigation 會消耗被 suppress 的 TTS follow', () {
      final provider =
          _FakeReaderProvider()
            ..pageTurnMode = PageAnim.scroll
            ..fakeHasActiveNavigation = true
            ..fakeActiveCommandReason = ReaderCommandReason.userScroll
            ..fakeCurrentTtsPosition = const ReaderTtsPosition(
              chapterIndex: 0,
              pageIndex: 0,
              lineIndex: 0,
              highlightStart: 100,
              highlightEnd: 110,
              wordStart: 108,
              wordEnd: 109,
              localOffset: 120,
              followKey: 8001,
            );
      final runtime = ReaderViewportRuntime(
        initialPageTurnMode: provider.pageTurnMode,
      );

      final suppressedUpdate = runtime.handleProviderStateChanged(provider);
      provider.fakeHasActiveNavigation = false;
      final resumedUpdate = runtime.handleProviderStateChanged(provider);

      expect(suppressedUpdate.shouldFollowTts, isFalse);
      expect(
        suppressedUpdate.viewportSettleState.shouldConsumeSuppressedTtsFollow,
        isTrue,
      );
      expect(resumedUpdate.shouldFollowTts, isFalse);
      provider.dispose();
    });

    test(
      'settingsRepaginate pending navigation 結束後會重放被 suppress 的 TTS follow',
      () {
        final provider =
            _FakeReaderProvider()
              ..pageTurnMode = PageAnim.scroll
              ..fakeHasActiveNavigation = true
              ..fakeActiveCommandReason = ReaderCommandReason.settingsRepaginate
              ..fakeCurrentTtsPosition = const ReaderTtsPosition(
                chapterIndex: 0,
                pageIndex: 0,
                lineIndex: 0,
                highlightStart: 100,
                highlightEnd: 110,
                wordStart: 108,
                wordEnd: 109,
                localOffset: 120,
                followKey: 8002,
              );
        final runtime = ReaderViewportRuntime(
          initialPageTurnMode: provider.pageTurnMode,
        );

        final suppressedUpdate = runtime.handleProviderStateChanged(provider);
        provider.fakeHasActiveNavigation = false;
        final resumedUpdate = runtime.handleProviderStateChanged(provider);

        expect(suppressedUpdate.shouldFollowTts, isFalse);
        expect(
          suppressedUpdate.viewportSettleState.shouldReplaySuppressedTtsFollow,
          isTrue,
        );
        expect(resumedUpdate.shouldFollowTts, isTrue);
        provider.dispose();
      },
    );
  });
}
