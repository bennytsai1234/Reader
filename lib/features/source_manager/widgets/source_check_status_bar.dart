import 'package:flutter/material.dart';
import '../source_manager_provider.dart';

class SourceCheckStatusBar extends StatelessWidget {
  final SourceManagerProvider provider;
  final VoidCallback onTap;

  const SourceCheckStatusBar({
    super.key,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isChecking = provider.checkService.isChecking;
    final report = provider.lastCheckReport;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color:
            isChecking
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.08),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child:
                  isChecking
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(
                        Icons.rule_folder_outlined,
                        size: 16,
                        color: Colors.orange,
                      ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isChecking
                    ? '正在校驗 (${provider.checkService.currentCount}/${provider.checkService.totalCount}): ${provider.checkService.statusMsg}'
                    : '上次校驗結果: ${report.summary}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: isChecking ? Colors.blue : Colors.orange,
            ),
            if (isChecking)
              TextButton(
                onPressed: provider.checkService.cancel,
                child: const Text('取消'),
              ),
          ],
        ),
      ),
    );
  }
}
