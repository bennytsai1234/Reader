import 'package:inkpage_reader/features/reader/engine/text_page.dart';

class ReaderParagraph {
  int num;
  final List<TextLine> textLines;

  ReaderParagraph({required this.num, required this.textLines});

  String get text => textLines.map((line) => line.text).join();
  int get length => text.length;
  TextLine get firstLine => textLines.first;
  TextLine get lastLine => textLines.last;
  int get chapterPosition => firstLine.chapterPosition;
  int get realNum => firstLine.paragraphNum;
  bool get isParagraphEnd => lastLine.isParagraphEnd;
  int get chapterEndPosition => lastLine.chapterPosition + lastLine.text.length;

  bool containsCharOffset(int charOffset) {
    return charOffset >= chapterPosition && charOffset <= chapterEndPosition;
  }
}
