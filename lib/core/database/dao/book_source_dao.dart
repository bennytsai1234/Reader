import 'package:drift/drift.dart';
import '../../models/book_source.dart';
import '../tables/app_tables.dart';
import '../app_database.dart';

part 'book_source_dao.g.dart';

@DriftAccessor(tables: [BookSources])
class BookSourceDao extends DatabaseAccessor<AppDatabase> with _$BookSourceDaoMixin {
  BookSourceDao(super.db);

  Future<List<BookSource>> getAll() => select(bookSources).get();

  Stream<List<BookSource>> watchAll() => select(bookSources).watch();

  Future<List<BookSource>> getEnabled() {
    return (select(bookSources)..where((t) => t.enabled.equals(true))).get();
  }

  Future<BookSource?> getByUrl(String url) {
    return (select(bookSources)..where((t) => t.bookSourceUrl.equals(url))).getSingleOrNull();
  }

  Future<void> upsert(BookSource source) => into(bookSources).insertOnConflictUpdate(BookSourceToInsertable(source).toInsertable());

  Future<void> upsertAll(List<BookSource> sources) async {
    await batch((b) => b.insertAllOnConflictUpdate(bookSources, sources.map((e) => BookSourceToInsertable(e).toInsertable()).toList()));
  }

  Future<void> deleteByUrl(String url) =>
      (delete(bookSources)..where((t) => t.bookSourceUrl.equals(url))).go();

  Future<void> deleteByUrls(List<String> urls) =>
      (delete(bookSources)..where((t) => t.bookSourceUrl.isIn(urls))).go();

  Future<List<BookSource>> getAllPart() => getAll();
  Future<List<BookSource>> getAllFull() => getAll();

  Future<void> insertOrUpdateAll(List<BookSource> sources) => upsertAll(sources);

  Future<void> updateCustomOrder(List<BookSource> sources) async {
    for (var i = 0; i < sources.length; i++) {
      await (update(bookSources)..where((t) => t.bookSourceUrl.equals(sources[i].bookSourceUrl)))
          .write(BookSourcesCompanion(customOrder: Value(i)));
    }
  }

  Future<void> renameGroup(String oldName, String newName) async {
    final all = await getAll();
    for (final s in all) {
      if (s.bookSourceGroup == null) continue;
      final groups = s.bookSourceGroup!.split(RegExp(r'[,，]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (groups.contains(oldName)) {
        final updated = groups.map((g) => g == oldName ? newName : g).join(',');
        await (update(bookSources)..where((t) => t.bookSourceUrl.equals(s.bookSourceUrl)))
            .write(BookSourcesCompanion(bookSourceGroup: Value(updated)));
      }
    }
  }

  Future<void> removeGroupLabel(String name) async {
    final all = await getAll();
    for (final s in all) {
      if (s.bookSourceGroup == null) continue;
      final groups = s.bookSourceGroup!
          .split(RegExp(r'[,，]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e != name)
          .toList();
      final updated = groups.join(',');
      await (update(bookSources)..where((t) => t.bookSourceUrl.equals(s.bookSourceUrl)))
          .write(BookSourcesCompanion(bookSourceGroup: Value(updated.isEmpty ? null : updated)));
    }
  }

  Future<void> adjustSortNumbers() async {
    final all = await (select(bookSources)
          ..orderBy([(t) => OrderingTerm(expression: t.customOrder)]))
        .get();
    for (var i = 0; i < all.length; i++) {
      if (all[i].customOrder != i) {
        await (update(bookSources)..where((t) => t.bookSourceUrl.equals(all[i].bookSourceUrl)))
            .write(BookSourcesCompanion(customOrder: Value(i)));
      }
    }
  }
}
