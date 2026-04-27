import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';

class ReaderBookmarkController {
  ReaderBookmarkController({
    required this.book,
    required this.runtime,
    required this.bookmarkDao,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Book book;
  final ReaderRuntime runtime;
  final BookmarkDao bookmarkDao;
  final DateTime Function() _now;

  Future<Bookmark> addVisibleLocationBookmark() async {
    final bookmark = await buildVisibleLocationBookmark();
    await bookmarkDao.upsert(bookmark);
    return bookmark;
  }

  Future<Bookmark> buildVisibleLocationBookmark() async {
    final location = runtime.state.visibleLocation.normalized(
      chapterCount: runtime.chapterCount,
    );
    final text = await runtime.textFromVisibleLocation();
    return Bookmark(
      time: _now().millisecondsSinceEpoch,
      bookName: book.name,
      bookAuthor: book.author,
      chapterIndex: location.chapterIndex,
      chapterPos: location.charOffset,
      chapterName: runtime.titleFor(location.chapterIndex),
      bookUrl: book.bookUrl,
      bookText: _firstLine(text),
    );
  }

  String _firstLine(String text) {
    if (text.isEmpty) return '';
    return text.split(RegExp(r'\n+')).first.trim();
  }
}
