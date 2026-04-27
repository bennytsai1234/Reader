import 'package:flutter/widgets.dart';
import 'read_style.dart';

class LayoutSpec {
  LayoutSpec({
    required this.viewportSize,
    required this.contentWidth,
    required this.contentHeight,
    required this.style,
  }) : layoutSignature = _buildSignature(
         viewportSize: viewportSize,
         contentWidth: contentWidth,
         contentHeight: contentHeight,
         style: style,
       );

  final Size viewportSize;
  final double contentWidth;
  final double contentHeight;
  final ReadStyle style;
  final String layoutSignature;

  static LayoutSpec fromViewport({
    required Size viewportSize,
    required ReadStyle style,
  }) {
    final contentWidth =
        (viewportSize.width - style.paddingLeft - style.paddingRight)
            .clamp(1.0, double.infinity)
            .toDouble();
    final contentHeight =
        (viewportSize.height - style.paddingTop - style.paddingBottom)
            .clamp(1.0, double.infinity)
            .toDouble();
    return LayoutSpec(
      viewportSize: viewportSize,
      contentWidth: contentWidth,
      contentHeight: contentHeight,
      style: style,
    );
  }

  static String _buildSignature({
    required Size viewportSize,
    required double contentWidth,
    required double contentHeight,
    required ReadStyle style,
  }) {
    String f(double value) => value.toStringAsFixed(3);
    return <String>[
      f(viewportSize.width),
      f(viewportSize.height),
      f(contentWidth),
      f(contentHeight),
      f(style.fontSize),
      f(style.lineHeight),
      f(style.letterSpacing),
      f(style.paragraphSpacing),
      f(style.paddingTop),
      f(style.paddingBottom),
      f(style.paddingLeft),
      f(style.paddingRight),
      style.fontFamily ?? '',
      style.bold ? 'b' : 'r',
      style.pageMode.name,
    ].join('|');
  }
}
