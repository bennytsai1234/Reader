import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/di/injection.dart';

class ExportBookService {
  final ChapterDao _chapterDao = getIt<ChapterDao>();

  /// 匯出全書為 TXT 檔案
  Future<void> exportToTxt(Book book, {Function(double progress)? onProgress}) async {
    final chapters = await _chapterDao.getChapters(book.bookUrl);
    if (chapters.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln(book.name);
    buffer.writeln('作者：${book.author}');
    buffer.writeln('---');

    for (var i = 0; i < chapters.length; i++) {
      final content = await _chapterDao.getContent(chapters[i].url);
      if (content != null) {
        buffer.writeln('\n${chapters[i].title}\n');
        buffer.writeln(content);
      }
      if (onProgress != null) onProgress((i + 1) / chapters.length);
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = '${book.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.txt';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    // 使用 SharePlus.instance.share
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: '匯出書籍: ${book.name}',
    ));
  }
}


