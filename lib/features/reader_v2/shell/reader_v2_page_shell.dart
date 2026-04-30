import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_constants.dart';
import 'package:inkpage_reader/features/reader_v2/features/menu/reader_v2_bottom_menu.dart';
import 'package:inkpage_reader/features/reader_v2/features/menu/reader_v2_top_menu.dart';
import 'package:inkpage_reader/features/reader_v2/shell/reader_v2_chapters_drawer.dart';

class ReaderV2PageShell extends StatelessWidget {
  const ReaderV2PageShell({
    super.key,
    required this.book,
    required this.scaffoldKey,
    required this.content,
    required this.drawer,
    required this.backgroundColor,
    required this.textColor,
    required this.controlsVisible,
    required this.readBarStyleFollowPage,
    required this.showReadTitleAddition,
    required this.hasVisibleContent,
    required this.isLoading,
    required this.chapterTitle,
    required this.chapterUrl,
    required this.originName,
    required this.displayPageLabel,
    required this.displayChapterPercentLabel,
    required this.navigation,
    required this.isAutoPaging,
    required this.dayNightIcon,
    required this.dayNightTooltip,
    required this.onExitIntent,
    required this.onMore,
    required this.onOpenDrawer,
    required this.onTts,
    required this.onInterface,
    required this.onSettings,
    required this.onAutoPage,
    required this.onToggleDayNight,
    required this.onReplaceRule,
    required this.onShowControls,
    required this.onDismissControls,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onScrubStart,
    required this.onScrubbing,
    required this.onScrubEnd,
    this.showTts = true,
    this.showAutoPage = true,
    this.showReplaceRule = true,
  });

  final Book book;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget content;
  final ReaderV2ChaptersDrawer drawer;
  final Color backgroundColor;
  final Color textColor;
  final bool controlsVisible;
  final bool readBarStyleFollowPage;
  final bool showReadTitleAddition;
  final bool hasVisibleContent;
  final bool isLoading;
  final String chapterTitle;
  final String chapterUrl;
  final String originName;
  final String displayPageLabel;
  final String displayChapterPercentLabel;
  final ReaderV2ChapterNavigationState navigation;
  final bool isAutoPaging;
  final IconData dayNightIcon;
  final String dayNightTooltip;
  final VoidCallback onExitIntent;
  final VoidCallback onMore;
  final VoidCallback onOpenDrawer;
  final VoidCallback onTts;
  final VoidCallback onInterface;
  final VoidCallback onSettings;
  final VoidCallback onAutoPage;
  final VoidCallback onToggleDayNight;
  final VoidCallback onReplaceRule;
  final VoidCallback onShowControls;
  final VoidCallback onDismissControls;
  final VoidCallback onPrevChapter;
  final VoidCallback onNextChapter;
  final VoidCallback onScrubStart;
  final ValueChanged<int> onScrubbing;
  final ValueChanged<int> onScrubEnd;
  final bool showTts;
  final bool showAutoPage;
  final bool showReplaceRule;

  @override
  Widget build(BuildContext context) {
    final topSystemExtent = _topSystemExtent(context);
    final permanentInfoExtent =
        showReadTitleAddition ? _permanentInfoExtent(context) : 0.0;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onExitIntent();
      },
      child: Scaffold(
        key: scaffoldKey,
        body: Container(
          color: backgroundColor,
          child: Stack(
            children: [
              Positioned.fill(
                top: topSystemExtent,
                bottom: permanentInfoExtent,
                child: content,
              ),
              if (topSystemExtent > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topSystemExtent,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => onShowControls(),
                    child: _TopSystemInfoBar(shell: this),
                  ),
                ),
              if (_shouldShowPermanentInfo())
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: permanentInfoExtent,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => onShowControls(),
                    child: _PermanentInfoBar(shell: this),
                  ),
                ),
              if (controlsVisible)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => onDismissControls(),
                  ),
                ),
              ReaderV2TopMenu(
                controlsVisible: controlsVisible,
                readBarStyleFollowPage: readBarStyleFollowPage,
                pageBackgroundColor: backgroundColor,
                pageTextColor: textColor,
                bookName: book.name,
                chapterTitle: chapterTitle,
                chapterUrl: chapterUrl,
                originName: originName,
                showReadTitleAddition: showReadTitleAddition,
                onBack: onExitIntent,
                onMore: onMore,
              ),
              ReaderV2BottomMenu(
                controlsVisible: controlsVisible,
                readBarStyleFollowPage: readBarStyleFollowPage,
                pageBackgroundColor: backgroundColor,
                pageTextColor: textColor,
                navigation: navigation,
                isAutoPaging: isAutoPaging,
                dayNightIcon: dayNightIcon,
                dayNightTooltip: dayNightTooltip,
                onOpenDrawer: onOpenDrawer,
                onTts: onTts,
                onInterface: onInterface,
                onSettings: onSettings,
                onAutoPage: onAutoPage,
                onToggleDayNight: onToggleDayNight,
                onReplaceRule: onReplaceRule,
                onPrevChapter: onPrevChapter,
                onNextChapter: onNextChapter,
                onScrubStart: onScrubStart,
                onScrubbing: onScrubbing,
                onScrubEnd: onScrubEnd,
                showTts: showTts,
                showAutoPage: showAutoPage,
                showReplaceRule: showReplaceRule,
              ),
            ],
          ),
        ),
        drawer: drawer,
      ),
    );
  }

  bool _shouldShowPermanentInfo() {
    return hasVisibleContent && !isLoading && showReadTitleAddition;
  }

  double _permanentInfoExtent(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom +
        kReaderPermanentInfoReservedHeight;
  }

  double _topSystemExtent(BuildContext context) {
    return MediaQuery.paddingOf(context).top;
  }
}

class _TopSystemInfoBar extends StatelessWidget {
  const _TopSystemInfoBar({required this.shell});

  final ReaderV2PageShell shell;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: shell.backgroundColor);
  }
}

class _PermanentInfoBar extends StatelessWidget {
  const _PermanentInfoBar({required this.shell});

  final ReaderV2PageShell shell;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            shell.backgroundColor.withValues(alpha: 0.0),
            shell.backgroundColor.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          kReaderPermanentInfoTopPadding,
          16,
          MediaQuery.of(context).padding.bottom +
              kReaderPermanentInfoBottomSpacing,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                shell.book.name,
                style: TextStyle(
                  color: shell.textColor.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              shell.displayPageLabel,
              style: TextStyle(
                color: shell.textColor.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Text(
                shell.displayChapterPercentLabel,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: shell.textColor.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
