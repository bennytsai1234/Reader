import 'line_box.dart';

/// Compatibility adapter for old reader code plus the new LineBox data model.
class TextLine extends LineBox {
  TextLine({
    required super.text,
    this.width = 0,
    double? height,
    super.isTitle = false,
    super.isParagraphStart = false,
    super.isParagraphEnd = false,
    this.shouldJustify = false,
    int chapterPosition = 0,
    this.lineTop = 0,
    double? lineBottom,
    this.paragraphNum = 0,
    int? startCharOffset,
    int? endCharOffset,
    double? baseline,
  }) : chapterPosition = startCharOffset ?? chapterPosition,
       lineBottom = lineBottom ?? lineTop + (height ?? 0),
       super(
         startCharOffset: startCharOffset ?? chapterPosition,
         endCharOffset:
             endCharOffset ??
             (startCharOffset ?? chapterPosition) + text.length,
         top: lineTop,
         bottom: lineBottom ?? lineTop + (height ?? 0),
         baseline:
             baseline ??
             lineTop +
                 ((lineBottom ?? lineTop + (height ?? 0)) - lineTop) * 0.82,
       );

  final double width;
  @override
  double get height => lineBottom - lineTop;
  final bool shouldJustify;
  final int chapterPosition;
  final double lineTop;
  final double lineBottom;
  final int paragraphNum;

  TextLine copyWith({
    String? text,
    double? width,
    double? height,
    bool? isTitle,
    bool? isParagraphStart,
    bool? isParagraphEnd,
    bool? shouldJustify,
    int? chapterPosition,
    double? lineTop,
    double? lineBottom,
    int? paragraphNum,
    int? startCharOffset,
    int? endCharOffset,
    double? baseline,
  }) {
    return TextLine(
      text: text ?? this.text,
      width: width ?? this.width,
      height: height ?? this.height,
      isTitle: isTitle ?? this.isTitle,
      isParagraphStart: isParagraphStart ?? this.isParagraphStart,
      isParagraphEnd: isParagraphEnd ?? this.isParagraphEnd,
      shouldJustify: shouldJustify ?? this.shouldJustify,
      chapterPosition: chapterPosition ?? this.chapterPosition,
      lineTop: lineTop ?? this.lineTop,
      lineBottom: lineBottom ?? this.lineBottom,
      paragraphNum: paragraphNum ?? this.paragraphNum,
      startCharOffset: startCharOffset ?? this.startCharOffset,
      endCharOffset: endCharOffset ?? this.endCharOffset,
      baseline: baseline ?? this.baseline,
    );
  }

  TextLine shiftedBy(double dy) {
    return copyWith(
      lineTop: lineTop + dy,
      lineBottom: lineBottom + dy,
      baseline: baseline + dy,
    );
  }

  TextLine toPageLocal(double pageTop) {
    return copyWith(
      lineTop: top - pageTop,
      lineBottom: bottom - pageTop,
      baseline: baseline - pageTop,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'width': width,
      'height': height,
      'isTitle': isTitle,
      'isParagraphStart': isParagraphStart,
      'isParagraphEnd': isParagraphEnd,
      'shouldJustify': shouldJustify,
      'chapterPosition': chapterPosition,
      'lineTop': lineTop,
      'lineBottom': lineBottom,
      'paragraphNum': paragraphNum,
      'startCharOffset': startCharOffset,
      'endCharOffset': endCharOffset,
      'baseline': baseline,
    };
  }

  factory TextLine.fromJson(Map<String, dynamic> json) {
    return TextLine(
      text: json['text'] ?? '',
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      isTitle: json['isTitle'] ?? false,
      isParagraphStart: json['isParagraphStart'] ?? false,
      isParagraphEnd: json['isParagraphEnd'] ?? false,
      shouldJustify: json['shouldJustify'] ?? false,
      chapterPosition: json['chapterPosition'] ?? 0,
      lineTop: (json['lineTop'] ?? 0).toDouble(),
      lineBottom: (json['lineBottom'] ?? 0).toDouble(),
      paragraphNum: json['paragraphNum'] ?? 0,
      startCharOffset: json['startCharOffset'] ?? json['chapterPosition'] ?? 0,
      endCharOffset: json['endCharOffset'],
      baseline: (json['baseline'] as num?)?.toDouble(),
    );
  }
}

class TextPage {
  TextPage({
    int? index,
    int? pageIndex,
    required List<TextLine> lines,
    this.title = '',
    required this.chapterIndex,
    this.chapterSize = 0,
    this.pageSize = 0,
    int? startCharOffset,
    int? endCharOffset,
    double? height,
    double? contentHeight,
    double? viewportHeight,
    bool? isChapterStart,
    bool? isChapterEnd,
    this.isLoading = false,
    this.errorMessage,
  }) : pageIndex = pageIndex ?? index ?? 0,
       lines = List<TextLine>.unmodifiable(lines),
       startCharOffset = startCharOffset ?? _firstOffset(lines),
       endCharOffset = endCharOffset ?? _lastOffset(lines),
       contentHeight = contentHeight ?? height ?? _pageHeight(lines),
       viewportHeight =
           viewportHeight ?? contentHeight ?? height ?? _pageHeight(lines),
       isChapterStart = isChapterStart ?? ((pageIndex ?? index ?? 0) == 0),
       isChapterEnd =
           isChapterEnd ??
           (pageSize > 0 && (pageIndex ?? index ?? 0) >= pageSize - 1);

