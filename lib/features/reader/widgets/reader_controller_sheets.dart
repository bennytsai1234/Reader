import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_settings_controller.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_tts_controller.dart';
import 'package:inkpage_reader/features/reader/models/reader_tap_action.dart';
import 'package:inkpage_reader/features/reader/widgets/settings/setting_components.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';

class ReaderControllerSheets {
  const ReaderControllerSheets._();

  static void showInterfaceSettings(
    BuildContext context,
    ReaderSettingsController settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReaderInterfaceSheet(settings: settings),
    );
  }

  static void showAdvancedSettings(
    BuildContext context,
    ReaderSettingsController settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReaderAdvancedSheet(settings: settings),
    );
  }

  static void showTts(
    BuildContext context, {
    required ReaderTtsController tts,
    required ReaderSettingsController settings,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReaderTtsSheet(tts: tts, settings: settings),
    );
  }
}

class _ReaderInterfaceSheet extends StatefulWidget {
  const _ReaderInterfaceSheet({required this.settings});

  final ReaderSettingsController settings;

  @override
  State<_ReaderInterfaceSheet> createState() => _ReaderInterfaceSheetState();
}

class _ReaderInterfaceSheetState extends State<_ReaderInterfaceSheet> {
  final Map<String, Timer> _debouncers = <String, Timer>{};
  late double _fontSize;
  late double _lineHeight;
  late double _letterSpacing;
  late double _paragraphSpacing;

  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    _fontSize = settings.fontSize;
    _lineHeight = settings.lineHeight;
    _letterSpacing = settings.letterSpacing;
    _paragraphSpacing = settings.paragraphSpacing;
  }

  @override
  void dispose() {
    for (final timer in _debouncers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _scheduleCommit(String key, VoidCallback action) {
    _debouncers.remove(key)?.cancel();
    _debouncers[key] = Timer(const Duration(milliseconds: 120), action);
  }

  void _commitNow(String key, VoidCallback action) {
    _debouncers.remove(key)?.cancel();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return AppBottomSheet(
          title: '界面設定',
          icon: Icons.format_paint_outlined,
          children: [
            const SheetSection(title: '閱讀主題'),
            const SizedBox(height: 4),
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: AppTheme.readingThemes.length,
                itemBuilder: (context, index) {
                  final theme = AppTheme.readingThemes[index];
                  final selected = settings.themeIndex == index;
                  return GestureDetector(
                    onTap: () => settings.setTheme(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.withValues(alpha: 0.2),
                          width: selected ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Aa',
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SheetSection(title: '排版精修'),
            SettingComponents.buildSliderRow(
              label: '字號',
              value: _fontSize,
              min: 14,
              max: 40,
              onChanged: (value) {
                setState(() => _fontSize = value);
                _scheduleCommit(
                  'fontSize',
                  () => settings.setFontSize(_fontSize),
                );
              },
              onChangeEnd: (value) {
                _commitNow('fontSize', () => settings.setFontSize(value));
              },
            ),
            SettingComponents.buildSliderRow(
              label: '行高',
              value: _lineHeight,
              min: 1.0,
              max: 3.0,
              onChanged: (value) {
                setState(() => _lineHeight = value);
                _scheduleCommit(
                  'lineHeight',
                  () => settings.setLineHeight(_lineHeight),
                );
              },
              onChangeEnd: (value) {
                _commitNow('lineHeight', () => settings.setLineHeight(value));
              },
            ),
            SettingComponents.buildSliderRow(
              label: '字距',
              value: _letterSpacing,
              min: 0.0,
              max: 4.0,
              onChanged: (value) {
                setState(() => _letterSpacing = value);
                _scheduleCommit(
                  'letterSpacing',
                  () => settings.setLetterSpacing(_letterSpacing),
                );
              },
              onChangeEnd: (value) {
                _commitNow(
                  'letterSpacing',
                  () => settings.setLetterSpacing(value),
                );
              },
            ),
            SettingComponents.buildSliderRow(
              label: '段距',
              value: _paragraphSpacing,
              min: 0.0,
              max: 3.0,
              onChanged: (value) {
                setState(() => _paragraphSpacing = value);
                _scheduleCommit(
                  'paragraphSpacing',
                  () => settings.setParagraphSpacing(_paragraphSpacing),
                );
              },
              onChangeEnd: (value) {
                _commitNow(
                  'paragraphSpacing',
                  () => settings.setParagraphSpacing(value),
                );
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('內容兩端對齊'),
              value: settings.textFullJustify,
              onChanged: settings.setTextFullJustify,
            ),
            Row(
              children: [
                const Text(
                  '首行縮排',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: settings.textIndent,
                  underline: const SizedBox.shrink(),
                  items:
                      [0, 1, 2, 4]
                          .map(
                            (i) =>
                                DropdownMenuItem(value: i, child: Text('$i 字')),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) settings.setTextIndent(value);
                  },
                ),
              ],
            ),
            const SheetSection(title: '翻頁與背景'),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('平移翻頁'),
                  selected: settings.pageTurnMode == PageAnim.slide,
                  onSelected:
                      (selected) =>
                          selected
                              ? settings.setPageTurnMode(PageAnim.slide)
                              : null,
                ),
                ChoiceChip(
                  label: const Text('上下滾動'),
                  selected: settings.pageTurnMode == PageAnim.scroll,
                  onSelected:
                      (selected) =>
                          selected
                              ? settings.setPageTurnMode(PageAnim.scroll)
                              : null,
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('顯示常駐底部資訊'),
              value: settings.showReadTitleAddition,
              onChanged: settings.setShowReadTitleAddition,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('選單配色跟隨閱讀頁'),
              value: settings.readBarStyleFollowPage,
              onChanged: settings.setReadBarStyleFollowPage,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('允許文字選取（新閱讀器暫未支援）'),
              value: settings.selectText,
              onChanged: settings.setSelectText,
            ),
          ],
        );
      },
    );
  }
}

class _ReaderAdvancedSheet extends StatelessWidget {
  const _ReaderAdvancedSheet({required this.settings});

  final ReaderSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return AppBottomSheet(
          title: '進階設定',
          icon: Icons.tune_rounded,
          children: [
            const SheetSection(title: '繁簡轉換'),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('不轉換'),
                  selected: settings.chineseConvert == 0,
                  onSelected:
                      (selected) =>
                          selected ? settings.setChineseConvert(0) : null,
                ),
                ChoiceChip(
                  label: const Text('簡轉繁'),
                  selected: settings.chineseConvert == 1,
                  onSelected:
                      (selected) =>
                          selected ? settings.setChineseConvert(1) : null,
                ),
                ChoiceChip(
                  label: const Text('繁轉簡'),
                  selected: settings.chineseConvert == 2,
                  onSelected:
                      (selected) =>
                          selected ? settings.setChineseConvert(2) : null,
                ),
              ],
            ),
            const Divider(height: 32),
            const SheetSection(
              title: '點擊區域設定',
              trailing: Text(
                '九宮格配置',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            _ClickActionGrid(settings: settings),
          ],
        );
      },
    );
  }
}

