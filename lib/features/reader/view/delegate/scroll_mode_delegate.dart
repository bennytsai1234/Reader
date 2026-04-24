import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/page_view_widget.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_layout.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'page_mode_delegate.dart';

class ScrollModeDelegate extends PageModeDelegate {
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Map<String, GlobalKey> pageKeys;
  final bool Function() isUserScrolling;

  const ScrollModeDelegate({
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.pageKeys,
    required this.isUserScrolling,
  });

  @override
  Widget build({
    required BuildContext context,
    required ReaderProvider provider,
    required PageController pageController,
    GestureTapUpCallback? onContentTapUp,
  }) {
    final contentStyle = TextStyle(
      fontSize: provider.fontSize,
      height: provider.lineHeight,
      color: provider.currentTheme.textColor,
      letterSpacing: provider.letterSpacing,
    );
    final titleStyle = TextStyle(
      fontSize: provider.fontSize + 4,
      fontWeight: FontWeight.bold,
      color: provider.currentTheme.textColor,
      letterSpacing: provider.letterSpacing,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: provider.scrollViewportTopInset,
        bottom: provider.scrollViewportBottomInset,
      ),
      child: ScrollablePositionedList.builder(
        itemCount: provider.chapters.length,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        initialScrollIndex:
            provider.chapters.isEmpty
                ? 0
                : provider.currentChapterIndex
                    .clamp(0, provider.chapters.length - 1)
                    .toInt(),
        initialAlignment:
            provider.visibleChapterAlignment.clamp(0.0, 1.0).toDouble(),
        physics:
            provider.shouldBlockScrollInputForRestore
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
        itemBuilder: (_, chapterIndex) {
          final runtimeChapter = provider.chapterAt(chapterIndex);
          var pages = runtimeChapter?.pages;

          if (pages == null || pages.isEmpty) {
            final estimatedHeight = _estimateChapterItemHeight(
              provider,
              chapterIndex,
            );
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: onContentTapUp,
              child: Container(
                color: provider.currentTheme.backgroundColor,
                height: estimatedHeight,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: provider.currentTheme.textColor.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ),
            );
          }
          return Container(
            color: provider.currentTheme.backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final page in pages)
                  SizedBox(
                    key: pageKeys.putIfAbsent(
                      '$chapterIndex:${page.index}',
                      GlobalKey.new,
                    ),
                    height: runtimeChapter?.pageHeightAt(page.index) ?? 0,
                    child: PageViewWidget(
                      page: page,
                      onPageTapUp: onContentTapUp,
                      contentStyle: contentStyle,
                      titleStyle: titleStyle,
                      ttsPosition: provider.currentTtsPosition,
                      isScrollMode: true,
                      paddingTop: 0,
                      paddingBottom: 0,
                      pageBackgroundColor:
                          provider.currentTheme.backgroundColor,
                    ),
                  ),
                if (chapterIndex < provider.chapters.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: ReaderScrollLayout.chapterSeparatorPadding(
                        fontSize: provider.fontSize,
                        lineHeight: provider.lineHeight,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 1,
                        color: provider.currentTheme.textColor.withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _estimateChapterItemHeight(ReaderProvider provider, int chapterIndex) {
    final knownHeight = provider.estimatedChapterContentHeight(chapterIndex);
    if (knownHeight > 0) {
      return ReaderScrollLayout.chapterItemExtent(
        contentHeight: knownHeight,
        hasSeparator: chapterIndex < provider.chapters.length - 1,
        fontSize: provider.fontSize,
        lineHeight: provider.lineHeight,
      );
    }

    final heights = <double>[];
    for (final offset in [-1, 1]) {
      final neighbor = chapterIndex + offset;
      if (neighbor < 0 || neighbor >= provider.chapters.length) continue;
      final neighborHeight = provider.estimatedChapterContentHeight(neighbor);
      if (neighborHeight > 0) {
        heights.add(neighborHeight);
      }
    }
    final viewportHeight =
        ((provider.viewSize?.height ?? 600.0) -
                provider.contentTopInset -
                provider.contentBottomInset)
            .clamp(1.0, double.infinity)
            .toDouble();
    final estimatedContentHeight =
        heights.isEmpty
            ? viewportHeight
            : heights.reduce((double a, double b) => a + b) / heights.length;
    provider.recordEstimatedPlaceholderChapterContentHeight(
      chapterIndex,
      contentHeight: estimatedContentHeight,
    );
    return ReaderScrollLayout.chapterItemExtent(
      contentHeight: estimatedContentHeight,
      hasSeparator: chapterIndex < provider.chapters.length - 1,
      fontSize: provider.fontSize,
      lineHeight: provider.lineHeight,
    );
  }
}
