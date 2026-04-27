import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';
import 'package:inkpage_reader/features/reader/engine/layout_engine.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/reader_layout.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';

import 'scroll_reader_viewport.dart';
import 'slide_reader_viewport.dart';

class EngineReaderScreen extends StatefulWidget {
  const EngineReaderScreen({
    super.key,
    required this.provider,
    this.onContentTapUp,
  });

  final ReaderProvider provider;
  final GestureTapUpCallback? onContentTapUp;

  @override
  State<EngineReaderScreen> createState() => _EngineReaderScreenState();
}

class _EngineReaderScreenState extends State<EngineReaderScreen>
    with WidgetsBindingObserver {
  ReaderRuntime? _runtime;
  Size? _lastSize;
  String? _lastStyleSignature;
  bool _opening = false;
  bool _syncingProvider = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.provider.addListener(_onProviderChanged);
  }

  @override
  void didUpdateWidget(covariant EngineReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      oldWidget.provider.removeListener(_onProviderChanged);
      widget.provider.addListener(_onProviderChanged);
      _disposeRuntime();
      _lastSize = null;
      _lastStyleSignature = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.provider.removeListener(_onProviderChanged);
    unawaited(_runtime?.flushProgress());
    _disposeRuntime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      unawaited(_runtime?.flushProgress());
    }
  }

  void _disposeRuntime() {
    _runtime?.removeListener(_syncProviderFromRuntime);
    _runtime?.dispose();
    _runtime = null;
  }

  void _onProviderChanged() {
    if (_syncingProvider) return;
    final runtime = _runtime;
    final size = _lastSize;
    if (runtime == null || size == null) return;
    final style = _styleFor(widget.provider, size);
    final spec = LayoutSpec.fromViewport(viewportSize: size, style: style);
    if (_lastStyleSignature != spec.layoutSignature) {
      _lastStyleSignature = spec.layoutSignature;
      unawaited(runtime.updateLayoutSpec(spec));
    }
    final targetMode = _modeFor(widget.provider.pageTurnMode);
    if (runtime.state.mode != targetMode) {
      unawaited(runtime.switchMode(targetMode));
    }
    final chapterJump = widget.provider.consumePendingChapterJump();
    if (chapterJump != null) {
      unawaited(runtime.jumpToChapter(chapterJump.chapterIndex));
      widget.provider.clearPendingChapterJump();
    }
  }

  void _syncProviderFromRuntime() {
    final runtime = _runtime;
    if (runtime == null || _syncingProvider) return;
    final state = runtime.state;
    final window = state.pageWindow;
    _syncingProvider = true;
    try {
      widget.provider.currentChapterIndex = state.visibleLocation.chapterIndex;
      widget.provider.visibleChapterIndex = state.visibleLocation.chapterIndex;
      widget.provider.currentPageIndex = window?.current.pageIndex ?? 0;
      if (window != null) {
        widget.provider.chapterPagesCache[window.current.chapterIndex] =
            runtime.resolver.cachedLayout(window.current.chapterIndex)?.pages ??
            <TextPage>[window.current];
        widget.provider.slidePages = <TextPage>[
          if (window.prev != null) window.prev!,
          window.current,
          if (window.next != null) window.next!,
        ];
      }
      if (widget.provider.lifecycle != ReaderLifecycle.ready &&
          state.phase == ReaderPhase.ready) {
        widget.provider.lifecycle = ReaderLifecycle.ready;
      }
      widget.provider.notifyListeners();
    } finally {
      _syncingProvider = false;
    }
  }

  ReaderRuntime _ensureRuntime(Size size, ReadStyle style) {
    final existing = _runtime;
    if (existing != null) return existing;
    final repository = ChapterRepository(
      book: widget.provider.book,
      initialChapters: widget.provider.chapters,
      bookDao: widget.provider.bookDao,
      chapterDao: widget.provider.chapterDao,
      replaceDao: widget.provider.replaceDao,
      sourceDao: widget.provider.sourceDao,
      contentDao: widget.provider.readerChapterContentDao,
      service: widget.provider.service,
      currentChineseConvert: () => widget.provider.chineseConvert,
    );
    final layoutEngine = LayoutEngine();
    final spec = LayoutSpec.fromViewport(viewportSize: size, style: style);
    final progressController = ReaderProgressController(
      book: widget.provider.book,
      repository: repository,
      bookDao: widget.provider.bookDao,
    );
    final runtime = ReaderRuntime(
      book: widget.provider.book,
      repository: repository,
      layoutEngine: layoutEngine,
      progressController: progressController,
      initialLayoutSpec: spec,
      initialMode: _modeFor(widget.provider.pageTurnMode),
    )..addListener(_syncProviderFromRuntime);
    _runtime = runtime;
    _lastStyleSignature = spec.layoutSignature;
    if (!_opening) {
      _opening = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(runtime.openBook().whenComplete(() => _opening = false));
      });
    }
    return runtime;
  }

  ReaderMode _modeFor(int pageTurnMode) {
    return pageTurnMode == PageAnim.scroll
        ? ReaderMode.scroll
        : ReaderMode.slide;
  }

  ReadStyle _styleFor(ReaderProvider provider, Size size) {
    final mediaPadding = MediaQuery.paddingOf(context);
    final top =
        (mediaPadding.top * kReaderContentTopSafeAreaFactor) +
        kReaderContentTopSpacing;
    final bottom = mediaPadding.bottom + kReaderPermanentInfoReservedHeight;
    provider.updateContentInsets(top: top, bottom: bottom);
    provider.updateScrollViewportInsets(top: top, bottom: bottom);
    return ReadStyle(
      fontSize: provider.fontSize,
      lineHeight: provider.lineHeight,
      letterSpacing: provider.letterSpacing,
      paragraphSpacing: provider.paragraphSpacing,
      paddingTop: top,
      paddingBottom: bottom,
      paddingLeft: provider.textPadding,
      paddingRight: provider.textPadding,
      bold: false,
      pageMode: ReaderPageMode.fromPageAnim(provider.pageTurnMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _lastSize = size;
        final provider = widget.provider;
        final style = _styleFor(provider, size);
        final runtime = _ensureRuntime(size, style);
        final spec = LayoutSpec.fromViewport(viewportSize: size, style: style);
        if (_lastStyleSignature != spec.layoutSignature) {
          _lastStyleSignature = spec.layoutSignature;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(runtime.updateLayoutSpec(spec));
          });
        }
        final theme = _readingTheme(provider);
        final state = runtime.state;
        if (state.mode == ReaderMode.scroll) {
          return ScrollReaderViewport(
            runtime: runtime,
            backgroundColor: theme.backgroundColor,
            textColor: theme.textColor,
            style: style,
            onTapUp: widget.onContentTapUp,
          );
        }
        return SlideReaderViewport(
          runtime: runtime,
          backgroundColor: theme.backgroundColor,
          textColor: theme.textColor,
          style: style,
          onTapUp: widget.onContentTapUp,
        );
      },
    );
  }

  ReadingTheme _readingTheme(ReaderProvider provider) {
    if (AppTheme.readingThemes.isEmpty) {
      return ReadingTheme(
        name: 'fallback',
        backgroundColor: Colors.white,
        textColor: const Color(0xFF1A1A1A),
      );
    }
    final index =
        provider.themeIndex.clamp(0, AppTheme.readingThemes.length - 1).toInt();
    return AppTheme.readingThemes[index];
  }
}
