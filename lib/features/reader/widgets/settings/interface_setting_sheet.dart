import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';
import 'setting_components.dart';

class InterfaceSettingSheet extends StatelessWidget {
  const InterfaceSettingSheet({super.key});

  static void show(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: const InterfaceSettingSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();
    
    return AppBottomSheet(
      title: '界面設定',
      icon: Icons.format_paint_outlined,
      children: [
        const SheetSection(title: '閱讀主題'),
        const SizedBox(height: 4),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: AppTheme.readingThemes.length,
            itemBuilder: (context, index) {
              final theme = AppTheme.readingThemes[index];
              final isSelected = provider.themeIndex == index;
              return GestureDetector(
                onTap: () => provider.setTheme(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52, 
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor, 
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.2), 
                      width: isSelected ? 3 : 1
                    ),
                    boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 8)] : null,
                  ),
                  child: Center(child: Text('Aa', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 13))),
                ),
              );
            },
          ),
        ),

        const SheetSection(title: '排版精修'),
        SettingComponents.buildSliderRow(label: '字號', value: provider.fontSize, min: 14, max: 40, onChanged: provider.setFontSize),
        SettingComponents.buildSliderRow(label: '行高', value: provider.lineHeight, min: 1.0, max: 3.0, onChanged: provider.setLineHeight),
        SettingComponents.buildSliderRow(label: '字距', value: provider.letterSpacing, min: 0.0, max: 4.0, onChanged: provider.setLetterSpacing),
        SettingComponents.buildSliderRow(label: '段距', value: provider.paragraphSpacing, min: 0.0, max: 3.0, onChanged: provider.setParagraphSpacing),

        const SizedBox(height: 12),
        Row(
          children: [
            const Text('內容兩端對齊', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Switch(
              value: provider.textFullJustify, 
              onChanged: (v) => provider.setTextFullJustify(v),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text('首行縮排', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            DropdownButton<int>(
              value: provider.textIndent,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: [0, 1, 2, 4]
                  .map((i) => DropdownMenuItem(value: i, child: Text('$i 字')))
                  .toList(),
              onChanged: (v) => v != null ? provider.setTextIndent(v) : null,
            ),
          ],
        ),
        
        const SheetSection(title: '翻頁與背景'),
        Wrap(
          spacing: 12,
          children: [
            ChoiceChip(
              label: const Text('平移翻頁'),
              selected: provider.pageTurnMode == PageAnim.slide,
              onSelected: (v) => v ? provider.setPageTurnMode(PageAnim.slide) : null,
            ),
            ChoiceChip(
              label: const Text('上下滾動'),
              selected: provider.pageTurnMode == PageAnim.scroll,
              onSelected: (v) => v ? provider.setPageTurnMode(PageAnim.scroll) : null,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('自定義背景圖', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _pickBackgroundImage(provider),
              ),
            ),
            if (provider.currentTheme.backgroundImage != null) ...[
              const SizedBox(width: 12),
              IconButton.filledTonal(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => provider.setBackgroundImage(null),
                style: IconButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _pickBackgroundImage(ReaderProvider p) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      p.setBackgroundImage(result.files.single.path!);
    }
  }
}
