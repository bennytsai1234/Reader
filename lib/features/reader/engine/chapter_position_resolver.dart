import 'text_page.dart';

class ChapterPositionResolver {
  const ChapterPositionResolver._();

  static double pageHeight(TextPage page) {
    return page.lines.isEmpty ? 0.0 : page.lines.last.lineBottom;
  }

  static double chapterHeight(List<TextPage> pages) {
    return pages.fold(0.0, (sum, page) => sum + pageHeight(page));
  }

  static List<double> pageTopOffsets(List<TextPage> pages) {
    final offsets = <double>[];
    var current = 0.0;
    for (final page in pages) {
      offsets.add(current);
      current += pageHeight(page);
    }
    return offsets;
  }

  static double charOffsetToLocalOffset(List<TextPage> pages, int charOffset) {
    if (pages.isEmpty) return 0.0;
    final tops = pageTopOffsets(pages);
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      for (final line in page.lines) {
        if (line.image != null) continue;
        if (line.chapterPosition >= charOffset) {
          return tops[i] + line.lineTop;
        }
      }
    }
    return chapterHeight(pages);
  }

  static double charOffsetToAlignment(List<TextPage> pages, int charOffset) {
    final total = chapterHeight(pages);
    if (total <= 0) return 0.0;
    return (charOffsetToLocalOffset(pages, charOffset) / total).clamp(0.0, 1.0);
  }

  static int localOffsetToCharOffset(List<TextPage> pages, double localOffset) {
    if (pages.isEmpty) return 0;
    final tops = pageTopOffsets(pages);
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final pageTop = tops[i];
      for (final line in page.lines) {
        if (line.image != null) continue;
        if (pageTop + line.lineBottom > localOffset) {
          return line.chapterPosition;
        }
      }
    }
    return pageEndCharOffset(pages.last);
  }

  static int findPageIndexByCharOffset(List<TextPage> pages, int charOffset) {
    if (pages.isEmpty) return 0;
    var best = 0;
    for (var i = 0; i < pages.length; i++) {
      final offset = firstCharOffset(pages[i]);
      if (offset <= charOffset) {
        best = i;
      } else {
        break;
      }
    }
    return best;
  }

  static int pageIndexAtLocalOffset(List<TextPage> pages, double localOffset) {
    if (pages.isEmpty) return 0;
    final tops = pageTopOffsets(pages);
    for (var i = 0; i < pages.length; i++) {
      if (tops[i] + pageHeight(pages[i]) > localOffset) {
        return i;
      }
    }
    return pages.length - 1;
  }

  static int getCharOffsetForPage(List<TextPage> pages, int pageIndex) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex >= pages.length) return 0;
    return firstCharOffset(pages[pageIndex]);
  }

  static int pageEndCharOffset(TextPage page) {
    for (final line in page.lines.reversed) {
      if (line.image == null) {
        return line.chapterPosition + line.text.length;
      }
    }
    return firstCharOffset(page);
  }

  static int firstCharOffset(TextPage page) {
    for (final line in page.lines) {
      if (line.image == null) return line.chapterPosition;
    }
    return 0;
  }
}
