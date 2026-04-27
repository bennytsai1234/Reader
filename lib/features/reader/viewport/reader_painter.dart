import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/page_window.dart';

class ReaderPainter extends CustomPainter {
  ReaderPainter({
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.pageWindow,
    this.singlePage,
    this.pageOffset = 0,
    this.debugOverlay = false,
    super.repaint,
  });

  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final PageWindow? pageWindow;
  final TextPage? singlePage;
  final double pageOffset;
  final bool debugOverlay;

  static final Map<String, TextPainter> _textPainterCache =
      <String, TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(backgroundColor, BlendMode.src);
    final page = singlePage;
    if (page != null) {
      _drawPage(canvas, page, 0, size);
      return;
    }
    final window = pageWindow;
    if (window == null) return;
    final prev = window.prev;
    if (prev != null && pageOffset > 0) {
      _drawPage(canvas, prev, pageOffset - prev.height, size);
    }
    var y = pageOffset;
    for (final page in window.paintForwardPages) {
      if (y > size.height) break;
      _drawPage(canvas, page, y, size);
      y += page.height;
    }
  }

  void _drawPage(Canvas canvas, TextPage page, double pageY, Size size) {
    final left = style.paddingLeft;
    final top = style.paddingTop + pageY;
    for (final line in page.lines) {
      if (top + line.bottom < 0 || top + line.top > size.height) continue;
      final painter = _painterFor(line);
      painter.paint(canvas, Offset(left, top + line.top));
    }
    if (debugOverlay) {
      final debugPainter = TextPainter(
        text: TextSpan(
          text:
              'c${page.chapterIndex} p${page.pageIndex} ${page.startCharOffset}-${page.endCharOffset}',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.45),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: size.width);
      debugPainter.paint(canvas, Offset(left, top + 2));
    }
  }

  TextPainter _painterFor(TextLine line) {
    final key = <Object?>[
      line.text,
      line.isTitle,
      style.fontSize,
      style.lineHeight,
      style.letterSpacing,
      style.fontFamily,
      style.bold,
      textColor.toARGB32(),
    ].join('|');
    final cached = _textPainterCache[key];
    if (cached != null) return cached;
    final textStyle = TextStyle(
      color: textColor,
      fontSize: line.isTitle ? style.fontSize + 4 : style.fontSize,
      height: style.lineHeight,
      letterSpacing: style.letterSpacing,
      fontFamily: style.fontFamily,
      fontWeight:
          line.isTitle || style.bold ? FontWeight.bold : FontWeight.normal,
    );
    final painter = TextPainter(
      text: TextSpan(text: line.text, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: double.infinity);
    if (_textPainterCache.length > 2000) {
      _textPainterCache.clear();
    }
    _textPainterCache[key] = painter;
    return painter;
  }

  @override
  bool shouldRepaint(covariant ReaderPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.style != style ||
        oldDelegate.pageWindow != pageWindow ||
        oldDelegate.singlePage != singlePage ||
        oldDelegate.pageOffset != pageOffset ||
        oldDelegate.debugOverlay != debugOverlay;
  }
}
