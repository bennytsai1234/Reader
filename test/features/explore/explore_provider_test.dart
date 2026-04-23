import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/source/explore_kind.dart';
import 'package:inkpage_reader/features/explore/explore_provider.dart';

class _FakeSourceDao extends Fake implements BookSourceDao {
  List<BookSource> sources = [];
  final StreamController<List<BookSource>> _controller =
      StreamController<List<BookSource>>.broadcast();

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((source) => source.enabled).toList();

  @override
  Future<List<BookSource>> getAll() async => List<BookSource>.from(sources);

  @override
  Stream<List<BookSource>> watchAll() => _controller.stream;

  void pushSources(List<BookSource> nextSources) {
    sources = List<BookSource>.from(nextSources);
    _controller.add(List<BookSource>.from(sources));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

Future<void> _settleAsync() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSourceDao fakeSourceDao;

  setUp(() {
    fakeSourceDao = _FakeSourceDao();
    addTearDown(fakeSourceDao.dispose);
  });

  test('toggleExpand waits for async kinds and reuses cache', () async {
    fakeSourceDao.sources = [
      BookSource(
        bookSourceUrl: 'source://bb',
        bookSourceName: 'BB成人小说',
        enabledExplore: true,
        exploreUrl: '<js>java.ajax("https://bbxxxx.com/")</js>',
      ),
    ];

    final kindsCompleter = Completer<List<ExploreKind>>();
    var loaderCalls = 0;
    final provider = ExploreProvider(
      sourceDao: fakeSourceDao,
      kindsLoader: (exploreUrl, {source}) async {
        loaderCalls++;
        expect(exploreUrl, contains('java.ajax'));
        expect(source?.bookSourceUrl, 'source://bb');
        return kindsCompleter.future;
      },
    );
    addTearDown(provider.dispose);

    await _settleAsync();
    expect(provider.sources, hasLength(1));

    final expandFuture = provider.toggleExpand(0);
    expect(provider.expandedIndex, 0);
    expect(provider.isLoadingKinds, isTrue);
    expect(provider.expandedKinds, isEmpty);

    kindsCompleter.complete([
      ExploreKind(
        title: '最新',
        url: 'https://bbxxxx.com/rank/new/{{page}}.html',
      ),
    ]);
    await expandFuture;

    expect(provider.isLoadingKinds, isFalse);
    expect(provider.expandedKinds, [
      ExploreKind(
        title: '最新',
        url: 'https://bbxxxx.com/rank/new/{{page}}.html',
      ),
    ]);
    expect(loaderCalls, 1);

    await provider.toggleExpand(0);
    expect(provider.expandedIndex, -1);

    await provider.toggleExpand(0);
    expect(provider.isLoadingKinds, isFalse);
    expect(provider.expandedKinds, hasLength(1));
    expect(loaderCalls, 1);
  });

  test('refreshKindsCache reloads currently expanded source', () async {
    fakeSourceDao.sources = [
      BookSource(
        bookSourceUrl: 'source://bb',
        bookSourceName: 'BB成人小说',
        enabledExplore: true,
        exploreUrl: '最新::https://example.com/new',
      ),
    ];

    final responses = <List<ExploreKind>>[
      [ExploreKind(title: '最新', url: 'https://example.com/new')],
      [ExploreKind(title: '熱門', url: 'https://example.com/hot')],
    ];
    var loaderCalls = 0;
    final provider = ExploreProvider(
      sourceDao: fakeSourceDao,
      kindsLoader: (exploreUrl, {source}) async => responses[loaderCalls++],
    );
    addTearDown(provider.dispose);

    await _settleAsync();
    await provider.toggleExpand(0);
    expect(provider.expandedKinds.first.title, '最新');
    expect(loaderCalls, 1);

    await provider.refreshKindsCache(provider.sources.first);
    expect(provider.expandedKinds.first.title, '熱門');
    expect(loaderCalls, 2);
  });

  test(
    'watchAll refreshes sources after import without recreating provider',
    () async {
      fakeSourceDao.sources = [
        BookSource(
          bookSourceUrl: 'source://one',
          bookSourceName: '第一個書源',
          enabled: true,
          enabledExplore: true,
          exploreUrl: '最新::https://example.com/one',
        ),
      ];

      final provider = ExploreProvider(
        sourceDao: fakeSourceDao,
        kindsLoader: (exploreUrl, {source}) async => const [],
      );
      addTearDown(provider.dispose);

      await _settleAsync();
      expect(provider.sources.map((source) => source.bookSourceUrl), [
        'source://one',
      ]);

      fakeSourceDao.pushSources([
        ...fakeSourceDao.sources,
        BookSource(
          bookSourceUrl: 'source://two',
          bookSourceName: '第二個書源',
          enabled: true,
          enabledExplore: true,
          exploreUrl: '最新::https://example.com/two',
        ),
      ]);

      await _settleAsync();
      expect(provider.sources.map((source) => source.bookSourceUrl), [
        'source://one',
        'source://two',
      ]);
    },
  );

  test('filters out imported unsupported discovery sources', () async {
    fakeSourceDao.sources = [
      BookSource(
        bookSourceUrl: 'source://novel',
        bookSourceName: '小說源',
        enabled: true,
        enabledExplore: true,
        exploreUrl: '最新::https://example.com/novel',
      ),
      BookSource(
        bookSourceUrl: 'source://audio',
        bookSourceName: '有聲源',
        bookSourceType: 1,
        enabled: true,
        enabledExplore: true,
        exploreUrl: '最新::https://example.com/audio',
      )..addGroup(nonNovelSourceGroupTag),
    ];

    final provider = ExploreProvider(
      sourceDao: fakeSourceDao,
      kindsLoader: (exploreUrl, {source}) async => const [],
    );
    addTearDown(provider.dispose);

    await _settleAsync();

    expect(provider.sources.map((source) => source.bookSourceUrl), [
      'source://novel',
    ]);
  });
}
