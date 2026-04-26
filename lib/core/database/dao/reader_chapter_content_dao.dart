import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:inkpage_reader/core/models/reader_chapter_content.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';

part 'reader_chapter_content_dao.g.dart';

@DriftAccessor(tables: [ReaderChapterContents])
class ReaderChapterContentDao extends DatabaseAccessor<AppDatabase>
    with _$ReaderChapterContentDaoMixin {
  ReaderChapterContentDao(super.db);

  static String contentKey({
    required String origin,
    required String bookUrl,
    required String chapterUrl,
  }) {
    final material = '$origin\n$bookUrl\n$chapterUrl';
    return sha1.convert(utf8.encode(material)).toString();
  }

  Future<String?> getContent({required String contentKey}) async {
    final entry = await getEntry(contentKey: contentKey);
    final content = entry?.content;
    return content == null || content.isEmpty ? null : content;
  }

  Future<ReaderChapterContentEntry?> getEntry({
    required String contentKey,
  }) async {
    final query = select(readerChapterContents)
      ..where((t) => t.contentKey.equals(contentKey));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return ReaderChapterContentEntry(
      contentKey: row.contentKey,
      origin: row.origin,
      bookUrl: row.bookUrl,
      chapterUrl: row.chapterUrl,
      chapterIndex: row.chapterIndex,
      status: ReaderChapterContentStatus.fromCode(row.status),
      content: row.content,
      failureMessage: row.failureMessage,
      updatedAt: row.updatedAt,
    );
  }

  Future<bool> hasContent({required String contentKey}) async {
    return hasReadyContent(contentKey: contentKey);
  }

  Future<bool> hasReadyContent({required String contentKey}) async {
    final entry = await getEntry(contentKey: contentKey);
    return entry != null && entry.isReady && entry.hasDisplayContent;
  }

  Future<Set<int>> getStoredChapterIndices({
    required String origin,
    required String bookUrl,
  }) async {
    final query = select(readerChapterContents)..where(
      (t) =>
          t.origin.equals(origin) &
          t.bookUrl.equals(bookUrl) &
          t.status.equals(ReaderChapterContentStatus.ready.code) &
          t.content.isNotNull() &
          t.content.isNotValue(''),
    );
    final rows = await query.get();
    return rows.map((row) => row.chapterIndex).toSet();
  }

  Future<void> saveContent({
    required String contentKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required String content,
    required int updatedAt,
    ReaderChapterContentStatus status = ReaderChapterContentStatus.ready,
    String? failureMessage,
  }) {
    return into(readerChapterContents).insertOnConflictUpdate(
      ReaderChapterContentsCompanion.insert(
        contentKey: contentKey,
        origin: origin,
        bookUrl: bookUrl,
        chapterUrl: chapterUrl,
        chapterIndex: chapterIndex,
        content: Value(content),
        status: Value(status.code),
        failureMessage: Value(failureMessage),
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> saveFailure({
    required String contentKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required String message,
    required int updatedAt,
  }) {
    return saveContent(
      contentKey: contentKey,
      origin: origin,
      bookUrl: bookUrl,
      chapterUrl: chapterUrl,
      chapterIndex: chapterIndex,
      content: message,
      updatedAt: updatedAt,
      status: ReaderChapterContentStatus.failed,
      failureMessage: message,
    );
  }

  Future<void> deleteContent({required String contentKey}) {
    return (delete(readerChapterContents)
      ..where((t) => t.contentKey.equals(contentKey))).go();
  }

  Future<void> deleteByBook(String origin, String bookUrl) {
    return (delete(readerChapterContents)
      ..where((t) => t.origin.equals(origin) & t.bookUrl.equals(bookUrl))).go();
  }

  Future<void> clearAllContent() {
    return delete(readerChapterContents).go();
  }

  Future<int> getTotalContentSize() async {
    final rows =
        await customSelect(
          'SELECT COALESCE(SUM(LENGTH(content)), 0) AS total FROM reader_chapter_contents WHERE status = 1 AND content IS NOT NULL AND content != ""',
          readsFrom: {readerChapterContents},
        ).get();
    if (rows.isEmpty) return 0;
    return rows.first.read<int>('total');
  }
}
