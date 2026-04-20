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
                      if (g == '全部' || g == '未分組') {
                        return const SizedBox.shrink();
                      }
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
            title: const Text('清理建議刪除來源'),
            content: const Text('會刪除目前標記為非小說、需要登入或下載站的來源。這些來源不會再參與搜尋或閱讀。'),
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

  static void showCheckResults(
    BuildContext context,
    SourceManagerProvider provider,
  ) {
    final report = provider.lastCheckReport;
    final affectedEntries = report.affectedEntries;
    final selected = report.cleanupCandidateUrls.toSet();

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('校驗結果'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 420,
                    child:
                        affectedEntries.isEmpty
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(report.summary),
                                const SizedBox(height: 12),
                                const Text('這次沒有需要處理的書源'),
                              ],
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.summary,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: affectedEntries.length,
                                    separatorBuilder:
                                        (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final entry = affectedEntries[index];
                                      final isChecked = selected.contains(
                                        entry.sourceUrl,
                                      );
                                      final badgeColor =
                                          entry.cleanupCandidate
                                              ? Colors.red
                                              : entry.health.quarantined
                                              ? Colors.orange
                                              : Colors.blueGrey;
                                      return CheckboxListTile(
                                        value: isChecked,
                                        onChanged:
                                            (_) => setState(() {
                                              if (isChecked) {
                                                selected.remove(
                                                  entry.sourceUrl,
                                                );
                                              } else {
                                                selected.add(entry.sourceUrl);
                                              }
                                            }),
                                        title: Text(
                                          entry.sourceName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                entry.health.label,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: badgeColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              entry.message,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                  ),
                  actions: [
                    if (affectedEntries.isNotEmpty)
                      TextButton(
                        onPressed:
                            () => setState(() {
                              selected
                                ..clear()
                                ..addAll(report.cleanupCandidateUrls);
                            }),
                        child: const Text('全選建議清理'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('關閉'),
                    ),
                    if (selected.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final deleteCount = selected.length;
                          await provider.deleteSourcesByUrls(selected);
                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('已刪除 $deleteCount 個書源')),
                            );
                          }
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: const Text(
                          '刪除選中',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
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
