import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
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
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('界面設定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          const Text('閱讀主題', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppTheme.readingThemes.length,
              itemBuilder: (context, index) {
                final theme = AppTheme.readingThemes[index];
                return GestureDetector(
                  onTap: () => provider.setTheme(index),
                  child: Container(
                    width: 50, margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor, shape: BoxShape.circle,
                      border: Border.all(color: provider.themeIndex == index ? Colors.blue : Colors.grey.withValues(alpha: 0.3), width: 3),
                    ),
                    child: Center(child: Text('Aa', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 32),

          const Text('排版微調', style: TextStyle(fontSize: 14, color: Colors.grey)),
          SettingComponents.buildSliderRow(label: '字體大小', value: provider.fontSize, min: 14, max: 40, onChanged: provider.setFontSize),
          SettingComponents.buildSliderRow(label: '行高間距', value: provider.lineHeight, min: 1.0, max: 3.0, onChanged: provider.setLineHeight),
          
          Row(
            children: [
              const Text('兩端對齊', style: TextStyle(fontSize: 13)),
              Switch(value: provider.textFullJustify, onChanged: (v) => provider.setTextFullJustify(v)),
              const Spacer(),
              const Text('首行縮排', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: provider.textIndent,
                items: [0, 1, 2, 4].map((i) => DropdownMenuItem(value: i, child: Text('$i字'))).toList(),
                onChanged: (v) => v != null ? provider.setTextIndent(v) : null,
              ),
            ],
          ),
          const Divider(height: 32),

          const Text('翻頁動畫', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              SettingComponents.buildChoiceChip(label: '平移', value: PageAnim.slide, groupValue: provider.pageTurnMode, onSelected: provider.setPageTurnMode),
              SettingComponents.buildChoiceChip(label: '覆蓋', value: PageAnim.cover, groupValue: provider.pageTurnMode, onSelected: provider.setPageTurnMode),
              SettingComponents.buildChoiceChip(label: '滾動', value: PageAnim.scroll, groupValue: provider.pageTurnMode, onSelected: provider.setPageTurnMode),
            ],
          ),
          const Divider(height: 32),

          const Text('背景圖片', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('選擇背景圖'),
                onPressed: () => _pickBackgroundImage(provider),
              ),
              const SizedBox(width: 12),
              if (provider.currentTheme.backgroundImage != null)
                TextButton(
                  onPressed: () => provider.setBackgroundImage(null),
                  child: const Text('清除', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
          if (provider.currentTheme.backgroundImage != null)
            SettingComponents.buildSliderRow(
              label: '背景模糊', 
              value: provider.backgroundBlur, 
              min: 0, max: 20, 
              onChanged: provider.setBackgroundBlur
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _pickBackgroundImage(ReaderProvider p) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      p.setBackgroundImage(result.files.single.path!);
    }
  }
}

