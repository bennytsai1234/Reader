class ReaderLocation {
  static const double minVisualOffsetPx = -80.0;
  static const double maxVisualOffsetPx = 120.0;

  final int chapterIndex;
  final int charOffset;
  final double visualOffsetPx;

  const ReaderLocation({
    required this.chapterIndex,
    required this.charOffset,
    this.visualOffsetPx = 0.0,
  });

  static double normalizeVisualOffsetPx(double value) {
    if (!value.isFinite || value.isNaN) return 0.0;
    return value.clamp(minVisualOffsetPx, maxVisualOffsetPx).toDouble();
  }

  factory ReaderLocation.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double asDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ReaderLocation(
      chapterIndex: asInt(json['chapterIndex']),
      charOffset: asInt(json['charOffset']),
      visualOffsetPx: asDouble(json['visualOffsetPx']),
    ).normalized();
  }

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
    return ReaderLocation(
      chapterIndex: safeChapter,
      charOffset: safeOffset,
      visualOffsetPx: normalizeVisualOffsetPx(visualOffsetPx),
    );
  }

  ReaderLocation copyWith({
    int? chapterIndex,
    int? charOffset,
    double? visualOffsetPx,
  }) {
    return ReaderLocation(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      charOffset: charOffset ?? this.charOffset,
      visualOffsetPx: visualOffsetPx ?? this.visualOffsetPx,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterIndex': chapterIndex,
      'charOffset': charOffset,
      'visualOffsetPx': visualOffsetPx,
    };
  }

  @override
  String toString() =>
      'ReaderLocation(chapterIndex: $chapterIndex, charOffset: $charOffset, visualOffsetPx: $visualOffsetPx)';

  @override
  bool operator ==(Object other) {
    return other is ReaderLocation &&
        other.chapterIndex == chapterIndex &&
        other.charOffset == charOffset &&
        other.visualOffsetPx == visualOffsetPx;
  }

  @override
  int get hashCode => Object.hash(chapterIndex, charOffset, visualOffsetPx);
}
