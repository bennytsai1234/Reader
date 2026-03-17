import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import '../reader_provider.dart';
import '../engine/page_view_widget.dart';
import '../engine/cover_page_view.dart';

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

class _ReaderViewBuilderState extends State<ReaderViewBuilder> {
  late ScrollController _scrollController;
  bool _isUserScrolling = false;
  Timer? _autoScrollTimer;
  int _lastTtsScrolledStart = -1;
  int _lastKnownPagesLength = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    widget.provider.addListener(_onProviderStateChanged);

    widget.provider.scrollTrimAdjustController.stream.listen((upBy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          final target = (_scrollController.offset - upBy)
              .clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.jumpTo(target);
        }
      });
    });

    widget.provider.scrollOffsetController.stream.listen((offset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          if (offset >= 999999) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          } else if (offset < 0) {
            final double targetScroll = _scrollController.offset + offset.abs();
            _scrollController.jumpTo(targetScroll);
          } else if (offset > 0) {
            _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
          } else {
            _scrollController.jumpTo(0);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderStateChanged);
    _stopScrollAutoPage();
    _scrollController.dispose();
    super.dispose();
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
        if (mounted) _handleScroll();
      });
    }

    if (p.pageTurnMode == PageAnim.scroll && p.ttsStart >= 0 && p.ttsStart != _lastTtsScrolledStart) {
      _lastTtsScrolledStart = p.ttsStart;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTtsHighlight();
      });
    }
  }

  void _startScrollAutoPage() {
    if (_autoScrollTimer != null) return;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
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

      final tickDelta = (viewSize.height / p.autoPageSpeed.clamp(1.0, 600.0)) * 0.016;
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
  }

  void _stopScrollAutoPage() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _handleScroll() {
    if (widget.provider.pageTurnMode == PageAnim.scroll) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double currentScroll = _scrollController.position.pixels;
        widget.provider.updateScrollOffset(currentScroll);

        if (_isUserScrolling) return;

        final firstPage = widget.provider.pages.firstOrNull;
        final lastPage = widget.provider.pages.lastOrNull;
        _updateScrollPageIndex(currentScroll);

        if (currentScroll <= 50 && !widget.provider.isLoading && firstPage != null && firstPage.chapterIndex > 0) {
           _isUserScrolling = true;
           widget.provider.prevChapter().then((_) {
             if (mounted) _isUserScrolling = false;
           });
           return;
        }

        if (currentScroll >= maxScroll - 100 && !widget.provider.isLoading && lastPage != null && lastPage.chapterIndex < widget.provider.chapters.length - 1) {
          _isUserScrolling = true;
          widget.provider.nextChapter().then((_) {
            if (mounted) _isUserScrolling = false;
          });
        }
      }
    }
  }

  void _updateScrollPageIndex(double currentScroll) {
    final provider = widget.provider;
    if (provider.pages.isEmpty) return;
    final firstPage = provider.pages.firstOrNull;
    final double headOffset = (firstPage != null && firstPage.chapterIndex > 0) ? 26.0 : 0.0;
    double cumHeight = headOffset;
    for (int i = 0; i < provider.pages.length; i++) {
      final page = provider.pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom + 40.0;
      cumHeight += pageHeight;
      if (currentScroll < cumHeight) {
        provider.updateScrollPageIndex(i);
        return;
      }
      if (i < provider.pages.length - 1) cumHeight += 24.0;
    }
  }

  void _scrollToTtsHighlight() {
    if (!_scrollController.hasClients) return;
    final provider = widget.provider;
    if (provider.ttsStart < 0 || provider.pages.isEmpty) return;

    double cumHeight = 0;
    for (int i = 0; i < provider.pages.length; i++) {
      final page = provider.pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom + 40.0;

      for (final line in page.lines) {
        if (line.image != null) continue;
        final lEnd = line.chapterPosition + line.text.length;
        if (provider.ttsStart >= line.chapterPosition && provider.ttsStart < lEnd) {
          final lineTop = cumHeight + 40.0 + line.lineTop;
          final viewportH = _scrollController.position.viewportDimension;
          final currentOffset = _scrollController.offset;
          final comfortZoneBottom = currentOffset + viewportH * 0.65;
          if (lineTop < currentOffset || lineTop > comfortZoneBottom) {
            final target = (lineTop - viewportH * 0.25).clamp(0.0, _scrollController.position.maxScrollExtent);
            _scrollController.animateTo(target, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
          }
          return;
        }
      }
      cumHeight += pageHeight;
      if (i < provider.pages.length - 1) cumHeight += 24.0;
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
      case PageAnim.cover:
        return _buildCoverReader();
      case PageAnim.slide:
      default:
        return _buildHorizontalReader();
    }
  }

  Widget _buildHorizontalReader() {
    final p = widget.provider;
    final hasPrev = p.currentChapterIndex > 0;
    final hasNext = p.currentChapterIndex < p.chapters.length - 1;
    final itemCount = (hasPrev ? 1 : 0) + p.pages.length + (hasNext ? 1 : 0);

    return PageView.builder(
      controller: widget.pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: itemCount,
      onPageChanged: (i) {
        if (p.pages.isEmpty || p.isLoading) return;
        if (hasPrev && i == 0) {
          p.prevChapter();
        } else if (hasNext && i == itemCount - 1) {
          p.nextChapter();
        } else {
          p.onPageChanged(hasPrev ? i - 1 : i);
        }
      },
      itemBuilder: (ctx, i) {
        if (hasPrev && i == 0) return _buildLoadingView('載入上一章...');
        if (hasNext && i == itemCount - 1) return _buildLoadingView('載入下一章...');
        final idx = hasPrev ? i - 1 : i;
        if (idx < 0 || idx >= p.pages.length) return const SizedBox.shrink();
        return _buildPageViewWidget(idx);
      },
    );
  }

  Widget _buildCoverReader() {
    final p = widget.provider;
    final idx = p.currentPageIndex;
    final nextChild = (idx < p.pages.length - 1) ? _buildPageViewWidget(idx + 1) : null;
    
    return CoverPageView(
      currentChild: _buildPageViewWidget(idx),
      nextChild: nextChild,
      onTurnNext: () => p.currentPageIndex < p.pages.length - 1 ? p.onPageChanged(p.currentPageIndex + 1) : p.nextChapter(),
      onTurnPrev: () => p.currentPageIndex > 0 ? p.onPageChanged(p.currentPageIndex - 1) : p.prevChapter(),
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
    final firstPage = widget.provider.pages.firstOrNull;
    final lastPage = widget.provider.pages.lastOrNull;
    final showHead = firstPage != null && firstPage.chapterIndex > 0;
    final showTail = lastPage != null && lastPage.chapterIndex < widget.provider.chapters.length - 1;

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: widget.provider.pages.length + (showHead ? 1 : 0) + (showTail ? 1 : 0),
      separatorBuilder: (ctx, i) => const SizedBox(height: 24),
      itemBuilder: (ctx, i) {
        if (showHead && i == 0) return _buildScrollLoadingHead();
        final actualIndex = showHead ? i - 1 : i;
        if (showTail && actualIndex == widget.provider.pages.length) return _buildScrollLoadingTail();
        if (actualIndex < 0 || actualIndex >= widget.provider.pages.length) return const SizedBox.shrink();

        final page = widget.provider.pages[actualIndex];
        return SizedBox(
          height: page.lines.isEmpty ? 0 : page.lines.last.lineBottom + 40.0,
          child: PageViewWidget(
            page: page,
            contentStyle: _getContentStyle(),
            titleStyle: _getTitleStyle(),
            isScrollMode: true,
            ttsStart: widget.provider.ttsStart,
            ttsEnd: widget.provider.ttsEnd,
            ttsChapterIndex: widget.provider.ttsChapterIndex,
          ),
        );
      },
    );
  }

  TextStyle _getContentStyle() => TextStyle(fontSize: widget.provider.fontSize, height: widget.provider.lineHeight, color: widget.provider.currentTheme.textColor, letterSpacing: widget.provider.letterSpacing);
  TextStyle _getTitleStyle() => TextStyle(fontSize: widget.provider.fontSize + 4, fontWeight: FontWeight.bold, color: widget.provider.currentTheme.textColor, letterSpacing: widget.provider.letterSpacing);

  Widget _buildLoadingView(String text) {
    return Container(
      color: widget.provider.currentTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 20),
            Text(text, style: TextStyle(color: widget.provider.currentTheme.textColor.withAlpha(102), fontSize: 13)),
          ],
        ),
      ),
    );
  }

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
    return Container(
      color: widget.provider.currentTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(child: Text('正在載入上一章...', style: TextStyle(color: widget.provider.currentTheme.textColor.withAlpha(77), fontSize: 14))),
    );
  }
}
