import 'dart:async';
import 'dart:convert';

import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

class ReaderProgressStore {
  ReaderLocation? _lastSavedLocation;
  ReaderAnchor? _lastSavedAnchor;

  ReaderLocation? get lastSavedLocation => _lastSavedLocation;
  ReaderAnchor? get lastSavedAnchor => _lastSavedAnchor;
  int get lastSavedCharOffset => _lastSavedLocation?.charOffset ?? -1;

  void updateBookProgress({
    required Book book,
    required int chapterIndex,
    required int charOffset,
    String? title,
    String? readerAnchorJson,
  }) {
    book.durChapterIndex = chapterIndex;
    book.durChapterPos = charOffset;
    if (title != null) {
      book.durChapterTitle = title;
    }
    if (readerAnchorJson != null) {
      book.readerAnchorJson = readerAnchorJson;
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
      String? readerAnchorJson,
    )
    write,
    required Book book,
    required List<BookChapter> chapters,
    required int chapterIndex,
    required int charOffset,
    ReaderAnchor? anchor,
  }) async {
    final title =
        chapters.isNotEmpty && chapterIndex < chapters.length
            ? chapters[chapterIndex].title
            : '';
    final currentLocation =
        ReaderLocation(
          chapterIndex: chapterIndex,
          charOffset: charOffset,
        ).normalized();
    final resolvedAnchor = (anchor ?? ReaderAnchor.location(currentLocation))
        .normalized()
        .copyWith(location: currentLocation);
    updateBookProgress(
      book: book,
      chapterIndex: chapterIndex,
      charOffset: charOffset,
      title: title,
      readerAnchorJson: jsonEncode(resolvedAnchor.toJson()),
    );
    _lastSavedLocation = currentLocation;
    _lastSavedAnchor = resolvedAnchor;
    try {
      await write(chapterIndex, title, charOffset, book.readerAnchorJson);
    } catch (e, stack) {
      AppLog.e(
        'ReaderProgressStore: persist failed ch=$chapterIndex pos=$charOffset',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void rememberAnchor(ReaderAnchor anchor) {
    _lastSavedAnchor = anchor.normalized();
    _lastSavedLocation = _lastSavedAnchor!.location;
  }
}
