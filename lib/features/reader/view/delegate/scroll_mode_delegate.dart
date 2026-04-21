import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/page_view_widget.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
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
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, chapterIndex) {
          final runtimeChapter = provider.chapterAt(chapterIndex);
          var pages = runtimeChapter?.pages;

          // Fast path: eagerly paginate for local books to avoid placeholder flash
          if ((pages == null || pages.isEmpty) &&
              provider.book.origin == 'local') {
            // trySyncPaginate is actually async, but we fire-and-forget here
            // and rely on the notifyListeners callback to rebuild with real pages
            unawaited(provider.trySyncPaginate(chapterIndex));
          }

          if (pages == null || pages.isEmpty) {
            final estimatedHeight = _estimateChapterHeight(
              provider,
              chapterIndex,
            );
            return Container(
              color: provider.currentTheme.backgroundColor,
              height: estimatedHeight,
              alignment: Alignment.center,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: provider.currentTheme.textColor.withValues(alpha: 0.3),
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
                      contentStyle: contentStyle,
                      titleStyle: titleStyle,
                      isScrollMode: true,
                      paddingTop: 0,
                      paddingBottom: 0,
                      ttsStart: provider.ttsStart,
                      ttsEnd: provider.ttsEnd,
                      ttsWordStart: provider.ttsWordStart,
                      ttsWordEnd: provider.ttsWordEnd,
                      ttsChapterIndex: provider.ttsChapterIndex,
                      pageBackgroundColor:
                          provider.currentTheme.backgroundColor,
                    ),
                  ),
                if (chapterIndex < provider.chapters.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: (provider.fontSize * provider.lineHeight * 0.5)
                          .clamp(8.0, 24.0),
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

  double _estimateChapterHeight(ReaderProvider provider, int chapterIndex) {
    final heights = <double>[];
    for (final offset in [-1, 1]) {
      final neighbor = chapterIndex + offset;
      final neighborPages = provider.chapterPagesCache[neighbor];
      if (neighborPages != null && neighborPages.isNotEmpty) {
        heights.add(ChapterPositionResolver.chapterHeight(neighborPages));
      }
    }
    final viewportHeight =
        ((provider.viewSize?.height ?? 600.0) -
                provider.contentTopInset -
                provider.contentBottomInset)
            .clamp(1.0, double.infinity)
            .toDouble();
    if (heights.isEmpty) {
      return viewportHeight;
    }
    return heights.reduce((double a, double b) => a + b) / heights.length;
  }
}
