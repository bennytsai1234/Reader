import 'package:flutter/material.dart';
import '../../reader_provider.dart';
import 'reader_menu_palette.dart';

class ReaderBottomMenu extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onOpenDrawer;
  final VoidCallback onTts;
  final VoidCallback onInterface;
  final VoidCallback onSettings;
  final VoidCallback onAutoPage;
  final VoidCallback onToggleDayNight;
  final VoidCallback? onSearch;
  final VoidCallback? onReplaceRule;

  const ReaderBottomMenu({
    super.key,
    required this.provider,
    required this.onOpenDrawer,
    required this.onTts,
    required this.onInterface,
    required this.onSettings,
    required this.onAutoPage,
    required this.onToggleDayNight,
    this.onSearch,
    this.onReplaceRule,
  });

  @override
  Widget build(BuildContext context) {
    final menuStyle = ReaderMenuStyle.resolve(
      context: context,
      followPageStyle: provider.readBarStyleFollowPage,
      pageBackgroundColor: provider.currentTheme.backgroundColor,
      pageTextColor: provider.currentTheme.textColor,
    );
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !provider.showControls,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          offset: provider.showControls ? Offset.zero : const Offset(0, 1.15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFloatingButtons(context, menuStyle),
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

  /// 懸浮按鈕組 (對標 Android ll_floating_button)
  Widget _buildFloatingButtons(
    BuildContext context,
    ReaderMenuStyle menuStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _floatingFab(
            icon: Icons.search,
            tooltip: '搜尋',
            onTap: onSearch ?? () {},
            menuStyle: menuStyle,
          ),
          _floatingFab(
            icon: Icons.auto_stories_outlined,
            tooltip: provider.isAutoPaging ? '自動翻頁設定' : '開始自動翻頁',
            onTap: onAutoPage,
            menuStyle: menuStyle,
            active: provider.isAutoPaging,
          ),
          _floatingFab(
            icon: Icons.find_replace,
            tooltip: '替換規則',
            onTap: onReplaceRule ?? () {},
            menuStyle: menuStyle,
          ),
          _floatingFab(
            icon: provider.dayNightToggleIcon,
            tooltip: provider.dayNightToggleTooltip,
            onTap: onToggleDayNight,
            menuStyle: menuStyle,
          ),
        ],
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

  /// 章節導航條 (對標 Android 導航 Seeking)
  Widget _buildChapterSlider(BuildContext context, ReaderMenuStyle menuStyle) {
    final chapterCount = provider.chapters.length;
    final maxVal = (chapterCount <= 1 ? 0 : chapterCount - 1).toDouble();
    final pendingIndex = provider.pendingChapterNavigationIndex;
    final displayIndex =
        provider.isScrubbing
            ? provider.scrubIndex
            : (pendingIndex ?? provider.chapterNavigationIndex);
    final displayTitle =
        (chapterCount > 0 && displayIndex < chapterCount)
            ? provider.displayChapterTitleAt(displayIndex)
            : '';
    final isPending = provider.hasPendingChapterNavigation;
    final canChangeChapter = chapterCount > 1 && !isPending;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if ((provider.isScrubbing || isPending) && displayTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPending) ...[
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
                onPressed:
                    provider.canNavigateToPrevChapter
                        ? () => provider.prevChapter(fromEnd: false)
                        : null,
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
                        canChangeChapter
                            ? (_) => provider.onScrubStart()
                            : null,
                    onChanged:
                        canChangeChapter
                            ? (v) => provider.onScrubbing(v.toInt())
                            : null,
                    onChangeEnd:
                        canChangeChapter
                            ? (v) => provider.onScrubEnd(v.toInt())
                            : null,
                    activeColor: menuStyle.accent,
                    inactiveColor: menuStyle.mutedForeground.withValues(
                      alpha: 0.24,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    provider.canNavigateToNextChapter
                        ? provider.nextChapter
                        : null,
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

  /// 主操作按鈕組 (對標 Android 底部四圖示)
  Widget _buildMainActions(ReaderMenuStyle menuStyle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _menuIcon(Icons.list, '目錄', onOpenDrawer, menuStyle),
        _menuIcon(Icons.record_voice_over, '朗讀', onTts, menuStyle),
        _menuIcon(Icons.color_lens, '介面', onInterface, menuStyle),
        _menuIcon(Icons.settings, '設定', onSettings, menuStyle),
      ],
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
      child: Container(
        width: 70,
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
    );
  }
}
