import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkpage_reader/core/services/check_source_service.dart';
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
          (context) => AnimatedBuilder(
            animation: provider.checkService,
            builder:
                (context, _) => AlertDialog(
                  title: const Text('校驗詳情'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 420,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.checkService.config.summary,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.checkService.isChecking
                              ? '進度 ${provider.checkService.currentCount}/${provider.checkService.totalCount}'
                              : '已完成',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.checkService.statusMsg,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                              provider.checkService.logs.isEmpty
                                  ? const Center(child: Text('目前還沒有校驗日誌'))
                                  : ListView.separated(
                                    itemCount:
                                        provider.checkService.logs.length,
                                    separatorBuilder:
                                        (_, __) => const Divider(height: 12),
                                    itemBuilder: (context, index) {
                                      final entry =
                                          provider.checkService.logs[index];
                                      return SelectableText(
                                        '${entry.formattedTime} ${entry.message}',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          height: 1.45,
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    if (provider.checkService.isChecking)
                      TextButton(
                        onPressed: provider.checkService.cancel,
                        child: const Text('取消校驗'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('關閉'),
                    ),
                  ],
                ),
          ),
    );
  }

  static Future<void> showCheckConfigDialog(
    BuildContext context,
    SourceManagerProvider provider, {
    bool checkAll = false,
  }) async {
    final targetCount =
        checkAll ? provider.sources.length : provider.selectedUrls.length;
    if (targetCount == 0) {
      return;
    }

    final initial = provider.checkConfig.normalized();
    final keywordController = TextEditingController(text: initial.keyword);
    final timeoutController = TextEditingController(
      text: initial.timeoutSeconds.toString(),
    );

    var checkSearch = initial.checkSearch;
    var checkDiscovery = initial.checkDiscovery;
    var checkInfo = initial.checkInfo;
    var checkCategory = initial.checkCategory;
    var checkContent = initial.checkContent;

    await showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    checkAll
                        ? '校驗所有書源 ($targetCount)'
                        : '校驗選中書源 ($targetCount)',
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: keywordController,
                            decoration: const InputDecoration(
                              labelText: '預設關鍵字',
                              hintText: '未設置書源校驗關鍵字時使用',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: timeoutController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: '單步超時（秒）',
                              hintText: '至少 1 秒',
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: checkSearch,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('校驗搜尋'),
                            subtitle: const Text('檢查 searchUrl 與搜尋結果'),
                            onChanged: (value) {
                              setState(() {
                                checkSearch = value ?? false;
                                if (!checkSearch && !checkDiscovery) {
                                  checkDiscovery = true;
                                }
                              });
                            },
                          ),
                          CheckboxListTile(
                            value: checkDiscovery,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('校驗發現'),
                            subtitle: const Text('依 exploreUrl 解析並檢查發現入口'),
                            onChanged: (value) {
                              setState(() {
                                checkDiscovery = value ?? false;
                                if (!checkSearch && !checkDiscovery) {
                                  checkSearch = true;
                                }
                              });
                            },
                          ),
                          CheckboxListTile(
                            value: checkInfo,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('校驗詳情'),
                            subtitle: const Text('拉取書籍詳情頁'),
                            onChanged: (value) {
                              setState(() {
                                checkInfo = value ?? false;
                                if (!checkInfo) {
                                  checkCategory = false;
                                  checkContent = false;
                                }
                              });
                            },
                          ),
                          CheckboxListTile(
                            value: checkCategory,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('校驗目錄'),
                            subtitle: const Text('拉取章節列表'),
                            onChanged:
                                checkInfo
                                    ? (value) {
                                      setState(() {
                                        checkCategory = value ?? false;
                                        if (!checkCategory) {
                                          checkContent = false;
                                        }
                                      });
                                    }
                                    : null,
                          ),
                          CheckboxListTile(
                            value: checkContent,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('校驗正文'),
                            subtitle: const Text('拉取首個可閱讀章節正文'),
                            onChanged:
                                checkInfo && checkCategory
                                    ? (value) {
                                      setState(() {
                                        checkContent = value ?? false;
                                      });
                                    }
                                    : null,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              SourceCheckConfig(
                                keyword: keywordController.text,
                                timeoutSeconds:
                                    int.tryParse(timeoutController.text) ??
                                    initial.timeoutSeconds,
                                checkSearch: checkSearch,
                                checkDiscovery: checkDiscovery,
                                checkInfo: checkInfo,
                                checkCategory: checkCategory,
                                checkContent: checkContent,
                              ).normalized().summary,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final timeoutSeconds = int.tryParse(
                          timeoutController.text,
                        );
                        if (timeoutSeconds == null || timeoutSeconds < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('超時秒數至少要 1 秒')),
                          );
                          return;
                        }

                        final config =
                            SourceCheckConfig(
                              keyword: keywordController.text,
                              timeoutSeconds: timeoutSeconds,
                              checkSearch: checkSearch,
                              checkDiscovery: checkDiscovery,
                              checkInfo: checkInfo,
                              checkCategory: checkCategory,
                              checkContent: checkContent,
                            ).normalized();

                        Navigator.pop(dialogContext);
                        if (checkAll) {
                          await provider.checkAllSources(config: config);
                        } else {
                          await provider.checkSelectedSources(config: config);
                        }
                      },
                      child: const Text('開始校驗'),
                    ),
                  ],
                ),
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
    String activeFilter = '全部';

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setState) {
              final buckets = _groupAffectedEntriesByLabel(affectedEntries);
              final visibleEntries =
                  activeFilter == '全部'
                      ? affectedEntries
                      : (buckets[activeFilter] ?? const <SourceCheckEntry>[]);
              final visibleUrls =
                  visibleEntries.map((entry) => entry.sourceUrl).toSet();
              final visibleCleanupUrls =
                  visibleEntries
                      .where((entry) => entry.cleanupCandidate)
                      .map((entry) => entry.sourceUrl)
                      .toSet();
              final selectedVisibleCount =
                  selected.intersection(visibleUrls).length;

              return AlertDialog(
                title: const Text('校驗結果'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 460,
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
                              SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ChoiceChip(
                                      label: Text(
                                        '全部 (${affectedEntries.length})',
                                      ),
                                      selected: activeFilter == '全部',
                                      onSelected:
                                          (_) => setState(() {
                                            activeFilter = '全部';
                                          }),
                                    ),
                                    ...buckets.entries.map(
                                      (bucket) => ChoiceChip(
                                        label: Text(
                                          '${bucket.key} (${bucket.value.length})',
                                        ),
                                        selected: activeFilter == bucket.key,
                                        onSelected:
                                            (_) => setState(() {
                                              activeFilter = bucket.key;
                                            }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '當前類型 ${visibleEntries.length} 項，已選 $selectedVisibleCount 項，總選中 ${selected.length} 項',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    label: const Text('全選當前類型'),
                                    onPressed:
                                        visibleEntries.isEmpty
                                            ? null
                                            : () => setState(() {
                                              selected.addAll(visibleUrls);
                                            }),
                                  ),
                                  ActionChip(
                                    label: const Text('只選當前建議清理'),
                                    onPressed:
                                        visibleCleanupUrls.isEmpty
                                            ? null
                                            : () => setState(() {
                                              selected
                                                ..removeAll(visibleUrls)
                                                ..addAll(visibleCleanupUrls);
                                            }),
                                  ),
                                  ActionChip(
                                    label: const Text('清空當前類型'),
                                    onPressed:
                                        visibleEntries.isEmpty
                                            ? null
                                            : () => setState(() {
                                              selected.removeAll(visibleUrls);
                                            }),
                                  ),
                                  if (selected.isNotEmpty)
                                    ActionChip(
                                      label: const Text('清空全部選擇'),
                                      onPressed:
                                          () => setState(() {
                                            selected.clear();
                                          }),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child:
                                    visibleEntries.isEmpty
                                        ? const Center(
                                          child: Text('這個類型目前沒有項目'),
                                        )
                                        : ListView.separated(
                                          itemCount: visibleEntries.length,
                                          separatorBuilder:
                                              (_, __) =>
                                                  const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final entry = visibleEntries[index];
                                            final isChecked = selected.contains(
                                              entry.sourceUrl,
                                            );
                                            final badgeColor =
                                                _badgeColorForEntry(entry);
                                            return CheckboxListTile(
                                              value: isChecked,
                                              onChanged:
                                                  (_) => setState(() {
                                                    if (isChecked) {
                                                      selected.remove(
                                                        entry.sourceUrl,
                                                      );
                                                    } else {
                                                      selected.add(
                                                        entry.sourceUrl,
                                                      );
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
                                                      color: badgeColor
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      entry.health.label,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: badgeColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    entry.message,
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                              contentPadding: EdgeInsets.zero,
                                            );
                                          },
                                        ),
                              ),
                            ],
                          ),
                ),
                actions: [
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
              );
            },
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

  static Map<String, List<SourceCheckEntry>> _groupAffectedEntriesByLabel(
    List<SourceCheckEntry> entries,
  ) {
    final buckets = <String, List<SourceCheckEntry>>{};
    for (final entry in entries) {
      buckets.putIfAbsent(entry.health.label, () => <SourceCheckEntry>[]);
      buckets[entry.health.label]!.add(entry);
    }
    return buckets;
  }

  static Color _badgeColorForEntry(SourceCheckEntry entry) {
    return entry.cleanupCandidate
        ? Colors.red
        : entry.health.quarantined
        ? Colors.orange
        : Colors.blueGrey;
  }
}
