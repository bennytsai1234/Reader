import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/features/settings/settings_provider.dart';
import 'package:legado_reader/core/services/default_data.dart';
import 'main_page.dart';
import '../../main.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _status = '正在初始化...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      setState(() => _status = '正在載入資料庫與預設資料...');
      await DefaultData.init();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    } catch (e, stack) {
      debugPrint('Init Error: $e\n$stack');
      if (mounted) {
        setState(() { _error = '$e\n$stack'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final customPath = isDarkMode ? settings.welcomeImageDark : settings.welcomeImage;
    final showIcon = isDarkMode ? settings.welcomeShowIconDark : settings.welcomeShowIcon;
    final showText = isDarkMode ? settings.welcomeShowTextDark : settings.welcomeShowText;
    final base = isDarkMode ? const Color(0xFF0F1D19) : const Color(0xFFF4F1E8);
    final accent = isDarkMode ? const Color(0xFFB9D7C2) : const Color(0xFF244739);
    final secondary = isDarkMode ? const Color(0xFF1B342C) : const Color(0xFFD8C8A8);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              base,
              Color.lerp(base, secondary, 0.45)!,
              Color.lerp(base, accent, 0.18)!,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (customPath.isNotEmpty && File(customPath).existsSync())
              Opacity(
                opacity: 0.14,
                child: Image.file(File(customPath), fit: BoxFit.cover),
              ),
            Positioned(
              top: -60,
              right: -40,
              child: _GlowOrb(color: secondary.withValues(alpha: 0.35), size: 220),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _GlowOrb(color: accent.withValues(alpha: 0.18), size: 260),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDarkMode ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: accent.withValues(alpha: 0.22)),
                      ),
                      child: Text(
                        '閱讀工作台',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (showIcon)
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDarkMode ? 0.24 : 0.12),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 44),
                      ),
                    if (showIcon) const SizedBox(height: 24),
                    if (showText) ...[
                      Text(
                        kAppDisplayName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: isDarkMode ? Colors.white : const Color(0xFF15231E),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '快速進入閱讀，聚焦在書架、章節與工作流程。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.white70 : const Color(0xFF4E5E57),
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    if (_error != null)
                      Text(
                        '啟動失敗：$_error',
                        style: const TextStyle(color: Colors.redAccent, height: 1.4),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: isDarkMode ? 0.08 : 0.72),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: isDarkMode ? 0.10 : 0.55),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(accent),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _status,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF4E5E57),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

