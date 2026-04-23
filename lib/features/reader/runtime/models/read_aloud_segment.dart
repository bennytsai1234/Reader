class ReadAloudSegment {
  final int chapterIndex;
  final int pageIndex;
  final int lineIndex;
  final int chapterStart;
  final int chapterEnd;
  final String text;

  const ReadAloudSegment({
    required this.chapterIndex,
    required this.pageIndex,
    required this.lineIndex,
    required this.chapterStart,
    required this.chapterEnd,
    required this.text,
  });

  int get length => chapterEnd - chapterStart;

  String get id => '$chapterIndex-$pageIndex-$lineIndex-$chapterStart';
}

class ReadAloudBuildResult {
  final int chapterIndex;
  final int startCharOffset;
  final List<ReadAloudSegment> segments;

  const ReadAloudBuildResult({
    required this.chapterIndex,
    required this.startCharOffset,
    required this.segments,
  });
}
