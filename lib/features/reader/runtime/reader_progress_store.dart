import 'dart:async';

import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

class ReaderProgressStore {
  ReaderLocation? _lastSavedLocation;

  ReaderLocation? get lastSavedLocation => _lastSavedLocation;
  int get lastSavedCharOffset => _lastSavedLocation?.charOffset ?? -1;

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
    final lastSavedLocation = _lastSavedLocation;
    return lastSavedLocation == null ||
        (currentCharOffset - lastSavedLocation.charOffset).abs() > 600 ||
        currentChapterIndex != targetChapterIndex ||
        lastSavedLocation.chapterIndex != targetChapterIndex;
  }

  Future<void> persistCharOffset({
    required Future<void> Function(
      int chapterIndex,
      String title,
      int charOffset,
    )
    write,
    required Book book,
    required List<BookChapter> chapters,
    required int chapterIndex,
    required int charOffset,
  }) async {
    final title =
        chapters.isNotEmpty && chapterIndex < chapters.length
            ? chapters[chapterIndex].title
            : '';
    updateBookProgress(
      book: book,
      chapterIndex: chapterIndex,
      charOffset: charOffset,
      title: title,
    );
    _lastSavedLocation =
        ReaderLocation(
          chapterIndex: chapterIndex,
          charOffset: charOffset,
        ).normalized();
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
