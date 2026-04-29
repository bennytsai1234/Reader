import 'package:flutter/material.dart';
import 'reader_menu_palette.dart';

class ReaderChapterNavigationState {
  const ReaderChapterNavigationState({
    required this.chapterCount,
    required this.currentIndex,
    required this.isScrubbing,
    required this.scrubIndex,
    required this.pendingIndex,
    required this.titleFor,
  });

  final int chapterCount;
  final int currentIndex;
  final bool isScrubbing;
  final int scrubIndex;
  final int? pendingIndex;
  final String Function(int index) titleFor;

  bool get hasPending => pendingIndex != null;
  bool get canNavigateToPrev => chapterCount > 1 && currentIndex > 0;
  bool get canNavigateToNext =>
      chapterCount > 1 && currentIndex < chapterCount - 1;
  int get displayIndex =>
      isScrubbing ? scrubIndex : (pendingIndex ?? currentIndex);
}

class ReaderBottomMenu extends StatelessWidget {
  const ReaderBottomMenu({
    super.key,
    required this.controlsVisible,
    required this.readBarStyleFollowPage,
    required this.pageBackgroundColor,
    required this.pageTextColor,
    required this.navigation,
    required this.isAutoPaging,
    required this.dayNightIcon,
    required this.dayNightTooltip,
    required this.onOpenDrawer,
    required this.onTts,
    required this.onInterface,
    required this.onSettings,
    required this.onAutoPage,
    required this.onToggleDayNight,
    required this.onSearch,
    required this.onReplaceRule,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onScrubStart,
    required this.onScrubbing,
    required this.onScrubEnd,
    this.showTts = true,
    this.showAutoPage = true,
    this.showSearch = true,
    this.showReplaceRule = true,
  });

  final bool controlsVisible;
  final bool readBarStyleFollowPage;
  final Color pageBackgroundColor;
  final Color pageTextColor;
  final ReaderChapterNavigationState navigation;
  final bool isAutoPaging;
  final IconData dayNightIcon;
  final String dayNightTooltip;
  final VoidCallback onOpenDrawer;
  final VoidCallback onTts;
  final VoidCallback onInterface;
  final VoidCallback onSettings;
  final VoidCallback onAutoPage;
  final VoidCallback onToggleDayNight;
  final VoidCallback onSearch;
  final VoidCallback onReplaceRule;
  final VoidCallback onPrevChapter;
  final VoidCallback onNextChapter;
  final VoidCallback onScrubStart;
  final ValueChanged<int> onScrubbing;
  final ValueChanged<int> onScrubEnd;
  final bool showTts;
  final bool showAutoPage;
  final bool showSearch;
  final bool showReplaceRule;

  @override
  Widget build(BuildContext context) {
    final menuStyle = ReaderMenuStyle.resolve(
      context: context,
      followPageStyle: readBarStyleFollowPage,
      pageBackgroundColor: pageBackgroundColor,
      pageTextColor: pageTextColor,
    );
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !controlsVisible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          offset: controlsVisible ? Offset.zero : const Offset(0, 1.15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFloatingButtons(menuStyle),
              Container(
                padding: EdgeInsets.fromLTRB(
                  0,
                  8,
                  0,
                  MediaQuery.of(context).padding.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: menuStyle.background,
                  border: Border(top: BorderSide(color: menuStyle.outline)),
                  boxShadow: [
                    BoxShadow(
                      color: menuStyle.scrim,
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChapterSlider(context, menuStyle),
                    const SizedBox(height: 8),
                    _buildMainActions(menuStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(ReaderMenuStyle menuStyle) {
    final actions = <Widget>[
      if (showSearch)
        _floatingFab(
          icon: Icons.search,
          tooltip: '搜尋',
          onTap: onSearch,
          menuStyle: menuStyle,
        ),
      if (showAutoPage)
        _floatingFab(
          icon: Icons.auto_stories_outlined,
          tooltip: isAutoPaging ? '停止自動翻頁' : '開始自動翻頁',
          onTap: onAutoPage,
          menuStyle: menuStyle,
          active: isAutoPaging,
        ),
      if (showReplaceRule)
        _floatingFab(
          icon: Icons.find_replace,
          tooltip: '替換規則',
          onTap: onReplaceRule,
          menuStyle: menuStyle,
        ),
      _floatingFab(
        icon: dayNightIcon,
        tooltip: dayNightTooltip,
        onTap: onToggleDayNight,
        menuStyle: menuStyle,
      ),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions,
      ),
    );
  }

  Widget _floatingFab({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required ReaderMenuStyle menuStyle,
    bool active = false,
  }) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: onTap,
      tooltip: tooltip,
      backgroundColor: menuStyle.backgroundElevated,
      foregroundColor: active ? menuStyle.accent : menuStyle.foreground,
      child: Icon(icon),
    );
  }

  Widget _buildChapterSlider(BuildContext context, ReaderMenuStyle menuStyle) {
    final maxVal =
        (navigation.chapterCount <= 1 ? 0 : navigation.chapterCount - 1)
            .toDouble();
    final displayIndex = navigation.displayIndex.clamp(
      0,
      navigation.chapterCount <= 0 ? 0 : navigation.chapterCount - 1,
    );
    final displayTitle =
        navigation.chapterCount > 0 ? navigation.titleFor(displayIndex) : '';
    final canChangeChapter =
        navigation.chapterCount > 1 && !navigation.hasPending;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if ((navigation.isScrubbing || navigation.hasPending) &&
              displayTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (navigation.hasPending) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          menuStyle.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      displayTitle,
                      style: TextStyle(
                        color: menuStyle.mutedForeground,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              TextButton(
                onPressed: navigation.canNavigateToPrev ? onPrevChapter : null,
                style: TextButton.styleFrom(
                  foregroundColor: menuStyle.foreground,
                ),
                child: const Text('上一章', style: TextStyle(fontSize: 14)),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: displayIndex.toDouble().clamp(0, maxVal),
                    min: 0,
                    max: maxVal,
                    onChangeStart:
                        canChangeChapter ? (_) => onScrubStart() : null,
                    onChanged:
                        canChangeChapter ? (v) => onScrubbing(v.toInt()) : null,
                    onChangeEnd:
                        canChangeChapter ? (v) => onScrubEnd(v.toInt()) : null,
                    activeColor: menuStyle.accent,
                    inactiveColor: menuStyle.mutedForeground.withValues(
                      alpha: 0.24,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: navigation.canNavigateToNext ? onNextChapter : null,
                style: TextButton.styleFrom(
                  foregroundColor: menuStyle.foreground,
                ),
                child: const Text('下一章', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions(ReaderMenuStyle menuStyle) {
    final actions = <Widget>[
      _menuIcon(Icons.list, '目錄', onOpenDrawer, menuStyle),
      if (showTts) _menuIcon(Icons.record_voice_over, '朗讀', onTts, menuStyle),
      _menuIcon(Icons.color_lens, '介面', onInterface, menuStyle),
      _menuIcon(Icons.settings, '設定', onSettings, menuStyle),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }

  Widget _menuIcon(
    IconData icon,
    String label,
    VoidCallback onTap,
    ReaderMenuStyle menuStyle,
  ) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: menuStyle.foreground, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(color: menuStyle.foreground, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
