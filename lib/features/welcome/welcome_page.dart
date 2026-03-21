import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:legado_reader/features/bookshelf/bookshelf_page.dart';
import 'package:legado_reader/features/settings/settings_provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivacy();
    });
  }

  Future<void> _checkPrivacy() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.privacyAgreed) {
      _showPrivacyDialog();
    } else {
      _startTimer();
    }
  }

  void _showPrivacyDialog() {
    final settings = context.read<SettingsProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('隱私協議與服務條款'),
        content: const SingleChildScrollView(
          child: Text('感謝您使用保安專用閱讀器！\\n\\n本軟體為開源閱讀工具，不提供任何書籍內容。\\n\\n在您開始使用前，請閱讀並同意我們的隱私政策。我們將依法保護您的個人資訊安全。'),
        ),
        actions: [
          TextButton(
            onPressed: () => exit(0),
            child: const Text('退出應用', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setPrivacyAgreed(true);
              Navigator.pop(context);
              _startTimer();
            },
            child: const Text('同意並繼續'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BookshelfPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imagePath = isDark ? settings.welcomeImageDark : settings.welcomeImage;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 啟動圖 (從 SettingsProvider 讀取)
          _buildWelcomeImage(imagePath),
          // 遮罩與文字
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (settings.welcomeShowIcon)
                  const Icon(Icons.library_books, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                if (settings.welcomeShowText)
                  const Column(
                    children: [
                      Text(
                        '保安專用閱讀器',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '「 讀萬卷書，行萬里路 」',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.blue.shade800,
        child: const Center(
          child: Icon(Icons.library_books, size: 100, color: Colors.white24),
        ),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    }

    return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black));
  }
}

