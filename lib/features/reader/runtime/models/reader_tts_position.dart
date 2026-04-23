class ReaderTtsPosition {
  final int chapterIndex;
  final int pageIndex;
  final int lineIndex;
  final int highlightStart;
  final int highlightEnd;
  final int wordStart;
  final int wordEnd;
  final double localOffset;
  final int followKey;

  const ReaderTtsPosition({
    required this.chapterIndex,
    required this.pageIndex,
    required this.lineIndex,
    required this.highlightStart,
    required this.highlightEnd,
    required this.wordStart,
    required this.wordEnd,
    required this.localOffset,
    required this.followKey,
  });

  bool get hasWordFocus => wordStart >= 0 && wordEnd > wordStart;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderTtsPosition &&
        other.chapterIndex == chapterIndex &&
        other.pageIndex == pageIndex &&
        other.lineIndex == lineIndex &&
        other.highlightStart == highlightStart &&
        other.highlightEnd == highlightEnd &&
        other.wordStart == wordStart &&
        other.wordEnd == wordEnd &&
        other.localOffset == localOffset &&
        other.followKey == followKey;
  }

  @override
  int get hashCode => Object.hash(
    chapterIndex,
    pageIndex,
    lineIndex,
    highlightStart,
    highlightEnd,
    wordStart,
    wordEnd,
    localOffset,
    followKey,
  );
}
