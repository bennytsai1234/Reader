class ReaderLocation {
  final int chapterIndex;
  final int charOffset;

  const ReaderLocation({required this.chapterIndex, required this.charOffset});

  ReaderLocation normalized({int? chapterCount, int? chapterLength}) {
    final maxChapter =
        chapterCount == null || chapterCount <= 0 ? null : chapterCount - 1;
    final safeChapter =
        maxChapter == null
            ? (chapterIndex < 0 ? 0 : chapterIndex)
            : chapterIndex.clamp(0, maxChapter).toInt();
    final maxOffset =
        chapterLength == null || chapterLength < 0 ? null : chapterLength;
    final safeOffset =
        maxOffset == null
            ? (charOffset < 0 ? 0 : charOffset)
            : charOffset.clamp(0, maxOffset).toInt();
    return ReaderLocation(chapterIndex: safeChapter, charOffset: safeOffset);
  }

  ReaderLocation copyWith({int? chapterIndex, int? charOffset}) {
    return ReaderLocation(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      charOffset: charOffset ?? this.charOffset,
    );
  }

  @override
  String toString() =>
      'ReaderLocation(chapterIndex: $chapterIndex, charOffset: $charOffset)';

  @override
  bool operator ==(Object other) {
    return other is ReaderLocation &&
        other.chapterIndex == chapterIndex &&
        other.charOffset == charOffset;
  }

  @override
  int get hashCode => Object.hash(chapterIndex, charOffset);
}
