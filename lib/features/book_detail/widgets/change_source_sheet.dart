import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/book_detail/book_detail_provider.dart';
import 'package:inkpage_reader/features/reader/provider/change_source_provider.dart';
import 'package:inkpage_reader/features/reader/widgets/change_source_item.dart';

class ChangeSourceSheet extends StatelessWidget {
  final Book book;
  final BookDetailProvider detailProvider;

  const ChangeSourceSheet({
    super.key,
    required this.book,
    required this.detailProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChangeSourceProvider(book),
      child: _ChangeSourceContent(
        originalBook: book,
        detailProvider: detailProvider,
      ),
    );
  }
}

class _ChangeSourceContent extends StatelessWidget {
  final Book originalBook;
  final BookDetailProvider detailProvider;

  const _ChangeSourceContent({
    required this.originalBook,
    required this.detailProvider,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChangeSourceProvider>();
    final sources =
        provider.filteredResults
            .where((result) => result.name == originalBook.name)
            .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(provider),
          const Divider(height: 1),
          if (provider.isSearching) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    provider.status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (sources.isNotEmpty)
                  Text(
                    '共 ${sources.length} 個來源',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                sources.isEmpty && !provider.isSearching
                    ? const Center(child: Text('未找到其他來源'))
                    : ListView.separated(
                      itemCount: sources.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final result = sources[i];
                        return ChangeSourceItem(
                          searchBook: result,
                          isCurrent: result.origin == originalBook.origin,
                          onTap:
                              result.origin == originalBook.origin
                                  ? null
                                  : () async {
                                    await detailProvider.changeSource(result);
                                    if (context.mounted) Navigator.pop(context);
                                  },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ChangeSourceProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '更換來源 (${provider.filteredResults.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: Icon(
              provider.checkAuthor ? Icons.person : Icons.person_off,
              size: 20,
            ),
            onPressed: provider.toggleCheckAuthor,
            tooltip: '校驗作者',
          ),
          if (provider.isSearching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: provider.startSearch,
              tooltip: '重新搜尋',
            ),
        ],
      ),
    );
  }
}
