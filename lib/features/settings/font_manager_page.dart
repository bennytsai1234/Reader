import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'font_provider.dart';

class FontManagerPage extends StatefulWidget {
  const FontManagerPage({super.key});

  @override
  State<FontManagerPage> createState() => _FontManagerPageState();
}

class _FontManagerPageState extends State<FontManagerPage> {
  final List<String> _systemFonts = [
    'System Default',
    'PingFang SC',
    'Heiti SC',
    'Kaiti SC',
    'Songti SC',
  ];

  final TextEditingController _previewCtrl = TextEditingController(text: '天地玄黃，宇宙洪荒。日月盈昃，辰宿列張。');
  double _previewSize = 16.0;

  @override
  void dispose() {
    _previewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('字體管理'),
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                tooltip: '網路下載',
                onPressed: () => _showDownloadDialog(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '本地匯入',
                onPressed: () => _importLocalFont(provider),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildConfigSection(),
              const Divider(height: 1),
              Expanded(
                child: provider.isLoading && provider.customFonts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          if (provider.isLoading && provider.downloadProgress > 0)
                            LinearProgressIndicator(value: provider.downloadProgress),
                          _buildSectionTitle('系統字體'),
                          ..._systemFonts.map((font) => _buildFontTile(
                                font,
                                font == 'System Default' ? null : font,
                                provider,
                              )),
                          const Divider(),
                          _buildSectionTitle('自訂字體'),
                          if (provider.customFonts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('無自訂字體，點擊右上角按鈕匯入。',
                                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                          ...provider.customFonts.map((font) => _buildFontTile(
                                font,
                                font,
                                provider,
                                isCustom: true,
                              )),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          TextField(
            controller: _previewCtrl,
            decoration: const InputDecoration(
              labelText: '預覽文字',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.format_size, size: 20, color: Colors.grey),
              Expanded(
                child: Slider(
                  value: _previewSize,
                  min: 10,
                  max: 40,
                  onChanged: (v) => setState(() => _previewSize = v),
                ),
              ),
              Text('${_previewSize.toInt()}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFontTile(String displayName, String? fontFamily, FontProvider provider,
      {bool isCustom = false}) {
    final isSelected = provider.selectedFont == fontFamily;

    return Column(
      children: [
        RadioListTile<String?>(
          title: Text(displayName),
          subtitle: Text(
            _previewCtrl.text,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: _previewSize,
              color: isSelected ? null : Colors.grey,
            ),
          ),
          value: fontFamily,
          groupValue: provider.selectedFont,
          onChanged: (val) => provider.setSelectedFont(val),
          secondary: isCustom
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(displayName, provider),
                )
              : null,
        ),
        const Divider(indent: 16, endIndent: 16, height: 1),
      ],
    );
  }

  Future<void> _importLocalFont(FontProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );

    if (result != null && result.files.single.path != null) {
      await provider.addLocalFont(result.files.single.path!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('字體匯入成功')),
        );
      }
    }
  }

  void _showDownloadDialog(BuildContext context, FontProvider provider) {
    final urlController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('網路下載字體'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '字體名稱', hintText: '例如: 方正楷體'),
            ),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: '下載 URL', hintText: 'http://.../font.ttf'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              final name = nameController.text.trim();
              if (url.isEmpty || name.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await provider.downloadFont(url, name);
              if (!mounted) return;
              
              messenger.showSnackBar(
                SnackBar(content: Text(success ? '下載並安裝成功' : '下載失敗，請檢查 URL')),
              );
            },
            child: const Text('下載'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String name, FontProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除字體'),
        content: Text('確定要刪除字體 "$name" 嗎？\n這將從本地儲存中移除該檔案。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.deleteFont(name);
              Navigator.pop(context);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