class _ClickActionGrid extends StatelessWidget {
  const _ClickActionGrid({required this.settings});

  final ReaderSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 2.2,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final action = settings.clickActions[index];
          final label = ReaderTapAction.fromCode(action).label;
          final isCenter = index == 4;
          return GestureDetector(
            onTap: () => _showActionPicker(context, index),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isCenter
                        ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.surfaceContainer,
                border: Border.all(
                  color:
                      isCenter
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isCenter ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showActionPicker(BuildContext context, int gridIndex) {
    AppBottomSheet.show(
      context: context,
      title: '選擇點擊功能',
      icon: Icons.ads_click,
      children:
          ReaderTapAction.values.map((action) {
            final selected = settings.clickActions[gridIndex] == action.code;
            return ListTile(
              title: Text(action.label, style: const TextStyle(fontSize: 14)),
              trailing:
                  selected
                      ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                      : null,
              onTap: () {
                settings.setClickAction(gridIndex, action.code);
                Navigator.pop(context);
              },
            );
          }).toList(),
    );
  }
}

class _ReaderTtsSheet extends StatelessWidget {
  const _ReaderTtsSheet({required this.tts, required this.settings});

  final ReaderTtsController tts;
  final ReaderSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tts,
      builder: (context, _) {
        return AppBottomSheet(
          title: '朗讀',
          icon: Icons.record_voice_over,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(tts.isPlaying ? Icons.pause : Icons.play_arrow),
              title: Text(tts.isPlaying ? '暫停朗讀' : '從目前位置朗讀'),
              onTap: () => unawaited(tts.toggle()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stop),
              title: const Text('停止'),
              onTap: () => unawaited(tts.stop()),
            ),
            SettingComponents.buildSliderRow(
              label: '語速',
              value: tts.rate,
              min: 0.5,
              max: 1.5,
              onChanged: (value) {
                unawaited(tts.setRate(value));
              },
            ),
            SettingComponents.buildSliderRow(
              label: '音調',
              value: tts.pitch,
              min: 0.5,
              max: 1.5,
              onChanged: (value) {
                unawaited(tts.setPitch(value));
              },
            ),
          ],
        );
      },
    );
  }
}
