import 'package:drift/drift.dart';
import '../../models/chapter.dart';
import '../tables/app_tables.dart';
import '../app_database.dart';

part 'chapter_dao.g.dart';

@DriftAccessor(tables: [Chapters])
class ChapterDao extends DatabaseAccessor<AppDatabase> with _$ChapterDaoMixin {
  ChapterDao(super.db);

  Future<List<BookChapter>> getByBook(String bookUrl) {
    return (select(chapters)
          ..where((t) => t.bookUrl.equals(bookUrl))
          ..orderBy([(t) => OrderingTerm(expression: t.index)]))
        .get();
  }

  Stream<List<BookChapter>> watchByBook(String bookUrl) {
    return (select(chapters)
          ..where((t) => t.bookUrl.equals(bookUrl))
          ..orderBy([(t) => OrderingTerm(expression: t.index)]))
        .watch();
  }

  Future<void> insertChapters(List<BookChapter> chapterList) async {
    await batch(
      (b) => b.insertAllOnConflictUpdate(
        chapters,
        chapterList
            .map((e) => BookChapterToInsertable(e).toInsertable())
            .toList(),
      ),
    );
  }

  Future<BookChapter?> getChapter(String bookUrl, int index) {
    return (select(chapters)..where(
      (t) => t.bookUrl.equals(bookUrl) & t.index.equals(index),
    )).getSingleOrNull();
  }

  Future<void> updateContent(String url, String content) {
    return (update(chapters)..where(
      (t) => t.url.equals(url),
    )).write(ChaptersCompanion(content: Value(content)));
  }

  Future<void> deleteByBook(String bookUrl) {
    return (delete(chapters)..where((t) => t.bookUrl.equals(bookUrl))).go();
  }

  Future<List<BookChapter>> getChapters(String bookUrl) => getByBook(bookUrl);

  Future<bool> hasContent(String url) async {
    final c =
        await (select(chapters)
          ..where((t) => t.url.equals(url))).getSingleOrNull();
    return c != null && (c.content?.isNotEmpty ?? false);
  }

  Future<String?> getContent(String url) async {
    final c =
        await (select(chapters)
          ..where((t) => t.url.equals(url))).getSingleOrNull();
    final content = c?.content;
    return (content == null || content.isEmpty) ? null : content;
  }

  Future<void> saveContent(String url, String content) =>
      updateContent(url, content);

  Future<void> deleteContentByBook(String bookUrl) {
    return (update(chapters)..where(
      (t) => t.bookUrl.equals(bookUrl),
    )).write(const ChaptersCompanion(content: Value(null)));
  }

  Future<void> clearAllContent() =>
      update(chapters).write(const ChaptersCompanion(content: Value(null)));

  Future<int> getTotalContentSize() async {
    final rows =
        await customSelect(
          'SELECT COALESCE(SUM(LENGTH(content)), 0) as total FROM chapters WHERE content IS NOT NULL AND content != ""',
          readsFrom: {chapters},
        ).get();
    if (rows.isEmpty) return 0;
    return rows.first.read<int>('total');
  }

  Future<Set<int>> getCachedChapterIndices(String bookUrl) async {
    final rows =
        await customSelect(
          'SELECT "index" FROM chapters WHERE bookUrl = ? AND content IS NOT NULL AND content != ""',
          variables: [Variable.withString(bookUrl)],
          readsFrom: {chapters},
        ).get();
    return rows.map((row) => row.read<int>('index')).toSet();
  }
}
