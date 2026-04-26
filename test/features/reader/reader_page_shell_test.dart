import 'package:flutter/material.dart';
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
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_exit_coordinator.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_page_shell.dart';
import 'package:provider/provider.dart';
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
  Future<void> upsert(Book book) async {}

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

class _ReaderPageShellProbe extends ReaderProvider {
  _ReaderPageShellProbe({required super.book, required super.initialChapters});

  bool promptAddToBookshelfOnExit = false;
  int persistExitProgressCalls = 0;
  int addToBookshelfCalls = 0;

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {}

  @override
  Future<void> loadChapter(
    int index, {
    bool fromEnd = false,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
    int? navigationToken,
  }) async {}

  void primeVisibleContent() {
    lifecycle = ReaderLifecycle.ready;
    loadingChapters.clear();
    pageTurnMode = PageAnim.slide;
    chapterPagesCache[0] = [
      TextPage(
        index: 0,
        title: 'c0',
        chapterIndex: 0,
        pageSize: 1,
        lines: [
          TextLine(
            text: 'reader shell content',
            width: 200,
            height: 20,
            chapterPosition: 0,
            lineTop: 0,
            lineBottom: 24,
            paragraphNum: 1,
            isParagraphEnd: true,
          ),
        ],
      ),
    ];
    slidePages = [...chapterPagesCache[0]!];
    currentChapterIndex = 0;
    visibleChapterIndex = 0;
    currentPageIndex = 0;
    viewSize = const Size(400, 800);
  }

  @override
  bool shouldPromptAddToBookshelfOnExit() {
    return promptAddToBookshelfOnExit;
  }

  @override
  Future<void> persistExitProgress() async {
    persistExitProgressCalls++;
  }

  @override
  Future<void> addCurrentBookToBookshelf() async {
    addToBookshelfCalls++;
  }

  @override
  Future<void> discardUnkeptBookStorage() async {}
}

typedef _ShellExitHandler =
    void Function(BuildContext context, ReaderProvider provider);

void _setupDi() {
  if (getIt.isRegistered<BookDao>()) getIt.unregister<BookDao>();
  if (getIt.isRegistered<ChapterDao>()) getIt.unregister<ChapterDao>();
  if (getIt.isRegistered<ReplaceRuleDao>()) getIt.unregister<ReplaceRuleDao>();
  if (getIt.isRegistered<BookSourceDao>()) getIt.unregister<BookSourceDao>();
  if (getIt.isRegistered<BookmarkDao>()) getIt.unregister<BookmarkDao>();

  getIt.registerLazySingleton<BookDao>(() => _FakeBookDao());
  getIt.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
  getIt.registerLazySingleton<ReplaceRuleDao>(() => _FakeReplaceRuleDao());
  getIt.registerLazySingleton<BookSourceDao>(() => _FakeBookSourceDao());
  getIt.registerLazySingleton<BookmarkDao>(() => _FakeBookmarkDao());
}

Book _makeBook() => Book(
  bookUrl: 'https://example.com/book',
  name: '示例書籍',
  author: '作者',
  origin: 'source://demo',
  originName: '測試書源',
);

Future<void> _pumpShell(
  WidgetTester tester,
  _ReaderPageShellProbe provider, {
  _ShellExitHandler? onExitIntent,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<ReaderProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Consumer<ReaderProvider>(
          builder:
              (context, value, _) => ReaderPageShell(
                provider: value,
                scaffoldKey: GlobalKey<ScaffoldState>(),
                content: const SizedBox.expand(),
                onExitIntent: () => onExitIntent?.call(context, value),
                onMore: () {},
                onOpenDrawer: () {},
                onTts: () {},
                onInterface: () {},
                onSettings: () {},
                onAutoPage: () {},
                onToggleDayNight: () {},
                onSearch: () {},
                onReplaceRule: () {},
              ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _setupDi();
  });

  testWidgets('ReaderPageShell 會依 visible content 與設定顯示 permanent info', (
    tester,
  ) async {
    final provider = _ReaderPageShellProbe(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );

    addTearDown(provider.dispose);
    await _pumpShell(tester, provider);
    provider.primeVisibleContent();
    provider.showReadTitleAddition = true;
    provider.notifyListeners();
    await tester.pump();

    expect(find.byType(ReaderPermanentInfoBar), findsOneWidget);

    provider.showReadTitleAddition = false;
    provider.notifyListeners();
    await tester.pump();

    expect(find.byType(ReaderPermanentInfoBar), findsNothing);
  });

  testWidgets('ReaderPageShell controls overlay 點擊後會收起控制列', (tester) async {
    final provider = _ReaderPageShellProbe(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );

    addTearDown(provider.dispose);
    await _pumpShell(tester, provider);
    provider.primeVisibleContent();
    provider.showControls = true;
    provider.notifyListeners();
    await tester.pump();

    expect(provider.showControls, isTrue);

    await tester.tapAt(const Offset(200, 400));
    await tester.pump();

    expect(provider.showControls, isFalse);
  });

  testWidgets('ReaderPageShell top back 會走 exit flow 並在無 prompt 時直接 pop', (
    tester,
  ) async {
    final provider = _ReaderPageShellProbe(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );
    final coordinator = ReaderPageExitCoordinator();
    var popCalls = 0;

    addTearDown(provider.dispose);
    await _pumpShell(
      tester,
      provider,
      onExitIntent:
          (context, value) => coordinator.handleExitIntent(
            context: context,
            provider: value,
            isDrawerOpen: () => false,
            popNavigator: () => popCalls++,
          ),
    );
    provider.primeVisibleContent();
    provider.showControls = true;
    provider.notifyListeners();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(provider.persistExitProgressCalls, 1);
    expect(provider.addToBookshelfCalls, 0);
    expect(popCalls, 1);
  });

  testWidgets('ReaderPageShell top back 在 prompt 後可完成加入書架 flow', (
    tester,
  ) async {
    final provider = _ReaderPageShellProbe(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    )..promptAddToBookshelfOnExit = true;
    final coordinator = ReaderPageExitCoordinator();
    var popCalls = 0;

    addTearDown(provider.dispose);
    await _pumpShell(
      tester,
      provider,
      onExitIntent:
          (context, value) => coordinator.handleExitIntent(
            context: context,
            provider: value,
            isDrawerOpen: () => false,
            popNavigator: () => popCalls++,
          ),
    );
    provider.primeVisibleContent();
    provider.showControls = true;
    provider.notifyListeners();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(find.text('加入書架？'), findsOneWidget);
    expect(popCalls, 0);

    await tester.tap(find.text('加入書架'));
    await tester.pump();

    expect(provider.persistExitProgressCalls, 1);
    expect(provider.addToBookshelfCalls, 1);
    expect(popCalls, 1);
  });
}
