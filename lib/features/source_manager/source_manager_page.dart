import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'source_manager_provider.dart';
import 'source_editor_page.dart';
import 'qr_scan_page.dart';
import 'explore_sources_page.dart';
import 'source_group_manage_page.dart';
import 'package:inkpage_reader/core/models/book_source_part.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';
import 'widgets/import_preview_dialog.dart';
import 'widgets/source_item_tile.dart';
import 'widgets/source_filter_bar.dart';
import 'widgets/source_batch_toolbar.dart';
import 'widgets/source_check_status_bar.dart';
import 'widgets/source_manager_menus.dart';
import 'widgets/source_manager_dialogs.dart';

class SourceManagerPage extends StatefulWidget {
  const SourceManagerPage({super.key});
  @override
  State<SourceManagerPage> createState() => _SourceManagerPageState();
}

class _SourceManagerPageState extends State<SourceManagerPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return Consumer<SourceManagerProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('書源管理'),
            actions: [
              SourceManagerMenus.buildSortMenu(context, provider),
              SourceManagerMenus.buildGroupMenu(context, provider),
              SourceManagerMenus.buildAddMenu(
                context,
                provider,
                onImportUrl: () => _showImportDialog(context, true),
                onImportFile: () => _importFromFile(context),
                onImportClipboard: () => _importFromClipboard(context),
                onScanQr: () => _scanQrCode(context, provider),
                onExplore:
                    () => nav.push(
                      MaterialPageRoute(
                        builder: (_) => const ExploreSourcesPage(),
                      ),
                    ),
                onManageGroups:
                    () => nav.push(
                      MaterialPageRoute(
                        builder: (_) => const SourceGroupManagePage(),
                      ),
                    ),
                onNewSource:
                    () => nav.push(
                      MaterialPageRoute(
                        builder: (_) => const SourceEditorPage(),
                      ),
                    ),
              ),
              SourceManagerMenus.buildMoreMenu(
                context,
                provider,
                onClearInvalid:
                    (p) => SourceManagerDialogs.confirmClearInvalid(context, p),
                onDeleteNonNovel:
                    (p) =>
                        SourceManagerDialogs.confirmDeleteNonNovel(context, p),
              ),
            ],
          ),
          body: Column(
            children: [
              if (provider.checkService.isChecking)
                SourceCheckStatusBar(
                  provider: provider,
                  onTap:
                      () =>
                          SourceManagerDialogs.showCheckLog(context, provider),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋書源名稱、網址',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                            : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
              SourceFilterBar(provider: provider),
              Expanded(child: _buildMainContent(provider)),
            ],
          ),
          // 始終顯示 SelectActionBar (對標 legado)
          bottomNavigationBar: SelectActionBar(
            provider: provider,
            onEnable: () => provider.batchSetEnabled(true),
            onDisable: () => provider.batchSetEnabled(false),
            onAddGroup: () => _showAddGroupDialog(context, provider),
            onRemoveGroup: () => _showRemoveGroupDialog(context, provider),
            onMoveToTop: () => provider.moveSelectedToTop(),
            onMoveToBottom: () => provider.moveSelectedToBottom(),
            onExport: () async {
              final messenger = ScaffoldMessenger.of(context);
              await provider.exportSelected();
              if (!mounted) return;
              messenger.showSnackBar(const SnackBar(content: Text('已複製至剪貼簿')));
            },
            onShare: () => provider.shareSelectedSources(),
            onCheckSource: () {
              _showCheckSourceDialog(context, provider);
            },
            onDelete: () {
              _confirmDeleteSelected(context, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildMainContent(SourceManagerProvider p) {
    if (p.isLoading) return const Center(child: CircularProgressIndicator());
    final list = p.sources;
    if (list.isEmpty) return const Center(child: Text('暫無書源'));

    if (p.groupByDomain) {
      return _buildGroupedList(p);
    }

    // 只有在手動排序 (0) 模式下才允許拖拽
    final bool canReorder = p.sortMode == 0;

    if (canReorder) {
      return ReorderableListView.builder(
        itemCount: list.length,
        onReorder: (oldIndex, newIndex) => p.reorderSource(oldIndex, newIndex),
        itemBuilder: (ctx, i) => _buildItem(p, list[i], index: i),
      );
    } else {
      return ListView.separated(
        itemCount: list.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1),
        itemBuilder: (ctx, i) => _buildItem(p, list[i]),
      );
    }
  }

  Widget _buildGroupedList(SourceManagerProvider p) {
    final Map<String, List<BookSourcePart>> groups = {};
    for (var s in p.sources) {
      final domain = _getDomain(s.bookSourceUrl);
      groups.putIfAbsent(domain, () => []).add(s);
    }
    final sortedDomains = groups.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedDomains.length,
      itemBuilder: (ctx, index) {
        final domain = sortedDomains[index];
        final items = groups[domain]!;
        return ExpansionTile(
          title: Text(
            domain,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            '共 ${items.length} 個書源',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          children: items.map((s) => _buildItem(p, s)).toList(),
        );
      },
    );
  }

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : '其他';
    } catch (_) {
      return '其他';
    }
  }

  Widget _buildItem(SourceManagerProvider p, BookSourcePart s, {int? index}) {
    return SourceItemTile(
      key: ValueKey(s.bookSourceUrl),
      source: s,
      provider: p,
      index: index,
      isSelected: p.selectedUrls.contains(s.bookSourceUrl),
      onTap: () async {
        final nav = Navigator.of(context);
        final full = await p.getFullSource(s.bookSourceUrl);
        if (full != null && mounted) {
          nav.push(
            MaterialPageRoute(builder: (_) => SourceEditorPage(source: full)),
          );
        }
      },
      onLongPress: () {
        _showSourceMenu(context, p, s);
      },
      onEnabledChanged: (v) => p.toggleEnabled(s),
    );
  }

  void _showSourceMenu(
    BuildContext context,
    SourceManagerProvider p,
    BookSourcePart s,
  ) {
    final nav = Navigator.of(context);
    AppBottomSheet.show(
      context: context,
      title: s.bookSourceName,
      icon: Icons.source_rounded,
      children: [
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('調試書源', style: TextStyle(fontSize: 14)),
          onTap: () async {
            Navigator.pop(context);
            final full = await p.getFullSource(s.bookSourceUrl);
            if (full != null && context.mounted)
              SourceManagerDialogs.showDebugInput(context, full);
          },
        ),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.edit_outlined),
          title: const Text('編輯書源', style: TextStyle(fontSize: 14)),
          onTap: () async {
            Navigator.pop(context);
            final full = await p.getFullSource(s.bookSourceUrl);
            if (full != null && mounted) {
              nav.push(
                MaterialPageRoute(
                  builder: (_) => SourceEditorPage(source: full),
                ),
              );
            }
          },
        ),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.vertical_align_top_rounded),
          title: const Text('移至最頂', style: TextStyle(fontSize: 14)),
          onTap: () async {
            Navigator.pop(context);
            await p.moveToTop(s.bookSourceUrl);
          },
        ),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.vertical_align_bottom_rounded),
          title: const Text('移至最底', style: TextStyle(fontSize: 14)),
          onTap: () async {
            Navigator.pop(context);
            await p.moveToBottom(s.bookSourceUrl);
          },
        ),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
          title: const Text(
            '刪除書源',
            style: TextStyle(fontSize: 14, color: Colors.red),
          ),
          onTap: () {
            Navigator.pop(context);
            p.deleteSource(s);
          },
        ),
      ],
    );
  }

  /// 確認刪除選中書源 (對標 legado onClickSelectBarMainAction)
  void _confirmDeleteSelected(BuildContext context, SourceManagerProvider p) {
    final count = p.selectedUrls.length;
    if (count == 0) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('確認刪除'),
            content: Text('確定要刪除選中的 $count 個書源嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  await p.deleteSelected();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('已刪除 $count 個書源')),
                  );
                },
                child: const Text('確定刪除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  /// 校驗選中書源 — 輸入關鍵字後開始 (對標 legado checkSource)
  void _showCheckSourceDialog(BuildContext context, SourceManagerProvider p) {
    final count = p.selectedUrls.length;
    if (count == 0) return;
    final ctrl = TextEditingController(text: '我的');
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('校驗選中書源 ($count)'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: '搜尋關鍵字'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  p.checkSelectedSources();
                },
                child: const Text('開始校驗'),
              ),
            ],
          ),
    );
  }

  /// 加入分組 (對標 legado selectionAddToGroups)
  void _showAddGroupDialog(BuildContext context, SourceManagerProvider p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('加入分組'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(hintText: '分組名稱'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: p.allGroups.length,
                    itemBuilder: (ctx2, i) {
                      final g = p.allGroups[i];
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isNotEmpty) {
                    p.selectionAddToGroups(p.selectedUrls, text);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('確定'),
              ),
            ],
          ),
    );
  }

  /// 移出分組 (對標 legado selectionRemoveFromGroups)
  void _showRemoveGroupDialog(BuildContext context, SourceManagerProvider p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('移出分組'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(hintText: '分組名稱'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: p.allGroups.length,
                    itemBuilder: (ctx2, i) {
                      final g = p.allGroups[i];
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isNotEmpty) {
                    p.selectionRemoveFromGroups(p.selectedUrls, text);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('確定'),
              ),
            ],
          ),
    );
  }

  Future<void> _importWithPreview(BuildContext context, String jsonStr) async {
    final p = context.read<SourceManagerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final parsed = p.parseSourcesDetailed(jsonStr);
      if (parsed.importableSources.isEmpty) {
        if (parsed.excludedNonNovelSources.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '已排除 ${parsed.excludedNonNovelSources.length} 個非小說源，未匯入任何書源',
              ),
            ),
          );
        } else {
          messenger.showSnackBar(const SnackBar(content: Text('未解析到有效書源')));
        }
        return;
      }
      final preview = await p.previewImport(
        parsed.importableSources,
        excludedSources: parsed.excludedNonNovelSources,
      );
      if (!context.mounted) return;
      final confirmed = await showImportPreviewDialog(context, preview);
      if (confirmed != null && confirmed.isNotEmpty) {
        final count = await p.importSources(confirmed);
        if (context.mounted) {
          final excludedCount = parsed.excludedNonNovelSources.length;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                excludedCount > 0
                    ? '成功匯入 $count 個書源，已排除 $excludedCount 個非小說源'
                    : '成功匯入 $count 個書源',
              ),
            ),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('匯入失敗: $e')));
    }
  }

  void _showImportDialog(BuildContext context, bool isUrl) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isUrl ? '網路匯入' : '文本匯入'),
            content: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: isUrl ? '請輸入 URL' : '請貼上 JSON',
              ),
              maxLines: 5,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final p = context.read<SourceManagerProvider>();
                  final input = ctrl.text.trim();
                  if (input.isEmpty) {
                    Navigator.pop(ctx);
                    return;
                  }
                  Navigator.pop(ctx);
                  if (isUrl) {
                    await p.importFromUrl(input);
                  } else {
                    if (!context.mounted) return;
                    await _importWithPreview(context, input);
                  }
                },
                child: const Text('匯入'),
              ),
            ],
          ),
    );
  }

  Future<void> _scanQrCode(
    BuildContext context,
    SourceManagerProvider p,
  ) async {
    final nav = Navigator.of(context);
    final res = await nav.push(
      MaterialPageRoute(builder: (ctx) => const QrScanPage()),
    );
    if (res != null && res.isNotEmpty) {
      await p.importFromUrl(res);
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt', 'legado'],
      );
      if (res?.files.single.path != null && context.mounted) {
        final content = await File(res!.files.single.path!).readAsString();
        if (context.mounted) await _importWithPreview(context, content);
      }
    } catch (_) {}
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && context.mounted) {
      await _importWithPreview(context, data!.text!);
    }
  }
}
