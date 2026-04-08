import 'dart:async';

import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/services/app_log_service.dart';

class ReaderProgressStore {
  int _lastSavedCharOffset = -1;

  int get lastSavedCharOffset => _lastSavedCharOffset;

  void updateBookProgress({
    required Book book,
    required int chapterIndex,
    required int charOffset,
    String? title,
  }) {
    book.durChapterIndex = chapterIndex;
    book.durChapterPos = charOffset;
    if (title != null) {
      book.durChapterTitle = title;
    }
  }

  bool shouldSaveImmediately({
    required int currentCharOffset,
    required int currentChapterIndex,
    required int targetChapterIndex,
  }) {
    return _lastSavedCharOffset == -1 ||
        (currentCharOffset - _lastSavedCharOffset).abs() > 600 ||
        currentChapterIndex != targetChapterIndex;
  }

  Future<void> persistCharOffset({
    required Future<void> Function(int chapterIndex, String title, int charOffset)
        write,
    required Book book,
    required List<BookChapter> chapters,
    required int chapterIndex,
    required int charOffset,
  }) async {
    final title = chapters.isNotEmpty && chapterIndex < chapters.length
        ? chapters[chapterIndex].title
        : '';
    updateBookProgress(
      book: book,
      chapterIndex: chapterIndex,
      charOffset: charOffset,
      title: title,
    );
    _lastSavedCharOffset = charOffset;
    try {
      await write(chapterIndex, title, charOffset);
    } catch (e, stack) {
      AppLog.e(
        'ReaderProgressStore: persist failed ch=$chapterIndex pos=$charOffset',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
