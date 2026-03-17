import 'package:flutter/material.dart';
import '../settings_provider.dart';

class SettingsGroupSystem extends StatelessWidget {
  final SettingsProvider settings;
  final Function(BuildContext) showComingSoon;

  const SettingsGroupSystem({
    super.key,
    required this.settings,
    required this.showComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('系統設定'),
        ListTile(
          title: const Text('用戶代理 (User-Agent)'),
          subtitle: Text(settings.userAgent.isEmpty ? '預設' : settings.userAgent, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => showComingSoon(context),
        ),
        ListTile(
          title: const Text('並行線程數'),
          subtitle: Text('${settings.threadCount}'),
          onTap: () => showComingSoon(context),
        ),
        SwitchListTile(
          title: const Text('記錄日誌'),
          value: settings.recordLog,
          onChanged: (v) => showComingSoon(context),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }
}
