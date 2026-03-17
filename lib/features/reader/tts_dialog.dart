import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'package:legado_reader/core/services/tts_service.dart';

class TtsDialog extends StatelessWidget {
  const TtsDialog({super.key});

  static void show(BuildContext context) {
    final readerProvider = context.read<ReaderProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: readerProvider),
          ChangeNotifierProvider.value(value: TTSService()),
        ],
        child: const TtsDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();
    final tts = context.watch<TTSService>();
    final theme = provider.currentTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            children: [
              Text('朗讀', style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: theme.textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 播放/暫停按鈕
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => provider.toggleTts(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: tts.isPlaying ? Colors.redAccent : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tts.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                if (tts.remainingMinutes > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '剩餘 ${tts.remainingMinutes} 分鐘',
                      style: TextStyle(color: theme.textColor.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 定時與章末停止
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimeOption(context, '不計時', 0, tts, theme),
                _buildTimeOption(context, '15分', 15, tts, theme),
                _buildTimeOption(context, '30分', 30, tts, theme),
                _buildTimeOption(context, '60分', 60, tts, theme),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('讀完本章停止', style: TextStyle(fontSize: 12)),
                  selected: provider.stopAfterChapter,
                  onSelected: (v) => provider.setStopAfterChapter(v),
                  selectedColor: Colors.blue.withValues(alpha: 0.2),
                  checkmarkColor: Colors.blue,
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // 語速選擇（離散）
          _buildChipRow(
            context: context,
            label: '語速',
            options: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
            current: tts.rate,
            format: (v) => '${v}x',
            onSelected: (v) => provider.setTtsRate(v),
            theme: theme,
          ),
          const SizedBox(height: 8),

          // 音調選擇（離散）
          _buildChipRow(
            context: context,
            label: '音調',
            options: const [0.5, 0.75, 1.0, 1.25, 1.5],
            current: tts.pitch,
            format: (v) => '$v',
            onSelected: (v) => provider.setTtsPitch(v),
            theme: theme,
          ),
          const SizedBox(height: 8),

          // 朗讀引擎選擇
          Row(
            children: [
              Text('引擎', style: TextStyle(color: theme.textColor, fontSize: 14)),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('系統語音', style: TextStyle(fontSize: 12)),
                selected: provider.ttsMode == 0,
                onSelected: (_) => provider.setTtsMode(0),
                selectedColor: Colors.blue.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('網絡語音', style: TextStyle(fontSize: 12)),
                selected: provider.ttsMode == 1,
                onSelected: (_) => provider.setTtsMode(1),
                selectedColor: Colors.blue.withValues(alpha: 0.2),
              ),
            ],
          ),

          // 語言選擇
          if (tts.languages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text('語言', style: TextStyle(color: theme.textColor, fontSize: 14)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: tts.language,
                    dropdownColor: theme.backgroundColor,
                    style: TextStyle(color: theme.textColor, fontSize: 13),
                    underline: const SizedBox.shrink(),
                    items: tts.languages.take(20).map((lang) => DropdownMenuItem<String>(
                      value: lang.toString(),
                      child: Text(lang.toString()),
                    )).toList(),
                    onChanged: (v) { if (v != null) provider.setTtsLanguage(v); },
                  ),
                ],
              ),
            ),

          const Divider(height: 24),

          // 快捷操作列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAction(
                icon: Icons.skip_previous,
                label: '上一頁',
                color: theme.textColor,
                onTap: () => provider.prevPageOrChapter(),
              ),
              _buildAction(
                icon: Icons.skip_next,
                label: '下一頁',
                color: theme.textColor,
                onTap: () => provider.nextPageOrChapter(),
              ),
              _buildAction(
                icon: Icons.stop_circle_outlined,
                label: '停止',
                color: Colors.redAccent,
                onTap: () {
                  provider.stopTts();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 離散選項 Chip 列（語速 / 音調）
  Widget _buildChipRow({
    required BuildContext context,
    required String label,
    required List<double> options,
    required double current,
    required String Function(double) format,
    required void Function(double) onSelected,
    required dynamic theme,
  }) {
    // 找最近的選項作為 selected
    final selected = options.reduce((a, b) => (a - current).abs() < (b - current).abs() ? a : b);
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(label, style: TextStyle(color: theme.textColor, fontSize: 14)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((v) {
                final isSelected = v == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(format(v), style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) => onSelected(v),
                    selectedColor: Colors.blue.withValues(alpha: 0.2),
                    checkmarkColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeOption(BuildContext context, String label, int mins, TTSService tts, dynamic theme) {
    final isSelected = tts.remainingMinutes == mins;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (v) { if (v) tts.setSleepTimer(mins); },
      ),
    );
  }

  Widget _buildAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
