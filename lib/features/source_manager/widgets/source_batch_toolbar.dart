import 'package:flutter/material.dart';
import '../source_manager_provider.dart';

class SourceBatchToolbar extends StatelessWidget {
  final SourceManagerProvider provider;
  final VoidCallback onGroup;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback? onEnable;
  final VoidCallback? onDisable;
  final VoidCallback? onMoveToTop;
  final VoidCallback? onMoveToBottom;

  const SourceBatchToolbar({
    super.key,
    required this.provider,
    required this.onGroup,
    required this.onExport,
    required this.onDelete,
    this.onEnable,
    this.onDisable,
    this.onMoveToTop,
    this.onMoveToBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).cardColor,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildItem(context, Icons.toggle_on_outlined, '啟用', () => onEnable?.call()),
          _buildItem(context, Icons.toggle_off_outlined, '禁用', () => onDisable?.call()),
          _buildItem(context, Icons.vertical_align_top, '置頂', () => onMoveToTop?.call()),
          _buildItem(context, Icons.drive_file_move_outlined, '移動', onGroup),
          _buildItem(context, Icons.playlist_add_check, '校驗', () => provider.checkSelectedSources()),
          _buildItem(context, Icons.delete_outline, '刪除', onDelete, isDanger: true),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDanger = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isDanger ? Colors.red : null),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isDanger ? Colors.red : null)),
          ],
        ),
      ),
    );
  }
}
