import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';

class TtsDialog extends StatelessWidget {
  const TtsDialog({super.key});

  static void show(BuildContext context) {
    final readerProvider = context.read<ReaderProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => MultiProvider(
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
    final isActive = provider.isTtsActive;
    final isPlaying = provider.isTtsPlaying;
    final statusText = isPlaying ? '正在朗讀...' : (isActive ? '已暫停' : '未開始');

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頂部拖拽條
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 標題與關閉
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.record_voice_over,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '語音朗讀',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 核心控制器 (播放與狀態)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.currentChapterTitle.isNotEmpty
                                  ? provider.currentChapterTitle
                                  : '準備就緒',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 播放按鈕
                      GestureDetector(
                        onTap: () => provider.toggleTts(),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isPlaying
                                      ? [Colors.redAccent, Colors.red.shade700]
                                      : [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.8),
                                      ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isPlaying
                                        ? Colors.red
                                        : Theme.of(context).colorScheme.primary)
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tts.remainingMinutes > 0) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '倒數計時中: ${tts.remainingMinutes} 分鐘',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 設定標籤區域
            _buildSectionTitle('定時關閉'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildTimeOption(context, '不計時', 0, tts),
                  _buildTimeOption(context, '15分', 15, tts),
                  _buildTimeOption(context, '30分', 30, tts),
                  _buildTimeOption(context, '60分', 60, tts),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('讀完本章停止', style: TextStyle(fontSize: 12)),
                    selected: provider.stopAfterChapter,
                    onSelected: (v) => provider.setStopAfterChapter(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('語音參數'),
            _buildChipRow(
              context: context,
              label: '語速',
              options: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
              current: tts.rate,
              format: (v) => '${v}x',
              onSelected: (v) => provider.setTtsRate(v),
            ),
            _buildChipRow(
              context: context,
              label: '音調',
              options: const [0.8, 0.9, 1.0, 1.1, 1.2],
              current: tts.pitch,
              format: (v) => '${v}x',
              onSelected: (v) => provider.setTtsPitch(v),
            ),

            const SizedBox(height: 24),
            // 底層操作
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryAction(
                    context,
                    Icons.skip_previous,
                    '上一頁',
                    () => provider.prevPageOrChapter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecondaryAction(
                    context,
                    Icons.skip_next,
                    '下一頁',
                    () => provider.nextPageOrChapter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecondaryAction(
                    context,
                    Icons.stop_circle_outlined,
                    '停止朗讀',
                    () {
                      provider.stopTts();
                      Navigator.pop(context);
                    },
                    isWarning: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSecondaryAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isWarning = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor:
            isWarning
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
        foregroundColor:
            isWarning
                ? Colors.red
                : Theme.of(context).colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChipRow({
    required BuildContext context,
    required String label,
    required List<double> options,
    required double current,
    required String Function(double) format,
    required void Function(double) onSelected,
  }) {
    final selected = options.reduce(
      (a, b) => (a - current).abs() < (b - current).abs() ? a : b,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children:
                    options.map((v) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            format(v),
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: v == selected,
                          onSelected: (_) => onSelected(v),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(
    BuildContext context,
    String label,
    int mins,
    TTSService tts,
  ) {
    final isSelected = tts.remainingMinutes == mins;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (v) {
          if (v) tts.setSleepTimer(mins);
        },
      ),
    );
  }
}
