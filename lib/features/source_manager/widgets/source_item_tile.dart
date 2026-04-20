import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/source/book_source_logic.dart';
import '../source_manager_provider.dart';
import 'package:inkpage_reader/core/models/book_source_part.dart';

/// 書源列表項 — 對標 legado item_book_source
/// 始終顯示 checkbox，點擊 checkbox 切換選取，點擊行本身編輯。
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
    final bool canDrag = provider.sortMode == 0 && !provider.groupByDomain;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color:
            isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // 拖拽手柄 (手動排序時)
            if (canDrag && index != null)
              ReorderableDragStartListener(
                index: index!,
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.drag_handle, size: 20, color: Colors.grey),
                ),
              ),

            // Checkbox — 始終顯示 (對標 legado cbBookSource)
            GestureDetector(
              onTap: () => provider.toggleSelect(source.bookSourceUrl),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 22,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                ),
              ),
            ),

            // 名稱 + URL + 標籤
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _displayNameGroup(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (source.runtimeHealth.category !=
                          SourceHealthCategory.healthy)
                        _buildStatusTag(source.runtimeHealth),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    source.bookSourceUrl,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  _buildTags(),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // 啟用 Switch (對標 legado swtEnabled)
            SizedBox(
              width: 44,
              child: Switch(
                value: source.enabled,
                onChanged: onEnabledChanged,
                activeThumbColor: Colors.blue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 對標 legado getDisPlayNameGroup: 名稱 [分組]
  String _displayNameGroup() {
    final group = source.bookSourceGroup;
    if (group != null && group.isNotEmpty) {
      return '${source.bookSourceName} [$group]';
    }
    return source.bookSourceName;
  }

  Widget _buildStatusTag(SourceRuntimeHealth health) {
    final color =
        health.cleanupCandidate
            ? Colors.red
            : health.quarantined
            ? Colors.orange
            : Colors.blueGrey;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        health.label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
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
      children:
          tags
              .map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(fontSize: 9, color: Colors.blueGrey),
                  ),
                ),
              )
              .toList(),
    );
  }
}
