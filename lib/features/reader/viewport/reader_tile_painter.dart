import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

typedef ReaderTilePaintObserver = void Function(PageCache tile);

class ReaderTilePainter extends CustomPainter {
  ReaderTilePainter({
    required this.tile,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.debugOverlay = false,
    this.enableJustification = true,
  });

  final PageCache tile;
  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final bool debugOverlay;
  final bool enableJustification;

  static final Map<String, TextPainter> _textPainterCache =
      <String, TextPainter>{};
  static ReaderTilePaintObserver? debugOnPaint;

  @override
  void paint(Canvas canvas, Size size) {
    assert(() {
      debugOnPaint?.call(tile);
      return true;
    }());

    canvas.drawColor(backgroundColor, BlendMode.src);
    final left = style.paddingLeft;
    final top = style.paddingTop;
    final contentWidth =
        (size.width - style.paddingLeft - style.paddingRight)
            .clamp(1.0, double.infinity)
            .toDouble();

    final contentRect = Rect.fromLTWH(
      left,
      top,
      contentWidth,
      tile.contentHeight,
    );
    canvas.save();
    canvas.clipRect(contentRect);
    for (final line in tile.lines) {
      final offset = Offset(left, top + line.top);
      if (_canJustify(line, contentWidth)) {
        _paintJustifiedLine(canvas, line, offset, contentWidth);
      } else {
        final painter = _painterFor(line);
        painter.paint(canvas, offset);
      }
    }
    canvas.restore();

    if (debugOverlay) {
      final debugPainter = TextPainter(
        text: TextSpan(
          text:
              'c${tile.chapterIndex} p${tile.pageIndex} ${tile.startCharOffset}-${tile.endCharOffset}',
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

  bool _canJustify(TextLine line, double contentWidth) {
    if (!enableJustification ||
        !line.shouldJustify ||
        line.isTitle ||
        line.isParagraphEnd) {
      return false;
    }
    if (line.text.trimRight().length < 2) return false;
    return contentWidth > line.width + 1;
  }

  void _paintJustifiedLine(
    Canvas canvas,
    TextLine line,
    Offset offset,
    double contentWidth,
  ) {
    final glyphs = line.text.characters.toList(growable: false);
    if (glyphs.length < 2) {
      _painterFor(line).paint(canvas, offset);
      return;
    }
    final extra = (contentWidth - line.width).clamp(0.0, style.fontSize * 1.5);
    final gap = extra / (glyphs.length - 1);
    var dx = offset.dx;
    for (var i = 0; i < glyphs.length; i++) {
      final painter = _painterForText(glyphs[i], line);
      painter.paint(canvas, Offset(dx, offset.dy));
      dx += painter.width + (i == glyphs.length - 1 ? 0 : gap);
    }
  }

  TextPainter _painterFor(TextLine line) {
    return _painterForText(line.text, line);
  }

  TextPainter _painterForText(String text, TextLine line) {
    final effectiveLineHeight = style.effectiveLineHeight;
    final key = <Object?>[
      text,
      line.isTitle,
      style.fontSize,
      effectiveLineHeight,
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
      height: effectiveLineHeight,
      letterSpacing: style.letterSpacing,
      fontFamily: style.fontFamily,
      fontWeight:
          line.isTitle || style.bold ? FontWeight.bold : FontWeight.normal,
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);

    if (_textPainterCache.length > 2000) {
      _textPainterCache.clear();
    }
    _textPainterCache[key] = painter;
    return painter;
  }

  @override
  bool shouldRepaint(covariant ReaderTilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.style != style ||
        oldDelegate.debugOverlay != debugOverlay ||
        oldDelegate.enableJustification != enableJustification;
  }
}
