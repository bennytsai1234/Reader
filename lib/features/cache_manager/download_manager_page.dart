import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/core/services/download_service.dart';
import 'package:inkpage_reader/core/models/download_task.dart';

/// DownloadManagerPage - 全域背景下載管理頁面
class DownloadManagerPage extends StatelessWidget {
  const DownloadManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DownloadService>();
    final tasks = service.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('背景下載佇列'),
        actions: [
          IconButton(
            icon: Icon(
              service.isPaused
                  ? Icons.play_circle_outline
                  : Icons.pause_circle_outline,
            ),
            tooltip: service.isPaused ? '恢復全部' : '暫停全部',
            onPressed: service.togglePause,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清除已完成',
            onPressed: () {
              // 深度還原：清除已完成的任務
              for (var task in tasks.where((t) => t.status == 3).toList()) {
                service.removeTask(task.bookUrl);
              }
            },
          ),
        ],
      ),
      body:
          tasks.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildTaskTile(context, service, task);
                },
              ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done_rounded,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            '暫無背景下載任務',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    DownloadService service,
    DownloadTask task,
  ) {
    final progress =
        task.totalCount == 0 ? 0.0 : task.successCount / task.totalCount;
    final isRunning = task.status == 1;
    final isPaused = task.status == 2;
    final isDone = task.status == 3;
    final isError = task.status == 4;

    return ListTile(
      title: Text(
        task.bookName,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDone
                    ? '下載完成'
                    : (isError
                        ? '下載失敗'
                        : '${task.successCount} / ${task.totalCount} 章'),
                style: TextStyle(
                  fontSize: 11,
                  color: isError ? Colors.red : Colors.grey,
                ),
              ),
              if (isRunning)
                const Text(
                  '正在下載...',
                  style: TextStyle(fontSize: 11, color: Colors.blue),
                ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDone)
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 20),
              onPressed:
                  () =>
                      isPaused
                          ? service.startDownloads()
                          : service.pauseTask(task.bookUrl),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => service.removeTask(task.bookUrl),
          ),
        ],
      ),
    );
  }
}
