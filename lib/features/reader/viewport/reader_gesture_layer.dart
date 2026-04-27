import 'package:flutter/material.dart';

class ReaderGestureLayer extends StatelessWidget {
  const ReaderGestureLayer({super.key, required this.child, this.onTapUp});

  final Widget child;
  final GestureTapUpCallback? onTapUp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: onTapUp,
      child: child,
    );
  }
}
