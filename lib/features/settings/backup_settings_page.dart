import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_provider.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('備份與還原')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildSectionTitle('本地備份與還原'),
              ListTile(
                title: const Text('選擇本地備份目錄'),
                subtitle: const Text('設定或變更本地配置備份的資料夾'),
                leading: const Icon(Icons.folder_open),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('手動備份 (本地)'),
                subtitle: const Text('將目前所有書架與配置進行備份至手機存儲'),
                leading: const Icon(Icons.backup_outlined),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('手動還原 (本地文件)'),
                subtitle: const Text('從本地備份檔恢復資料'),
                leading: const Icon(Icons.restore),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.single.path != null) {
                    // TODO: 實作本地還原邏輯
                    _showComingSoon(context);
                  }
                },
              ),
              const Divider(),
              _buildSectionTitle('備份設定'),
              SwitchListTile(
                title: const Text('僅保留最新備份'),
                value: settings.onlyLatestBackup,
                onChanged: (v) => settings.setOnlyLatestBackup(v),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '註：WebDAV 雲端同步功能已於精簡版中移除。',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
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
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能開發中')));
  }
}
