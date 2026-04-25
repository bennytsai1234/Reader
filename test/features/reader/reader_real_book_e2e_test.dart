import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
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
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/local_book_service.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_page.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../tool/source_validation_support.dart';

const _targetChapterIndex = 9;
const _targetContentLineIndex = 10;
const _viewSize = Size(400, 800);
const _readyTimeout = Duration(seconds: 90);
const _fixedLocalBookPath = 'test/fixtures/reader/local_real_e2e_novel.txt';
const _fixedNetworkKeyword = '我的';

bool get _runRealE2e => Platform.environment['RUN_READER_REAL_E2E'] != '0';

String? _env(String name) {
  final value = Platform.environment[name]?.trim();
  return value == null || value.isEmpty ? null : value;
}

Object? _skipUnlessRealE2e(String? missingReason) {
  if (!_runRealE2e) {
    return 'live E2E 已被 RUN_READER_REAL_E2E=0 明確關閉';
  }
  return missingReason;
}

class _ProgressUpdate {
  final int chapterIndex;
  final String chapterTitle;
  final int pos;
  final String? readerAnchorJson;

  const _ProgressUpdate({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.pos,
    this.readerAnchorJson,
  });
}

class _ReaderE2eBookDao implements BookDao {
  final updates = <_ProgressUpdate>[];

  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos, {
    String? readerAnchorJson,
  }) async {
    updates.add(
      _ProgressUpdate(
        chapterIndex: chapterIndex,
        chapterTitle: chapterTitle,
        pos: pos,
        readerAnchorJson: readerAnchorJson,
      ),
    );
  }

  @override
  Future<void> upsert(Book book) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ReaderE2eChapterDao implements ChapterDao {
  _ReaderE2eChapterDao(List<BookChapter> chapters)
    : _chapters = List<BookChapter>.from(chapters);

  final List<BookChapter> _chapters;
  final Map<String, String> _contentByUrl = <String, String>{};

  @override
  Future<List<BookChapter>> getByBook(String bookUrl) async =>
      _chapters.where((chapter) => chapter.bookUrl == bookUrl).toList();

  @override
  Future<List<BookChapter>> getChapters(String bookUrl) => getByBook(bookUrl);

  @override
  Future<String?> getContent(String url) async {
    final cached = _contentByUrl[url];
    if (cached != null && cached.isNotEmpty) return cached;
    for (final chapter in _chapters) {
      if (chapter.url == url && (chapter.content?.isNotEmpty ?? false)) {
        return chapter.content;
      }
    }
    return null;
  }

  @override
  Future<void> insertChapters(List<BookChapter> chapterList) async {
    for (final chapter in chapterList) {
      final existingIndex = _chapters.indexWhere((c) => c.url == chapter.url);
      if (existingIndex >= 0) {
        _chapters[existingIndex] = chapter;
      } else {
        _chapters.add(chapter);
      }
      final content = chapter.content;
      if (content != null && content.isNotEmpty) {
        _contentByUrl[chapter.url] = content;
      }
    }
  }

  @override
  Future<void> updateContent(String url, String content) async {
    _contentByUrl[url] = content;
  }

  @override
  Future<void> saveContent(String url, String content) =>
      updateContent(url, content);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ReaderE2eSourceDao implements BookSourceDao {
  _ReaderE2eSourceDao(this.source);

  final BookSource? source;

  @override
  Future<BookSource?> getByUrl(String url) async {
    final current = source;
    if (current == null) return null;
    return current.bookSourceUrl == url ? current : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ReaderE2eReplaceRuleDao implements ReplaceRuleDao {
  @override
  Future<List<ReplaceRule>> getEnabled() async => const <ReplaceRule>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ReaderE2eBookmarkDao implements BookmarkDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ReaderWidgetScrollProbe extends ReaderProvider {
  _ReaderWidgetScrollProbe({
    required super.book,
    required List<BookChapter> fixtureChapters,
    required this.progressDao,
  }) : fixtureChapters = List<BookChapter>.from(fixtureChapters),
       super(initialChapters: fixtureChapters);

  final _ReaderE2eBookDao progressDao;
  final List<BookChapter> fixtureChapters;

  void primeScrollFixture({
    required List<TextPage> pages,
    int initialCharOffset = 0,
    bool queueRestore = false,
  }) {
    chapters = List<BookChapter>.from(fixtureChapters);
    lifecycle = ReaderLifecycle.ready;
    pageTurnMode = PageAnim.scroll;
    viewSize = _viewSize;
    currentChapterIndex = _targetChapterIndex;
    visibleChapterIndex = _targetChapterIndex;
    currentPageIndex = 0;
    visibleChapterAlignment = 0.0;
    chapterPagesCache[_targetChapterIndex] = pages;
    refreshChapterRuntime(_targetChapterIndex);
    final runtimeChapter = chapterAt(_targetChapterIndex);
    visibleChapterLocalOffset =
        runtimeChapter?.localOffsetFromCharOffset(initialCharOffset) ?? 0.0;

    if (queueRestore && runtimeChapter != null) {
      jumpToChapterLocalOffset(
        chapterIndex: _targetChapterIndex,
        localOffset: visibleChapterLocalOffset,
        reason: ReaderCommandReason.restore,
      );
    }
  }

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {}

  @override
  Future<List<TextPage>> ensureChapterCached(
    int index, {
    bool silent = true,
    bool prioritize = false,
    int preloadRadius = 1,
  }) async {
    return pagesForChapter(index);
  }

  @override
  void scheduleDeferredWindowWarmup(
    int centerIndex, {
    Duration delay = const Duration(milliseconds: 1500),
  }) {}

  @override
  void triggerSilentPreload() {}

  @override
  void updateScrollPreloadForVisibleChapter(
    int visibleChapter, {
    double? localOffset,
  }) {}

  @override
  void setScrollInteractionActive(bool active) {}

  @override
  Future<void> persistExitProgress() async {
    final runtimeChapter = chapterAt(visibleChapterIndex);
    final charOffset =
        runtimeChapter?.charOffsetFromLocalOffset(visibleChapterLocalOffset) ??
        0;
    final location =
        ReaderLocation(
          chapterIndex: visibleChapterIndex,
          charOffset: charOffset,
        ).normalized();
    final anchorJson =
        '{"chapterIndex":${location.chapterIndex},'
        '"charOffset":${location.charOffset},'
        '"localOffsetSnapshot":${visibleChapterLocalOffset.toStringAsFixed(2)}}';

    book.durChapterIndex = location.chapterIndex;
    book.durChapterPos = location.charOffset;
    book.readerAnchorJson = anchorJson;
    await progressDao.updateProgress(
      book.bookUrl,
      location.chapterIndex,
      chapters[location.chapterIndex].title,
      location.charOffset,
      readerAnchorJson: anchorJson,
    );
  }
}

class _ScrollRoundTripTarget {
  final double localOffset;
  final int expectedCharOffset;
  final double expectedRestoredLocalOffset;
  final String linePreview;

  const _ScrollRoundTripTarget({
    required this.localOffset,
    required this.expectedCharOffset,
    required this.expectedRestoredLocalOffset,
    required this.linePreview,
  });
}

void _installReaderE2eDi({
  required _ReaderE2eBookDao bookDao,
  required List<BookChapter> chapters,
  BookSource? source,
}) {
  if (getIt.isRegistered<BookDao>()) getIt.unregister<BookDao>();
  if (getIt.isRegistered<ChapterDao>()) getIt.unregister<ChapterDao>();
  if (getIt.isRegistered<ReplaceRuleDao>()) {
    getIt.unregister<ReplaceRuleDao>();
  }
  if (getIt.isRegistered<BookSourceDao>()) getIt.unregister<BookSourceDao>();
  if (getIt.isRegistered<BookmarkDao>()) getIt.unregister<BookmarkDao>();

  getIt.registerSingleton<BookDao>(bookDao);
  getIt.registerSingleton<ChapterDao>(_ReaderE2eChapterDao(chapters));
  getIt.registerSingleton<ReplaceRuleDao>(_ReaderE2eReplaceRuleDao());
  getIt.registerSingleton<BookSourceDao>(_ReaderE2eSourceDao(source));
  getIt.registerSingleton<BookmarkDao>(_ReaderE2eBookmarkDao());
}

void _mockPlatformChannels(Directory tempDir) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('flutter_tts'),
    (call) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.ryanheise.audio_service.methods'),
    (call) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
        case 'getApplicationSupportDirectory':
        case 'getTemporaryDirectory':
          return tempDir.path;
      }
      return null;
    },
  );
}

