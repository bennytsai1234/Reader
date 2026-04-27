import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/engine/app_event_bus.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_host_base.dart'
    show ReaderCommandReason;
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:inkpage_reader/core/services/source_switch_service.dart';

typedef ReaderChapterTitlesRefresher = Future<void> Function({bool notify});
typedef ReaderChapterLoader =
    Future<void> Function(int chapterIndex, {ReaderCommandReason reason});
typedef ReaderCharOffsetJump =
    void Function({
      required int chapterIndex,
      required int charOffset,
      required ReaderCommandReason reason,
    });
typedef ReaderChapterContentSeeder =
    void Function(int chapterIndex, String content);
typedef ReaderChapterContentSaver =
    Future<void> Function(BookChapter chapter, String content);

class ReaderSessionFacade {
  const ReaderSessionFacade();

  Future<List<BookChapter>> loadChapters({
    required Book book,
    required List<BookChapter> chapters,
    required ChapterDao chapterDao,
  }) async {
    if (chapters.isNotEmpty) {
      return List<BookChapter>.from(chapters);
    }
    return chapterDao.getByBook(book.bookUrl);
  }

  Future<BookSource?> loadSource({
    required Book book,
    required BookSourceDao sourceDao,
  }) {
    return sourceDao.getByUrl(book.origin);
  }

  Bookmark buildBookmark({
    required Book book,
    required int chapterIndex,
    required String chapterTitle,
    required int chapterPos,
    String? content,
  }) {
    return Bookmark(
      time: DateTime.now().millisecondsSinceEpoch,
      bookName: book.name,
      bookAuthor: book.author,
      bookUrl: book.bookUrl,
      chapterIndex: chapterIndex,
      chapterName: chapterTitle,
      chapterPos: chapterPos,
      bookText: content ?? '',
    );
  }

  Future<void> addCurrentBookToBookshelf({
    required Book book,
    required List<BookChapter> chapters,
    required ReaderLocation location,
    required String chapterTitle,
    required ReaderProgressStore progressStore,
    required BookDao bookDao,
    required ChapterDao chapterDao,
    void Function()? onCompleted,
  }) async {
    progressStore.updateBookProgress(
      book: book,
      chapterIndex: location.chapterIndex,
      charOffset: location.charOffset,
      title: chapterTitle,
    );
    book.durChapterTime = DateTime.now().millisecondsSinceEpoch;
    book.isInBookshelf = true;
    await bookDao.upsert(book);
    if (chapters.isNotEmpty) {
      await chapterDao.insertChapters(chapters);
    }
    AppEventBus().fire(AppEventBus.upBookshelf, data: book.bookUrl);
    onCompleted?.call();
  }

  void saveBookmark({
    required BookmarkDao bookmarkDao,
    required Bookmark bookmark,
    void Function()? onCompleted,
  }) {
    bookmarkDao.upsert(bookmark);
    onCompleted?.call();
  }

  Future<void> applySourceSwitchResolution({
    required SourceSwitchResolution resolution,
    required Book book,
    required void Function(BookSource value) setSource,
    required void Function(List<BookChapter> value) setChapters,
    required void Function(int chapterIndex) clearChapterFailure,
    required ReaderChapterTitlesRefresher refreshChapterDisplayTitles,
    required void Function({bool refreshPaginationConfig})
    resetContentLifecycle,
    required ReaderChapterContentSeeder putChapterContent,
    required BookDao bookDao,
    required ChapterDao chapterDao,
    ReaderChapterContentSaver? saveChapterContent,
    required void Function(ReaderLocation location) updateCommittedLocation,
    required ReaderChapterLoader loadChapter,
    required ReaderCharOffsetJump jumpToChapterCharOffset,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) async {
    final nextChapters = List<BookChapter>.from(resolution.chapters);
    book.overwriteFrom(resolution.migratedBook);
    setSource(resolution.source);
    setChapters(nextChapters);
    clearChapterFailure(resolution.targetChapterIndex);

    await refreshChapterDisplayTitles(notify: false);
    resetContentLifecycle(refreshPaginationConfig: false);

    final validatedContent = resolution.validatedContent;
    if (validatedContent != null &&
        resolution.targetChapterIndex >= 0 &&
        resolution.targetChapterIndex < nextChapters.length) {
      await saveChapterContent?.call(
        nextChapters[resolution.targetChapterIndex],
        validatedContent,
      );
      putChapterContent(resolution.targetChapterIndex, validatedContent);
    }

    if (book.isInBookshelf) {
      await chapterDao.deleteByBook(book.bookUrl);
      await bookDao.upsert(book);
      await chapterDao.insertChapters(nextChapters);
    }

    updateCommittedLocation(
      ReaderLocation(
        chapterIndex: resolution.targetChapterIndex,
        charOffset: book.charOffset,
      ),
    );
    await loadChapter(resolution.targetChapterIndex, reason: reason);
    if (book.charOffset > 0) {
      jumpToChapterCharOffset(
        chapterIndex: resolution.targetChapterIndex,
        charOffset: book.charOffset,
        reason: reason,
      );
    }
  }
}
