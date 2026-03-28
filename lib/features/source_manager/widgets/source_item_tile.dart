import 'package:flutter/material.dart';
import '../source_manager_provider.dart';
import 'package:legado_reader/core/models/book_source_part.dart';

class SourceItemTile extends StatelessWidget {
  final BookSourcePart source;
  final SourceManagerProvider provider;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onEnabledChanged;
  final int? index;

  const SourceItemTile({
    super.key,
    required this.source,
    required this.provider,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEnabledChanged,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    // 只有在手動排序且非批量模式下才顯示拖拽手柄
    final bool canDrag = provider.sortMode == 0 && !provider.isBatchMode && !provider.groupByDomain;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (canDrag && index != null)
              ReorderableDragStartListener(
                index: index!,
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.drag_handle, size: 20, color: Colors.grey),
                ),
              ),
            if (provider.isBatchMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          source.bookSourceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (source.respondTime > 0)
                        _buildResponseTimeTag(source.respondTime),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    source.bookSourceUrl,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildTags(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: source.enabled,
              onChanged: onEnabledChanged,
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTimeTag(int ms) {
    Color color = Colors.green;
    if (ms > 2000) {
      color = Colors.red;
    } else if (ms > 800) {
      color = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text('${ms}ms', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTags() {
    final List<String> tags = [];
    if (source.hasSearchUrl) tags.add('搜');
    if (source.hasExploreUrl) tags.add('發');
    if (source.hasBookInfoRule) tags.add('詳');
    if (source.hasTocRule) tags.add('目');
    if (source.hasContentRule) tags.add('正');
    if (source.hasLoginUrl) tags.add('登');

    return Wrap(
      spacing: 4,
      children: tags.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(t, style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
      )).toList(),
    );
  }
}
