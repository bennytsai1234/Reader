import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_highlight.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_gesture_layer.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_viewport_controller.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_runtime.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_state.dart';

import 'scroll_reader_v2_viewport.dart';
import 'slide_reader_v2_viewport.dart';

typedef ReaderRuntime = ReaderV2Runtime;
typedef ReaderMode = ReaderV2Mode;

class EngineReaderV2Screen extends StatefulWidget {
  const EngineReaderV2Screen({
    super.key,
    required this.runtime,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.onContentTapUp,
    this.viewportController,
    this.ttsHighlight,
  });

  final ReaderRuntime runtime;
  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final GestureTapUpCallback? onContentTapUp;
  final ReaderViewportController? viewportController;
  final ReaderTtsHighlight? ttsHighlight;

  @override
  State<EngineReaderV2Screen> createState() => _EngineReaderV2ScreenState();
}

class _EngineReaderV2ScreenState extends State<EngineReaderV2Screen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.runtime.addListener(_handleRuntimeChanged);
  }

  @override
  void didUpdateWidget(covariant EngineReaderV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) {
      oldWidget.runtime.removeListener(_handleRuntimeChanged);
      widget.runtime.addListener(_handleRuntimeChanged);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.runtime.removeListener(_handleRuntimeChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      unawaited(widget.runtime.flushProgress());
    }
  }

  void _handleRuntimeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.runtime.state;
    final viewport =
        state.mode == ReaderMode.scroll
            ? ScrollReaderV2Viewport(
              runtime: widget.runtime,
              backgroundColor: widget.backgroundColor,
              textColor: widget.textColor,
              style: widget.style,
              controller: widget.viewportController,
              ttsHighlight: widget.ttsHighlight,
            )
            : SlideReaderV2Viewport(
              runtime: widget.runtime,
              backgroundColor: widget.backgroundColor,
              textColor: widget.textColor,
              style: widget.style,
              controller: widget.viewportController,
              ttsHighlight: widget.ttsHighlight,
            );
    return ReaderGestureLayer(
      onTapUp: widget.onContentTapUp,
      gesturesEnabled: widget.onContentTapUp != null,
      child: viewport,
    );
  }
}
