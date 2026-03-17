import 'package:flutter/material.dart';
import '../settings_provider.dart';

class SettingsGroupInterface extends StatelessWidget {
  final SettingsProvider settings;
  final Function(BuildContext) showComingSoon;

  const SettingsGroupInterface({super.key, required this.settings, required this.showComingSoon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('主介面'),
        SwitchListTile(
          title: const Text('下拉自動更新'),
          subtitle: const Text('開啟後進入書架自動重新整理'),
          value: settings.autoRefresh,
          onChanged: (v) => settings.setAutoRefresh(v),
        ),
        SwitchListTile(
          title: const Text('預設展開書籍'),
          value: settings.defaultToRead,
          onChanged: (v) => settings.setDefaultToRead(v),
        ),
        SwitchListTile(
          title: const Text('顯示發現'),
          value: settings.showDiscovery,
          onChanged: (v) => settings.setShowDiscovery(v),
        ),
        ListTile(
          title: const Text('預設首頁'),
          subtitle: const Text('啟動 App 時預設顯示的頁面'),
          onTap: () => showComingSoon(context),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }
}

