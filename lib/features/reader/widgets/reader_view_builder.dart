import 'package:flutter/material.dart';
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

class _ReaderViewBuilderState extends State<ReaderViewBuilder> {
  late ScrollController _scrollController;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    
    // 監聽並跳轉捲動位置 (處理切換章節後的初始位置)
    widget.provider.scrollOffsetController.stream.listen((offset) {
      if (_scrollController.hasClients) {
        if (offset >= 999999) {
          // 跳到末尾 (載入前一章時)
          Future.delayed(const Duration(milliseconds: 100), () {
             if (_scrollController.hasClients) {
               _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
             }
          });
        } else {
          // 跳到頂部 (載入下一章時)
          _scrollController.jumpTo(0);
        }
      }
    });
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (widget.provider.pageTurnMode == 2 && !_isUserScrolling) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double currentScroll = _scrollController.position.pixels;
        
        // 向上滾動到頂部載入上一章
        if (currentScroll <= 10 && !widget.provider.isLoading && widget.provider.currentChapterIndex > 0) {
           _isUserScrolling = true; // 暫時鎖定防止連續觸發
           widget.provider.prevChapter().then((_) {
             if (mounted) setState(() => _isUserScrolling = false);
           });
           return;
        }

        // 向下滾動到底部載入下一章
        if (currentScroll >= maxScroll - 50 && !widget.provider.isLoading && widget.provider.currentChapterIndex < widget.provider.chapters.length - 1) {
          _isUserScrolling = true;
          widget.provider.nextChapter().then((_) {
            if (mounted) setState(() => _isUserScrolling = false);
          });
        }
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // 更新視窗大小並觸發分頁 (對標 Android ReadBookViewModel.viewSize)
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (provider.viewSize != size) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.setViewSize(size);
          });
        }


        if (provider.isLoading && provider.pages.isEmpty) {
          return Container(
            color: provider.currentTheme.backgroundColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.pages.isEmpty && !provider.isLoading) {
          return Container(
            color: provider.currentTheme.backgroundColor,
            child: Center(child: Text('暫無內容', style: TextStyle(color: provider.currentTheme.textColor.withValues(alpha: 0.5)))),
          );
        }

        // 當自動翻頁開啟且為捲動模式時，啟動平滑捲動
        if (provider.isAutoPaging && provider.pageTurnMode == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startSmoothScroll());
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
      case 2: // 捲動模式 (Vertical Scroll)
        return _buildScrollReader();
      case 3: // 無動畫
        return _buildHorizontalReader(physics: const NeverScrollableScrollPhysics());
      case 0: // 平移 (Normal)
      case 1: // 仿真 (模擬)
      default:
        return _buildHorizontalReader();
    }
  }

  void _startSmoothScroll() {

    if (!_scrollController.hasClients || _isUserScrolling) return;
    
    // 計算滾動增量 (對標 Android 速度級別)
    final double speedFactor = widget.provider.autoPageSpeed * 2.0;
    final double currentOffset = _scrollController.offset;
    final double maxOffset = _scrollController.position.maxScrollExtent;

    if (currentOffset < maxOffset) {
      _scrollController.animateTo(
        currentOffset + 50,
        duration: Duration(milliseconds: (5000 / speedFactor).round()),
        curve: Curves.linear,
      );
    } else {
      // 滾動到底部，自動切換下一章
      widget.provider.nextChapter();
    }
  }

  Widget _buildHorizontalReader({ScrollPhysics? physics}) {
    final provider = widget.provider;
    final hasPrev = provider.currentChapterIndex > 0;
    final hasNext = provider.currentChapterIndex < provider.chapters.length - 1;

    // 構建總頁數，包含前後導航頁
    final itemCount = (hasPrev ? 1 : 0) + provider.pages.length + (hasNext ? 1 : 0);

    return PageView.builder(
      controller: widget.pageController,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: itemCount,
      onPageChanged: (i) {
        if (provider.pages.isEmpty || provider.isLoading) return;
        
        if (hasPrev && i == 0) {
          provider.prevChapter();
        } else if (hasNext && i == itemCount - 1) {
          provider.nextChapter();
        } else {
          final actualIndex = hasPrev ? i - 1 : i;
          provider.onPageChanged(actualIndex);
        }
      },
      itemBuilder: (ctx, i) {
        if (hasPrev && i == 0) return _buildLoadingView('載入上一章...');
        
        if (hasNext && i == itemCount - 1) return _buildLoadingView('載入下一章...');
        
        final idx = hasPrev ? i - 1 : i;
        if (idx < 0 || idx >= provider.pages.length) return const SizedBox.shrink();
        
        return PageViewWidget(
          page: provider.pages[idx],
          contentStyle: _getContentStyle(),
          titleStyle: _getTitleStyle(),
        );
      },
    );
  }


  Widget _buildScrollReader() {
    final hasPrev = widget.provider.currentChapterIndex > 0;
    return Listener(
      onPointerDown: (_) => setState(() => _isUserScrolling = true),
      onPointerUp: (_) => Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isUserScrolling = false);
      }),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _handleScroll();
          }
          return false;
        },
        child: ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          itemCount: widget.provider.pages.length + (hasPrev ? 1 : 0) + 1,
          separatorBuilder: (ctx, i) => const SizedBox(height: 24),
          itemBuilder: (ctx, i) {
            if (hasPrev && i == 0) {
              return _buildScrollLoadingHead();
            }
            
            final actualIndex = hasPrev ? i - 1 : i;

            if (actualIndex == widget.provider.pages.length) {
              return _buildScrollLoadingTail();
            }
            final page = widget.provider.pages[actualIndex];

            final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom + 40.0;
            
            return SizedBox(
              height: pageHeight,
              child: PageViewWidget(
                page: page,
                contentStyle: _getContentStyle(),
                titleStyle: _getTitleStyle(),
                isScrollMode: true,
              ),
            );
          },
        ),
      ),
    );
  }


  TextStyle _getContentStyle() {
    final p = widget.provider;
    return TextStyle(fontSize: p.fontSize, height: p.lineHeight, color: p.currentTheme.textColor, letterSpacing: p.letterSpacing);
  }

  TextStyle _getTitleStyle() {
    final p = widget.provider;
    return TextStyle(fontSize: p.fontSize + 4, fontWeight: FontWeight.bold, color: p.currentTheme.textColor, letterSpacing: p.letterSpacing);
  }

  Widget _buildLoadingView(String text) {
    return Container(
      color: widget.provider.currentTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 20),
            Text(text, style: TextStyle(color: widget.provider.currentTheme.textColor.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollLoadingTail() {
    final hasNext = widget.provider.currentChapterIndex < widget.provider.chapters.length - 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Text(
              hasNext ? '正在載入下一章...' : '全書完',
              style: TextStyle(
                color: widget.provider.currentTheme.textColor.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
            if (hasNext)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollLoadingHead() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 20),
            Text(
              '正在載入上一章...',
              style: TextStyle(
                color: widget.provider.currentTheme.textColor.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

