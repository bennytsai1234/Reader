import 'package:flutter/material.dart';
import '../../reader_provider.dart';

class ReaderTopMenu extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onBack;
  final VoidCallback onMore;

  const ReaderTopMenu({
    super.key,
    required this.provider,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final panelColor = provider.currentTheme.backgroundColor.withValues(
      alpha: 0.96,
    );
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showControls ? 0 : -120,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: panelColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildAppBar(context), _buildAdditionInfo(context)],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final iconColor = provider.currentTheme.textColor;
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: onBack,
        ),
        Expanded(
          child: Text(
            provider.book.name,
            style: TextStyle(
              color: iconColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: iconColor),
          onPressed: onMore,
        ),
      ],
    );
  }

  /// 頂部附加資訊 (對標 Android title_bar_addition)
  Widget _buildAdditionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.currentChapterTitle,
                  style: TextStyle(
                    color: provider.currentTheme.textColor.withValues(
                      alpha: 0.72,
                    ),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.currentChapterUrl.isNotEmpty)
                  Text(
                    provider.currentChapterUrl,
                    style: TextStyle(
                      color: provider.currentTheme.textColor.withValues(
                        alpha: 0.45,
                      ),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildSourceTag(context),
        ],
      ),
    );
  }

  /// 書源標籤 (對標 Android tv_source_action)
  Widget _buildSourceTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        provider.book.originName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
