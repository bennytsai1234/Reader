import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

import 'package:legado_reader/features/source_manager/source_manager_page.dart';
import 'package:legado_reader/features/replace_rule/replace_rule_page.dart';
import 'package:legado_reader/features/dict/dict_rule_page.dart';
import 'package:legado_reader/features/read_record/read_record_page.dart';
import 'package:legado_reader/features/bookmark/bookmark_page.dart';
import 'package:legado_reader/features/txt_toc_rule/txt_toc_rule_page.dart';
import 'backup_settings_page.dart';
import 'theme_settings_page.dart';
import 'other_settings_page.dart';
import 'package:legado_reader/features/about/about_page.dart';

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
              _buildListTile(
                context,
                icon: Icons.source_outlined,
                title: '書源管理',
                summary: '管理閱讀書源',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceManagerPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.format_list_bulleted,
                title: '本地TXT目錄規則',
                summary: '管理本地TXT的目錄解析規則',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TxtTocRulePage())),
              ),
              _buildListTile(
                context,
                icon: Icons.find_replace,
                title: '替換淨化',
                summary: '管理替換淨化規則',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReplaceRulePage())),
              ),
              _buildListTile(
                context,
                icon: Icons.translate,
                title: '字典規則',
                summary: '管理字典規則',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DictRulePage())),
              ),
              
              // --- 顯示與服務 ---
              _buildThemeModeTile(context, settings),

              // --- 設定分類 ---
              _buildCategoryHeader(context, '設定'),
              _buildListTile(
                context,
                icon: Icons.backup_outlined,
                title: '備份與還原',
                summary: 'WebDAV / 本地備份',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupSettingsPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.palette_outlined,
                title: '主題設定',
                summary: '設定App主題顏色及外觀',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.settings_outlined,
                title: '其他設定',
                summary: '更多進階設定選項',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OtherSettingsPage())),
              ),

              // --- 其他分類 ---
              _buildCategoryHeader(context, '其他'),
              _buildListTile(
                context,
                icon: Icons.bookmark_border,
                title: '書籤',
                summary: '查看所有書籤',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarkPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.history,
                title: '閱讀紀錄',
                summary: '查看閱讀歷史',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadRecordPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.folder_open,
                title: '檔案管理',
                summary: '管理本地快取與下載檔案',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('開發中')));
                },
              ),
              _buildListTile(
                context,
                icon: Icons.info_outline,
                title: '關於',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
              ),
              _buildListTile(
                context,
                icon: Icons.exit_to_app,
                title: '退出',
                onTap: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
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

  Widget _buildThemeModeTile(BuildContext context, SettingsProvider settings) {
    final modes = ['跟隨系統', '白天模式', '夜間模式'];
    final currentMode = settings.themeMode == ThemeMode.system ? 0 : (settings.themeMode == ThemeMode.light ? 1 : 2);
    
    return ListTile(
      leading: Icon(Icons.brightness_medium, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)),
      title: const Text('主題模式', style: TextStyle(fontSize: 16)),
      subtitle: Text(modes[currentMode], style: const TextStyle(fontSize: 13)),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('主題模式'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return RadioListTile<int>(
                  title: Text(modes[index]),
                  value: index,
                  groupValue: currentMode,
                  onChanged: (val) {
                    if (val != null) {
                      final mode = val == 0 ? ThemeMode.system : (val == 1 ? ThemeMode.light : ThemeMode.dark);
                      settings.setThemeMode(mode);
                      Navigator.pop(ctx);
                    }
                  },
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

