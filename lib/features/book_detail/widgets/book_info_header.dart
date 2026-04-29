import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/widgets/book_cover_widget.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_open_target.dart';
import '../book_detail_provider.dart';

class BookInfoHeader extends StatelessWidget {
  final Book book;
  final BookDetailProvider provider;
  final Function(BuildContext, String) showPhotoView;
  final VoidCallback onEdit;
  final Function(BuildContext, Book) showSourceOptions;
  final void Function(BuildContext, Book, ReaderV2OpenTarget, List<BookChapter>)
  navigateToReader;
  final Function(BuildContext, BookDetailProvider) showChangeSource;
  final Future<void> Function(BuildContext, BookDetailProvider) toggleBookshelf;

  const BookInfoHeader({
    super.key,
    required this.book,
    required this.provider,
    required this.showPhotoView,
    required this.onEdit,
    required this.showSourceOptions,
    required this.navigateToReader,
    required this.showChangeSource,
    required this.toggleBookshelf,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = book.getDisplayCover();
    final actionButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              if (coverUrl != null && coverUrl.isNotEmpty) {
                showPhotoView(context, coverUrl);
              }
            },
            child: Hero(
              tag: 'book_cover',
              child: BookCoverWidget(
                coverUrl: coverUrl,
                bookName: book.name,
                author: book.author,
                width: 100,
                height: 140,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '作者：${book.author}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => showSourceOptions(context, book),
                    child: Text(
                      '來源：${book.originName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _SourceStatusChip(provider: provider),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              () => navigateToReader(
                                context,
                                book,
                                ReaderV2OpenTarget.resume(book),
                                provider.allChapters,
                              ),
                          style: actionButtonStyle,
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: Text(
                            book.chapterIndex == 0 && book.charOffset == 0
                                ? '開始閱讀'
                                : '繼續閱讀',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => toggleBookshelf(context, provider),
                          style: actionButtonStyle,
                          icon: Icon(
                            provider.isInBookshelf
                                ? Icons.library_add_check
                                : Icons.library_add,
                            size: 18,
                          ),
                          label: Text(provider.isInBookshelf ? '移出書架' : '放入書架'),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => showChangeSource(context, provider),
                          child: const Text(
                            '換源',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceStatusChip extends StatelessWidget {
  const _SourceStatusChip({required this.provider});

  final BookDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthy = provider.sourceStatusIsHealthy;
    final color = healthy ? Colors.green : Colors.orange;
    final foreground = healthy ? Colors.green.shade700 : Colors.orange.shade700;
    return Tooltip(
      message: provider.sourceStatusDescription,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          provider.sourceStatusLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