Future<void> _prepareReaderPrefs() async {
  await AppTheme.init();
  SharedPreferences.setMockInitialValues({
    PreferKey.readerPageTurnMode: PageAnim.scroll,
  });
}

Future<void> _waitForReadyChapter(
  ReadBookController controller,
  int chapterIndex,
) async {
  final watch = Stopwatch()..start();
  while (watch.elapsed < _readyTimeout) {
    final runtimeChapter = controller.chapterAt(chapterIndex);
    if (controller.isReady &&
        !controller.isLoading &&
        runtimeChapter != null &&
        runtimeChapter.pages.isNotEmpty &&
        !controller.hasChapterFailure(chapterIndex)) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  final failure = controller.chapterFailureMessage(chapterIndex);
  throw StateError(
    'reader chapter $chapterIndex not ready within ${_readyTimeout.inSeconds}s '
    '(lifecycle=${controller.lifecycle}, isLoading=${controller.isLoading}, '
    'pages=${controller.pagesForChapter(chapterIndex).length}, failure=$failure)',
  );
}

Future<void> _pumpUntilWidgetCondition(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = _readyTimeout,
}) async {
  const step = Duration(milliseconds: 50);
  final maxPumps = (timeout.inMilliseconds / step.inMilliseconds).ceil();
  for (var i = 0; i < maxPumps; i++) {
    if (condition()) return;
    await tester.pump(step);
  }
  throw StateError('widget condition not met within ${timeout.inSeconds}s');
}

