import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/storage/storage_metrics.dart';
import 'package:provider/provider.dart';

import 'storage_management_provider.dart';

import 'package:inkpage_reader/features/cache_manager/download_manager_page.dart';

class StorageManagementPage extends StatelessWidget {
  const StorageManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StorageManagementProvider()..load(),
      child: Consumer<StorageManagementProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('存儲與下載'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.isLoading ? null : provider.load,
                ),
              ],
            ),
            body:
                provider.isLoading && provider.entries.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: provider.load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildHeader(context, provider),
                          const SizedBox(height: 24),

                          _buildSectionTitle(context, '下載任務'),
                          Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.download_for_offline_outlined,
                              ),
                              title: const Text('背景下載佇列'),
                              subtitle: const Text('查看並管理進行中的章節下載任務'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const DownloadManagerPage(),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle(context, '本地儲存'),
                          ...provider.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _StorageEntryCard(
                                entry: entry,
                                onClear:
                                    () => _confirmClearEntry(
                                      context,
                                      provider,
                                      entry,
                                    ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete_sweep_outlined),
                            label: const Text('清理所有可重建資料'),
                            onPressed:
                                provider.isLoading
                                    ? null
                                    : () => _confirmClearAll(context, provider),
                          ),
                        ],
                      ),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    StorageManagementProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('已追蹤的本地空間', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            StorageMetrics.formatBytes(provider.totalTrackedBytes),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('包含書籍正文、封面、圖片暫存、分享匯出暫存、規則資料與自訂字體。搜尋歷史以筆數顯示。'),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    StorageManagementProvider provider,
  ) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('一鍵清理可重建資料'),
          content: const Text('會清空臨時圖片、匯出暫存、搜尋歷史、規則資料與自訂字體，不會刪除書籍正文與本地封面。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('確定清理'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) return;
    await provider.clearAll();
  }

  Future<void> _confirmClearEntry(
    BuildContext context,
    StorageManagementProvider provider,
    StorageEntry entry,
  ) async {
    if (!entry.canClear) return;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('清理 ${entry.title}'),
          content: Text(entry.description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(entry.clearLabel),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) return;
    await provider.clearEntry(entry);
  }
}

class _StorageEntryCard extends StatelessWidget {
  const _StorageEntryCard({required this.entry, required this.onClear});

  final StorageEntry entry;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(entry.icon),
        title: Text(entry.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(entry.description),
        ),
        trailing: SizedBox(
          width: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.displayValue,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end,
              ),
              TextButton(
                onPressed: entry.canClear ? onClear : null,
                child: Text(entry.canClear ? entry.clearLabel : '保留'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
