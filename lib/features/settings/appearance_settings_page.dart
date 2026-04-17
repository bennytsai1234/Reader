import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'icon_settings_page.dart';
import 'welcome_settings_page.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('外觀與主題')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
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
                title: const Text('歡迎介面'),
                subtitle: const Text('設定 App 啟動時的歡迎圖片'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeSettingsPage()),
                ),
              ),

              const Divider(),
              _buildSectionTitle('主題'),
              _buildThemeModeTile(context, settings),
              SwitchListTile(
                title: const Text('沉浸式狀態欄'),
                value: settings.transparentStatusBar,
                onChanged: (v) => settings.setTransparentStatusBar(v),
              ),
              SwitchListTile(
                title: const Text('沉浸式導覽列'),
                value: settings.immNavigationBar,
                onChanged: (v) => settings.setImmNavigationBar(v),
              ),

              const Divider(),
              _buildSectionTitle('配色管理'),
              _buildColorGroup(context, settings),

              const Divider(),
              _buildSectionTitle('圖標'),
              ListTile(
                title: const Text('更換桌面圖標'),
                subtitle: Text('目前：${_getIconName(settings.launcherIcon)}'),
                leading: const Icon(Icons.grid_view_rounded),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IconSettingsPage()),
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

  Widget _buildThemeModeTile(BuildContext context, SettingsProvider settings) {
    final modes = ['跟隨系統', '白天模式', '夜間模式'];
    final currentMode =
        settings.themeMode == ThemeMode.system
            ? 0
            : (settings.themeMode == ThemeMode.light ? 1 : 2);

    return ListTile(
      title: const Text('主題模式'),
      subtitle: Text(modes[currentMode]),
      onTap: () {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('主題模式'),
                content: RadioGroup<int>(
                  groupValue: currentMode,
                  onChanged: (val) {
                    if (val == null) return;
                    final mode =
                        val == 0
                            ? ThemeMode.system
                            : (val == 1
                                ? ThemeMode.light
                                : ThemeMode.dark);
                    settings.setThemeMode(mode);
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      return RadioListTile<int>(
                        title: Text(modes[index]),
                        value: index,
                        // ignore: deprecated_member_use
                        groupValue: null, // Managed by RadioGroup
                        // ignore: deprecated_member_use
                        onChanged: null, // Managed by RadioGroup
                      );
                    }),
                  ),
                ),
              ),
        );
      },
    );
  }

  Widget _buildColorGroup(BuildContext context, SettingsProvider settings) {
    return ExpansionTile(
      title: const Text('自訂主題色彩', style: TextStyle(fontSize: 15)),
      children: [
        _buildColorTile(context, '日間主色調', settings.dayPrimaryColor,
            (c) => settings.setDayPrimaryColor(c)),
        _buildColorTile(context, '日間背景色', settings.dayBackgroundColor,
            (c) => settings.setDayBackgroundColor(c)),
        _buildColorTile(context, '夜間主色調', settings.nightPrimaryColor,
            (c) => settings.setNightPrimaryColor(c)),
        _buildColorTile(context, '夜間背景色', settings.nightBackgroundColor,
            (c) => settings.setNightBackgroundColor(c)),
      ],
    );
  }

  Widget _buildColorTile(BuildContext context, String title, Color currentColor,
      Function(Color) onColorChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
      onTap: () => _showColorPicker(context, title, currentColor, onColorChanged),
    );
  }

  void _showColorPicker(BuildContext context, String title, Color currentColor,
      Function(Color) onColorChanged) {
    final colors = [
      Colors.brown,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('選擇 $title'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  onColorChanged(colors[index]);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentColor == colors[index]
                          ? Colors.white
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getIconName(String id) {
    final icons = {
      'Launcher1': '預設圖標',
      'Launcher2': '簡約黑',
      'Launcher3': '活力紅',
      'Launcher4': '清新綠',
      'Launcher5': '優雅紫',
      'Launcher6': '暖陽橘',
    };
    return icons[id] ?? '預設圖標';
  }
}
