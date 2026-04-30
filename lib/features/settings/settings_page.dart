import 'package:flutter/material.dart';

import 'package:inkpage_reader/features/source_manager/source_manager_page.dart';
import 'package:inkpage_reader/features/read_record/read_record_page.dart';
import 'package:inkpage_reader/features/cache_manager/download_manager_page.dart';
import 'reading_settings_page.dart';
import 'tts_settings_page.dart';
import 'backup_settings_page.dart';
import 'package:inkpage_reader/features/about/about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的'), elevation: 0),
      body: ListView(
        children: [
          _buildCategoryHeader(context, '書源'),
          _buildListTile(
            context,
            icon: Icons.source_outlined,
            title: '書源管理',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SourceManagerPage()),
                ),
          ),

          const Divider(),
          _buildCategoryHeader(context, '個人化設定'),
          _buildListTile(
            context,
            icon: Icons.chrome_reader_mode_outlined,
            title: '閱讀設定',
            summary: '打點區、排版、繁簡轉換',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReadingSettingsPage(),
                  ),
                ),
          ),
          _buildListTile(
            context,
            icon: Icons.volume_up_outlined,
            title: '朗讀與語音',
            summary: '語速、音調、系統語音',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TtsSettingsPage()),
                ),
          ),
          _buildListTile(
            context,
            icon: Icons.backup_outlined,
            title: '備份與還原',
            summary: '本地備份、數據遷移',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupSettingsPage()),
                ),
          ),

          const Divider(),
          _buildCategoryHeader(context, '工具與其他'),
          _buildListTile(
            context,
            icon: Icons.history,
            title: '閱讀紀錄',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReadRecordPage()),
                ),
          ),
          _buildListTile(
            context,
            icon: Icons.download_for_offline_outlined,
            title: '背景下載佇列',
            summary: '查看、暫停、重試與刪除下載任務',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DownloadManagerPage(),
                  ),
                ),
          ),
          _buildListTile(
            context,
            icon: Icons.info_outline,
            title: '關於墨頁',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? summary,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle:
          summary != null
              ? Text(summary, style: const TextStyle(fontSize: 13))
              : null,
      onTap: onTap,
    );
  }
}
