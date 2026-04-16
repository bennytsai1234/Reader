import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

import 'package:inkpage_reader/features/source_manager/source_manager_page.dart';
import 'package:inkpage_reader/features/replace_rule/replace_rule_page.dart';
import 'package:inkpage_reader/features/dict/dict_rule_page.dart';
import 'package:inkpage_reader/features/read_record/read_record_page.dart';
import 'package:inkpage_reader/features/bookmark/bookmark_page.dart';
import 'package:inkpage_reader/features/txt_toc_rule/txt_toc_rule_page.dart';
import 'appearance_settings_page.dart';
import 'reading_settings_page.dart';
import 'tts_settings_page.dart';
import 'backup_settings_page.dart';
import 'other_settings_page.dart';
import 'package:inkpage_reader/features/about/about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              // --- 核心管理 ---
              _buildCategoryHeader(context, '書源與規則'),
              _buildListTile(
                context,
                icon: Icons.source_outlined,
                title: '書源管理',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceManagerPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.format_list_bulleted,
                title: '本地目錄規則',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TxtTocRulePage())),
              ),
              _buildListTile(
                context,
                icon: Icons.find_replace,
                title: '替換淨化',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReplaceRulePage())),
              ),
              _buildListTile(
                context,
                icon: Icons.translate,
                title: '字典規則',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DictRulePage())),
              ),
              
              const Divider(),
              // --- 設定分類 ---
              _buildCategoryHeader(context, '個人化設定'),
              _buildListTile(
                context,
                icon: Icons.palette_outlined,
                title: '外觀與主題',
                summary: '介面佈局、顏色、桌面圖標',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceSettingsPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.chrome_reader_mode_outlined,
                title: '閱讀設定',
                summary: '翻頁、排版、系統適配',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingSettingsPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.volume_up_outlined,
                title: '朗讀與語音',
                summary: 'TTS 參數、語音引擎管理',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TtsSettingsPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.backup_outlined,
                title: '備份與還原',
                summary: '本地備份、數據遷移',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupSettingsPage())),
              ),

              const Divider(),
              // --- 其他工具 ---
              _buildCategoryHeader(context, '工具與其他'),
              _buildListTile(
                context,
                icon: Icons.bookmark_border,
                title: '書籤管理',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarkPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.history,
                title: '閱讀紀錄',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadRecordPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.settings_outlined,
                title: '其他設定',
                summary: '語言、UA、快取清理',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OtherSettingsPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.info_outline,
                title: '關於墨頁',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
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

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, String? summary, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: summary != null ? Text(summary, style: const TextStyle(fontSize: 13)) : null,
      onTap: onTap,
    );
  }
}

