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
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_scroll_viewport_settle_state.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:inkpage_reader/features/reader/runtime/read_view_runtime_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_position.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_state.dart';
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
  bool knownEmpty = false;
  ReaderTtsPosition? fakeCurrentTtsPosition;
  String? fakeFailureMessage;
  bool fakePendingVisiblePlaceholderReanchor = false;
  ReaderSessionPhase fakeSessionPhase = ReaderSessionPhase.ready;
  bool fakeHasActiveNavigation = false;
  ReaderCommandReason? fakeActiveCommandReason;

  _FakeReaderProvider()
    : super(book: Book(bookUrl: 'book', name: 'Book', origin: 'local'));

  @override
  bool isKnownEmptyChapter(int index) =>
      knownEmpty && index == currentChapterIndex;

  @override
  ReaderTtsPosition? get currentTtsPosition => fakeCurrentTtsPosition;

  @override
  bool get hasPendingVisiblePlaceholderReanchor =>
      fakePendingVisiblePlaceholderReanchor;

  @override
  ReaderSessionPhase get sessionPhase => fakeSessionPhase;

  @override
  bool get hasActiveNavigation => fakeHasActiveNavigation;

  @override
  ReaderCommandReason? get activeCommandReason => fakeActiveCommandReason;

  @override
  String? chapterFailureMessage(int chapterIndex) {
    if (fakeFailureMessage != null && chapterIndex == currentChapterIndex) {
      return fakeFailureMessage;
    }
    return super.chapterFailureMessage(chapterIndex);
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

  group('ReadViewRuntimeCoordinator', () {
    const coordinator = ReadViewRuntimeCoordinator();

    test('載入中時回傳 loading state', () {
      final provider =
          _FakeReaderProvider()
            ..lifecycle = ReaderLifecycle.loading
            ..pageTurnMode = PageAnim.slide;

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: false,
      );

      expect(state.showLoading, isTrue);
      expect(state.message, '正在載入內容');
      provider.dispose();
    });

    test('無章節時回傳暫無章節', () {
      final provider =
          _FakeReaderProvider()
            ..lifecycle = ReaderLifecycle.ready
            ..pageTurnMode = PageAnim.slide
            ..viewSize = const Size(300, 500);

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: false,
      );

      expect(state.showLoading, isFalse);
      expect(state.message, '暫無章節');
      provider.dispose();
    });

    test('已知空章節時回傳本章暫無內容', () {
      final provider =
          _FakeReaderProvider()
            ..lifecycle = ReaderLifecycle.ready
            ..pageTurnMode = PageAnim.slide
            ..viewSize = const Size(300, 500)
            ..chapters = [BookChapter(title: 'c0', index: 0, bookUrl: 'book')]
            ..knownEmpty = true;

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: false,
      );

      expect(state.showLoading, isFalse);
      expect(state.message, '本章暫無內容');
      provider.dispose();
    });

    test('transient viewport state 會優先回傳', () {
      final provider =
          _FakeReaderProvider()
            ..lifecycle = ReaderLifecycle.ready
            ..pageTurnMode = PageAnim.slide
            ..viewSize = const Size(300, 500)
            ..chapters = [BookChapter(title: 'c0', index: 0, bookUrl: 'book')];
      provider.showTransientViewportStateForChapter(
        0,
        const ReaderViewportState.message('加載章節失敗: 測試錯誤'),
        notify: false,
      );

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: true,
      );

      expect(state.showLoading, isFalse);
      expect(state.message, '加載章節失敗: 測試錯誤');
      provider.dispose();
    });

    test('失敗章節時回傳 failure message', () {
      final provider =
          _FakeReaderProvider()
            ..lifecycle = ReaderLifecycle.ready
            ..pageTurnMode = PageAnim.slide
            ..viewSize = const Size(300, 500)
            ..chapters = [BookChapter(title: 'c0', index: 0, bookUrl: 'book')]
            ..fakeFailureMessage = '加載章節失敗: 找不到書源';

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: false,
      );

      expect(state.showLoading, isFalse);
      expect(state.message, '加載章節失敗: 找不到書源');
      provider.dispose();
    });

    test('非 loading 且無可見資料時回傳暫無可顯示頁面', () {
      final provider =
          _FakeReaderProvider()
            ..lifecycle = ReaderLifecycle.ready
            ..pageTurnMode = PageAnim.scroll
            ..viewSize = const Size(300, 500)
            ..chapters = [BookChapter(title: 'c0', index: 0, bookUrl: 'book')];

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: false,
      );

      expect(state.showLoading, isFalse);
      expect(state.message, '暫無可顯示頁面');
      provider.dispose();
    });

    test('scroll pending jump 會保留原始命令 reason', () {
      final provider = _FakeReaderProvider()..pageTurnMode = PageAnim.scroll;

      provider.requestJumpToChapter(
        chapterIndex: 2,
        localOffset: 48,
        reason: ReaderCommandReason.settingsRepaginate,
      );
      final action = coordinator.consumePendingScrollAction(provider);

      expect(action, isNotNull);
      expect(action!.command.target.chapterIndex, 2);
      expect(action.command.target.localOffset, 48);
      expect(action.isRestore, isFalse);
      expect(action.command.reason, ReaderCommandReason.settingsRepaginate);
      expect(
        action.command.location,
        const ReaderLocation(chapterIndex: 2, charOffset: 0),
      );
      provider.dispose();
    });

    test('scroll restore action 只會 dispatch 一次，直到 defer 後才可重試', () {
      final provider = _FakeReaderProvider()..pageTurnMode = PageAnim.scroll;

      final token = provider.registerPendingScrollRestore(
        chapterIndex: 2,
        localOffset: 48,
      );
      final first = coordinator.consumePendingScrollAction(provider);
      final second = coordinator.consumePendingScrollAction(provider);

      expect(first, isNotNull);
      expect(first!.isRestore, isTrue);
      expect(first.restoreToken, token);
      expect(first.command.target.chapterIndex, 2);
      expect(first.command.target.localOffset, 48);
      expect(first.command.reason, ReaderCommandReason.restore);
      expect(first.command.anchor.location.chapterIndex, 2);
      expect(first.command.anchor.localOffsetSnapshot, 48);
      expect(second, isNull);
      expect(provider.pendingScrollRestoreChapterIndex, 2);
      expect(provider.pendingScrollRestoreLocalOffset, 48);

      provider.deferPendingScrollRestore(token);
      final retried = coordinator.consumePendingScrollAction(provider);
      expect(retried, isNotNull);
      expect(retried!.restoreToken, token);
      provider.dispose();
    });

    test('scroll restore pending 期間會持續 hold content', () {
      final provider = _FakeReaderProvider()..pageTurnMode = PageAnim.scroll;

      provider.registerPendingScrollRestore(chapterIndex: 2, localOffset: 48);
      final settleState = coordinator.resolveScrollViewportSettleState(
        provider,
        hasVisibleData: false,
      );
      final shouldHold = coordinator.shouldHoldScrollUntilRestored(
        provider,
        hasVisibleData: false,
      );

      expect(settleState.phase, ReaderScrollViewportSettlePhase.pendingRestore);
      expect(shouldHold, isTrue);
      provider.dispose();
    });

    test(
      'restoring 但尚未 visible confirmed 時會進入 awaitingVisibleConfirmation',
      () {
        final provider =
            _FakeReaderProvider()
              ..pageTurnMode = PageAnim.scroll
              ..fakeSessionPhase = ReaderSessionPhase.restoring;

        final settleState = coordinator.resolveScrollViewportSettleState(
          provider,
          hasVisibleData: true,
        );

        expect(
          settleState.phase,
          ReaderScrollViewportSettlePhase.awaitingVisibleConfirmation,
        );
        expect(settleState.shouldHoldContent, isTrue);
        expect(settleState.shouldShowRestoreOverlay, isFalse);
        expect(settleState.shouldSuppressTtsFollow, isTrue);
        provider.dispose();
      },
    );

    test('scroll TTS follow 只會在 followKey 變更時觸發', () {
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
              followKey: 5001,
            );

      final shouldFollow = coordinator.shouldFollowTts(
        provider,
        lastTtsFollowKey: 5001,
        isUserScrolling: false,
        hasVisibleData: true,
      );

      expect(shouldFollow, isFalse);
      provider.dispose();
    });

    test('使用者拖動期間不會觸發 scroll TTS follow', () {
      final provider =
          _FakeReaderProvider()
            ..pageTurnMode = PageAnim.scroll
            ..fakeCurrentTtsPosition = const ReaderTtsPosition(
              chapterIndex: 0,
              pageIndex: 1,
              lineIndex: 0,
              highlightStart: 120,
              highlightEnd: 140,
              wordStart: 132,
              wordEnd: 133,
              localOffset: 160,
              followKey: 6001,
            );

      final shouldFollow = coordinator.shouldFollowTts(
        provider,
        lastTtsFollowKey: 80,
        isUserScrolling: true,
        hasVisibleData: true,
      );

      expect(shouldFollow, isFalse);
      provider.dispose();
    });

    test('restore pending 期間不會觸發 scroll TTS follow', () {
      final provider =
          _FakeReaderProvider()
            ..pageTurnMode = PageAnim.scroll
            ..fakeCurrentTtsPosition = const ReaderTtsPosition(
              chapterIndex: 0,
              pageIndex: 1,
              lineIndex: 0,
              highlightStart: 120,
              highlightEnd: 140,
              wordStart: 132,
              wordEnd: 133,
              localOffset: 160,
              followKey: 6002,
            );

      provider.registerPendingScrollRestore(chapterIndex: 2, localOffset: 48);
      final shouldFollow = coordinator.shouldFollowTts(
        provider,
        lastTtsFollowKey: -1,
        isUserScrolling: false,
        hasVisibleData: true,
      );

      expect(shouldFollow, isFalse);
      provider.dispose();
    });

    test('visible placeholder re-anchor pending 期間會抑制 scroll TTS follow', () {
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

      final shouldFollow = coordinator.shouldFollowTts(
        provider,
        lastTtsFollowKey: -1,
        isUserScrolling: false,
        hasVisibleData: true,
      );
      final settleState = coordinator.resolveScrollViewportSettleState(
        provider,
        hasVisibleData: true,
      );

      expect(shouldFollow, isFalse);
      expect(
        settleState.phase,
        ReaderScrollViewportSettlePhase.pendingPlaceholderReanchor,
      );
      expect(
        coordinator.shouldHoldScrollUntilRestored(
          provider,
          hasVisibleData: true,
        ),
        isFalse,
      );
      provider.dispose();
    });

    test('active navigation pending 期間只抑制 scroll TTS follow', () {
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
              followKey: 7004,
            );

      final settleState = coordinator.resolveScrollViewportSettleState(
        provider,
        hasVisibleData: true,
      );
      final shouldFollow = coordinator.shouldFollowTts(
        provider,
        lastTtsFollowKey: -1,
        isUserScrolling: false,
        hasVisibleData: true,
      );

      expect(
        settleState.phase,
        ReaderScrollViewportSettlePhase.pendingNavigation,
      );
      expect(settleState.commandReason, ReaderCommandReason.userScroll);
      expect(settleState.isNavigationDriven, isTrue);
      expect(settleState.shouldHoldContent, isFalse);
      expect(settleState.shouldSuppressTtsFollow, isTrue);
      expect(shouldFollow, isFalse);
      provider.dispose();
    });

    test('active navigation 會保留 tts command reason', () {
      final provider =
          _FakeReaderProvider()
            ..pageTurnMode = PageAnim.scroll
            ..fakeHasActiveNavigation = true
            ..fakeActiveCommandReason = ReaderCommandReason.tts;

      final settleState = coordinator.resolveScrollViewportSettleState(
        provider,
        hasVisibleData: true,
      );

      expect(
        settleState.phase,
        ReaderScrollViewportSettlePhase.pendingNavigation,
      );
      expect(settleState.commandReason, ReaderCommandReason.tts);
      provider.dispose();
    });
  });
}
