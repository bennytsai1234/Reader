import 'dart:async';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

typedef ReaderProgressWriter =
    Future<void> Function(
      int chapterIndex,
      String title,
      int charOffset,
      double visualOffsetPx,
      String? readerAnchorJson,
    );

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
    double visualOffsetPx = 0.0,
    String? title,
    String? readerAnchorJson,
  }) {
    final location =
        ReaderLocation(
          chapterIndex: chapterIndex,
          charOffset: charOffset,
          visualOffsetPx: visualOffsetPx,
        ).normalized();
    book.chapterIndex = location.chapterIndex;
    book.charOffset = location.charOffset;
    book.visualOffsetPx = location.visualOffsetPx;
    if (title != null) {
      book.durChapterTitle = title;
    }
    book.readerAnchorJson = readerAnchorJson;
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

  Future<void> persistLocation({
    required ReaderProgressWriter write,
    required Book book,
    required List<BookChapter> chapters,
    required ReaderLocation location,
    ReaderAnchor? anchor,
  }) async {
    final currentLocation = location.normalized();
    final chapterIndex = currentLocation.chapterIndex;
    final title =
        chapters.isNotEmpty && chapterIndex < chapters.length
            ? chapters[chapterIndex].title
            : '';
    updateBookProgress(
      book: book,
      chapterIndex: currentLocation.chapterIndex,
      charOffset: currentLocation.charOffset,
      visualOffsetPx: currentLocation.visualOffsetPx,
      title: title,
      readerAnchorJson: null,
    );
    _lastSavedLocation = currentLocation;
    _lastSavedAnchor = ReaderAnchor.location(currentLocation);
    try {
      await write(
        currentLocation.chapterIndex,
        title,
        currentLocation.charOffset,
        currentLocation.visualOffsetPx,
        book.readerAnchorJson,
      );
    } catch (e, stack) {
      AppLog.e(
        'ReaderProgressStore: persist failed ch=${currentLocation.chapterIndex} pos=${currentLocation.charOffset}',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> persistCharOffset({
    required ReaderProgressWriter write,
    required Book book,
    required List<BookChapter> chapters,
    required int chapterIndex,
    required int charOffset,
    double visualOffsetPx = 0.0,
    ReaderAnchor? anchor,
  }) async {
    await persistLocation(
      write: write,
      book: book,
      chapters: chapters,
      location: ReaderLocation(
        chapterIndex: chapterIndex,
        charOffset: charOffset,
        visualOffsetPx: visualOffsetPx,
      ),
      anchor: anchor,
    );
  }

  void rememberAnchor(ReaderAnchor anchor) {
    _lastSavedAnchor = ReaderAnchor.location(anchor.normalized().location);
    _lastSavedLocation = _lastSavedAnchor!.location;
  }
}
