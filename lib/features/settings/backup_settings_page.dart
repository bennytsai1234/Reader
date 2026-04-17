import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:inkpage_reader/core/services/backup_service.dart';
import 'package:inkpage_reader/core/services/restore_service.dart';
import 'dart:io';
import 'settings_provider.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  bool _isProcessing = false;

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
                title: const Text('手動備份 (本地)'),
                subtitle: const Text('將目前所有書架與配置進行備份至手機存儲'),
                leading: const Icon(Icons.backup_outlined),
                onTap: _isProcessing ? null : _handleManualBackup,
              ),
              ListTile(
                title: const Text('手動還原 (本地文件)'),
                subtitle: const Text('從本地備份檔恢復資料'),
                leading: const Icon(Icons.restore),
                onTap: _isProcessing ? null : _handleManualRestore,
              ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const Divider(),
              _buildSectionTitle('備份設定'),
              SwitchListTile(
                title: const Text('僅保留最新備份'),
                value: settings.onlyLatestBackup,
                onChanged: (v) => settings.setOnlyLatestBackup(v),
              ),
              const SizedBox(height: 24),
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
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Future<void> _handleManualBackup() async {
    setState(() => _isProcessing = true);
    try {
      final file = await BackupService().createBackupZip();
      if (file != null && await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: '墨頁備份檔'),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('建立備份失敗')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('備份出錯: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleManualRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (!mounted) return;

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() => _isProcessing = true);
      try {
        final success = await RestoreService().restoreFromZip(file);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('還原成功，請重啟 App 以載入新資料')),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('還原失敗，備份檔格式不正確')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('還原出錯: $e')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }
}
