import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'http_tts_manager_page.dart';

class TtsSettingsPage extends StatelessWidget {
  const TtsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('朗讀與語音')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildSectionTitle('朗讀參數'),
              ListTile(
                title: const Text('語速'),
                subtitle: Slider(
                  value: settings.speechRate,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) => settings.setSpeechRate(v),
                ),
                trailing: Text(settings.speechRate.toStringAsFixed(1)),
              ),
              ListTile(
                title: const Text('音調'),
                subtitle: Slider(
                  value: settings.speechPitch,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) => settings.setSpeechPitch(v),
                ),
                trailing: Text(settings.speechPitch.toStringAsFixed(1)),
              ),

              const Divider(),
              _buildSectionTitle('進階控制'),
              SwitchListTile(
                title: const Text('朗讀時保持喚醒'),
                subtitle: const Text('朗讀期間防止系統休眠'),
                value: settings.readAloudWakeLock,
                onChanged: (v) => settings.setReadAloudWakeLock(v),
              ),
              SwitchListTile(
                title: const Text('媒體按鍵控制'),
                subtitle: const Text('使用耳機或媒體按鍵控制朗讀'),
                value: settings.readAloudByMediaButton,
                onChanged: (v) => settings.setReadAloudByMediaButton(v),
              ),
              SwitchListTile(
                title: const Text('通話時暫停朗讀'),
                value: settings.pauseReadAloudWhilePhoneCalls,
                onChanged: (v) => settings.setPauseReadAloudWhilePhoneCalls(v),
              ),

              const Divider(),
              _buildSectionTitle('語音引擎'),
              ListTile(
                title: const Text('HTTP TTS 管理'),
                subtitle: const Text('設定網路自定義語音引擎'),
                leading: const Icon(Icons.cloud_queue),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HttpTtsManagerPage(),
                      ),
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
}

class TtsSettingsPageWidget extends StatelessWidget {
  const TtsSettingsPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const TtsSettingsPage();
  }
}
