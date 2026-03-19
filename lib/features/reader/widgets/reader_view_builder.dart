import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import '../reader_provider.dart';
import '../engine/page_view_widget.dart';

class ReaderViewBuilder extends StatefulWidget {
  final ReaderProvider provider;
  final PageController pageController;

  const ReaderViewBuilder({
    super.key,
    required this.provider,
    required this.pageController,
  });

  @override
  State<ReaderViewBuilder> createState() => _ReaderViewBuilderState();
}

class _ReaderViewBuilderState extends State<ReaderViewBuilder> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isUserScrolling = false;
  Ticker? _autoScrollTicker;
  Duration _lastTickTime = Duration.zero;
  Timer? _userScrollResetTimer;
  int _lastTtsScrolledStart = -1;
  int _lastKnownPagesLength = 0;
  final Key _centerKey = const ValueKey('center_sliver');
  
  bool _hasInitializedScrollController = false;
  bool _isFetchingNext = false;
  bool _isFetchingPrev = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    widget.provider.addListener(_onProviderStateChanged);

    widget.provider.scrollOffsetController.stream.listen((offset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final double pastExtent = _getPastExtent();
          if (offset >= 999999) {
            _isUserScrolling = true;
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            Future.microtask(() {
               if (mounted) {
                 _isUserScrolling = false;
                 widget.provider.isRestoring = false;
               }
            });
          } else {
            final double sliverY = offset - pastExtent;
            _isUserScrolling = true;
            _scrollController.jumpTo(sliverY.clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent + 100)); // allow beyond slightly
            Future.microtask(() {
               if (mounted) {
                 _isUserScrolling = false;
                 widget.provider.isRestoring = false;
               }
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderStateChanged);
    _stopScrollAutoPage();
    _userScrollResetTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  double _getPastExtent() {
    final p = widget.provider;
    if (p.pages.isEmpty || p.pivotChapterIndex < 0) return 0.0;
    
    double pastHeight = 0;
    for (int i = 0; i < p.pages.length; i++) {
      if (p.pages[i].chapterIndex >= p.pivotChapterIndex) break;
      pastHeight += p.pages[i].lines.isEmpty ? 0 : p.pages[i].lines.last.lineBottom;
    }
    return pastHeight;
  }

  void _onProviderStateChanged() {
    if (!mounted) return;
    final p = widget.provider;

    if (p.pages.length != _lastKnownPagesLength) {
      _lastKnownPagesLength = p.pages.length;
      setState(() {});
    }

    if (p.pageTurnMode == PageAnim.scroll && p.isAutoPaging && !p.isAutoPagePaused) {
      _startScrollAutoPage();
    } else {
      _stopScrollAutoPage();
    }

    if (p.pageTurnMode == PageAnim.scroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // In case layout changed extent, we want to immediately check bounds
        if (mounted) _handleScroll();
      });
    }

    if (p.pageTurnMode == PageAnim.scroll && p.ttsStart >= 0 && p.ttsStart != _lastTtsScrolledStart && !_isUserScrolling) {
      _lastTtsScrolledStart = p.ttsStart;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTtsHighlight();
      });
    }
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
      if (!_scrollController.hasClients) return;

      final viewSize = p.viewSize;
      if (viewSize == null) return;
      
      if (_lastTickTime == Duration.zero) {
        _lastTickTime = elapsed;
        return;
      }
      
      final dtSeconds = (elapsed.inMicroseconds - _lastTickTime.inMicroseconds) / 1000000.0;
      _lastTickTime = elapsed;

      final velocity = viewSize.height / p.autoPageSpeed.clamp(1.0, 600.0);
      final tickDelta = velocity * dtSeconds;
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (currentScroll < maxScroll - tickDelta) {
        _scrollController.jumpTo(currentScroll + tickDelta);
      } else if (currentScroll < maxScroll) {
        _scrollController.jumpTo(maxScroll);
      } else if (!p.isLoading) {
        p.nextChapter();
      }
    });
    _autoScrollTicker!.start();
  }

  void _stopScrollAutoPage() {
    _autoScrollTicker?.stop();
    _autoScrollTicker?.dispose();
    _autoScrollTicker = null;
  }

  void _handleScroll() {
    if (widget.provider.pageTurnMode == PageAnim.scroll) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double minScroll = _scrollController.position.minScrollExtent;
        final double currentScroll = _scrollController.position.pixels;
        
        final double pastExtent = _getPastExtent();
        final double virtualY = currentScroll + pastExtent;
        
        widget.provider.updateScrollOffset(virtualY);
        _updateScrollPageIndex(virtualY);

        if (widget.provider.isRestoring) return;

        final firstPage = widget.provider.pages.firstOrNull;
        final lastPage = widget.provider.pages.lastOrNull;

        // 觸發載入上一章 (邊距 500)
        if (currentScroll <= minScroll + 500 && !widget.provider.isLoading && firstPage != null && firstPage.chapterIndex > 0) {
           if (!_isFetchingPrev) {
             _isFetchingPrev = true;
             widget.provider.prevChapter().whenComplete(() {
               if (mounted) _isFetchingPrev = false;
             });
           }
           return;
        }

        // 觸發載入下一章 (邊距 1500，激進預載，消除等待時間)
        if (currentScroll >= maxScroll - 1500 && !widget.provider.isLoading && lastPage != null && lastPage.chapterIndex < widget.provider.chapters.length - 1) {
           if (!_isFetchingNext) {
             _isFetchingNext = true;
             widget.provider.nextChapter().whenComplete(() {
               if (mounted) _isFetchingNext = false;
             });
           }
        }
      }
    }
  }

  void _updateScrollPageIndex(double virtualY) {
    final provider = widget.provider;
    if (provider.pages.isEmpty) return;
    final firstPage = provider.pages.firstOrNull;
    final double headOffset = (firstPage != null && firstPage.chapterIndex > 0) ? 2.0 : 0.0;
    double cumHeight = headOffset;
    for (int i = 0; i < provider.pages.length; i++) {
      final page = provider.pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
      cumHeight += pageHeight;
      if (virtualY < cumHeight) {
        provider.updateScrollPageIndex(i);
        return;
      }
    }
  }

  void _scrollToTtsHighlight() {
    if (!_scrollController.hasClients) return;
    final provider = widget.provider;
    if (provider.ttsStart < 0 || provider.pages.isEmpty) return;

    final firstPage = provider.pages.firstOrNull;
    final double headOffset = (firstPage != null && firstPage.chapterIndex > 0) ? 2.0 : 0.0;
    double cumHeight = 0;
    for (int i = 0; i < provider.pages.length; i++) {
      final page = provider.pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom;

      // 1. 章節過濾 (Bug Fix: 避免多章節同偏移量混淆)
      if (provider.ttsChapterIndex >= 0 && page.chapterIndex != provider.ttsChapterIndex) {
        cumHeight += pageHeight;
        continue;
      }

      // 2. 頁面邊界跳過 (O(N) 降維優化)
      if (page.lines.isNotEmpty) {
        final lastLine = page.lines.last;
        final pageEndOffset = lastLine.chapterPosition + lastLine.text.length;
        if (provider.ttsStart >= pageEndOffset) {
          cumHeight += pageHeight;
          continue;
        }
      }

      for (final line in page.lines) {
        if (line.image != null) continue;
        final lEnd = line.chapterPosition + line.text.length;
        if (provider.ttsStart >= line.chapterPosition && provider.ttsStart < lEnd) {
          final virtualLineTop = headOffset + cumHeight + line.lineTop;
          final pastExtent = _getPastExtent();
          final sliverLineTop = virtualLineTop - pastExtent;
          
          final viewportH = _scrollController.position.viewportDimension;
          final currentOffset = _scrollController.offset;
          final comfortZoneBottom = currentOffset + viewportH * 0.65;
          if (sliverLineTop < currentOffset || sliverLineTop > comfortZoneBottom) {
            final target = (sliverLineTop - viewportH * 0.25).clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent);
            final distance = (target - currentOffset).abs();
            if (distance > viewportH * 0.5) {
              _scrollController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            } else {
              _scrollController.jumpTo(target);
            }
          }
          return;
        }
      }
      cumHeight += pageHeight;
    }
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

        if (provider.isLoading && provider.pages.isEmpty) {
          return Container(color: provider.currentTheme.backgroundColor, child: const Center(child: CircularProgressIndicator()));
        }

        if (provider.pages.isEmpty && !provider.isLoading) {
          return Container(color: provider.currentTheme.backgroundColor, child: Center(child: Text('暫無內容', style: TextStyle(color: provider.currentTheme.textColor.withAlpha(128)))));
        }

        if (provider.pages.isNotEmpty && !_hasInitializedScrollController && provider.pageTurnMode == PageAnim.scroll) {
          _scrollController.dispose();
          _scrollController = ScrollController(initialScrollOffset: provider.initialTargetY);
          _scrollController.addListener(_handleScroll);
          _hasInitializedScrollController = true;
        }

        if (provider.isRestoring && provider.pages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.pageTurnMode != PageAnim.scroll && widget.pageController.hasClients) {
               if (widget.pageController.page?.round() != provider.currentPageIndex) {
                 widget.pageController.jumpToPage(provider.currentPageIndex);
               }
            }
          });
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildModeReader(provider),
        );
      },
    );
  }

  Widget _buildModeReader(ReaderProvider provider) {
    switch (provider.pageTurnMode) {
      case PageAnim.scroll:
        return _buildScrollReader();
      case PageAnim.slide:
      default:
        return _buildHorizontalReader();
    }
  }

  Widget _buildHorizontalReader() {
    final p = widget.provider;
    final itemCount = p.pages.length;

    return PageView.builder(
      controller: widget.pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: itemCount,
      onPageChanged: (i) {
        if (p.pages.isEmpty || p.isLoading) return;
        if (p.isRestoring) {
          p.isRestoring = false;
          return;
        }
        
        p.onPageChanged(i);
      },
      itemBuilder: (ctx, i) {
        if (i < 0 || i >= p.pages.length) return const SizedBox.shrink();
        return _buildPageViewWidget(i);
      },
    );
  }

  Widget _buildPageViewWidget(int idx) {
    final p = widget.provider;
    return PageViewWidget(
      page: p.pages[idx],
      contentStyle: _getContentStyle(),
      titleStyle: _getTitleStyle(),
      ttsStart: p.ttsStart,
      ttsEnd: p.ttsEnd,
      ttsChapterIndex: p.ttsChapterIndex,
      isAutoPaging: p.isAutoPaging,
      autoPageProgress: p.autoPageProgress,
      pageBackgroundColor: p.currentTheme.backgroundColor,
    );
  }

  Widget _buildScrollReader() {
    final p = widget.provider;
    final int splitIndex = p.pivotChapterIndex < 0 ? 0 : p.pages.indexWhere((page) => page.chapterIndex >= p.pivotChapterIndex);
    final int safeSplitIndex = splitIndex < 0 ? 0 : splitIndex;
    
    final pastPages = p.pages.sublist(0, safeSplitIndex);
    final futurePages = p.pages.sublist(safeSplitIndex);

    final showHead = pastPages.isNotEmpty ? pastPages.first.chapterIndex > 0 : (futurePages.isNotEmpty && futurePages.first.chapterIndex > 0);
    final showTail = p.pages.isNotEmpty && p.pages.last.chapterIndex < p.chapters.length - 1;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification && notification.dragDetails != null) {
          _isUserScrolling = true;
          _userScrollResetTimer?.cancel();
        } else if (notification is ScrollEndNotification) {
          _userScrollResetTimer?.cancel();
          _userScrollResetTimer = Timer(const Duration(milliseconds: 800), () {
            if (mounted) _isUserScrolling = false;
          });
        }
        return false;
      },
      child: CustomScrollView(
        controller: _scrollController,
        center: _centerKey,
        physics: const BouncingScrollPhysics(),
        slivers: [
          if (pastPages.isNotEmpty || showHead)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (showHead && i == pastPages.length) return _buildScrollLoadingHead();
                  if (i >= pastPages.length) return const SizedBox.shrink();
                  
                  final actualIndex = pastPages.length - 1 - i;
                  final page = pastPages[actualIndex];
                  return SizedBox(
                    height: page.lines.isEmpty ? 0 : page.lines.last.lineBottom,
                    child: PageViewWidget(
                      page: page,
                      contentStyle: _getContentStyle(),
                      titleStyle: _getTitleStyle(),
                      isScrollMode: true,
                      paddingTop: 0,
                      paddingBottom: 0,
                      ttsStart: widget.provider.ttsStart,
                      ttsEnd: widget.provider.ttsEnd,
                      ttsChapterIndex: widget.provider.ttsChapterIndex,
                    ),
                  );
                },
                childCount: pastPages.length + (showHead ? 1 : 0),
              ),
            ),
          SliverList(
            key: _centerKey,
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                if (showHead && pastPages.isEmpty && i == 0) return _buildScrollLoadingHead();
                
                final actualIndex = (showHead && pastPages.isEmpty) ? i - 1 : i;
                if (showTail && actualIndex == futurePages.length) return _buildScrollLoadingTail();
                if (actualIndex < 0 || actualIndex >= futurePages.length) return const SizedBox.shrink();

                final page = futurePages[actualIndex];
                return SizedBox(
                  height: page.lines.isEmpty ? 0 : page.lines.last.lineBottom,
                  child: PageViewWidget(
                    page: page,
                    contentStyle: _getContentStyle(),
                    titleStyle: _getTitleStyle(),
                    isScrollMode: true,
                    paddingTop: 0,
                    paddingBottom: 0,
                    ttsStart: widget.provider.ttsStart,
                    ttsEnd: widget.provider.ttsEnd,
                    ttsChapterIndex: widget.provider.ttsChapterIndex,
                  ),
                );
              },
              childCount: futurePages.length + (showTail ? 1 : 0) + ((showHead && pastPages.isEmpty) ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _getContentStyle() => TextStyle(fontSize: widget.provider.fontSize, height: widget.provider.lineHeight, color: widget.provider.currentTheme.textColor, letterSpacing: widget.provider.letterSpacing);
  TextStyle _getTitleStyle() => TextStyle(fontSize: widget.provider.fontSize + 4, fontWeight: FontWeight.bold, color: widget.provider.currentTheme.textColor, letterSpacing: widget.provider.letterSpacing);

  Widget _buildScrollLoadingTail() {
    final p = widget.provider;
    final hasNext = (p.pages.lastOrNull?.chapterIndex ?? 0) < p.chapters.length - 1;
    return Container(
      color: p.currentTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(child: Text(hasNext ? '正在載入下一章...' : '全書完', style: TextStyle(color: p.currentTheme.textColor.withAlpha(77), fontSize: 14))),
    );
  }

  Widget _buildScrollLoadingHead() {
    return SizedBox(
      height: 2,
      child: Container(
        color: widget.provider.currentTheme.textColor.withValues(alpha: 0.15),
      ),
    );
  }
}
