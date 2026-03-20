import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'package:legado_reader/features/reader/view/delegate/scroll_mode_delegate.dart';
import 'package:legado_reader/features/reader/view/delegate/slide_mode_delegate.dart';
import 'package:legado_reader/features/reader/view/scroll_execution_adapter.dart';
import 'package:legado_reader/features/reader/view/scroll_restore_runner.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ReadViewRuntime extends StatefulWidget {
  final ReaderProvider provider;
  final PageController pageController;

  const ReadViewRuntime({
    super.key,
    required this.provider,
    required this.pageController,
  });

  @override
  State<ReadViewRuntime> createState() => _ReadViewRuntimeState();
}

class _ReadViewRuntimeState extends State<ReadViewRuntime>
    with TickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final Map<String, GlobalKey> _pageKeys = {};
  Ticker? _autoScrollTicker;
  Duration _lastTickTime = Duration.zero;
  Timer? _userScrollResetTimer;
  bool _isUserScrolling = false;
  int _lastTtsScrolledStart = -1;
  late final ScrollExecutionAdapter _scrollExecution = ScrollExecutionAdapter(
    pageKeys: _pageKeys,
    onStateChanged: () {
      if (mounted) {
        setState(() {});
      }
    },
  );
  final ScrollRestoreRunner _scrollRestoreRunner = const ScrollRestoreRunner();

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_onProviderStateChanged);
    _itemPositionsListener.itemPositions.addListener(_handleItemPositionsChanged);
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderStateChanged);
    _itemPositionsListener.itemPositions.removeListener(_handleItemPositionsChanged);
    _stopScrollAutoPage();
    _userScrollResetTimer?.cancel();
    widget.provider.setScrollInteractionActive(false);
    super.dispose();
  }

  void _onProviderStateChanged() {
    if (!mounted) return;
    final p = widget.provider;
    p.reconcileVisibleScrollLoads();

    if (p.pageTurnMode == PageAnim.scroll && p.isAutoPaging && !p.isAutoPagePaused) {
      _startScrollAutoPage();
    } else {
      _stopScrollAutoPage();
    }

    final pendingChapterJump = p.consumePendingChapterJump();
    if (pendingChapterJump != null && p.pageTurnMode == PageAnim.scroll) {
      if (p.isRestoring) {
        final token = p.registerPendingScrollRestore(
          chapterIndex: pendingChapterJump.chapterIndex,
          localOffset: pendingChapterJump.localOffset,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreScrollPosition(
            provider: p,
            chapterIndex: pendingChapterJump.chapterIndex,
            localOffset: pendingChapterJump.localOffset,
            token: token,
          );
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _jumpScrollPosition(
            chapterIndex: pendingChapterJump.chapterIndex,
            localOffset: pendingChapterJump.localOffset,
          );
        });
      }
    } else if (p.pageTurnMode == PageAnim.scroll &&
        p.isRestoring) {
      final pendingRestore = p.consumePendingScrollRestore();
      if (pendingRestore == null) {
        setState(() {});
        return;
      }
      final token = p.pendingScrollRestoreToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollPosition(
          provider: p,
          chapterIndex: pendingRestore.chapterIndex,
          localOffset: pendingRestore.localOffset,
          token: token,
        );
      });
    }

    if (p.pageTurnMode == PageAnim.scroll &&
        p.ttsStart >= 0 &&
        p.ttsStart != _lastTtsScrolledStart &&
        !_isUserScrolling) {
      _lastTtsScrolledStart = p.ttsStart;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTtsHighlight();
      });
    }

    setState(() {});
  }

  void _handleItemPositionsChanged() {
    final p = widget.provider;
    if (p.pageTurnMode != PageAnim.scroll) return;
    final positions = _itemPositionsListener.itemPositions.value.toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    if (positions.isEmpty) return;
    final visible = positions
        .where((item) => item.itemTrailingEdge > 0 && item.itemLeadingEdge < 1)
        .toList();
    if (visible.isEmpty) return;
    final topItem = visible.first;
    final chapterIndex = topItem.index;
    final viewportHeight = context.size?.height ?? 1.0;
    final localOffset = (-topItem.itemLeadingEdge * viewportHeight).clamp(0.0, double.infinity);
    p.handleVisibleScrollState(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      alignment: topItem.itemLeadingEdge.clamp(0.0, 1.0),
      visibleChapterIndexes: visible.map((item) => item.index).toList(),
    );
  }

  void _startScrollAutoPage() {
    if (_autoScrollTicker != null) return;
    _lastTickTime = Duration.zero;
    _autoScrollTicker = createTicker((elapsed) {
      if (!mounted) {
        _stopScrollAutoPage();
        return;
      }
      final p = widget.provider;
      if (!p.isAutoPaging || p.isAutoPagePaused || p.pageTurnMode != PageAnim.scroll) {
        _stopScrollAutoPage();
        return;
      }
      if (_lastTickTime == Duration.zero) {
        _lastTickTime = elapsed;
        return;
      }
      final dtSeconds =
          (elapsed.inMicroseconds - _lastTickTime.inMicroseconds) / 1000000.0;
      _lastTickTime = elapsed;
      final step = p.evaluateScrollAutoPageStep(dtSeconds);
      if (step == null) {
        return;
      }
      if (!step.advanceChapter &&
          step.chapterIndex != null &&
          step.localOffset != null) {
        _scrollToChapterLocalOffset(
          chapterIndex: step.chapterIndex!,
          localOffset: step.localOffset!,
          animate: false,
        );
      } else if (step.advanceChapter) {
        p.nextChapter(reason: ReaderCommandReason.autoPage);
      }
    });
    _autoScrollTicker!.start();
  }

  void _stopScrollAutoPage() {
    _autoScrollTicker?.stop();
    _autoScrollTicker?.dispose();
    _autoScrollTicker = null;
  }

  void _scrollToChapterLocalOffset({
    required int chapterIndex,
    required double localOffset,
    bool animate = false,
    Duration duration = Duration.zero,
    double topPadding = 0.0,
  }) {
    _scrollExecution.scrollToChapterLocalOffset(
      provider: widget.provider,
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      animate: animate,
      duration: duration,
      topPadding: topPadding,
    );
  }

  void _jumpScrollPosition({
    required int chapterIndex,
    required double localOffset,
  }) {
    if (!_itemScrollController.isAttached) return;
    _itemScrollController.jumpTo(
      index: chapterIndex,
      alignment: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToChapterLocalOffset(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        animate: false,
      );
    });
  }

  void _restoreScrollPosition({
    required ReaderProvider provider,
    required int chapterIndex,
    required double localOffset,
    required int token,
    int retries = 20,
  }) {
    _scrollRestoreRunner.run(
      provider: provider,
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      token: token,
      retries: retries,
      isMounted: () => mounted,
      isScrollControllerAttached: () => _itemScrollController.isAttached,
      ensureChapterVisible: () {
        _itemScrollController.jumpTo(
          index: chapterIndex,
          alignment: 0,
        );
      },
      completeRestore: () => _completeScrollRestore(provider, token),
      scrollToChapterLocalOffset: ({
        required int chapterIndex,
        required double localOffset,
        required bool animate,
      }) {
        _scrollToChapterLocalOffset(
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          animate: animate,
        );
      },
      ensureChapterCached: (targetChapterIndex) {
        return provider.ensureChapterCached(
          targetChapterIndex,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        );
      },
      hasTargetPageContext: (targetChapterIndex) {
        final runtimeChapter = provider.chapterAt(targetChapterIndex);
        final pages = provider.pagesForChapter(targetChapterIndex);
        final pageIndex = runtimeChapter != null
            ? runtimeChapter.pageIndexAtLocalOffset(localOffset)
            : ChapterPositionResolver.pageIndexAtLocalOffset(
                pages,
                localOffset,
              );
        return _pageKeys['$targetChapterIndex:$pageIndex']?.currentContext !=
            null;
      },
    );
  }

  void _completeScrollRestore(ReaderProvider provider, int token) {
    if (!mounted || !provider.matchesPendingScrollRestore(token)) return;
    provider.completeRestoreTransition();
    setState(() {});
  }

  void _scrollToTtsHighlight() {
    final provider = widget.provider;
    final viewportHeight = context.size?.height ?? 0.0;
    final target = provider.evaluateTtsFollowTarget(
      viewportHeight: viewportHeight,
    );
    if (target == null) {
      return;
    }
    _itemScrollController.scrollTo(
      index: target.chapterIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToChapterLocalOffset(
        chapterIndex: target.chapterIndex,
        localOffset: target.localOffset,
        animate: true,
        duration: const Duration(milliseconds: 160),
        topPadding: target.topPadding,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (provider.viewSize != size) {
          WidgetsBinding.instance.addPostFrameCallback((_) => provider.setViewSize(size));
        }

        final hasVisibleData = provider.pageTurnMode == PageAnim.scroll
            ? provider.pageFactory.orderedChapters.isNotEmpty
            : provider.slidePages.isNotEmpty;

        final waitingForFirstContent =
            !hasVisibleData &&
            (provider.lifecycle == ReaderLifecycle.loading ||
                provider.lifecycle == ReaderLifecycle.restoring ||
                provider.viewSize == null ||
                provider.chapters.isNotEmpty);
        final holdScrollUntilRestored =
            provider.pageTurnMode == PageAnim.scroll &&
            provider.lifecycle == ReaderLifecycle.restoring &&
            hasVisibleData;

        if ((provider.isLoading && !hasVisibleData) || waitingForFirstContent) {
          return Container(
            color: provider.currentTheme.backgroundColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!hasVisibleData && !provider.isLoading) {
          return Container(
            color: provider.currentTheme.backgroundColor,
            child: Center(
              child: Text(
                '暫無內容',
                style: TextStyle(color: provider.currentTheme.textColor.withAlpha(128)),
              ),
            ),
          );
        }

        if (provider.isRestoring && provider.pageTurnMode != PageAnim.scroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.pageController.hasClients &&
                widget.pageController.page?.round() != provider.currentPageIndex) {
              widget.pageController.jumpToPage(provider.currentPageIndex);
            }
            provider.completeRestoreTransition();
          });
        }

        final delegate = provider.pageTurnMode == PageAnim.scroll
            ? ScrollModeDelegate(
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                pageKeys: _pageKeys,
                isUserScrolling: () => _isUserScrolling,
              )
            : const SlideModeDelegate();

        final content = NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (provider.pageTurnMode != PageAnim.scroll) return false;
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _isUserScrolling = true;
              _userScrollResetTimer?.cancel();
              provider.setScrollInteractionActive(true);
            } else if (notification is ScrollEndNotification) {
              _userScrollResetTimer?.cancel();
              _userScrollResetTimer = Timer(const Duration(milliseconds: 800), () {
                if (mounted) {
                  _isUserScrolling = false;
                  provider.setScrollInteractionActive(false);
                }
              });
            }
            return false;
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: delegate.build(
              context: context,
              provider: provider,
              pageController: widget.pageController,
            ),
          ),
        );

        if (holdScrollUntilRestored) {
          return Stack(
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: 0,
                  child: content,
                ),
              ),
              Container(
                color: provider.currentTheme.backgroundColor,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        return content;
      },
    );
  }
}
