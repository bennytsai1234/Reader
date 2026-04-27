import 'package:flutter/gestures.dart';
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
import 'package:inkpage_reader/features/reader/reader_page.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/view/read_view_runtime.dart';
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
  Future<List<BookChapter>> getByBook(String bookUrl) async => [];

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

class _ReaderPageActionProbe extends ReaderProvider {
  _ReaderPageActionProbe({required super.book, required super.initialChapters});

  int nextPageCalls = 0;
  int toggleControlsCalls = 0;
  final List<({int token, ReaderCommandReason reason})> completedNavigations =
      [];

  void primeVisibleContent() {
    lifecycle = ReaderLifecycle.ready;
    pageTurnMode = PageAnim.slide;
    chapterPagesCache[0] = [
      TextPage(
        index: 0,
        title: 'c0',
        chapterIndex: 0,
        pageSize: 1,
        lines: [
          TextLine(
            text: 'reader page content',
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

  void primeSlideContent(List<int> pageStarts) {
    lifecycle = ReaderLifecycle.ready;
    pageTurnMode = PageAnim.slide;
    chapterPagesCache[0] = _buildPages(0, pageStarts, title: 'c0');
    refreshChapterRuntime(0);
    slidePages = [...chapterPagesCache[0]!];
    currentChapterIndex = 0;
    visibleChapterIndex = 0;
    currentPageIndex = 0;
    viewSize = const Size(400, 800);
  }

  void primeScrollContent() {
    lifecycle = ReaderLifecycle.ready;
    pageTurnMode = PageAnim.scroll;
    chapterPagesCache[0] = _buildPages(0, [0, 10], title: 'c0');
    chapterPagesCache[1] = _buildPages(1, [0, 10], title: 'c1');
    refreshChapterRuntime(0);
    refreshChapterRuntime(1);
    currentChapterIndex = 0;
    visibleChapterIndex = 0;
    currentPageIndex = 0;
    viewSize = const Size(400, 800);
  }

  @override
  void nextPage({ReaderCommandReason reason = ReaderCommandReason.user}) {
    nextPageCalls++;
  }

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {}

  @override
  void setScrollInteractionActive(bool active) {}

  @override
  void toggleControls() {
    toggleControlsCalls++;
    super.toggleControls();
  }

  @override
  void completeNavigation(int token, ReaderCommandReason reason) {
    completedNavigations.add((token: token, reason: reason));
    super.completeNavigation(token, reason);
  }
}

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

List<TextPage> _buildPages(
  int chapterIndex,
  List<int> pageStarts, {
  String title = 'chapter',
}) {
  return List.generate(pageStarts.length, (pageIndex) {
    final start = pageStarts[pageIndex];
    final nextStart =
        pageIndex + 1 < pageStarts.length
            ? pageStarts[pageIndex + 1]
            : start + 8;
    final length = (nextStart - start).clamp(4, 12);
    return TextPage(
      index: pageIndex,
      title: title,
      chapterIndex: chapterIndex,
      pageSize: pageStarts.length,
      lines: [
        TextLine(
          text: List.filled(length, 'X').join(),
          width: 100,
          height: 20,
          chapterPosition: start,
          lineTop: pageIndex * 100,
          lineBottom: pageIndex * 100 + 40,
          paragraphNum: pageIndex + 1,
          isParagraphEnd: true,
        ),
      ],
    );
  });
}

Future<void> _pumpReaderPage(
  WidgetTester tester,
  _ReaderPageActionProbe provider, {
  bool primeContent = true,
  bool selectText = false,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (primeContent) {
    provider.primeVisibleContent();
  }
  provider.selectText = selectText;
  await tester.pumpWidget(
    ChangeNotifierProvider<ReaderProvider>.value(
      value: provider,
      child: MaterialApp(home: ReaderPage(book: provider.book)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _setupDi();
  });

  test('ReaderPage can be constructed', () {
    expect(() => ReaderPage(book: _makeBook()), returnsNormally);
  });

  testWidgets('ReaderPage 內容點擊 menu action 會開關 controls', (tester) async {
    final provider = _ReaderPageActionProbe(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );
    provider.clickActions = List<int>.filled(9, 0);

    addTearDown(provider.dispose);
    await _pumpReaderPage(tester, provider);

    expect(find.byType(ReaderPageShell), findsOneWidget);
    expect(
      tester
          .widget<ReadViewRuntime>(find.byType(ReadViewRuntime))
          .onContentTapUp,
      isNotNull,
    );

    final runtimeBeforeToggle = tester.widget<ReadViewRuntime>(
      find.byType(ReadViewRuntime),
    );
    expect(runtimeBeforeToggle.onContentTapUp, isNotNull);

    runtimeBeforeToggle.onContentTapUp!(
      TapUpDetails(
        localPosition: const Offset(10, 10),
        kind: PointerDeviceKind.touch,
      ),
    );
    await tester.pump();

    expect(provider.showControls, isTrue);
    expect(provider.toggleControlsCalls, 1);

    final runtimeAfterToggle = tester.widget<ReadViewRuntime>(
      find.byType(ReadViewRuntime),
    );
    expect(runtimeAfterToggle.onContentTapUp, isNull);
  });

  testWidgets('ReaderPage 內容點擊會分發 next page tap action', (tester) async {
    final provider = _ReaderPageActionProbe(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );

    addTearDown(provider.dispose);
    await _pumpReaderPage(tester, provider);
    provider.clickActions = List<int>.filled(9, 1);
    await tester.pump();

    expect(
      tester
          .widget<ReadViewRuntime>(find.byType(ReadViewRuntime))
          .onContentTapUp,
      isNotNull,
    );

    final runtime = tester.widget<ReadViewRuntime>(
      find.byType(ReadViewRuntime),
    );
    expect(runtime.onContentTapUp, isNotNull);

    runtime.onContentTapUp!(
      TapUpDetails(
        localPosition: const Offset(10, 10),
        kind: PointerDeviceKind.touch,
      ),
    );
    await tester.pump();

    expect(provider.nextPageCalls, 1);
    expect(provider.showControls, isFalse);
  });

  testWidgets('ReaderPage 開啟 selectText 時仍保留 tap action wiring', (
    tester,
  ) async {
    final provider = _ReaderPageActionProbe(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );
    provider.clickActions = List<int>.filled(9, 0);

    addTearDown(provider.dispose);
    await _pumpReaderPage(tester, provider);
    provider.setSelectText(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final runtime = tester.widget<ReadViewRuntime>(
      find.byType(ReadViewRuntime),
    );
    expect(runtime.onContentTapUp, isNotNull);

    runtime.onContentTapUp!(
      TapUpDetails(
        localPosition: const Offset(10, 10),
        kind: PointerDeviceKind.touch,
      ),
    );
    await tester.pump();

    expect(provider.showControls, isTrue);
    expect(provider.toggleControlsCalls, 1);
  });

  testWidgets('ReaderPage 實際點擊內容頁會開關 controls', (tester) async {
    final provider = _ReaderPageActionProbe(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );
    provider.clickActions = List<int>.filled(9, 0);

    addTearDown(provider.dispose);
    await _pumpReaderPage(tester, provider);
    provider.primeVisibleContent();
    provider.notifyListeners();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final contentCenter = tester.getCenter(find.byType(ReadViewRuntime));
    await tester.tapAt(contentCenter);
    await tester.pump();

    expect(provider.showControls, isTrue);
    expect(provider.toggleControlsCalls, 1);
  });

  testWidgets('ReaderPage 開啟 selectText 後實際點擊內容頁仍會分發 tap action', (
    tester,
  ) async {
    final provider = _ReaderPageActionProbe(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );
    provider.clickActions = List<int>.filled(9, 0);

    addTearDown(provider.dispose);
    await _pumpReaderPage(tester, provider, selectText: true);
    provider.primeVisibleContent();
    provider.setSelectText(true);
    provider.notifyListeners();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final contentCenter = tester.getCenter(find.byType(ReadViewRuntime));
    await tester.tapAt(contentCenter);
    await tester.pump();

    expect(provider.showControls, isTrue);
    expect(provider.toggleControlsCalls, 1);
  });
}
