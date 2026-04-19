import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/features/source_manager/source_manager_provider.dart';

class _FakeSourceDao extends Fake implements BookSourceDao {
  @override
  Future<List<BookSource>> getAllPart() async => [];
}

void main() {
  setUp(() {
    GetIt.instance.registerLazySingleton<BookSourceDao>(() => _FakeSourceDao());
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
}
