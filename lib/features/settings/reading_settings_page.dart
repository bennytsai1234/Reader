import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

import 'click_action_config_page.dart';

class ReadingSettingsPage extends StatelessWidget {
  const ReadingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('閱讀設定')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildSectionTitle('介面控制'),
              ListTile(
                title: const Text('點擊區域設定 (打點區)'),
                subtitle: const Text('自訂螢幕各點擊區塊的對應行為'),
                leading: const Icon(Icons.touch_app),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClickActionConfigPage()),
                ),
              ),
              SwitchListTile(
                title: const Text('音量鍵翻頁'),
                value: settings.volumeKeyPage,
                onChanged: (v) => settings.setVolumeKeyPage(v),
              ),
              SwitchListTile(
                title: const Text('滑鼠滾輪翻頁'),
                value: settings.mouseWheelPage,
                onChanged: (v) => settings.setMouseWheelPage(v),
              ),
              
              const Divider(),
              _buildSectionTitle('全域排版'),
              SwitchListTile(
                title: const Text('使用中文獨立排版'),
                subtitle: const Text('強迫套用中文排版規則'),
                value: settings.useZhLayout,
                onChanged: (v) => settings.setUseZhLayout(v),
              ),
              SwitchListTile(
                title: const Text('文字兩端對齊'),
                value: settings.textFullJustify,
                onChanged: (v) => settings.setTextFullJustify(v),
              ),
              
              const Divider(),
              _buildSectionTitle('系統相容性'),
              SwitchListTile(
                title: const Text('隱藏狀態欄'),
                value: settings.hideStatusBar,
                onChanged: (v) => settings.setHideStatusBar(v),
              ),
              SwitchListTile(
                title: const Text('隱藏導航欄'),
                value: settings.hideNavigationBar,
                onChanged: (v) => settings.setHideNavigationBar(v),
              ),
              SwitchListTile(
                title: const Text('適配挖孔螢幕 (留出邊距)'),
                value: settings.paddingDisplayCutouts,
                onChanged: (v) => settings.setPaddingDisplayCutouts(v),
              ),

              const Divider(),
              _buildSectionTitle('進階'),
              SwitchListTile(
                title: const Text('自動替換書源 (來源失效時)'),
                value: settings.autoChangeSource,
                onChanged: (v) => settings.setAutoChangeSource(v),
              ),
              SwitchListTile(
                title: const Text('圖片抗鋸齒'),
                value: settings.antiAlias,
                onChanged: (v) => settings.setAntiAlias(v),
              ),
            ],
          );
        },
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

