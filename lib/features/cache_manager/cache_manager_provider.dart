import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/services/download_service.dart';
import 'package:legado_reader/core/di/injection.dart';

class CacheManagerProvider extends ChangeNotifier {
  final Book book;
  final ChapterDao _chapterDao = getIt<ChapterDao>();
  final DownloadService downloadService = DownloadService();

  List<BookChapter> _chapters = [];
  final Set<int> _cachedIndices = {};
  bool _isLoading = false;

  List<BookChapter> get chapters => _chapters;
  Set<int> get cachedIndices => _cachedIndices;
  bool get isLoading => _isLoading;

  CacheManagerProvider(this.book) {
    loadStatus();
    downloadService.addListener(notifyListeners);
  }

  @override
  void dispose() {
    downloadService.removeListener(notifyListeners);
    super.dispose();
  }

  Future<void> loadStatus() async {
    _isLoading = true;
    notifyListeners();

    _chapters = await _chapterDao.getChapters(book.bookUrl);
    _cachedIndices
      ..clear()
      ..addAll(await _chapterDao.getCachedChapterIndices(book.bookUrl));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> downloadChapters(int start, int end) async {
    final toDownload = _chapters.sublist(
      start.clamp(0, _chapters.length),
      end.clamp(0, _chapters.length),
    );
    await downloadService.addDownloadTask(book, toDownload);
  }

  Future<void> downloadUncached() async {
    final uncached =
        _chapters.where((ch) => !_cachedIndices.contains(ch.index)).toList();
    if (uncached.isNotEmpty) {
      await downloadService.addDownloadTask(book, uncached);
    }
  }

  Future<void> clearCache() async {
    await _chapterDao.deleteContentByBook(book.bookUrl);
    await loadStatus();
  }
}