Future<void> _pumpRealReaderPage(
  WidgetTester tester,
  ReaderProvider provider,
) async {
  tester.view.physicalSize = _viewSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<ReaderProvider>.value(
      value: provider,
      child: MaterialApp(home: ReaderPage(book: provider.book)),
    ),
  );
  await tester.pump();
}

Future<void> _waitForReadyReaderWidget(
  WidgetTester tester,
  ReadBookController controller,
  int chapterIndex,
) async {
  try {
    await _pumpUntilWidgetCondition(tester, () {
      final runtimeChapter = controller.chapterAt(chapterIndex);
      return controller.isReady &&
          !controller.isLoading &&
          runtimeChapter != null &&
          runtimeChapter.pages.isNotEmpty &&
          !controller.hasChapterFailure(chapterIndex) &&
          find.byType(ScrollablePositionedList).evaluate().isNotEmpty;
    }, timeout: const Duration(seconds: 5));
  } on StateError catch (_) {
    throw StateError(
      'reader widget not ready '
      '(lifecycle=${controller.lifecycle}, isLoading=${controller.isLoading}, '
      'pages=${controller.pagesForChapter(chapterIndex).length}, '
      'hasList=${find.byType(ScrollablePositionedList).evaluate().isNotEmpty})',
    );
  }
}

