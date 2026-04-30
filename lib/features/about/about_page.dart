import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/features/read_record/read_record_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'crash_log_page.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '0.1.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('關於')),
      body: ListView(
        children: [
          const SizedBox(height: 40),
          _buildAppLogo(context),
          const SizedBox(height: 32),

          _buildCategoryHeader('開源與法律'),
          _buildListTile(
            context,
            icon: Icons.code_rounded,
            title: 'GitHub 開源位址',
            subtitle: 'github.com/bennytsai1234/reader',
            onTap: () => _launchUrl('https://github.com/bennytsai1234/reader'),
          ),
          _buildListTile(
            context,
            icon: Icons.description_outlined,
            title: '開源許可證',
            subtitle: '查看第三方庫協議',
            onTap:
                () => showLicensePage(
                  context: context,
                  applicationName: '墨頁 Inkpage',
                  applicationVersion: '$_version ($_buildNumber)',
                ),
          ),
          _buildListTile(
            context,
            icon: Icons.gavel_outlined,
            title: '免責聲明',
            onTap: () => _showDisclaimer(context),
          ),

          _buildCategoryHeader('系統工具'),
          _buildListTile(
            context,
            icon: Icons.bar_chart_rounded,
            title: '閱讀紀錄',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReadRecordPage()),
                ),
          ),
          _buildListTile(
            context,
            icon: Icons.report_problem_outlined,
            title: '崩潰日誌',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrashLogPage()),
                ),
          ),

          const SizedBox(height: 40),
          _buildFooter(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAppLogo(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.library_books_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '墨頁 Inkpage',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'v$_version',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        size: 22,
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle:
          subtitle != null
              ? Text(subtitle, style: const TextStyle(fontSize: 12))
              : null,
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.0),
      child: Text(
        '本專案為開源學習作品，不提供任何內容服務。所有數據由使用者自行導入。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('免責聲明'),
            content: const SingleChildScrollView(
              child: Text(
                '1. 本軟體僅作為開源閱讀工具使用，不提供任何書籍、書源或訂閱內容。\n\n'
                '2. 使用者應遵守當地法律法規，並對所導入的內容承擔全部法律責任。\n\n'
                '3. 對於使用本軟體產生的任何版權爭議、數據損失，開發者概不負責。',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('我已閱讀並知曉'),
              ),
            ],
          ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppLog.d('無法開啟連結: $url');
    }
  }
}
