import 'package:legado_reader/core/di/injection.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'association_base.dart';
import 'package:legado_reader/features/source_manager/source_manager_provider.dart';
import 'package:legado_reader/features/replace_rule/replace_rule_provider.dart';
import 'package:legado_reader/features/bookshelf/bookshelf_provider.dart';
import 'package:legado_reader/core/database/dao/http_tts_dao.dart';
import 'package:legado_reader/core/models/http_tts.dart';

/// AssociationHandlerService 的對話框與 UI 邏輯擴展
mixin AssociationDialogHelper on AssociationBase {
  void showImportDialog(BuildContext context, String type, String src, {bool isFile = false, String? jsonData}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('外部匯入'),
        content: Text('偵測到外部內容：\n${isFile ? src.split('/').last : src}\n\n辨識類型：$type'),
        actions: [
          _btn(ctx, '書源', () => isFile ? context.read<SourceManagerProvider>().importFromJson(jsonData!) : context.read<SourceManagerProvider>().importFromUrl(src)),
          if (type == 'book' || type == 'auto') _btn(ctx, '書籍', () => context.read<BookshelfProvider>().importBookshelfFromUrl(src)),
          if (type == 'replaceRule' || type == 'auto') _btn(ctx, '替換規則', () { if (isFile) context.read<ReplaceRuleProvider>().importFromText(jsonData!); }),
          if (type == 'httpTts' || type == 'auto') _btn(ctx, 'TTS', () { if (isFile) _importTts(context, jsonData!); }),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ],
      ),
    );
  }

  void showForceImportDialog(BuildContext context, String path, Function(BuildContext, String) handleBook) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('格式不支援'),
      content: const Text('無法辨識此 JSON 內容，是否嘗試作為書籍導入？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); handleBook(context, path); }, child: const Text('嘗試導入書籍')),
      ],
    ));
  }

  Future<void> _importTts(BuildContext context, String jsonStr) async {
    try {
      final List<dynamic> list = jsonDecode(jsonStr) is List ? jsonDecode(jsonStr) : [jsonDecode(jsonStr)];
      final dao = getIt<HttpTtsDao>();
      for (var item in list) {
        await dao.upsert(HttpTTS.fromJson(item as Map<String, dynamic>));
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功匯入 ${list.length} 個 TTS')));
    } catch (_) {}
  }

  Widget _btn(BuildContext context, String label, VoidCallback action) => TextButton(onPressed: () { Navigator.pop(context); action(); }, child: Text('匯入為 $label'));
}
// AI_PORT: GAP-INTENT-01 extracted from AssociationHandlerService

