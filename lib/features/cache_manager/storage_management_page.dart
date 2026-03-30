import 'package:flutter/material.dart';
import 'package:legado_reader/core/storage/storage_metrics.dart';
import 'package:provider/provider.dart';

import 'storage_management_provider.dart';

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
              title: const Text('儲存空間管理'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.isLoading ? null : provider.load,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed:
                      provider.isLoading
                          ? null
                          : () => _confirmClearAll(context, provider),
                ),
              ],
            ),
            body:
                provider.isLoading && provider.entries.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: provider.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.entries.length + 1,
                        separatorBuilder:
                            (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildHeader(context, provider);
                          }

                          final entry = provider.entries[index - 1];
                          return _StorageEntryCard(
                            entry: entry,
                            onClear:
                                () => _confirmClearEntry(
                                  context,
                                  provider,
                                  entry,
                                ),
                          );
                        },
                      ),
                    ),
          );
        },
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
          const Text('包含正文快取、圖片、分享匯出暫存、規則資料與自訂字體。搜尋歷史以筆數顯示。'),
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
          title: const Text('一鍵清理所有快取'),
          content: const Text('會清空正文、圖片、匯出暫存、搜尋歷史、規則資料與自訂字體。'),
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
              child: const Text('清理'),
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
              TextButton(onPressed: onClear, child: const Text('清理')),
            ],
          ),
        ),
      ),
    );
  }
}