Future<void> _dragReaderWidgetToTargetOffset(
  WidgetTester tester,
  ReaderProvider provider,
  double targetLocalOffset,
) async {
  final list = find.byType(ScrollablePositionedList);
  expect(list, findsOneWidget);

  for (var i = 0; i < 16; i++) {
    if (provider.visibleChapterIndex == _targetChapterIndex &&
        provider.visibleChapterLocalOffset >= targetLocalOffset) {
      return;
    }

    await tester.timedDrag(
      list,
      const Offset(0, -80),
      const Duration(milliseconds: 120),
    );
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  throw StateError(
    'widget scroll did not reach target localOffset=$targetLocalOffset '
    '(chapter=${provider.visibleChapterIndex}, '
    'localOffset=${provider.visibleChapterLocalOffset})',
  );
}

_ScrollRoundTripTarget _targetAfterTenAndHalfContentLines(
  ReaderChapter chapter,
) {
  final lines = <({double top, dynamic line})>[];
  for (var pageIndex = 0; pageIndex < chapter.pages.length; pageIndex++) {
    final pageTop = chapter.metrics.pageTopOffsets[pageIndex];
    for (final line in chapter.pages[pageIndex].lines) {
      if (line.image != null || line.isTitle || line.text.trim().isEmpty) {
        continue;
      }
      lines.add((top: pageTop + line.lineTop, line: line));
    }
  }

  if (lines.length <= _targetContentLineIndex) {
    throw StateError(
      '第 ${chapter.index + 1} 章實際排版後只有 ${lines.length} 行正文，'
      '不足以測第 ${_targetContentLineIndex + 1} 行中段',
    );
  }

  final target = lines[_targetContentLineIndex];
  final line = target.line;
  return _ScrollRoundTripTarget(
    localOffset: target.top + (line.height / 2),
    expectedCharOffset: line.chapterPosition as int,
    expectedRestoredLocalOffset: target.top,
    linePreview: line.text.toString(),
  );
}

String _extractFixtureChapterText(String fixtureText, String title) {
  final start = fixtureText.indexOf(title);
  if (start < 0) throw StateError('fixture 找不到章節: $title');
  final next = RegExp(
    r'\n第[一二三四五六七八九十]+章 ',
  ).firstMatch(fixtureText.substring(start + title.length));
  final end =
      next == null ? fixtureText.length : start + title.length + next.start;
  return fixtureText.substring(start + title.length, end).trim();
}

List<String> _chunkRunes(String text, int chunkSize) {
  final runes = text.runes.toList();
  final chunks = <String>[];
  for (var start = 0; start < runes.length; start += chunkSize) {
    final end =
        start + chunkSize > runes.length ? runes.length : start + chunkSize;
    chunks.add(String.fromCharCodes(runes.sublist(start, end)));
  }
  return chunks;
}

({Book book, List<BookChapter> chapters, List<TextPage> pages})
_buildWidgetFixture() {
  final fixtureText = File(_fixedLocalBookPath).readAsStringSync();
  final chapters = List<BookChapter>.generate(
    12,
    (index) => BookChapter(
      title: '第${index + 1}章 霧港來信',
      index: index,
      bookUrl: 'fixture://reader-widget-scroll',
      url: 'fixture://reader-widget-scroll/${index + 1}',
    ),
  );
  const chapterTitle = '第十章 霧港來信';
  final chapterText = _extractFixtureChapterText(
    fixtureText,
    chapterTitle,
  ).replaceAll(RegExp(r'\s+'), '');
  final chunks = _chunkRunes(chapterText, 24).take(44).toList();
  const linesPerPage = 22;
  const lineHeight = 28.0;
  const lineGap = 6.0;
  final pages = <TextPage>[];
  var charOffset = 0;
  for (var pageIndex = 0; pageIndex < 2; pageIndex++) {
    final lines = <TextLine>[];
    for (var lineInPage = 0; lineInPage < linesPerPage; lineInPage++) {
      final lineIndex = pageIndex * linesPerPage + lineInPage;
      if (lineIndex >= chunks.length) break;
      final text = chunks[lineIndex];
      final lineTop = lineInPage * (lineHeight + lineGap);
      lines.add(
        TextLine(
          text: text,
          width: 360,
          height: lineHeight,
          chapterPosition: charOffset,
          lineTop: lineTop,
          lineBottom: lineTop + lineHeight,
          paragraphNum: lineIndex + 1,
          isParagraphEnd: true,
        ),
      );
      charOffset += text.length;
    }
    pages.add(
      TextPage(
        index: pageIndex,
        title: chapterTitle,
        chapterIndex: _targetChapterIndex,
        pageSize: 2,
        lines: lines,
      ),
    );
  }
  return (
    book: Book(
      bookUrl: 'fixture://reader-widget-scroll',
      name: 'Widget 固定本地書',
      author: '測試',
      origin: 'fixture://local',
      originName: '固定本地測試書',
      durChapterIndex: _targetChapterIndex,
      durChapterPos: 0,
      isInBookshelf: true,
    ),
    chapters: chapters,
    pages: pages,
  );
}

Future<void> _expectRealScrollRoundTrip({
  required Book book,
  required List<BookChapter> chapters,
  BookSource? source,
}) async {
  expect(
    chapters.length,
    greaterThan(_targetChapterIndex),
    reason: '真實書籍至少要有 ${_targetChapterIndex + 1} 個可閱讀章節',
  );

  final liveBook = book.copyWith(
    durChapterIndex: _targetChapterIndex,
    durChapterPos: 0,
    readerAnchorJson: null,
    isInBookshelf: true,
  );
  final bookDao = _ReaderE2eBookDao();
  _installReaderE2eDi(bookDao: bookDao, chapters: chapters, source: source);
  await _prepareReaderPrefs();

  final firstController = ReadBookController(
    book: liveBook,
    initialLocation: const ReaderLocation(
      chapterIndex: _targetChapterIndex,
      charOffset: 0,
    ),
    initialChapters: chapters,
  );
  firstController.setViewSize(_viewSize);
  await _waitForReadyChapter(firstController, _targetChapterIndex);

  final firstRuntime = firstController.chapterAt(_targetChapterIndex)!;
  final target = _targetAfterTenAndHalfContentLines(firstRuntime);

  firstController.handleVisibleScrollState(
    chapterIndex: _targetChapterIndex,
    localOffset: target.localOffset,
    alignment: 0.0,
    visibleChapterIndexes: const [_targetChapterIndex],
    isAnchorConfirmed: true,
  );

  await firstController.persistExitProgress();

  expect(bookDao.updates, isNotEmpty);
  expect(bookDao.updates.last.chapterIndex, _targetChapterIndex);
  expect(bookDao.updates.last.pos, target.expectedCharOffset);
  expect(bookDao.updates.last.readerAnchorJson, isNotNull);
  expect(liveBook.durChapterIndex, _targetChapterIndex);
  expect(liveBook.durChapterPos, target.expectedCharOffset);
  firstController.dispose();

  _installReaderE2eDi(bookDao: bookDao, chapters: chapters, source: source);
  await _prepareReaderPrefs();

  final reopenedController = ReadBookController(
    book: liveBook,
    initialChapters: chapters,
  );
  reopenedController.setViewSize(_viewSize);
  await _waitForReadyChapter(reopenedController, _targetChapterIndex);

  expect(reopenedController.pageTurnMode, PageAnim.scroll);
  expect(reopenedController.currentChapterIndex, _targetChapterIndex);
  expect(reopenedController.visibleChapterIndex, _targetChapterIndex);
  expect(
    reopenedController.committedLocation,
    ReaderLocation(
      chapterIndex: _targetChapterIndex,
      charOffset: target.expectedCharOffset,
    ),
    reason: 'line="${target.linePreview}"',
  );
  expect(
    reopenedController.visibleChapterLocalOffset,
    closeTo(target.expectedRestoredLocalOffset, 1.0),
  );

  final restore = reopenedController.dispatchPendingScrollRestore();
  expect(restore, isNotNull);
  expect(restore!.chapterIndex, _targetChapterIndex);
  expect(restore.localOffset, closeTo(target.expectedRestoredLocalOffset, 1.0));

  reopenedController.dispose();
}

Future<void> _expectRealWidgetScrollRoundTrip({
  required WidgetTester tester,
  required Book book,
  required List<BookChapter> chapters,
  required List<TextPage> pages,
}) async {
  expect(
    chapters.length,
    greaterThan(_targetChapterIndex),
    reason: '真實書籍至少要有 ${_targetChapterIndex + 1} 個可閱讀章節',
  );

  final liveBook = book.copyWith(
    durChapterIndex: _targetChapterIndex,
    durChapterPos: 0,
    readerAnchorJson: null,
    isInBookshelf: true,
  );
  final bookDao = _ReaderE2eBookDao();
  _installReaderE2eDi(bookDao: bookDao, chapters: chapters);
  SharedPreferences.setMockInitialValues({
    PreferKey.readerPageTurnMode: PageAnim.scroll,
  });

  final firstProvider = _ReaderWidgetScrollProbe(
    book: liveBook,
    fixtureChapters: chapters,
    progressDao: bookDao,
  );
  firstProvider.primeScrollFixture(pages: pages);
  await _pumpRealReaderPage(tester, firstProvider);
  await _waitForReadyReaderWidget(tester, firstProvider, _targetChapterIndex);

  final firstRuntime = firstProvider.chapterAt(_targetChapterIndex)!;
  final target = _targetAfterTenAndHalfContentLines(firstRuntime);
  final initialLocalOffset = firstProvider.visibleChapterLocalOffset;

  await _dragReaderWidgetToTargetOffset(
    tester,
    firstProvider,
    target.localOffset,
  );

  expect(firstProvider.visibleChapterIndex, _targetChapterIndex);
  expect(
    firstProvider.visibleChapterLocalOffset,
    greaterThan(initialLocalOffset + 20),
    reason: 'widget drag 必須真的推動 ReadViewRuntime 的 scroll listener',
  );

  final savedLocalOffset = firstProvider.visibleChapterLocalOffset;
  final expectedCharOffset = firstRuntime.charOffsetFromLocalOffset(
    savedLocalOffset,
  );
  final expectedRestoredLocalOffset = firstRuntime.localOffsetFromCharOffset(
    expectedCharOffset,
  );

  await firstProvider.persistExitProgress();
  expect(bookDao.updates, isNotEmpty);
  expect(bookDao.updates.last.chapterIndex, _targetChapterIndex);
  expect(bookDao.updates.last.pos, expectedCharOffset);
  expect(bookDao.updates.last.readerAnchorJson, isNotNull);
  expect(liveBook.durChapterIndex, _targetChapterIndex);
  expect(liveBook.durChapterPos, expectedCharOffset);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  firstProvider.dispose();

  _installReaderE2eDi(bookDao: bookDao, chapters: chapters);
  SharedPreferences.setMockInitialValues({
    PreferKey.readerPageTurnMode: PageAnim.scroll,
  });

  final reopenedProvider = _ReaderWidgetScrollProbe(
    book: liveBook,
    fixtureChapters: chapters,
    progressDao: bookDao,
  );
  reopenedProvider.primeScrollFixture(
    pages: pages,
    initialCharOffset: expectedCharOffset,
    queueRestore: true,
  );
  await _pumpRealReaderPage(tester, reopenedProvider);
  reopenedProvider.notifyListeners();
  await tester.pump();
  await _waitForReadyReaderWidget(
    tester,
    reopenedProvider,
    _targetChapterIndex,
  );
  final expectedVisibleLocalOffset =
      expectedRestoredLocalOffset + reopenedProvider.scrollRestoreAnchorPadding;

  try {
    await _pumpUntilWidgetCondition(
      tester,
      () =>
          !reopenedProvider.isScrollRestoreUnconfirmed &&
          reopenedProvider.visibleChapterIndex == _targetChapterIndex &&
          (reopenedProvider.visibleChapterLocalOffset -
                      expectedVisibleLocalOffset)
                  .abs() <
              80,
      timeout: const Duration(seconds: 20),
    );
  } on StateError catch (_) {
    throw StateError(
      'widget restore not complete '
      '(pending=${reopenedProvider.hasPendingScrollRestore}, '
      'active=${reopenedProvider.activeCommandReason}, '
      'phase=${reopenedProvider.sessionPhase}, '
      'chapter=${reopenedProvider.visibleChapterIndex}, '
      'local=${reopenedProvider.visibleChapterLocalOffset}, '
      'expectedLocal=$expectedVisibleLocalOffset, '
      'committed=${reopenedProvider.committedLocation})',
    );
  }

  expect(reopenedProvider.pageTurnMode, PageAnim.scroll);
  expect(reopenedProvider.currentChapterIndex, _targetChapterIndex);
  expect(reopenedProvider.visibleChapterIndex, _targetChapterIndex);
  expect(
    reopenedProvider.committedLocation,
    ReaderLocation(
      chapterIndex: _targetChapterIndex,
      charOffset: expectedCharOffset,
    ),
    reason: 'line="${target.linePreview}"',
  );
  expect(
    reopenedProvider.visibleChapterLocalOffset,
    closeTo(expectedVisibleLocalOffset, 80),
  );

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  reopenedProvider.dispose();
}

Future<(Book book, List<BookChapter> chapters)> _loadRealLocalBook() async {
  final path = _env('REAL_LOCAL_BOOK_PATH') ?? File(_fixedLocalBookPath).path;
  final result = await LocalBookService().importBook(path);
  if (result == null) {
    throw StateError('本地書不存在或無法匯入: $path');
  }
  return (result.book, result.chapters);
}

BookSource _fixedNetworkSource() => BookSource.fromJson(<String, dynamic>{
  'bookSourceComment': '',
  'bookSourceGroup': '',
  'bookSourceName': '随心看吧',
  'bookSourceType': 0,
  'bookSourceUrl': 'https://m.suixkan.com#♤guaner',
  'customOrder': 2,
  'enabled': true,
  'enabledCookieJar': true,
  'enabledExplore': true,
  'lastUpdateTime': 1721279493711,
  'respondTime': 7163,
  'ruleBookInfo': <String, dynamic>{
    'kind': '',
    'tocUrl': 'class.sumchapter@a@href',
  },
  'ruleContent': <String, dynamic>{
    'content': 'class.con@html',
    'nextContentUrl': '',
    'replaceRegex': r'##\s*.*?本章.*?完.*\s*',
  },
  'ruleExplore': <String, dynamic>{},
  'ruleSearch': <String, dynamic>{
    'author': '.v-author@text',
    'bookList':
        'class.v-list-item\n'
        '@js:\n'
        'list=result.toArray();\n'
        'list1=[];\n'
        'for(i in list){\n'
        "if(list[i].text().indexOf(java.get('key'))>-1){\n"
        'list1.push(list[i])\n'
        '}\n'
        '}\n'
        'list1.map(x=>x)',
    'bookUrl': r'''##="newWebView\('([^']+)'##$1###''',
    'coverUrl': '',
    'intro': '.v-intro@text',
    'kind': 'tag.div.-1@text',
    'lastChapter':
        '<js>\n'
        "url=String(result).match(/=\"newWebView\\('([^']+)'/)[1];url='https://m.suixkan.com'+url\n"
        'java.ajax(url)</js>\n'
        'class.chapter-entrance@text',
    'name': '.v-title@text',
    'wordCount': '.v-words@text',
  },
  'ruleToc': <String, dynamic>{
    'chapterList': 'class.catalog_ls@li@a',
    'chapterName': 'text',
    'chapterUrl': 'href',
  },
  'searchUrl':
      'https://m.suixkan.com/s/1.html?keyword={{key}}\n'
      "@js:java.put('key',key);result",
  'weight': 0,
});

Future<(BookSource source, Book book, List<BookChapter> chapters)>
_tryLoadRealNetworkBookFromSource({
  required BookSourceService service,
  required BookSource source,
}) async {
  if (!source.isNovelTextSource) {
    throw StateError(source.nonNovelExclusionReason ?? '非文字小說書源');
  }

  final directBookUrl = _env('REAL_NETWORK_BOOK_URL') ?? _env('BOOK_URL');
  final directBookName = _env('REAL_NETWORK_BOOK_NAME') ?? _env('BOOK_NAME');
  late final Book selectedBook;

  if (directBookUrl != null) {
    selectedBook = Book(
      bookUrl: directBookUrl,
      name: directBookName ?? 'live network book',
      origin: source.bookSourceUrl,
      originName: source.bookSourceName,
      isInBookshelf: true,
    );
  } else {
    final keyword =
        _env('REAL_NETWORK_BOOK_KEYWORD') ??
        _env('KEYWORD') ??
        _fixedNetworkKeyword;
    final searchBooks = await service.searchBooks(source, keyword);
    if (searchBooks.isEmpty) {
      throw StateError('固定書源 ${source.bookSourceName} 搜尋 "$keyword" 無結果');
    }
    final matched =
        selectMatchingSearchBook(searchBooks, keyword) ?? searchBooks.first;
    selectedBook = matched.toBook();
  }

  final hydrated = await service.getBookInfo(source, selectedBook);
  final book = hydrated.copyWith(
    origin: source.bookSourceUrl,
    originName: source.bookSourceName,
    isInBookshelf: true,
  );
  final rawChapters = await service.getChapterList(
    source,
    book,
    chapterLimit: 64,
    pageConcurrency: validationPageConcurrency,
  );
  final readableChapters =
      rawChapters
          .where((chapter) => !chapter.isVolume)
          .toList()
          .asMap()
          .entries
          .map(
            (entry) =>
                entry.value.copyWith(index: entry.key, bookUrl: book.bookUrl),
          )
          .toList();

  if (readableChapters.length <= _targetChapterIndex) {
    throw StateError('可閱讀章節不足 ${_targetChapterIndex + 1} 章');
  }

  final targetChapter = readableChapters[_targetChapterIndex];
  final targetContent = await service.getContent(
    source,
    book,
    targetChapter,
    pageConcurrency: validationPageConcurrency,
    nextChapterUrl:
        readableChapters.length > _targetChapterIndex + 1
            ? readableChapters[_targetChapterIndex + 1].url
            : null,
  );
  if (looksLikeLoginRequiredContent(targetContent)) {
    throw StateError('第十章正文需要登入後閱讀');
  }
  if (!looksReadable(targetContent)) {
    throw StateError('第十章正文不可讀');
  }
  if (targetContent.trim().runes.length < 300) {
    throw StateError('第十章正文太短，不足以測第 10.5 行');
  }
  readableChapters[_targetChapterIndex] = targetChapter.copyWith(
    content: targetContent,
  );

  // ignore: avoid_print
  print(
    '[real-e2e] fixed source ${source.bookSourceName} '
    'book="${book.name}" chapters=${readableChapters.length}',
  );
  return (source, book, readableChapters);
}

Future<(BookSource source, Book book, List<BookChapter> chapters)>
_loadRealNetworkBook() async {
  await initSourceValidationEnvironment();
  final service = BookSourceService();

  return _tryLoadRealNetworkBookFromSource(
    service: service,
    source: _fixedNetworkSource(),
  ).timeout(
    Duration(
      seconds: int.tryParse(_env('REAL_SOURCE_TIMEOUT_SECONDS') ?? '') ?? 45,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reader_real_e2e_');
    _mockPlatformChannels(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Reader real book live E2E', () {
    test(
      '真實本地書：匯入後 scroll 到第十個章節第 10.5 行，退出再進入會還原',
      () async {
        final (book, chapters) = await _loadRealLocalBook();
        await _expectRealScrollRoundTrip(book: book, chapters: chapters);
      },
      skip: _skipUnlessRealE2e(null),
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets(
      '真 UI widget：拖動 scroll view 後退出再進入會還原到章節中段',
      (tester) async {
        final fixture = _buildWidgetFixture();
        await _expectRealWidgetScrollRoundTrip(
          tester: tester,
          book: fixture.book,
          chapters: fixture.chapters,
          pages: fixture.pages,
        );
      },
      skip: !_runRealE2e,
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      '真實網路書源：抓書源書籍後 scroll 到第十個可閱讀章節第 10.5 行，退出再進入會還原',
      () async {
        final (source, book, chapters) = await _loadRealNetworkBook();
        await _expectRealScrollRoundTrip(
          book: book,
          chapters: chapters,
          source: source,
        );
      },
      skip: _skipUnlessRealE2e(null),
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
