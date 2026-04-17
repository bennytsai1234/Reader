import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';

class AdvancedSettingSheet extends StatelessWidget {
  const AdvancedSettingSheet({super.key});

  static void show(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: const AdvancedSettingSheet(),
      ),
    );
  }

  static const Map<int, String> _clickActions = {
    0: '喚起選單',
    1: '下一頁',
    2: '上一頁',
    3: '下一章',
    4: '上一章',
    7: '加入書籤',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();

    return AppBottomSheet(
      title: '進階設定',
      icon: Icons.tune_rounded,
      children: [
        const SheetSection(title: '繁簡轉換'),
        Wrap(
          spacing: 12,
          children: [
            ChoiceChip(
              label: const Text('不轉換'),
              selected: provider.chineseConvert == 0,
              onSelected: (v) => v ? provider.setChineseConvert(0) : null,
            ),
            ChoiceChip(
              label: const Text('簡轉繁'),
              selected: provider.chineseConvert == 1,
              onSelected: (v) => v ? provider.setChineseConvert(1) : null,
            ),
            ChoiceChip(
              label: const Text('繁轉簡'),
              selected: provider.chineseConvert == 2,
              onSelected: (v) => v ? provider.setChineseConvert(2) : null,
            ),
          ],
        ),
        
        const Divider(height: 32),
        const SheetSection(
          title: '點擊區域設定', 
          trailing: Text('九宮格配置', style: TextStyle(fontSize: 11, color: Colors.grey))
        ),
        const SizedBox(height: 8),
        _buildClickActionGrid(context, provider),
        
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '狀態列功能目前由系統全域設定接管。',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClickActionGrid(BuildContext context, ReaderProvider provider) {
    return AspectRatio(
      aspectRatio: 3 / 2.2,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final action = provider.clickActions[index];
          final label = _clickActions[action] ?? '未知';
          final isCenter = index == 4;

          return GestureDetector(
            onTap: () => _showActionPicker(context, provider, index),
            child: Container(
              decoration: BoxDecoration(
                color: isCenter 
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.surfaceContainer,
                border: Border.all(
                  color: isCenter ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: isCenter ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                        color: isCenter ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                      ),
                    ),
                    if (isCenter) 
                      const Icon(Icons.touch_app_outlined, size: 10, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showActionPicker(BuildContext context, ReaderProvider provider, int gridIndex) {
    AppBottomSheet.show(
      context: context,
      title: '選擇點擊功能',
      icon: Icons.ads_click,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: ListView(
            shrinkWrap: true,
            children: _clickActions.entries.map((e) {
              final isSelected = provider.clickActions[gridIndex] == e.key;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(e.value, style: const TextStyle(fontSize: 14)),
                trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                selected: isSelected,
                onTap: () {
                  provider.setClickAction(gridIndex, e.key);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
