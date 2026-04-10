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
import 'package:legado_reader/core/models/book_source_part.dart';
import 'widgets/import_preview_dialog.dart';
import 'widgets/source_item_tile.dart';
import 'widgets/source_filter_bar.dart';
import 'widgets/source_batch_toolbar.dart';
import 'widgets/source_check_status_bar.dart';
import 'widgets/source_manager_menus.dart';
import 'widgets/source_manager_dialogs.dart';

class SourceManagerPage extends StatefulWidget {
  const SourceManagerPage({super.key});
  @override State<SourceManagerPage> createState() => _SourceManagerPageState();
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
    return Consumer<SourceManagerProvider>(builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text(provider.isBatchMode ? '已選擇 ${provider.selectedUrls.length} 項' : '書源管理'),
          actions: provider.isBatchMode ? [
            IconButton(icon: const Icon(Icons.select_all), tooltip: '全選', onPressed: provider.selectAll),
            IconButton(icon: const Icon(Icons.close), tooltip: '退出多選', onPressed: provider.toggleBatchMode),
          ] : [
            SourceManagerMenus.buildSortMenu(context, provider),
            SourceManagerMenus.buildGroupMenu(context, provider),
            SourceManagerMenus.buildAddMenu(context, provider, 
              onImportUrl: () => _showImportDialog(context, true), onImportFile: () => _importFromFile(context), 
              onImportClipboard: () => _importFromClipboard(context), onScanQr: () => _scanQrCode(context, provider), 
              onExplore: () => nav.push(MaterialPageRoute(builder: (_) => const ExploreSourcesPage())), 
              onManageGroups: () => nav.push(MaterialPageRoute(builder: (_) => const SourceGroupManagePage())), 
              onNewSource: () => nav.push(MaterialPageRoute(builder: (_) => const SourceEditorPage()))),
            SourceManagerMenus.buildMoreMenu(context, provider, onClearInvalid: (p) => SourceManagerDialogs.confirmClearInvalid(context, p)),
          ],
        ),
        body: Column(children: [
          if (provider.checkService.isChecking) SourceCheckStatusBar(provider: provider, onTap: () => SourceManagerDialogs.showCheckLog(context, provider)),
          if (!provider.isBatchMode) Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋書源名稱、網址',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); provider.setSearchQuery(''); })
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),
          if (!provider.isBatchMode) SourceFilterBar(provider: provider),
          Expanded(child: _buildMainContent(provider)),
        ]),
        bottomNavigationBar: provider.isBatchMode ? SourceBatchToolbar(provider: provider, onGroup: () => SourceManagerDialogs.showBatchGroup(context, provider),
          onExport: () async {
            final messenger = ScaffoldMessenger.of(context);
            await provider.exportSelected();
            if (!mounted) return;
            messenger.showSnackBar(const SnackBar(content: Text('已複製至剪貼簿')));
          },
          onDelete: () async {
            final messenger = ScaffoldMessenger.of(context);
            await provider.deleteSelected();
            if (!mounted) return;
            messenger.showSnackBar(const SnackBar(content: Text('已刪除選定書源')));
          },
          onEnable: () => provider.batchSetEnabled(true),
          onDisable: () => provider.batchSetEnabled(false),
          onMoveToTop: () => provider.moveSelectedToTop(),
          onMoveToBottom: () => provider.moveSelectedToBottom(),
        ) : null,
      );
    });
  }

  Widget _buildMainContent(SourceManagerProvider p) {
    if (p.isLoading) return const Center(child: CircularProgressIndicator());
    final list = p.sources;
    if (list.isEmpty) return const Center(child: Text('暫無書源'));

    if (p.groupByDomain) {
      return _buildGroupedList(p);
    }

    // 只有在手動排序 (0) 模式下才允許拖拽
    final bool canReorder = p.sortMode == 0 && !p.isBatchMode;

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
          title: Text(domain, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('共 ${items.length} 個書源', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          children: items.map((s) => _buildItem(p, s)).toList(),
        );
      },
    );
  }

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : '其他';
    } catch (_) { return '其他'; }
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
        if (p.isBatchMode) {
          p.toggleSelect(s.bookSourceUrl);
        } else {
          final full = await p.getFullSource(s.bookSourceUrl);
          if (full != null && mounted) {
            nav.push(MaterialPageRoute(builder: (_) => SourceEditorPage(source: full)));
          }
        }
      }, 
      onLongPress: () {
        if (!p.isBatchMode) {
          _showSourceMenu(context, p, s);
        }
      },
      onEnabledChanged: (v) => p.toggleEnabled(s),
    );
  }

  void _showSourceMenu(BuildContext context, SourceManagerProvider p, BookSourcePart s) {
    final nav = Navigator.of(context);
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.bug_report), title: const Text('調試書源'), onTap: () async { 
        Navigator.pop(ctx); 
        final full = await p.getFullSource(s.bookSourceUrl);
        if (full != null && context.mounted) SourceManagerDialogs.showDebugInput(context, full); 
      }),
      ListTile(leading: const Icon(Icons.edit), title: const Text('編輯書源'), onTap: () async { 
        Navigator.pop(ctx); 
        final full = await p.getFullSource(s.bookSourceUrl);
        if (full != null && mounted) {
          nav.push(MaterialPageRoute(builder: (_) => SourceEditorPage(source: full))); 
        }
      }),
      ListTile(leading: const Icon(Icons.vertical_align_top), title: const Text('移至頂部'), onTap: () async {
        Navigator.pop(ctx);
        await p.moveToTop(s.bookSourceUrl);
      }),
      ListTile(leading: const Icon(Icons.vertical_align_bottom), title: const Text('移至底部'), onTap: () async {
        Navigator.pop(ctx);
        await p.moveToBottom(s.bookSourceUrl);
      }),
      ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('刪除書源', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(ctx); p.deleteSource(s); }),
    ])));
  }

  Future<void> _importWithPreview(BuildContext context, String jsonStr) async {
    final p = context.read<SourceManagerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final parsed = p.parseSources(jsonStr);
      if (parsed.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('未解析到有效書源')));
        return;
      }
      final preview = await p.previewImport(parsed);
      if (!context.mounted) return;
      final confirmed = await showImportPreviewDialog(context, preview);
      if (confirmed != null && confirmed.isNotEmpty) {
        final count = await p.importSources(confirmed);
        if (context.mounted) {
          messenger.showSnackBar(SnackBar(content: Text('成功匯入 $count 個書源')));
        }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('匯入失敗: $e')));
    }
  }

  void _showImportDialog(BuildContext context, bool isUrl) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(isUrl ? '網路匯入' : '文本匯入'), content: TextField(controller: ctrl, decoration: InputDecoration(hintText: isUrl ? '請輸入 URL' : '請貼上 JSON'), maxLines: 5), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      ElevatedButton(onPressed: () async {
        final p = context.read<SourceManagerProvider>();
        final input = ctrl.text.trim();
        if (input.isEmpty) { Navigator.pop(ctx); return; }
        Navigator.pop(ctx);
        if (isUrl) {
          await p.importFromUrl(input);
        } else {
          if (!context.mounted) return;
          await _importWithPreview(context, input);
        }
      }, child: const Text('匯入')),
    ]));
  }

  Future<void> _scanQrCode(BuildContext context, SourceManagerProvider p) async {
    final nav = Navigator.of(context);
    final res = await nav.push(MaterialPageRoute(builder: (ctx) => const QrScanPage()));
    if (res != null && res.isNotEmpty) {
      await p.importFromUrl(res);
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt', 'legado']);
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
