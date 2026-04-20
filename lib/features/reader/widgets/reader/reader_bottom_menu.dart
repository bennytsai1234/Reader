import 'package:flutter/material.dart';
import '../../reader_provider.dart';

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
    final panelColor = provider.currentTheme.backgroundColor.withValues(
      alpha: 0.96,
    );
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: provider.showControls ? 0 : -250,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloatingButtons(context),
          Container(
            padding: EdgeInsets.fromLTRB(
              0,
              8,
              0,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            color: panelColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildChapterSlider(context),
                const SizedBox(height: 8),
                _buildMainActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 懸浮按鈕組 (對標 Android ll_floating_button)
  Widget _buildFloatingButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _floatingFab(Icons.search, '搜尋', onSearch ?? () {}),
          _floatingFab(
            Icons.auto_stories_outlined,
            '自動翻頁',
            onAutoPage,
            active: provider.isAutoPaging,
          ),
          _floatingFab(Icons.find_replace, '替換規則', onReplaceRule ?? () {}),
          _floatingFab(
            provider.themeIndex == 1 ? Icons.wb_sunny : Icons.nightlight_round,
            '日夜切換',
            onToggleDayNight,
          ),
        ],
      ),
    );
  }

  Widget _floatingFab(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: onTap,
      backgroundColor: provider.currentTheme.backgroundColor.withValues(
        alpha: 0.92,
      ),
      foregroundColor: active ? Colors.blue : provider.currentTheme.textColor,
      child: Icon(icon),
    );
  }

  /// 章節導航條 (對標 Android 導航 Seeking)
  Widget _buildChapterSlider(BuildContext context) {
    final chapterCount = provider.chapters.length;
    final maxVal = (chapterCount <= 1 ? 0 : chapterCount - 1).toDouble();
    final displayIndex =
        provider.isScrubbing
            ? provider.scrubIndex
            : provider.currentChapterIndex;
    final displayTitle =
        (chapterCount > 0 && displayIndex < chapterCount)
            ? provider.displayChapterTitleAt(displayIndex)
            : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.isScrubbing && displayTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                displayTitle,
                style: TextStyle(
                  color: provider.currentTheme.textColor.withValues(
                    alpha: 0.72,
                  ),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            children: [
              TextButton(
                onPressed:
                    provider.currentChapterIndex > 0
                        ? provider.prevChapter
                        : null,
                child: Text(
                  '上一章',
                  style: TextStyle(
                    color: provider.currentTheme.textColor,
                    fontSize: 14,
                  ),
                ),
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
                        chapterCount <= 1
                            ? null
                            : (_) => provider.onScrubStart(),
                    onChanged:
                        chapterCount <= 1
                            ? null
                            : (v) => provider.onScrubbing(v.toInt()),
                    onChangeEnd:
                        chapterCount <= 1
                            ? null
                            : (v) => provider.onScrubEnd(v.toInt()),
                    activeColor: Colors.blue,
                    inactiveColor: provider.currentTheme.textColor.withValues(
                      alpha: 0.24,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    provider.currentChapterIndex < chapterCount - 1
                        ? provider.nextChapter
                        : null,
                child: Text(
                  '下一章',
                  style: TextStyle(
                    color: provider.currentTheme.textColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 主操作按鈕組 (對標 Android 底部四圖示)
  Widget _buildMainActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _menuIcon(Icons.list, '目錄', onOpenDrawer),
        _menuIcon(Icons.record_voice_over, '朗讀', onTts),
        _menuIcon(Icons.color_lens, '介面', onInterface),
        _menuIcon(Icons.settings, '設定', onSettings),
      ],
    );
  }

  Widget _menuIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: provider.currentTheme.textColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: provider.currentTheme.textColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
