class ReaderScrollLayout {
  const ReaderScrollLayout._();

  static const double anchorRatio = 0.0;

  static double chapterSeparatorPadding({
    required double fontSize,
    required double lineHeight,
  }) {
    return (fontSize * lineHeight * 0.5).clamp(8.0, 24.0).toDouble();
  }

  static double chapterSeparatorExtent({
    required double fontSize,
    required double lineHeight,
  }) {
    final padding = chapterSeparatorPadding(
      fontSize: fontSize,
      lineHeight: lineHeight,
    );
    return (padding * 2) + 1.0;
  }

  static double chapterItemExtent({
    required double contentHeight,
    required bool hasSeparator,
    required double fontSize,
    required double lineHeight,
  }) {
    final normalizedContentHeight = contentHeight.clamp(0.0, double.infinity);
    if (!hasSeparator) return normalizedContentHeight;
    return normalizedContentHeight +
        chapterSeparatorExtent(fontSize: fontSize, lineHeight: lineHeight);
  }

  static double scrollViewportHeight({
    required double viewportHeight,
    required double topInset,
    required double bottomInset,
  }) {
    return (viewportHeight - topInset - bottomInset)
        .clamp(1.0, double.infinity)
        .toDouble();
  }

  static double anchorPadding({
    required double viewportHeight,
    required double topInset,
    required double bottomInset,
  }) {
    return scrollViewportHeight(
          viewportHeight: viewportHeight,
          topInset: topInset,
          bottomInset: bottomInset,
        ) *
        anchorRatio;
  }
}
