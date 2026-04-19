import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/search_book.dart';

class SourceOptionTile extends StatelessWidget {
  final SearchBook searchBook;
  final bool isCurrent;
  final VoidCallback? onTap;

  const SourceOptionTile({
    super.key,
    required this.searchBook,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      enabled: !isCurrent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Row(
        children: [
          Expanded(
            child: Text(
              searchBook.originName ?? '未知來源',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (searchBook.respondTime > 0) ...[
            const SizedBox(width: 8),
            _ResponseTimeTag(ms: searchBook.respondTime),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((searchBook.author ?? '').isNotEmpty)
              Text(
                '作者: ${searchBook.author}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Text(
              '最新: ${searchBook.latestChapterTitle ?? '無最新章節資訊'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if ((searchBook.wordCount ?? '').isNotEmpty ||
                (searchBook.kind ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if ((searchBook.wordCount ?? '').isNotEmpty)
                    _MetaChip(
                      label: searchBook.wordCount!,
                      foregroundColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                  if ((searchBook.kind ?? '').isNotEmpty)
                    _MetaChip(
                      label: searchBook.kind!,
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      trailing:
          isCurrent
              ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
              : null,
      onTap: onTap,
    );
  }
}

class _ResponseTimeTag extends StatelessWidget {
  final int ms;

  const _ResponseTimeTag({required this.ms});

  @override
  Widget build(BuildContext context) {
    final color =
        ms > 2000
            ? Colors.red
            : ms > 800
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '${ms}ms',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _MetaChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
