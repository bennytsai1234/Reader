class ReadAloudOffsetMap {
  final int ttsOffset;
  final int chapterOffset;

  const ReadAloudOffsetMap({
    required this.ttsOffset,
    required this.chapterOffset,
  });
}

class ReadAloudSegment {
  final int chapterIndex;
  final int pageIndex;
  final int lineIndex;
  final int chapterStart;
  final int chapterEnd;
  final String text;
  final List<ReadAloudOffsetMap> offsetMap;

  const ReadAloudSegment({
    required this.chapterIndex,
    required this.pageIndex,
    required this.lineIndex,
    required this.chapterStart,
    required this.chapterEnd,
    required this.text,
    this.offsetMap = const [],
  });

  int get length => chapterEnd - chapterStart;

  String get id => '$chapterIndex-$pageIndex-$lineIndex-$chapterStart';

  int chapterOffsetForTtsOffset(int ttsOffset) {
    if (offsetMap.isEmpty) {
      return (chapterStart + ttsOffset).clamp(chapterStart, chapterEnd).toInt();
    }

    ReadAloudOffsetMap? current;
    for (final item in offsetMap) {
      if (item.ttsOffset <= ttsOffset) {
        current = item;
      } else {
        break;
      }
    }

    if (current == null) return chapterStart;
    final delta = ttsOffset - current.ttsOffset;
    return (current.chapterOffset + delta)
        .clamp(chapterStart, chapterEnd)
        .toInt();
  }
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
