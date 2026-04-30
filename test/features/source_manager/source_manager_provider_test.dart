import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkpage_reader/core/constant/source_type.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/services/network_service.dart';
import 'package:inkpage_reader/features/source_manager/source_manager_provider.dart';

const _nyasamaSourceUrl =
    'https://shuyuan.nyasama.net/shuyuan/382015f6ff010d7fee368c6daabd5081.json';
const _nyasamaFixturePath =
    'test/features/source_manager/fixtures/nyasama_sources_subset.json';

Future<String> _readFixture(String path) => File(path).readAsString();

class _FakeSourceDao extends Fake implements BookSourceDao {
  final Map<String, BookSource> store = <String, BookSource>{};
  int getByUrlCallCount = 0;

  @override
  Future<List<BookSource>> getAllPart() async => store.values.toList();

  @override
  Future<List<BookSource>> getAll() async => store.values.toList();

  @override
  Future<BookSource?> getByUrl(String url) async {
    getByUrlCallCount += 1;
    return store[url];
  }

  @override
  Future<void> upsert(BookSource source) async {
    store[source.bookSourceUrl] = source;
  }

  @override
  Future<void> insertOrUpdateAll(List<BookSource> sources) async {
    for (final source in sources) {
      store[source.bookSourceUrl] = source;
    }
  }

  @override
  Future<void> deleteByUrls(List<String> urls) async {
    for (final url in urls) {
      store.remove(url);
    }
  }
}

class _FakeNetworkService extends Fake implements NetworkService {
  _FakeNetworkService(this.body);

  final String body;

  @override
  Dio get dio => Dio()..httpClientAdapter = _StaticResponseAdapter(body);
}

