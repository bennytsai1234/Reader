import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_temp_chapter_cache_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';

enum ReaderChapterContentCachePolicy { bookshelfLongTerm, transientNetwork }

class ReaderChapterContentCacheRepository {
  ReaderChapterContentCacheRepository({
    required this.chapterDao,
    required this.tempCacheDao,
    DateTime Function()? now,
    this.transientCacheTtl = const Duration(days: 14),
    this.failureSkipThreshold = 3,
  }) : _now = now ?? DateTime.now;

  final ChapterDao chapterDao;
  final ReaderTempChapterCacheDao tempCacheDao;
  final DateTime Function() _now;
  final Duration transientCacheTtl;
  final int failureSkipThreshold;

  ReaderChapterContentCachePolicy policyFor(Book book) {
    if (book.origin == 'local' || book.isInBookshelf) {
      return ReaderChapterContentCachePolicy.bookshelfLongTerm;
    }
    return ReaderChapterContentCachePolicy.transientNetwork;
  }

  Future<String?> getRawContent({
    required Book book,
    required BookChapter chapter,
    ReaderChapterContentCachePolicy? policy,
  }) async {
    final inlineContent = chapter.content;
    if (inlineContent != null && inlineContent.isNotEmpty) {
      return inlineContent;
    }

    final resolvedPolicy = policy ?? policyFor(book);
    if (resolvedPolicy == ReaderChapterContentCachePolicy.bookshelfLongTerm) {
      return chapterDao.getContent(chapter.url);
    }

    return tempCacheDao.getContent(
      cacheKey: cacheKeyFor(book: book, chapter: chapter),
      minUpdatedAt: _transientMinUpdatedAt,
    );
  }

  Future<void> saveRawContent({
    required Book book,
    required BookChapter chapter,
    required String content,
    ReaderChapterContentCachePolicy? policy,
  }) async {
    if (content.isEmpty) return;
    final resolvedPolicy = policy ?? policyFor(book);
    if (resolvedPolicy == ReaderChapterContentCachePolicy.bookshelfLongTerm) {
      await chapterDao.insertChapters(<BookChapter>[chapter]);
      await chapterDao.saveContent(chapter.url, content);
      return;
    }

    await tempCacheDao.saveContent(
      cacheKey: cacheKeyFor(book: book, chapter: chapter),
      origin: book.origin,
      bookUrl: book.bookUrl,
      chapterUrl: chapter.url,
      chapterIndex: chapter.index,
      content: content,
      updatedAt: _now().millisecondsSinceEpoch,
    );
  }

  Future<void> promoteTransientCacheToBookshelf({
    required Book book,
    required List<BookChapter> chapters,
  }) async {
    if (chapters.isEmpty) return;
    await chapterDao.insertChapters(chapters);
    if (book.origin == 'local') return;
    for (final chapter in chapters) {
      final content = await tempCacheDao.getContent(
        cacheKey: cacheKeyFor(book: book, chapter: chapter),
        minUpdatedAt: _transientMinUpdatedAt,
      );
      if (content != null && content.isNotEmpty) {
        await chapterDao.saveContent(chapter.url, content);
      }
    }
    await tempCacheDao.deleteByBook(book.origin, book.bookUrl);
  }

  Future<void> recordFetchFailure({
    required Book book,
    required BookChapter chapter,
  }) {
    if (policyFor(book) == ReaderChapterContentCachePolicy.bookshelfLongTerm) {
      return Future<void>.value();
    }
    return tempCacheDao.recordFailure(
      cacheKey: cacheKeyFor(book: book, chapter: chapter),
      origin: book.origin,
      bookUrl: book.bookUrl,
      chapterUrl: chapter.url,
      chapterIndex: chapter.index,
      updatedAt: _now().millisecondsSinceEpoch,
    );
  }

  Future<bool> shouldSkipFetch({
    required Book book,
    required BookChapter chapter,
  }) async {
    if (policyFor(book) == ReaderChapterContentCachePolicy.bookshelfLongTerm) {
      return false;
    }
    final failures = await tempCacheDao.getFailureCount(
      cacheKeyFor(book: book, chapter: chapter),
    );
    return failures >= failureSkipThreshold;
  }

  Future<int> cleanupTransientCache() {
    return tempCacheDao.cleanupOlderThan(_transientMinUpdatedAt);
  }

  int get _transientMinUpdatedAt =>
      _now().subtract(transientCacheTtl).millisecondsSinceEpoch;

  static String cacheKeyFor({
    required Book book,
    required BookChapter chapter,
  }) {
    final material = '${book.origin}\n${book.bookUrl}\n${chapter.url}';
    return sha1.convert(utf8.encode(material)).toString();
  }
}
