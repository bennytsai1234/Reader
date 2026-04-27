import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_screen.dart';

class ReadViewRuntime extends StatelessWidget {
  const ReadViewRuntime({
    super.key,
    required this.provider,
    required this.pageController,
    this.onContentTapUp,
  });

  final ReaderProvider provider;
  final PageController pageController;
  final GestureTapUpCallback? onContentTapUp;

  @override
  Widget build(BuildContext context) {
    return EngineReaderScreen(
      provider: provider,
      onContentTapUp: onContentTapUp,
    );
  }
}
