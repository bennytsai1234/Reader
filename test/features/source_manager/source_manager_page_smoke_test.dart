import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/features/source_manager/source_manager_page.dart';
import 'package:inkpage_reader/features/source_manager/source_manager_provider.dart';

class _FakeSourceDao extends Fake implements BookSourceDao {
  @override
  Future<List<BookSource>> getAllPart() async => <BookSource>[];

  @override
  Future<List<BookSource>> getAll() async => <BookSource>[];

  @override
  Future<BookSource?> getByUrl(String url) async => null;
}

void main() {
  setUp(() {
    GetIt.instance.registerLazySingleton<BookSourceDao>(() => _FakeSourceDao());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('SourceManagerPage can render with the new check result flow', (
    tester,
  ) async {
    final provider = SourceManagerProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SourceManagerProvider>.value(
        value: provider,
        child: const MaterialApp(home: SourceManagerPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('書源管理'), findsOneWidget);
    expect(find.text('暫無書源'), findsOneWidget);
  });
}
