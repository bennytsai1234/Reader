import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_source_fallback_sheet.dart';
import 'text_page.dart';

/// PageViewWidget - 核心內容繪製組件
/// 對應 Android: ui/book/read/page/PageView.kt 與 ContentTextView.kt
class PageViewWidget extends StatelessWidget {
  final TextPage page;
  final TextPage? nextPage; // 用於分頁模式掃描線效果
  final TextStyle contentStyle;
  final TextStyle titleStyle;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final bool isAutoPaging;
  final double autoPageProgress;
  final int ttsStart;
  final int ttsEnd;
  final bool isScrollMode;
  final void Function(int lineIndex)? onLineTap;
  final Color pageBackgroundColor;

  /// TTS 正在朗讀的章節索引，用於過濾跨章節時的重複高亮（-1 表示不過濾）
  final int ttsChapterIndex;

  const PageViewWidget({
    super.key,
    required this.page,
    this.nextPage,
    required this.contentStyle,
    required this.titleStyle,
    this.paddingTop = 40.0,
    this.paddingBottom = 40.0,
    this.paddingLeft = 16.0,
    this.paddingRight = 16.0,
    this.isAutoPaging = false,
    this.autoPageProgress = 0.0,
    this.ttsStart = -1,
    this.ttsEnd = -1,
    this.ttsChapterIndex = -1,
    this.isScrollMode = false,
    this.onLineTap,
    this.pageBackgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();
    final double currentPaddingTop = isScrollMode ? 0.0 : paddingTop;
    final failureMessage = provider.chapterFailureMessage(page.chapterIndex);

    if (failureMessage != null && failureMessage.trim().isNotEmpty) {
      return _buildFailureCard(context, provider, failureMessage);
    }

    // 分頁模式自動翻頁：使用 ValueListenableBuilder 實現 60fps 掃描線動畫
    final bool needsScanLine =
        isAutoPaging && !isScrollMode && nextPage != null;
    final scanLineColor = provider.currentTheme.textColor.withValues(
      alpha: 0.6,
    );

    return SelectionArea(
      contextMenuBuilder: (context, selectableRegionState) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: selectableRegionState.contextMenuAnchors,
          buttonItems: selectableRegionState.contextMenuButtonItems,
        );
      },
      child: Stack(
        children: [
          // 1. 文字繪製層
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                if (onLineTap == null) return;
                // 扣除 paddingTop 後，判斷點擊落在哪一行
                final tapY = details.localPosition.dy - currentPaddingTop;
                for (int i = 0; i < page.lines.length; i++) {
                  final line = page.lines[i];
                  if (tapY >= line.lineTop && tapY < line.lineBottom) {
                    onLineTap!(i);
                    break;
                  }
                }
              },
              child:
                  needsScanLine
                      ? ValueListenableBuilder<double>(
                        valueListenable: provider.autoPageProgressNotifier,
                        builder:
                            (_, progress, __) => CustomPaint(
                              painter: _TextPagePainter(
                                page: page,
                                nextPage: nextPage,
                                contentStyle: contentStyle,
                                titleStyle: titleStyle,
                                paddingLeft: paddingLeft,
                                paddingTop: currentPaddingTop,
                                isAutoPaging: true,
                                autoPageProgress: progress,
                                scanLineColor: scanLineColor,
                                pageBackgroundColor: pageBackgroundColor,
                                ttsStart: ttsStart,
                                ttsEnd: ttsEnd,
                                ttsChapterIndex: ttsChapterIndex,
                              ),
                            ),
                      )
                      : CustomPaint(
                        painter: _TextPagePainter(
                          page: page,
                          contentStyle: contentStyle,
                          titleStyle: titleStyle,
                          paddingLeft: paddingLeft,
                          paddingTop: currentPaddingTop,
                          isAutoPaging: false,
                          autoPageProgress: 0.0,
                          ttsStart: ttsStart,
                          ttsEnd: ttsEnd,
                          ttsChapterIndex: ttsChapterIndex,
                        ),
                      ),
            ),
          ),
          // 2. 圖片互動層 (原 Android：支援點擊查看圖片)
          ...page.lines.where((l) => l.image != null).map((line) {
            final img = line.image!;
            return Positioned(
              left: provider.textPadding + img.left,
              top: currentPaddingTop + line.lineTop,
              width: img.width,
              height: img.height,
              child: GestureDetector(
                onTap: () => _showImageDialog(context, img.url),
                child: CachedNetworkImage(
                  imageUrl: img.url,
                  fit: BoxFit.contain,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFailureCard(
    BuildContext context,
    ReaderProvider provider,
    String failureMessage,
  ) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '目前來源無法載入這一章',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                failureMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if ((provider.sourceSwitchMessage ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  provider.sourceSwitchMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                    provider.isSwitchingSource
                        ? null
                        : () {
                          provider.autoChangeSourceForCurrentChapter();
                        },
                icon:
                    provider.isSwitchingSource
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.auto_fix_high),
                label: const Text('自動換源'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    provider.isSwitchingSource
                        ? null
                        : () => ReaderSourceFallbackSheet.show(
                          context,
                          provider.book,
                        ),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('手動換源'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CachedNetworkImage(imageUrl: url),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('關閉'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已保存圖片 (模擬)')),
                        );
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}

class _TextPagePainter extends CustomPainter {
  final TextPage page;
  final TextPage? nextPage;
  final TextStyle contentStyle;
  final TextStyle titleStyle;
  final double paddingLeft;
  final double paddingTop;
  final bool isAutoPaging;
  final double autoPageProgress;
  final Color scanLineColor;
  final Color pageBackgroundColor;
  final int ttsStart;
  final int ttsEnd;
  final int ttsChapterIndex;

  _TextPagePainter({
    required this.page,
    this.nextPage,
    required this.contentStyle,
    required this.titleStyle,
    required this.paddingLeft,
    this.paddingTop = 40.0,
    this.isAutoPaging = false,
    this.autoPageProgress = 0.0,
    this.scanLineColor = Colors.blue,
    this.pageBackgroundColor = Colors.white,
    this.ttsStart = -1,
    this.ttsEnd = -1,
    this.ttsChapterIndex = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 繪製當前頁面 (底層)
    _drawPageLines(canvas, size, page);

    // 2. 分頁模式掃描線效果 (對標 Android AutoPager.onDraw)
    if (isAutoPaging && nextPage != null && autoPageProgress > 0) {
      final double scanY = size.height * autoPageProgress;

      // 繪製下一頁覆蓋內容 (頂層)
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, scanY));

      // 繪製下一頁背景 (遮蓋底層當前頁文字，避免重疊閃爍)
      final bgPaint = Paint()..color = pageBackgroundColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, scanY), bgPaint);

      _drawPageLines(canvas, size, nextPage!);
      canvas.restore();

      // 繪製掃描線漸變陰影 (提升立體感)
      final shadowPaint =
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.15),
              ],
            ).createShader(Rect.fromLTWH(0, scanY - 20, size.width, 20));
      canvas.drawRect(
        Rect.fromLTWH(0, scanY - 20, size.width, 20),
        shadowPaint,
      );

      // 繪製掃描進度橫線 (1.5px)
      final scanPaint =
          Paint()
            ..color = scanLineColor
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.butt;
      canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);
    }
  }

  /// 繪製單頁內容的所有文字行
  void _drawPageLines(Canvas canvas, Size size, TextPage targetPage) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final width = size.width - paddingLeft * 2;

    for (var line in targetPage.lines) {
      if (line.image != null) continue;

      // 處理 TTS 高亮（對位 Android：朗讀時背景高亮）
      // 同時限制章節索引，避免多章節合併時不同 chapter 的相同 chapterPosition 誤觸發
      final lineStart = line.chapterPosition;
      final lineEnd = line.chapterPosition + line.text.length;
      final bool isTtsActive =
          ttsStart != -1 &&
          (ttsChapterIndex < 0 || targetPage.chapterIndex == ttsChapterIndex) &&
          lineEnd > ttsStart &&
          lineStart < ttsEnd;

      if (isTtsActive) {
        final highlightPaint =
            Paint()
              ..color =
                  contentStyle.color?.withValues(alpha: 0.2) ??
                  Colors.yellow.withValues(alpha: 0.3);
        canvas.drawRect(
          Rect.fromLTWH(
            paddingLeft,
            paddingTop + line.lineTop,
            width,
            line.height,
          ),
          highlightPaint,
        );
      }

      textPainter.text = TextSpan(
        text: line.text,
        style: line.isTitle ? titleStyle : contentStyle,
      );

      // 關鍵：對位 Android 的兩端對齊繪製
      textPainter.textAlign =
          line.shouldJustify ? TextAlign.justify : TextAlign.left;
      textPainter.layout(minWidth: width, maxWidth: width);
      textPainter.paint(canvas, Offset(paddingLeft, paddingTop + line.lineTop));
    }
  }

  @override
  bool shouldRepaint(covariant _TextPagePainter oldDelegate) {
    return oldDelegate.autoPageProgress != autoPageProgress ||
        oldDelegate.page != page ||
        oldDelegate.nextPage != nextPage ||
        oldDelegate.ttsStart != ttsStart ||
        oldDelegate.ttsEnd != ttsEnd ||
        oldDelegate.ttsChapterIndex != ttsChapterIndex ||
        oldDelegate.isAutoPaging != isAutoPaging ||
        oldDelegate.pageBackgroundColor != pageBackgroundColor;
  }
}
