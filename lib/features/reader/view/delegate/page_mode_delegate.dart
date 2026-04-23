import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/page_view_widget.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';

class PageModeDelegate {
  const PageModeDelegate();

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

    return PageView.builder(
      controller: pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: provider.slidePages.length,
      onPageChanged: (i) {
        provider.handleSlidePageChanged(i);
      },
      itemBuilder: (_, i) {
        if (i < 0 || i >= provider.slidePages.length) {
          return const SizedBox.shrink();
        }
        return PageViewWidget(
          page: provider.slidePages[i],
          onPageTapUp: onContentTapUp,
          contentStyle: contentStyle,
          titleStyle: titleStyle,
          ttsPosition: provider.currentTtsPosition,
          paddingTop: provider.contentTopInset,
          paddingBottom: provider.contentBottomInset,
          isAutoPaging: provider.isAutoPaging,
          autoPageProgress: provider.autoPageProgress,
          nextPage: provider.nextPageForAutoPage,
          pageBackgroundColor: provider.currentTheme.backgroundColor,
        );
      },
    );
  }
}
