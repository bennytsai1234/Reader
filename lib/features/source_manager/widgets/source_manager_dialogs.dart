import 'package:flutter/material.dart';
import '../source_manager_provider.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import '../source_debug_page.dart';

class SourceManagerDialogs {
  static void showCheckLog(
    BuildContext context,
    SourceManagerProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('校驗詳情'),
            backgroundColor: Colors.black87,
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: StreamBuilder(
                stream: provider.checkService.eventBus.on(),
                builder:
                    (context, snapshot) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          provider.checkService.statusMsg,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('關閉', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  static void showBatchGroup(
    BuildContext context,
    SourceManagerProvider provider,
  ) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('批量管理分組'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(hintText: '輸入或選擇分組名'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: provider.groups.length,
                    itemBuilder: (ctx, i) {
                      final g = provider.groups[i];
                      if (g == '全部' || g == '未分組')
                        return const SizedBox.shrink();
                      return ListTile(
                        title: Text(g),
                        dense: true,
                        onTap: () => ctrl.text = g,
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  provider.selectionRemoveFromGroups(
                    provider.selectedUrls,
                    ctrl.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: const Text('移除分組'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.selectionAddToGroups(
                    provider.selectedUrls,
                    ctrl.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: const Text('加入分組'),
              ),
            ],
          ),
    );
  }

  static void confirmClearInvalid(
    BuildContext context,
    SourceManagerProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('清理失效書源'),
            content: const Text('確定要刪除所有標記為「失效」或「搜尋失效」的書源嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  provider.clearInvalidSources();
                  Navigator.pop(ctx);
                },
                child: const Text('確定刪除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  static void confirmDeleteNonNovel(
    BuildContext context,
    SourceManagerProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('刪除非小說源'),
            content: const Text('會直接刪除影音、漫畫、RSS 等非小說源，且無法復原。要繼續嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final affected = await provider.deleteNonNovelSources();
                  if (context.mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('已刪除 $affected 個非小說源')),
                    );
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('確定刪除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  static void showDebugInput(BuildContext context, BookSource source) {
    final ctrl = TextEditingController(text: '我的世界');
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('輸入調試關鍵字'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: '搜尋詞或 URL'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (c) => SourceDebugPage(
                            source: source,
                            debugKey: ctrl.text.trim(),
                          ),
                    ),
                  );
                },
                child: const Text('開始調試'),
              ),
            ],
          ),
    );
  }
}
