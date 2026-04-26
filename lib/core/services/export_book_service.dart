import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/services/local_book_service.dart';
import 'package:inkpage_reader/core/storage/app_storage_paths.dart';
import 'package:share_plus/share_plus.dart';

class ExportBookService {
  final ChapterDao _chapterDao = getIt<ChapterDao>();
  final ReaderChapterContentDao _chapterContentDao =
      getIt<ReaderChapterContentDao>();

  /// 匯出全書為 TXT 檔案
  Future<void> exportToTxt(
    Book book, {
    Function(double progress)? onProgress,
  }) async {
    final chapters = await _chapterDao.getChapters(book.bookUrl);
    if (chapters.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln(book.name);
    buffer.writeln('作者：${book.author}');
    buffer.writeln('---');

    for (var i = 0; i < chapters.length; i++) {
      final entry = await _chapterContentDao.getEntry(
        contentKey: ReaderChapterContentDao.contentKey(
          origin: book.origin,
          bookUrl: book.bookUrl,
          chapterUrl: chapters[i].url,
        ),
      );
      var content = entry?.isReady == true ? entry?.content : null;
      if ((content == null || content.isEmpty) && book.origin == 'local') {
        content = await LocalBookService().getContent(book, chapters[i]);
      }
      if (content != null) {
        buffer.writeln('\n${chapters[i].title}\n');
        buffer.writeln(content);
      }
      if (onProgress != null) {
        onProgress((i + 1) / chapters.length);
      }
    }

    final fileName =
        '${book.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.txt';
    final file = await AppStoragePaths.shareExportFile(fileName);
    await file.writeAsString(buffer.toString());

    // 使用 SharePlus.instance.share
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: '匯出書籍: ${book.name}'),
    );
  }
}
