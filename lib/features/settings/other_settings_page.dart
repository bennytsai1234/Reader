import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'global_cache_page.dart';
import 'widgets/settings_group_interface.dart';
import 'widgets/settings_group_advanced.dart';
import 'widgets/settings_group_system.dart';

class OtherSettingsPage extends StatelessWidget {
  const OtherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('其他設定')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              ListTile(
                title: const Text('語言 (Language)'),
                subtitle: Text(_getLanguageName(settings.locale)),
                leading: const Icon(Icons.language),
                onTap: () => _showLanguageDialog(context, settings),
              ),
              const Divider(),
              ListTile(
                title: const Text('清理快取'),
                subtitle: const Text('管理正文、圖片與搜尋歷史等緩存數據'),
                leading: const Icon(Icons.delete_sweep_outlined),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalCachePage())),
              ),
              const Divider(),
              SettingsGroupInterface(settings: settings, showComingSoon: _showComingSoon),
              const Divider(),
              ListTile(
                title: const Text('User Agent'),
                subtitle: Text(settings.userAgent.isEmpty ? '預設' : settings.userAgent),
                onTap: () => _showUserAgentDialog(context, settings),
              ),
              ListTile(
                title: const Text('全域封面規則'),
                subtitle: Text(settings.globalCoverRule.isEmpty ? '未設定' : '已設定 (點擊編輯)'),
                onTap: () => _showAdvancedCoverConfig(context, settings),
              ),
              const Divider(),
              SettingsGroupAdvanced(settings: settings, showComingSoon: _showComingSoon),
              const Divider(),
              SettingsGroupSystem(settings: settings, showComingSoon: _showComingSoon),
            ],
          );
        },
      ),
    );
  }

  String _getLanguageName(Locale? locale) {
    if (locale == null) return '跟隨系統';
    final code = locale.languageCode;
    if (code == 'zh') return (locale.countryCode == 'TW' || locale.countryCode == 'HK') ? '繁體中文' : '简体中文';
    return code == 'en' ? 'English' : locale.toString();
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final languages = [
      {'label': '跟隨系統', 'value': 'system'},
      {'label': '繁體中文', 'value': 'zh_TW'},
      {'label': '简体中文', 'value': 'zh_CN'},
      {'label': 'English', 'value': 'en'},
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇語言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) => RadioListTile<String>(
            title: Text(lang['label']!),
            value: lang['value']!,
            groupValue: (lang['value'] == 'system' && settings.locale == null) ? 'system' : (settings.locale != null && (lang['value'] == settings.locale!.languageCode || lang['value'] == '${settings.locale!.languageCode}_${settings.locale!.countryCode}')) ? lang['value'] : null,
            onChanged: (val) { settings.setLanguage(val!); Navigator.pop(context); },
          )).toList(),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能開發中')));
  }

  void _showUserAgentDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.userAgent);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('設定 User Agent'),
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: '輸入自定義 User-Agent', helperText: '留空則使用預設', border: OutlineInputBorder()), maxLines: 3),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), TextButton(onPressed: () { settings.setUserAgent(controller.text.trim()); Navigator.pop(context); }, child: const Text('儲存'))],
    ));
  }

  void _showThreadCountDialog(BuildContext context, SettingsProvider settings) {
    showDialog(context: context, builder: (context) {
      var val = settings.threadCount.toDouble();
      return StatefulBuilder(builder: (context, setState) => AlertDialog(
        title: Text('執行緒數量: ${val.toInt()}'),
        content: Slider(value: val, min: 1, max: 32, divisions: 31, onChanged: (v) => setState(() => val = v)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), TextButton(onPressed: () { settings.setThreadCount(val.toInt()); Navigator.pop(context); }, child: const Text('確定'))],
      ));
    });
  }

  void _showAdvancedCoverConfig(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.globalCoverRule);
    showDialog(context: context, builder: (context) {
      var priority = settings.coverSearchPriority;
      var timeout = settings.coverTimeout.toDouble();
      return StatefulBuilder(builder: (context, setState) => AlertDialog(
        title: const Text('進階封面設定'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(value: priority, decoration: const InputDecoration(labelText: '搜尋優先級'), items: const [DropdownMenuItem(value: 0, child: Text('書源優先')), DropdownMenuItem(value: 1, child: Text('全域規則優先'))], onChanged: (v) => setState(() => priority = v!)),
          const SizedBox(height: 16),
          Text('超時時間: ${(timeout / 1000).toStringAsFixed(1)} 秒'),
          Slider(value: timeout, min: 1000, max: 30000, divisions: 29, onChanged: (v) => setState(() => timeout = v)),
          TextField(controller: controller, decoration: const InputDecoration(labelText: '全域規則 (每行一個)', border: OutlineInputBorder()), maxLines: 5),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), TextButton(onPressed: () { settings.setCoverSearchPriority(priority); settings.setCoverTimeout(timeout.toInt()); settings.setGlobalCoverRule(controller.text); Navigator.pop(context); }, child: const Text('儲存'))],
      ));
    });
  }
}
