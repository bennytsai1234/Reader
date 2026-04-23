import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/view/scroll_execution_adapter.dart';
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
  origin: 'local',
);

List<TextPage> _buildPages() {
  return [
    TextPage(
      index: 0,
      title: 'c0',
      chapterIndex: 0,
      pageSize: 2,
      lines: [
        TextLine(
          text: 'A',
          width: 100,
          height: 100,
          chapterPosition: 0,
          lineTop: 0,
          lineBottom: 100,
          paragraphNum: 1,
          isParagraphEnd: true,
        ),
      ],
    ),
    TextPage(
      index: 1,
      title: 'c0',
      chapterIndex: 0,
      pageSize: 2,
      lines: [
        TextLine(
          text: 'B',
          width: 100,
          height: 100,
          chapterPosition: 100,
          lineTop: 0,
          lineBottom: 100,
          paragraphNum: 2,
          isParagraphEnd: true,
        ),
      ],
    ),
  ];
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

  testWidgets('resolveAnchorLocation 會以 page anchor 計算章內 localOffset', (
    tester,
  ) async {
    final provider = ReaderProvider(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );
    await tester.pump(const Duration(milliseconds: 10));
    provider.chapterPagesCache[0] = _buildPages();
    provider.refreshChapterRuntime(0);

    final pageKeys = <String, GlobalKey>{
      '0:0': GlobalKey(),
      '0:1': GlobalKey(),
    };
    final adapter = ScrollExecutionAdapter(pageKeys: pageKeys);
    final scrollController = ScrollController(initialScrollOffset: 90);

    addTearDown(provider.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 100,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  SizedBox(key: pageKeys['0:0'], height: 100),
                  SizedBox(key: pageKeys['0:1'], height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final location = adapter.resolveAnchorLocation(provider: provider);

    expect(location, isNotNull);
    expect(location!.chapterIndex, 0);
    expect(location.pageIndex, 1);
    expect(location.localOffset, closeTo(105, 0.1));
  });

  testWidgets('resolveAnchorLocation 在 anchor 落於頁間空隙時會退到最近可見頁', (tester) async {
    final provider = ReaderProvider(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'https://example.com/book'),
      ],
    );
    await tester.pump(const Duration(milliseconds: 10));
    provider.chapterPagesCache[0] = _buildPages();
    provider.refreshChapterRuntime(0);

    final pageKeys = <String, GlobalKey>{
      '0:0': GlobalKey(),
      '0:1': GlobalKey(),
    };
    final adapter = ScrollExecutionAdapter(pageKeys: pageKeys);
    final scrollController = ScrollController(initialScrollOffset: 100);

    addTearDown(provider.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 100,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  SizedBox(key: pageKeys['0:0'], height: 100),
                  const SizedBox(height: 40),
                  SizedBox(key: pageKeys['0:1'], height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final location = adapter.resolveAnchorLocation(provider: provider);

    expect(location, isNotNull);
    expect(location!.chapterIndex, 0);
    expect(location.pageIndex, 1);
    expect(location.localOffset, closeTo(100, 0.1));
  });
}