  /// Old slide/PageView code uses [index]. New engine uses [pageIndex].
  int get index => pageIndex;
  final int pageIndex;
  final List<TextLine> lines;
  final String title;
  final int chapterIndex;
  final int chapterSize;
  final int pageSize;
  final int startCharOffset;
  final int endCharOffset;
  final double contentHeight;
  final double viewportHeight;
  final bool isChapterStart;
  final bool isChapterEnd;
  final bool isLoading;
  final String? errorMessage;
  double get height => contentHeight;
  bool get isPlaceholder => isLoading || errorMessage != null;
  bool get hasBodyContent =>
      lines.any((line) => !line.isTitle && line.text.isNotEmpty);

  int get lineSize => lines.length;

  String get readProgress {
    if (chapterSize == 0 || (pageSize == 0 && chapterIndex == 0)) {
      return '0.0%';
    } else if (pageSize == 0) {
      return '${((chapterIndex + 1.0) / chapterSize * 100).toStringAsFixed(1)}%';
    }
    final percent =
        (chapterIndex / chapterSize) +
        (1.0 / chapterSize) * (index + 1) / pageSize;
    var formatted = '${(percent * 100).toStringAsFixed(1)}%';
    if (formatted == '100.0%' &&
        (chapterIndex + 1 != chapterSize || index + 1 != pageSize)) {
      formatted = '99.9%';
    }
    return formatted;
  }

  bool containsCharOffset(int charOffset) {
    if (lines.isEmpty) return charOffset == startCharOffset;
    if (charOffset < startCharOffset || charOffset > endCharOffset) {
      return false;
    }
    return charOffset < endCharOffset || isChapterEnd;
  }

  TextPage copyWith({
    int? index,
    int? pageIndex,
    List<TextLine>? lines,
    String? title,
    int? chapterIndex,
    int? chapterSize,
    int? pageSize,
    int? startCharOffset,
    int? endCharOffset,
    double? height,
    double? contentHeight,
    double? viewportHeight,
    bool? isChapterStart,
    bool? isChapterEnd,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    final nextPageIndex = pageIndex ?? index ?? this.pageIndex;
    final nextLines = lines ?? this.lines;
    return TextPage(
      pageIndex: nextPageIndex,
      lines: nextLines,
      title: title ?? this.title,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterSize: chapterSize ?? this.chapterSize,
      pageSize: pageSize ?? this.pageSize,
      startCharOffset: startCharOffset ?? this.startCharOffset,
      endCharOffset: endCharOffset ?? this.endCharOffset,
      contentHeight: contentHeight ?? height ?? this.contentHeight,
      viewportHeight: viewportHeight ?? this.viewportHeight,
      isChapterStart: isChapterStart ?? this.isChapterStart,
      isChapterEnd: isChapterEnd ?? this.isChapterEnd,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'pageIndex': pageIndex,
      'title': title,
      'chapterIndex': chapterIndex,
      'chapterSize': chapterSize,
      'pageSize': pageSize,
      'startCharOffset': startCharOffset,
      'endCharOffset': endCharOffset,
      'height': height,
      'contentHeight': contentHeight,
      'viewportHeight': viewportHeight,
      'isChapterStart': isChapterStart,
      'isChapterEnd': isChapterEnd,
      'isLoading': isLoading,
      'errorMessage': errorMessage,
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }

  factory TextPage.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List? ?? const [];
    return TextPage(
      pageIndex: json['pageIndex'] ?? json['index'] ?? 0,
      title: json['title'] ?? '',
      chapterIndex: json['chapterIndex'] ?? 0,
      chapterSize: json['chapterSize'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
      startCharOffset: json['startCharOffset'],
      endCharOffset: json['endCharOffset'],
      height: (json['height'] as num?)?.toDouble(),
      contentHeight: (json['contentHeight'] as num?)?.toDouble(),
      viewportHeight: (json['viewportHeight'] as num?)?.toDouble(),
      isChapterStart: json['isChapterStart'],
      isChapterEnd: json['isChapterEnd'],
      isLoading: json['isLoading'] ?? false,
      errorMessage: json['errorMessage'],
      lines:
          rawLines
              .map(
                (line) =>
                    TextLine.fromJson(Map<String, dynamic>.from(line as Map)),
              )
              .toList(),
    );
  }

  static int _firstOffset(List<TextLine> lines) {
    for (final line in lines) {
      if (line.text.isNotEmpty) return line.startCharOffset;
    }
    return 0;
  }

  static int _lastOffset(List<TextLine> lines) {
    for (final line in lines.reversed) {
      if (line.text.isNotEmpty) return line.endCharOffset;
    }
    return _firstOffset(lines);
  }

  static double _pageHeight(List<TextLine> lines) {
    if (lines.isEmpty) return 0;
    return lines
        .map((line) => line.lineBottom)
        .fold<double>(0, (max, bottom) => bottom > max ? bottom : max);
  }
}
