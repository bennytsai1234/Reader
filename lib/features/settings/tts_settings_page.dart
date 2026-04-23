import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_source.dart';
import 'settings_provider.dart';
import 'http_tts_provider.dart';
import 'http_tts_manager_page.dart';

class TtsSettingsPage extends StatelessWidget {
  const TtsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HttpTtsProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('朗讀與語音')),
        body: Consumer2<SettingsProvider, HttpTtsProvider>(
          builder: (context, settings, httpTts, child) {
            final availableHttpEngines =
                httpTts.engines
                    .where((engine) => engine.url.trim().isNotEmpty)
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
            final selectedSourceKey = _effectiveSourceKey(
              settings.ttsSourceKey,
              availableHttpEngines.map((engine) => engine.id).toSet(),
            );

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
                _buildSectionTitle('語音來源'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedSourceKey,
                    decoration: const InputDecoration(
                      labelText: '朗讀來源',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: ReaderTtsSourcePreference.systemKey,
                        child: Text('系統 TTS'),
                      ),
                      ...availableHttpEngines.map(
                        (engine) => DropdownMenuItem<String>(
                          value: ReaderTtsSourcePreference.httpKeyForId(
                            engine.id,
                          ),
                          child: Text('HTTP TTS · ${engine.name}'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      settings.setTtsSourceKey(value);
                    },
                  ),
                ),
                if (ReaderTtsSourcePreference.httpIdFromKey(
                      selectedSourceKey,
                    ) !=
                    null)
                  ListTile(
                    leading: const Icon(Icons.cloud_done_outlined),
                    title: const Text('目前 HTTP 引擎'),
                    subtitle: Text(
                      availableHttpEngines
                          .firstWhere(
                            (engine) =>
                                engine.id ==
                                ReaderTtsSourcePreference.httpIdFromKey(
                                  selectedSourceKey,
                                ),
                          )
                          .name,
                    ),
                  ),

                const Divider(),
                _buildSectionTitle('語音引擎'),
                ListTile(
                  title: const Text('HTTP TTS 管理'),
                  subtitle: const Text('設定網路自定義語音引擎'),
                  leading: const Icon(Icons.cloud_queue),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HttpTtsManagerPage(),
                      ),
                    );
                    if (!context.mounted) return;
                    await context.read<HttpTtsProvider>().loadEngines();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _effectiveSourceKey(String rawKey, Set<int> availableHttpIds) {
    final normalized = ReaderTtsSourcePreference.normalize(rawKey);
    final httpId = ReaderTtsSourcePreference.httpIdFromKey(normalized);
    if (httpId != null && !availableHttpIds.contains(httpId)) {
      return ReaderTtsSourcePreference.systemKey;
    }
    return normalized;
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