class _StaticResponseAdapter implements HttpClientAdapter {
  _StaticResponseAdapter(this.body);

  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/plain; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeSourceDao fakeDao;
  late String networkBody;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    fakeDao = _FakeSourceDao();
    networkBody = '';
    GetIt.instance.registerLazySingleton<BookSourceDao>(() => fakeDao);
    GetIt.instance.registerLazySingleton<NetworkService>(
      () => _FakeNetworkService(networkBody),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('parseSources supports Legado source arrays', () {
    final provider = SourceManagerProvider();
    final jsonStr = jsonEncode([
      {
        'bookSourceName': 'BB成人小说',
        'bookSourceUrl': 'https://bbxxxx.com',
        'searchUrl': '/search/?q={{key}}&page={{page}}',
        'enabled': true,
        'enabledExplore': true,
        'ruleSearch': {
          'bookList': 'class.novel-item',
          'name': 'class.info@tag.a@text',
          'bookUrl': 'class.info@tag.a@href',
        },
      },
      {
        'bookSourceName': '第二个书源',
        'bookSourceUrl': 'https://example.com',
        'searchUrl': '/search?q={{key}}',
        'enabled': true,
      },
    ]);

    final parsed = provider.parseSources(jsonStr);

    expect(parsed, hasLength(2));
    expect(parsed.first.bookSourceName, 'BB成人小说');
    expect(parsed.first.bookSourceUrl, 'https://bbxxxx.com');
    expect(parsed.first.ruleSearch?.bookList, 'class.novel-item');
    expect(parsed[1].bookSourceName, '第二个书源');
  });

  test('parseSources supports nyasama source fixture subset', () async {
    final provider = SourceManagerProvider();
    final jsonStr = await _readFixture(_nyasamaFixturePath);

    final parsed = provider.parseSources(jsonStr);

    expect(parsed, hasLength(4));
    expect(parsed.first.bookSourceName, 'BB成人小说');
    expect(parsed.first.bookSourceType, SourceType.book);
    expect(parsed.first.ruleSearch?.bookList, 'class.novel-item');
    expect(parsed[2].searchUrl, contains('@js:java.put'));
    expect(parsed[3].bookSourceUrl, 'https://app.kujiang.com#🎃');
  });

  test(
    'parseSourcesDetailedAsync supports nyasama source fixture subset',
    () async {
      final provider = SourceManagerProvider();
      final jsonStr = await _readFixture(_nyasamaFixturePath);

      final parsed = await provider.parseSourcesDetailedAsync(jsonStr);

      expect(parsed.allSources, hasLength(4));
      expect(parsed.importableSources.first.bookSourceName, 'BB成人小说');
      expect(parsed.importableSources[2].searchUrl, contains('@js:java.put'));
    },
  );

  test(
    'importFromUrl imports nyasama raw JSON string without double encoding',
    () async {
      networkBody = await _readFixture(_nyasamaFixturePath);
      final provider = SourceManagerProvider();

      final count = await provider.importFromUrl(_nyasamaSourceUrl);

      expect(count, 4);
      expect(fakeDao.store.keys, contains('https://bbxxxx.com'));
      expect(
        fakeDao.store['https://m.suixkan.com#♤guaner']?.ruleSearch?.bookUrl,
        '##="newWebView\\(\'([^\']+)\'##\$1###',
      );
    },
  );

  test('importPayloadToText strips BOM and decodes bytes', () {
    final provider = SourceManagerProvider();
    final payload = utf8.encode('\uFEFF[{"bookSourceName":"A"}]');

    final text = provider.importPayloadToTextForTest(payload);

    expect(text, '[{"bookSourceName":"A"}]');
  });

  test(
    'parseSourcesDetailed preserves unsupported sources as disabled entries',
    () {
      final provider = SourceManagerProvider();
      final jsonStr = jsonEncode([
        {
          'bookSourceName': '純小說站',
          'bookSourceUrl': 'https://novel.example.com',
          'bookSourceType': SourceType.book,
        },
        {
          'bookSourceName': '有聲站',
          'bookSourceUrl': 'https://audio.example.com',
          'bookSourceType': SourceType.audio,
        },
        {
          'bookSourceName': '漫畫站',
          'bookSourceUrl': 'https://comic.example.com',
          'bookSourceType': SourceType.book,
        },
      ]);

      final parsed = provider.parseSourcesDetailed(jsonStr);

      expect(parsed.importableSources, hasLength(1));
      expect(parsed.importableSources.single.bookSourceName, '純小說站');
      expect(parsed.unsupportedSources, hasLength(2));
      expect(parsed.allSources, hasLength(3));
      expect(parsed.unsupportedSources.first.enabled, isFalse);
      expect(
        parsed.unsupportedSources.first.bookSourceGroup,
        contains(nonNovelSourceGroupTag),
      );
    },
  );

  test(
    'checkAllSources uses all stored sources instead of current filter',
    () async {
      fakeDao.store['https://enabled.example.com'] = BookSource(
        bookSourceUrl: 'https://enabled.example.com',
        bookSourceName: '啟用源',
        bookSourceType: SourceType.book,
        enabled: true,
      );
      fakeDao.store['https://disabled.example.com'] = BookSource(
        bookSourceUrl: 'https://disabled.example.com',
        bookSourceName: '停用源',
        bookSourceType: SourceType.book,
        enabled: false,
      );

      final provider = SourceManagerProvider();
      await provider.loadSources();
      provider.setFilterGroup('已啟用');

      await provider.checkAllSources();

      expect(provider.lastCheckReport.total, 2);
    },
  );

  test(
    'previewImport keeps unsupported new sources in import buckets',
    () async {
      final provider = SourceManagerProvider();
      final novelSource = BookSource(
        bookSourceUrl: 'https://novel.example.com',
        bookSourceName: '小說源',
        bookSourceType: SourceType.book,
      );
      final unsupportedSource = BookSource(
        bookSourceUrl: 'https://audio.example.com',
        bookSourceName: '有聲源',
        bookSourceType: SourceType.audio,
        enabled: false,
        enabledExplore: false,
        bookSourceGroup: nonNovelSourceGroupTag,
      );

      final preview = await provider.previewImport(
        [novelSource, unsupportedSource],
        unsupportedSources: [unsupportedSource],
      );

      expect(fakeDao.getByUrlCallCount, 0);
      expect(preview.newSources, hasLength(2));
      expect(preview.unsupportedSources, [unsupportedSource]);
    },
  );

  test('deleteNonNovelSources removes existing non-novel sources', () async {
    fakeDao.store['https://novel.example.com'] = BookSource(
      bookSourceUrl: 'https://novel.example.com',
      bookSourceName: '小說源',
      bookSourceType: SourceType.book,
    );
    fakeDao.store['https://audio.example.com'] = BookSource(
      bookSourceUrl: 'https://audio.example.com',
      bookSourceName: '有聲源',
      bookSourceType: SourceType.audio,
      enabledExplore: true,
    );
    fakeDao.store['https://comic.example.com'] = BookSource(
      bookSourceUrl: 'https://comic.example.com',
      bookSourceName: '漫畫源',
      bookSourceType: SourceType.book,
      enabledExplore: true,
    );

    final provider = SourceManagerProvider();
    final affected = await provider.deleteNonNovelSources();

    expect(affected, 2);
    expect(fakeDao.store.keys, contains('https://novel.example.com'));
    expect(fakeDao.store.keys, isNot(contains('https://audio.example.com')));
    expect(fakeDao.store.keys, isNot(contains('https://comic.example.com')));
  });

  test('clearInvalidSources removes login-required sources', () async {
    fakeDao.store['https://valid.example.com'] = BookSource(
      bookSourceUrl: 'https://valid.example.com',
      bookSourceName: '正常源',
      bookSourceType: SourceType.book,
    );
    fakeDao.store['https://login.example.com'] = BookSource(
      bookSourceUrl: 'https://login.example.com',
      bookSourceName: '登入牆源',
      bookSourceType: SourceType.book,
      bookSourceGroup: loginRequiredSourceGroupTag,
    );
    fakeDao.store['https://search-broken.example.com'] = BookSource(
      bookSourceUrl: 'https://search-broken.example.com',
      bookSourceName: '搜尋失效源',
      bookSourceType: SourceType.book,
      bookSourceGroup: searchBrokenSourceGroupTag,
    );

    final provider = SourceManagerProvider();
    await provider.clearInvalidSources();

    expect(fakeDao.store.keys, contains('https://valid.example.com'));
    expect(fakeDao.store.keys, isNot(contains('https://login.example.com')));
    expect(fakeDao.store.keys, contains('https://search-broken.example.com'));
  });

  test('filterGroup supports enabled and disabled explore buckets', () async {
    fakeDao.store['https://explore-on.example.com'] = BookSource(
      bookSourceUrl: 'https://explore-on.example.com',
      bookSourceName: '可發現源',
      bookSourceType: SourceType.book,
      exploreUrl: '/explore',
      enabledExplore: true,
    );
    fakeDao.store['https://explore-off.example.com'] = BookSource(
      bookSourceUrl: 'https://explore-off.example.com',
      bookSourceName: '停用發現源',
      bookSourceType: SourceType.book,
      exploreUrl: '/explore',
      enabledExplore: false,
    );

    final provider = SourceManagerProvider();
    await provider.loadSources();

    provider.setFilterGroup('已啟用發現');
    expect(provider.sources.map((source) => source.bookSourceUrl), [
      'https://explore-on.example.com',
    ]);

    provider.setFilterGroup('已禁用發現');
    expect(provider.sources.map((source) => source.bookSourceUrl), [
      'https://explore-off.example.com',
    ]);
  });

  test(
    'checkSelectedInterval selects sources between first and last selection',
    () async {
      for (var index = 0; index < 4; index++) {
        fakeDao.store['https://$index.example.com'] = BookSource(
          bookSourceUrl: 'https://$index.example.com',
          bookSourceName: '源$index',
          bookSourceType: SourceType.book,
          customOrder: index,
        );
      }

      final provider = SourceManagerProvider();
      await provider.loadSources();

      provider.toggleSelect('https://0.example.com');
      provider.toggleSelect('https://2.example.com');
      provider.checkSelectedInterval();

      expect(
        provider.selectedUrls,
        containsAll(<String>[
          'https://0.example.com',
          'https://1.example.com',
          'https://2.example.com',
        ]),
      );
    },
  );
}
