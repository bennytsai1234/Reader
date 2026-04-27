import 'dart:async';

import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';

class ReaderProgressController {
  ReaderProgressController({
    required this.book,
    required this.repository,
    required this.bookDao,
    this.debounce = const Duration(milliseconds: 400),
  });

  final Book book;
  final ChapterRepository repository;
  final BookDao bookDao;
  final Duration debounce;

  Timer? _timer;
  ReaderLocation? _pendingLocation;
  Future<void>? _activeFlush;
  int writeCount = 0;

  void schedule(ReaderLocation location) {
    _pendingLocation = location.normalized();
    _timer?.cancel();
    _timer = Timer(debounce, () {
      unawaited(flush());
    });
  }

  Future<void> saveImmediately(ReaderLocation location) async {
    _pendingLocation = location.normalized();
    await flush();
  }

  Future<void> flush() {
    final active = _activeFlush;
    if (active != null) return active;
    _timer?.cancel();
    final location = _pendingLocation;
    if (location == null) return Future<void>.value();
    _pendingLocation = null;
    _activeFlush = _write(location).whenComplete(() {
      _activeFlush = null;
    });
    return _activeFlush!;
  }

  Future<void> _write(ReaderLocation location) async {
    final normalized = location.normalized(
      chapterCount: repository.chapterCount,
    );
    final title = repository.titleFor(normalized.chapterIndex);
    book.chapterIndex = normalized.chapterIndex;
    book.charOffset = normalized.charOffset;
    book.durChapterTitle = title;
    book.readerAnchorJson = null;
    writeCount += 1;
    await bookDao.updateProgress(
      book.bookUrl,
      normalized.chapterIndex,
      title,
      normalized.charOffset,
      readerAnchorJson: null,
    );
  }

  void dispose() {
    _timer?.cancel();
  }
}
