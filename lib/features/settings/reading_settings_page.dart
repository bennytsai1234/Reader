import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/settings/reader_prefs_repository.dart';
import 'package:inkpage_reader/features/reader/widgets/settings/setting_components.dart';
import 'package:provider/provider.dart';

import 'click_action_config_page.dart';
import 'settings_provider.dart';

class ReadingSettingsPage extends StatefulWidget {
  const ReadingSettingsPage({super.key});

  @override
  State<ReadingSettingsPage> createState() => _ReadingSettingsPageState();
}

class _ReadingSettingsPageState extends State<ReadingSettingsPage> {
  final ReaderPrefsRepository _prefsRepository = const ReaderPrefsRepository();
  ReaderPrefsSnapshot? _prefs;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final snapshot = await _prefsRepository.load();
    if (!mounted) return;
    setState(() {
      _prefs = snapshot;
    });
  }

  void _updatePrefs(ReaderPrefsSnapshot next) {
    setState(() {
      _prefs = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    return Scaffold(
      appBar: AppBar(title: const Text('閱讀設定')),
      body:
          prefs == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildSectionTitle('操作'),
                  ListTile(
                    title: const Text('點擊區域設定 (打點區)'),
                    subtitle: const Text('自訂螢幕各點擊區塊的對應行為'),
                    leading: const Icon(Icons.touch_app),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClickActionConfigPage(),
                        ),
                      );
                      _loadPrefs();
                    },
                  ),

                  const Divider(),
                  _buildSectionTitle('排版'),
                  SettingComponents.buildSliderRow(
                    label: '字號',
                    value: prefs.fontSize,
                    min: 14,
                    max: 40,
                    onChanged: (value) {
                      _updatePrefs(prefs.copyWith(fontSize: value));
                      _prefsRepository.saveFontSize(value);
                    },
                  ),
                  SettingComponents.buildSliderRow(
                    label: '行高',
                    value: prefs.lineHeight,
                    min: 1.0,
                    max: 3.0,
                    onChanged: (value) {
                      _updatePrefs(prefs.copyWith(lineHeight: value));
                      _prefsRepository.saveLineHeight(value);
                    },
                  ),
                  SettingComponents.buildSliderRow(
                    label: '字距',
                    value: prefs.letterSpacing,
                    min: 0.0,
                    max: 4.0,
                    onChanged: (value) {
                      _updatePrefs(prefs.copyWith(letterSpacing: value));
                      _prefsRepository.saveLetterSpacing(value);
                    },
                  ),
                  SettingComponents.buildSliderRow(
                    label: '段距',
                    value: prefs.paragraphSpacing,
                    min: 0.0,
                    max: 3.0,
                    onChanged: (value) {
                      _updatePrefs(prefs.copyWith(paragraphSpacing: value));
                      _prefsRepository.saveParagraphSpacing(value);
                    },
                  ),
                  ListTile(
                    title: const Text('首行縮排'),
                    trailing: DropdownButton<int>(
                      value: prefs.textIndent,
                      underline: const SizedBox.shrink(),
                      items:
                          const [0, 1, 2, 4]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value 字'),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        _updatePrefs(prefs.copyWith(textIndent: value));
                        _prefsRepository.saveTextIndent(value);
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('文字兩端對齊'),
                    value: prefs.textFullJustify,
                    onChanged: (value) {
                      _updatePrefs(prefs.copyWith(textFullJustify: value));
                      _prefsRepository.saveTextFullJustify(value);
                    },
                  ),
                  ListTile(
                    title: const Text('翻頁模式'),
                    subtitle: Wrap(
                      spacing: 8,
                      children: [
                        SettingComponents.buildChoiceChip(
                          label: '平移翻頁',
                          value: PageAnim.slide,
                          groupValue: prefs.pageTurnMode,
                          onSelected: (value) {
                            _updatePrefs(prefs.copyWith(pageTurnMode: value));
                            _prefsRepository.savePageTurnMode(value);
                          },
                        ),
                        SettingComponents.buildChoiceChip(
                          label: '上下滾動',
                          value: PageAnim.scroll,
                          groupValue: prefs.pageTurnMode,
                          onSelected: (value) {
                            _updatePrefs(prefs.copyWith(pageTurnMode: value));
                            _prefsRepository.savePageTurnMode(value);
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(),
                  _buildSectionTitle('顯示'),
                  SwitchListTile(
                    title: const Text('顯示常駐底部資訊'),
                    value: prefs.showReadTitleAddition,
                    onChanged: (value) {
                      _updatePrefs(
                        prefs.copyWith(showReadTitleAddition: value),
                      );
                      _prefsRepository.saveShowReadTitleAddition(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('選單配色跟隨閱讀頁'),
                    value: prefs.readBarStyleFollowPage,
                    onChanged: (value) {
                      _updatePrefs(
                        prefs.copyWith(readBarStyleFollowPage: value),
                      );
                      _prefsRepository.saveReadBarStyleFollowPage(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('允許文字選取'),
                    value: prefs.selectText,
                    onChanged: (value) {
                      _updatePrefs(prefs.copyWith(selectText: value));
                      _prefsRepository.saveSelectText(value);
                    },
                  ),

                  const Divider(),
                  _buildSectionTitle('內容'),
                  ListTile(
                    title: const Text('繁簡轉換'),
                    subtitle: Wrap(
                      spacing: 8,
                      children: [
                        SettingComponents.buildChoiceChip(
                          label: '不轉換',
                          value: 0,
                          groupValue: prefs.chineseConvert,
                          onSelected: (value) {
                            _updatePrefs(prefs.copyWith(chineseConvert: value));
                            _prefsRepository.saveChineseConvert(value);
                          },
                        ),
                        SettingComponents.buildChoiceChip(
                          label: '簡轉繁',
                          value: 1,
                          groupValue: prefs.chineseConvert,
                          onSelected: (value) {
                            _updatePrefs(prefs.copyWith(chineseConvert: value));
                            _prefsRepository.saveChineseConvert(value);
                          },
                        ),
                        SettingComponents.buildChoiceChip(
                          label: '繁轉簡',
                          value: 2,
                          groupValue: prefs.chineseConvert,
                          onSelected: (value) {
                            _updatePrefs(prefs.copyWith(chineseConvert: value));
                            _prefsRepository.saveChineseConvert(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return SwitchListTile(
                        title: const Text('自動替換書源 (來源失效時)'),
                        value: settings.autoChangeSource,
                        onChanged: settings.setAutoChangeSource,
                      );
                    },
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
