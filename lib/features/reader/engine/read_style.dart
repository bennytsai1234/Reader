import 'package:inkpage_reader/core/constant/page_anim.dart';

enum ReaderPageMode {
  scroll,
  slide;

  static ReaderPageMode fromPageAnim(int pageAnim) {
    return pageAnim == PageAnim.scroll ? ReaderPageMode.scroll : slide;
  }

  int get pageAnim => switch (this) {
    ReaderPageMode.scroll => PageAnim.scroll,
    ReaderPageMode.slide => PageAnim.slide,
  };
}

class ReadStyle {
  const ReadStyle({
    required this.fontSize,
    required this.lineHeight,
    required this.letterSpacing,
    required this.paragraphSpacing,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingLeft,
    required this.paddingRight,
    this.fontFamily,
    this.bold = false,
    this.textIndent = 0,
    this.textFullJustify = false,
    this.selectText = true,
    required this.pageMode,
  });

  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final double paragraphSpacing;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final String? fontFamily;
  final bool bold;
  final int textIndent;
  final bool textFullJustify;
  final bool selectText;
  final ReaderPageMode pageMode;

  ReadStyle copyWith({
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
    double? paragraphSpacing,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
    String? fontFamily,
    bool? bold,
    int? textIndent,
    bool? textFullJustify,
    bool? selectText,
    ReaderPageMode? pageMode,
  }) {
    return ReadStyle(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
      fontFamily: fontFamily ?? this.fontFamily,
      bold: bold ?? this.bold,
      textIndent: textIndent ?? this.textIndent,
      textFullJustify: textFullJustify ?? this.textFullJustify,
      selectText: selectText ?? this.selectText,
      pageMode: pageMode ?? this.pageMode,
    );
  }
}
