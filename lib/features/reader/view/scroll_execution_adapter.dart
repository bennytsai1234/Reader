import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_layout.dart';

class ReaderScrollAnchorLocation {
  final int chapterIndex;
  final int pageIndex;
  final double localOffset;

  const ReaderScrollAnchorLocation({
    required this.chapterIndex,
    required this.pageIndex,
    required this.localOffset,
  });
}

class ScrollExecutionAdapter {
  final Map<String, GlobalKey> pageKeys;
  final VoidCallback? onStateChanged;

  const ScrollExecutionAdapter({required this.pageKeys, this.onStateChanged});

  bool scrollByDelta({
    required ReaderProvider provider,
    required double deltaPixels,
  }) {
    if (deltaPixels <= 0) return false;
    final position = _resolveActiveScrollPosition(provider);
    if (position == null || !position.hasPixels) {
      return false;
    }
    final currentPixels = position.pixels;
    final targetPixels = (currentPixels + deltaPixels).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((targetPixels - currentPixels).abs() < 0.1) {
      return false;
    }
    position.jumpTo(targetPixels);
    onStateChanged?.call();
    return true;
  }

  void scrollToPageKey({
    required int chapterIndex,
    required int pageIndex,
    bool animate = false,
  }) {
    final key = pageKeys['$chapterIndex:$pageIndex'];
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: animate ? const Duration(milliseconds: 240) : Duration.zero,
      alignment: 0,
      curve: Curves.easeOut,
    );
  }

  void scrollToChapterLocalOffset({
    required ReaderProvider provider,
    required int chapterIndex,
    required double localOffset,
    bool animate = false,
    Duration duration = Duration.zero,
    double topPadding = 0.0,
  }) {
    final runtimeChapter = provider.chapterAt(chapterIndex);
    final pages = provider.pagesForChapter(chapterIndex);
    if ((runtimeChapter == null && pages.isEmpty) ||
        (runtimeChapter != null && runtimeChapter.isEmpty)) {
      return;
    }
    final target =
        runtimeChapter != null
            ? runtimeChapter.resolveRestoreTarget(localOffset: localOffset)
            : () {
              final pageIndex = ChapterPositionResolver.pageIndexAtLocalOffset(
                pages,
                localOffset,
              );
              final pageStartOffset =
                  ChapterPositionResolver.getCharOffsetForPage(
                    pages,
                    pageIndex,
                  );
              final pageStartLocalOffset =
                  ChapterPositionResolver.charOffsetToLocalOffset(
                    pages,
                    pageStartOffset,
                  );
              final intraPageOffset = (localOffset - pageStartLocalOffset)
                  .clamp(0.0, double.infinity);
              return (
                pageIndex: pageIndex,
                pageStartCharOffset: pageStartOffset,
                pageStartLocalOffset: pageStartLocalOffset,
                targetLocalOffset: localOffset,
                intraPageOffset: intraPageOffset,
                alignment: ChapterPositionResolver.charOffsetToAlignment(
                  pages,
                  pageStartOffset,
                ),
              );
            }();
    final key = pageKeys['$chapterIndex:${target.pageIndex}'];
    final pageContext = key?.currentContext;
    if (pageContext == null) {
      scrollToPageKey(
        chapterIndex: chapterIndex,
        pageIndex: target.pageIndex,
        animate: animate,
      );
      return;
    }
    void applyScrollOffset() {
      final position = Scrollable.maybeOf(pageContext)?.position;
      final renderObject = pageContext.findRenderObject();
      final viewportObject =
          Scrollable.maybeOf(pageContext)?.context.findRenderObject();
      if (position == null ||
          renderObject is! RenderBox ||
          viewportObject is! RenderBox) {
        return;
      }
      final pageTop =
          renderObject.localToGlobal(Offset.zero, ancestor: viewportObject).dy;
      final targetPixels = (position.pixels +
              pageTop +
              target.intraPageOffset -
              topPadding)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if (animate) {
        position.animateTo(
          targetPixels,
          duration: duration,
          curve: Curves.easeOut,
        );
      } else {
        position.jumpTo(targetPixels);
      }
      onStateChanged?.call();
    }

    final renderObject = pageContext.findRenderObject();
    final viewportObject =
        Scrollable.maybeOf(pageContext)?.context.findRenderObject();
    if (renderObject is RenderBox && viewportObject is RenderBox) {
      final pageTop =
          renderObject.localToGlobal(Offset.zero, ancestor: viewportObject).dy;
      final pageBottom = pageTop + renderObject.size.height;
      final viewportHeight = viewportObject.size.height;
      final isVisible = pageBottom > 0 && pageTop < viewportHeight;
      if (isVisible) {
        applyScrollOffset();
        return;
      }
    }

    Scrollable.ensureVisible(
      pageContext,
      duration: animate ? duration : Duration.zero,
      alignment: 0,
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => applyScrollOffset());
  }

  ReaderScrollAnchorLocation? resolveAnchorLocation({
    required ReaderProvider provider,
    double anchorRatio = ReaderScrollLayout.anchorRatio,
  }) {
    final visiblePages = <_VisiblePageGeometry>[];
    for (final entry in pageKeys.entries) {
      final pageAddress = _parsePageAddress(entry.key);
      if (pageAddress == null) continue;

      final pageContext = entry.value.currentContext;
      final renderObject = pageContext?.findRenderObject();
      final viewportObject =
          pageContext == null
              ? null
              : Scrollable.maybeOf(pageContext)?.context.findRenderObject();
      if (renderObject is! RenderBox || viewportObject is! RenderBox) {
        continue;
      }

      final pageTop =
          renderObject.localToGlobal(Offset.zero, ancestor: viewportObject).dy;
      final pageHeight = renderObject.size.height;
      final pageBottom = pageTop + pageHeight;
      final viewportHeight = viewportObject.size.height;
      if (pageBottom <= 0 || pageTop >= viewportHeight || pageHeight <= 0) {
        continue;
      }

      final pageStartLocalOffset = _pageStartLocalOffset(
        provider: provider,
        chapterIndex: pageAddress.chapterIndex,
        pageIndex: pageAddress.pageIndex,
      );
      if (pageStartLocalOffset == null) continue;

      visiblePages.add(
        _VisiblePageGeometry(
          chapterIndex: pageAddress.chapterIndex,
          pageIndex: pageAddress.pageIndex,
          pageTop: pageTop,
          pageHeight: pageHeight,
          pageStartLocalOffset: pageStartLocalOffset,
          viewportHeight: viewportHeight,
        ),
      );
    }

    if (visiblePages.isEmpty) return null;

    visiblePages.sort((a, b) => a.pageTop.compareTo(b.pageTop));
    final viewportHeight = visiblePages.first.viewportHeight;
    final anchorY = viewportHeight * anchorRatio.clamp(0.0, 1.0);

    _VisiblePageGeometry focusPage = visiblePages.first;
    var minDistance = double.infinity;
    for (final page in visiblePages) {
      if (page.pageTop <= anchorY && page.pageBottom > anchorY) {
        focusPage = page;
        minDistance = 0;
        break;
      }
      final distance =
          anchorY < page.pageTop
              ? page.pageTop - anchorY
              : anchorY - page.pageBottom;
      if (distance < minDistance) {
        minDistance = distance;
        focusPage = page;
      }
    }

    final localOffset =
        (focusPage.pageStartLocalOffset +
                (anchorY - focusPage.pageTop).clamp(0.0, focusPage.pageHeight))
            .clamp(0.0, _chapterHeight(provider, focusPage.chapterIndex))
            .toDouble();
    return ReaderScrollAnchorLocation(
      chapterIndex: focusPage.chapterIndex,
      pageIndex: focusPage.pageIndex,
      localOffset: localOffset,
    );
  }

  ScrollPosition? _resolveActiveScrollPosition(ReaderProvider provider) {
    final chapterIndex = provider.visibleChapterIndex;
    final runtimeChapter = provider.chapterAt(chapterIndex);
    final pages = provider.pagesForChapter(chapterIndex);
    final pageIndex =
        runtimeChapter != null
            ? runtimeChapter.pageIndexAtLocalOffset(
              provider.visibleChapterLocalOffset,
            )
            : ChapterPositionResolver.pageIndexAtLocalOffset(
              pages,
              provider.visibleChapterLocalOffset,
            );
    final primaryContext = pageKeys['$chapterIndex:$pageIndex']?.currentContext;
    final primaryPosition = _scrollPositionFromContext(primaryContext);
    if (primaryPosition != null) {
      return primaryPosition;
    }
    for (final key in pageKeys.values) {
      final position = _scrollPositionFromContext(key.currentContext);
      if (position != null) {
        return position;
      }
    }
    return null;
  }

  ScrollPosition? _scrollPositionFromContext(BuildContext? context) {
    if (context == null) return null;
    return Scrollable.maybeOf(context)?.position;
  }

  ({int chapterIndex, int pageIndex})? _parsePageAddress(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final chapterIndex = int.tryParse(parts[0]);
    final pageIndex = int.tryParse(parts[1]);
    if (chapterIndex == null || pageIndex == null) return null;
    return (chapterIndex: chapterIndex, pageIndex: pageIndex);
  }

  double? _pageStartLocalOffset({
    required ReaderProvider provider,
    required int chapterIndex,
    required int pageIndex,
  }) {
    final runtimeChapter = provider.chapterAt(chapterIndex);
    if (runtimeChapter != null) {
      if (pageIndex < 0 || pageIndex >= runtimeChapter.pageCount) return null;
      return runtimeChapter.localOffsetForPageIndex(pageIndex);
    }

    final pages = provider.pagesForChapter(chapterIndex);
    if (pageIndex < 0 || pageIndex >= pages.length) return null;
    final pageStartCharOffset = ChapterPositionResolver.getCharOffsetForPage(
      pages,
      pageIndex,
    );
    return ChapterPositionResolver.charOffsetToLocalOffset(
      pages,
      pageStartCharOffset,
    );
  }

  double _chapterHeight(ReaderProvider provider, int chapterIndex) {
    return provider.estimatedChapterContentHeight(chapterIndex);
  }
}

class _VisiblePageGeometry {
  final int chapterIndex;
  final int pageIndex;
  final double pageTop;
  final double pageHeight;
  final double pageStartLocalOffset;
  final double viewportHeight;

  const _VisiblePageGeometry({
    required this.chapterIndex,
    required this.pageIndex,
    required this.pageTop,
    required this.pageHeight,
    required this.pageStartLocalOffset,
    required this.viewportHeight,
  });

  double get pageBottom => pageTop + pageHeight;
}
