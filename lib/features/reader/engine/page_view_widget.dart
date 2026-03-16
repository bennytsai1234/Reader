import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'text_page.dart';

/// PageViewWidget - 核心內容繪製組件
/// 對應 Android: ui/book/read/page/PageView.kt 與 ContentTextView.kt
class PageViewWidget extends StatelessWidget {
  final TextPage page;
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

  const PageViewWidget({
    super.key,
    required this.page,
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
    this.isScrollMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();
    
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
            child: CustomPaint(
              painter: _TextPagePainter(
                page: page,
                contentStyle: contentStyle,
                titleStyle: titleStyle,
                paddingLeft: paddingLeft,
                isAutoPaging: isAutoPaging,
                autoPageProgress: autoPageProgress,
                ttsStart: ttsStart,
                ttsEnd: ttsEnd,
              ),
            ),
          ),
          // 2. 圖片互動層 (原 Android：支援點擊查看圖片)
          ...page.lines.where((l) => l.image != null).map((line) {
            final img = line.image!;
            return Positioned(
              left: provider.textPadding + img.left,
              top: 40.0 + line.lineTop,
              width: img.width,
              height: img.height,
              child: GestureDetector(
                onTap: () => _showImageDialog(context, img.url),
                child: CachedNetworkImage(
                  imageUrl: img.url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(imageUrl: url),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('關閉')),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存圖片 (模擬)')));
                }, child: const Text('保存')),
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
  final TextStyle contentStyle;
  final TextStyle titleStyle;
  final double paddingLeft;
  final bool isAutoPaging;
  final double autoPageProgress;
  final int ttsStart;
  final int ttsEnd;

  _TextPagePainter({
    required this.page,
    required this.contentStyle,
    required this.titleStyle,
    required this.paddingLeft,
    this.isAutoPaging = false,
    this.autoPageProgress = 0.0,
    this.ttsStart = -1,
    this.ttsEnd = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final width = size.width - paddingLeft * 2;

    // 繪製每一行
    for (var line in page.lines) {
      if (line.image != null) continue;

      // 處理 TTS 高亮 (對位 Android：朗讀時背景高亮)
      final bool isTtsActive = ttsStart != -1 && 
          line.chapterPosition >= ttsStart && 
          line.chapterPosition < ttsEnd;

      if (isTtsActive) {
        final highlightPaint = Paint()
          ..color = contentStyle.color?.withOpacity(0.2) ?? Colors.yellow.withOpacity(0.3);
        canvas.drawRect(
          Rect.fromLTWH(paddingLeft, 40.0 + line.lineTop, width, line.height),
          highlightPaint,
        );
      }

      textPainter.text = TextSpan(
        text: line.text, 
        style: line.isTitle ? titleStyle : contentStyle
      );
      
      // 關鍵：對位 Android 的兩端對齊繪製
      textPainter.textAlign = line.shouldJustify ? TextAlign.justify : TextAlign.left;
      
      textPainter.layout(minWidth: width, maxWidth: width);
      textPainter.paint(canvas, Offset(paddingLeft, 40.0 + line.lineTop));
    }
  }

  @override
  bool shouldRepaint(covariant _TextPagePainter oldDelegate) => true;
}
