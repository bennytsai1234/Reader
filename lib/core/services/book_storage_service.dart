import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/services/book_cover_storage_service.dart';

class BookStorageService {
  BookStorageService({
    BookDao? bookDao,
    ChapterDao? chapterDao,
    ReaderChapterContentDao? contentDao,
    BookCoverStorageService? coverStorage,
  }) : _bookDao = bookDao ?? getIt<BookDao>(),
       _chapterDao = chapterDao ?? getIt<ChapterDao>(),
       _contentDao =
           contentDao ??
           (getIt.isRegistered<ReaderChapterContentDao>()
               ? getIt<ReaderChapterContentDao>()
               : null),
       _coverStorage = coverStorage ?? BookCoverStorageService();

  final BookDao _bookDao;
  final ChapterDao _chapterDao;
  final ReaderChapterContentDao? _contentDao;
  final BookCoverStorageService _coverStorage;

  Future<void> discardBook(Book book) async {
    await _contentDao?.deleteByBook(book.origin, book.bookUrl);
    await _chapterDao.deleteByBook(book.bookUrl);
    await _bookDao.deleteByUrl(book.bookUrl);
    await _coverStorage.deleteBookAssets(book);
  }
}
