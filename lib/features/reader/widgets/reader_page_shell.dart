import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/reader/reader_layout.dart';
import 'package:inkpage_reader/features/reader/widgets/reader/reader_bottom_menu.dart';
import 'package:inkpage_reader/features/reader/widgets/reader/reader_top_menu.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_chapters_drawer.dart';

class ReaderPageShell extends StatelessWidget {
  const ReaderPageShell({
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
    required this.onSearch,
    required this.onReplaceRule,
    required this.onToggleControls,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onScrubStart,
    required this.onScrubbing,
    required this.onScrubEnd,
  });

  final Book book;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget content;
  final ReaderChaptersDrawer drawer;
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
  final ReaderChapterNavigationState navigation;
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
  final VoidCallback onSearch;
  final VoidCallback onReplaceRule;
  final VoidCallback onToggleControls;
  final VoidCallback onPrevChapter;
  final VoidCallback onNextChapter;
  final VoidCallback onScrubStart;
  final ValueChanged<int> onScrubbing;
  final ValueChanged<int> onScrubEnd;

  @override
  Widget build(BuildContext context) {
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
              Positioned.fill(child: content),
              if (_shouldShowPermanentInfo()) _PermanentInfoBar(shell: this),
              if (controlsVisible)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onToggleControls,
                  ),
                ),
              ReaderTopMenu(
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
              ReaderBottomMenu(
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
                onSearch: onSearch,
                onReplaceRule: onReplaceRule,
                onPrevChapter: onPrevChapter,
                onNextChapter: onNextChapter,
                onScrubStart: onScrubStart,
                onScrubbing: onScrubbing,
                onScrubEnd: onScrubEnd,
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
}

class _PermanentInfoBar extends StatelessWidget {
  const _PermanentInfoBar({required this.shell});

  final ReaderPageShell shell;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
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
      ),
    );
  }
}
