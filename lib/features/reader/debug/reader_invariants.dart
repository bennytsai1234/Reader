import 'package:inkpage_reader/features/reader/engine/chapter_layout.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

class ReaderInvariantViolation implements Exception {
  ReaderInvariantViolation(this.message);
  final String message;

  @override
  String toString() => 'ReaderInvariantViolation: $message';
}

class ReaderInvariants {
  const ReaderInvariants._();

  static void validateChapterLayout(ChapterLayout layout) {
    var previousBottom = -double.infinity;
    var previousPageStart = -1;
    for (final line in layout.lines) {
      if (line.startCharOffset > line.endCharOffset) {
        throw ReaderInvariantViolation('line char range is inverted');
      }
      if (line.bottom < line.top) {
        throw ReaderInvariantViolation('line vertical range is inverted');
      }
      if (line.top < previousBottom - 0.01) {
        throw ReaderInvariantViolation('line positions are not increasing');
      }
      previousBottom = line.bottom;
    }
    for (final page in layout.pages) {
      validateTextPage(page);
      if (page.startCharOffset < previousPageStart) {
        throw ReaderInvariantViolation('page char ranges are not increasing');
      }
      previousPageStart = page.startCharOffset;
    }
  }

  static void validateTextPage(TextPage page) {
    if (page.startCharOffset > page.endCharOffset) {
      throw ReaderInvariantViolation('page char range is inverted');
    }
    for (final line in page.lines) {
      if (line.startCharOffset < page.startCharOffset ||
          line.endCharOffset > page.endCharOffset) {
        throw ReaderInvariantViolation('page contains a foreign line');
      }
    }
  }

  static TextPage nearestPageForLocation(
    ChapterLayout layout,
    ReaderLocation location,
  ) {
    if (layout.pages.isEmpty) {
      throw ReaderInvariantViolation('chapter layout has no pages');
    }
    return layout.pageForCharOffset(location.charOffset);
  }
}
