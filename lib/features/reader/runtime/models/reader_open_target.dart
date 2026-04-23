import 'dart:convert';

import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

enum ReaderOpenIntent { resume, chapterStart, bookmark }

class ReaderOpenTarget {
  final ReaderAnchor anchor;
  final ReaderOpenIntent intent;

  const ReaderOpenTarget({required this.anchor, required this.intent});

  ReaderLocation get location => anchor.location;

  factory ReaderOpenTarget.resume(Book book) {
    final location =
        ReaderLocation(
          chapterIndex: book.durChapterIndex,
          charOffset: book.durChapterPos,
        ).normalized();
    ReaderAnchor? persistedAnchor;
    final rawAnchorJson = book.readerAnchorJson;
    if (rawAnchorJson != null && rawAnchorJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawAnchorJson);
        if (decoded is Map<String, dynamic>) {
          persistedAnchor = ReaderAnchor.fromJson(decoded);
        } else if (decoded is Map) {
          persistedAnchor = ReaderAnchor.fromJson(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } catch (_) {
        persistedAnchor = null;
      }
    }
    final normalizedAnchor = persistedAnchor?.normalized();
    return ReaderOpenTarget(
      intent: ReaderOpenIntent.resume,
      anchor:
          normalizedAnchor == null || normalizedAnchor.location != location
              ? ReaderAnchor.location(location)
              : normalizedAnchor,
    );
  }

  factory ReaderOpenTarget.chapterStart(int chapterIndex) {
    return ReaderOpenTarget(
      intent: ReaderOpenIntent.chapterStart,
      anchor: ReaderAnchor.location(
        ReaderLocation(chapterIndex: chapterIndex, charOffset: 0).normalized(),
      ),
    );
  }

  factory ReaderOpenTarget.bookmark(Bookmark bookmark) {
    return ReaderOpenTarget(
      intent: ReaderOpenIntent.bookmark,
      anchor: ReaderAnchor.location(
        ReaderLocation(
          chapterIndex: bookmark.chapterIndex,
          charOffset: bookmark.chapterPos,
        ).normalized(),
      ),
    );
  }

  factory ReaderOpenTarget.location(
    ReaderLocation location, {
    ReaderOpenIntent intent = ReaderOpenIntent.chapterStart,
  }) {
    return ReaderOpenTarget(
      intent: intent,
      anchor: ReaderAnchor.location(location.normalized()),
    );
  }

  factory ReaderOpenTarget.anchor(
    ReaderAnchor anchor, {
    ReaderOpenIntent intent = ReaderOpenIntent.chapterStart,
  }) {
    return ReaderOpenTarget(intent: intent, anchor: anchor.normalized());
  }
}
