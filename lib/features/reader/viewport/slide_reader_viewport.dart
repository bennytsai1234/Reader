import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';

import 'reader_painter.dart';

class SlideReaderViewport extends StatefulWidget {
  const SlideReaderViewport({
    super.key,
    required this.runtime,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.onTapUp,
  });

  final ReaderRuntime runtime;
  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final GestureTapUpCallback? onTapUp;

  @override
  State<SlideReaderViewport> createState() => _SlideReaderViewportState();
}

class _SlideReaderViewportState extends State<SlideReaderViewport> {
  late PageController _controller;
  bool _recentering = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 1);
    widget.runtime.addListener(_onRuntimeChanged);
  }

  @override
  void didUpdateWidget(covariant SlideReaderViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) {
      oldWidget.runtime.removeListener(_onRuntimeChanged);
      widget.runtime.addListener(_onRuntimeChanged);
      _resetController();
    }
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_onRuntimeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _resetController() {
    _controller.dispose();
    _controller = PageController(initialPage: 1);
  }

  void _handlePageChanged(int index) {
    if (_recentering) return;
    if (index == 1) return;
    final moved =
        index > 1
            ? widget.runtime.moveToNextPage()
            : widget.runtime.moveToPrevPage();
    if (!moved) {
      _jumpBackToCenter();
      return;
    }
    final page = widget.runtime.state.pageWindow?.current;
    if (page != null) {
      widget.runtime.handleSlidePageSettled(page);
    }
    _jumpBackToCenter();
  }

  void _jumpBackToCenter() {
    _recentering = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.jumpToPage(1);
      _recentering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.runtime.state;
    final window = state.pageWindow;
    if (state.phase != ReaderPhase.ready || window == null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onTapUp,
        child: ColoredBox(
          color: widget.backgroundColor,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.textColor.withValues(alpha: 0.35),
            ),
          ),
        ),
      );
    }
    final pages = <TextPage?>[window.prev, window.current, window.next];
    return PageView.builder(
      controller: _controller,
      physics: const BouncingScrollPhysics(),
      itemCount: pages.length,
      onPageChanged: _handlePageChanged,
      itemBuilder: (context, index) {
        final page = pages[index];
        if (page == null) {
          return ColoredBox(color: widget.backgroundColor);
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: widget.onTapUp,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: ReaderPainter(
                backgroundColor: widget.backgroundColor,
                textColor: widget.textColor,
                style: widget.style,
                singlePage: page,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}
