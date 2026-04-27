import 'text_page.dart';

class ChapterLayout {
  const ChapterLayout({
    required this.chapterIndex,
    required this.contentHash,
    required this.layoutSignature,
    required this.lines,
    required this.pages,
  });

  final int chapterIndex;
  final String contentHash;
  final String layoutSignature;
  final List<TextLine> lines;
  final List<TextPage> pages;

  TextPage pageForCharOffset(int charOffset) {
    if (pages.isEmpty) {
      return TextPage(
        pageIndex: 0,
        chapterIndex: chapterIndex,
        lines: const <TextLine>[],
        height: 1,
      );
    }
    var best = pages.first;
    for (final page in pages) {
      if (charOffset >= page.startCharOffset &&
          charOffset <= page.endCharOffset) {
        return page;
      }
      if (page.startCharOffset <= charOffset) {
        best = page;
      }
    }
    return best;
  }
}
