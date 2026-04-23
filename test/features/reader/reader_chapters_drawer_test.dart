import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_chapters_drawer.dart';
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

class _DrawerReaderProvider extends ReaderProvider {
  _DrawerReaderProvider({required super.book, required super.initialChapters});

  final List<int> loadRequests = [];
  Completer<void>? loadCompleter;

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {}

  @override
  Future<void> loadChapter(
    int index, {
    bool fromEnd = false,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
    int? navigationToken,
  }) async {
    loadRequests.add(index);
    final completer = loadCompleter ??= Completer<void>();
    await completer.future;
    currentChapterIndex = index;
    visibleChapterIndex = index;
    notifyListeners();
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

List<BookChapter> _buildChapters(int count) {
  return List.generate(
    count,
    (index) => BookChapter(
      title: 'c$index',
      index: index,
      bookUrl: 'https://example.com/book',
    ),
  );
}

Future<void> _pumpDrawer(
  WidgetTester tester,
  _DrawerReaderProvider provider,
) async {
  tester.view.physicalSize = const Size(320, 400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<ReaderProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Consumer<ReaderProvider>(
          builder:
              (context, value, _) => Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 400,
                  child: ReaderChaptersDrawer(provider: value),
                ),
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

  testWidgets('ReaderChaptersDrawer 會在目前章節變化後自動定位到該章', (tester) async {
    final provider = _DrawerReaderProvider(
      book: _makeBook(),
      initialChapters: _buildChapters(30),
    );
    await tester.pump(const Duration(milliseconds: 10));
    addTearDown(provider.dispose);

    await _pumpDrawer(tester, provider);
    expect(find.text('c20'), findsNothing);

    provider.currentChapterIndex = 20;
    provider.notifyListeners();
    await tester.pump();
    await tester.pump();

    expect(find.text('c20'), findsOneWidget);
  });

  testWidgets('ReaderChaptersDrawer 在 pending chapter navigation 時顯示目標章並鎖定重入', (
    tester,
  ) async {
    final provider = _DrawerReaderProvider(
      book: _makeBook(),
      initialChapters: _buildChapters(30),
    );
    await tester.pump(const Duration(milliseconds: 10));
    addTearDown(provider.dispose);

    await _pumpDrawer(tester, provider);

    unawaited(provider.jumpToChapter(18));
    await tester.pump();
    await tester.pump();

    expect(find.text('c18'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<ListTile>(find.widgetWithText(ListTile, 'c18')).enabled,
      isFalse,
    );

    await tester.tap(find.text('c18'));
    await tester.pump();
    expect(provider.loadRequests, [18]);

    provider.loadCompleter!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
