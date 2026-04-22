import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

enum ReaderOpenIntent { resume, chapterStart, bookmark }

class ReaderOpenTarget {
  final ReaderLocation location;
  final ReaderOpenIntent intent;

  const ReaderOpenTarget({required this.location, required this.intent});

  factory ReaderOpenTarget.resume(Book book) {
    return ReaderOpenTarget(
      intent: ReaderOpenIntent.resume,
      location:
          ReaderLocation(
            chapterIndex: book.durChapterIndex,
            charOffset: book.durChapterPos,
          ).normalized(),
    );
  }

  factory ReaderOpenTarget.chapterStart(int chapterIndex) {
    return ReaderOpenTarget(
      intent: ReaderOpenIntent.chapterStart,
      location:
          ReaderLocation(
            chapterIndex: chapterIndex,
            charOffset: 0,
          ).normalized(),
    );
  }

  factory ReaderOpenTarget.bookmark(Bookmark bookmark) {
    return ReaderOpenTarget(
      intent: ReaderOpenIntent.bookmark,
      location:
          ReaderLocation(
            chapterIndex: bookmark.chapterIndex,
            charOffset: bookmark.chapterPos,
          ).normalized(),
    );
  }

  factory ReaderOpenTarget.location(
    ReaderLocation location, {
    ReaderOpenIntent intent = ReaderOpenIntent.chapterStart,
  }) {
    return ReaderOpenTarget(intent: intent, location: location.normalized());
  }
}
