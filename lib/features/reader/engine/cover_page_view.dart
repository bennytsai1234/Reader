import 'package:flutter/material.dart';

/// CoverPageView - 覆蓋翻頁效果
/// 當前頁覆蓋在下一頁上方，向左滑出露出下一頁
class CoverPageView extends StatefulWidget {
  final Widget currentChild;
  final Widget? nextChild;
  final VoidCallback onTurnNext;
  final VoidCallback onTurnPrev;

  const CoverPageView({
    super.key,
    required this.currentChild,
    this.nextChild,
    required this.onTurnNext,
    required this.onTurnPrev,
  });

  @override
  State<CoverPageView> createState() => _CoverPageViewState();
}

class _CoverPageViewState extends State<CoverPageView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragOffset = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CoverPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當 widget 更新時（通常是翻頁完成後數據刷新），重置偏移
    if (!_isAnimating) {
      _dragOffset = 0;
    }
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.delta.dx;
      // 限制向左滑動偏移量在 [-width, 0]
      // 向右滑動不設嚴格限制以便偵測上一頁
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final width = MediaQuery.of(context).size.width;
    
    if (_dragOffset < -width * 0.25) {
      // 向左滑動超過 25%，完成翻到下一頁
      _isAnimating = true;
      _controller.forward(from: (-_dragOffset / width)).then((_) {
        widget.onTurnNext();
        _isAnimating = false;
        // 注意：這裡不 setState(_dragOffset=0)，交由 didUpdateWidget 或下一次渲染處理
      });
    } else if (_dragOffset > width * 0.15) {
      // 向右滑動超過 15%，觸發上一頁
      widget.onTurnPrev();
      setState(() => _dragOffset = 0);
    } else {
      // 彈回原位
      _isAnimating = true;
      _controller.reverse(from: (-_dragOffset / width)).then((_) {
        setState(() => _dragOffset = 0);
        _isAnimating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final displayOffset = _isAnimating 
        ? -_controller.value * width 
        : _dragOffset.clamp(-width, width.toDouble());

    return GestureDetector(
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // 底層：下一頁內容 (靜止不動)
          if (widget.nextChild != null)
            widget.nextChild!,

          // 上層：當前頁內容 (跟隨手指滑動或動畫)
          Transform.translate(
            offset: Offset(displayOffset.clamp(-width, 0), 0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  if (displayOffset < 0)
                    BoxShadow(
                      color: Colors.black.withAlpha(77),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(5, 0),
                    ),
                ],
              ),
              child: widget.currentChild,
            ),
          ),
        ],
      ),
    );
  }
}
