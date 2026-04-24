import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';

part 'reader_temp_chapter_cache_dao.g.dart';

@DriftAccessor(tables: [ReaderTempChapterCaches])
class ReaderTempChapterCacheDao extends DatabaseAccessor<AppDatabase>
    with _$ReaderTempChapterCacheDaoMixin {
  ReaderTempChapterCacheDao(super.db);

  Future<String?> getContent({
    required String cacheKey,
    int? minUpdatedAt,
  }) async {
    final query = select(readerTempChapterCaches)
      ..where((t) => t.cacheKey.equals(cacheKey));
    if (minUpdatedAt != null) {
      query.where((t) => t.updatedAt.isBiggerOrEqualValue(minUpdatedAt));
    }
    final row = await query.getSingleOrNull();
    final content = row?.content;
    return content == null || content.isEmpty ? null : content;
  }

  Future<int> getFailureCount(String cacheKey) async {
    final row =
        await (select(readerTempChapterCaches)
          ..where((t) => t.cacheKey.equals(cacheKey))).getSingleOrNull();
    return row?.failureCount ?? 0;
  }

  Future<void> saveContent({
    required String cacheKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required String content,
    required int updatedAt,
  }) {
    return into(readerTempChapterCaches).insertOnConflictUpdate(
      ReaderTempChapterCachesCompanion.insert(
        cacheKey: cacheKey,
        origin: origin,
        bookUrl: bookUrl,
        chapterUrl: chapterUrl,
        chapterIndex: chapterIndex,
        content: Value(content),
        updatedAt: updatedAt,
        failureCount: const Value(0),
      ),
    );
  }

  Future<void> recordFailure({
    required String cacheKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required int updatedAt,
  }) async {
    final current = await getFailureCount(cacheKey);
    await into(readerTempChapterCaches).insertOnConflictUpdate(
      ReaderTempChapterCachesCompanion.insert(
        cacheKey: cacheKey,
        origin: origin,
        bookUrl: bookUrl,
        chapterUrl: chapterUrl,
        chapterIndex: chapterIndex,
        updatedAt: updatedAt,
        failureCount: Value(current + 1),
      ),
    );
  }

  Future<void> deleteByBook(String origin, String bookUrl) {
    return (delete(readerTempChapterCaches)
      ..where((t) => t.origin.equals(origin) & t.bookUrl.equals(bookUrl))).go();
  }

  Future<int> cleanupOlderThan(int cutoffMillis) {
    return (delete(readerTempChapterCaches)
      ..where((t) => t.updatedAt.isSmallerThanValue(cutoffMillis))).go();
  }
}
