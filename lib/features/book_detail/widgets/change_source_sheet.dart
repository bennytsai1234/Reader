import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/features/search/search_provider.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import '../book_detail_provider.dart';

class ChangeSourceSheet extends StatelessWidget {
  final Book book;
  const ChangeSourceSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider()..search('${book.name} ${book.author}'),
      child: _ChangeSourceContent(originalBook: book),
    );
  }
}

class _ChangeSourceContent extends StatelessWidget {
  final Book originalBook;
  const _ChangeSourceContent({required this.originalBook});

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final detailProvider = context.read<BookDetailProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(context, searchProvider),
          const Divider(height: 1),
          if (searchProvider.isSearching)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child:
                searchProvider.results.isEmpty && !searchProvider.isSearching
                    ? const Center(child: Text('未找到其他來源'))
                    : _buildSourceList(context, searchProvider, detailProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SearchProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '更換來源 (${p.results.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (p.isSearching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed:
                  () => p.search('${originalBook.name} ${originalBook.author}'),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceList(
    BuildContext context,
    SearchProvider sp,
    BookDetailProvider dp,
  ) {
    // 展開聚合結果，保留來源順序與匹配結果。
    final allSources = <SearchBook>[];
    for (var sb in sp.results) {
      if (sb.name == originalBook.name) {
        allSources.add(sb);
      }
    }

    return ListView.separated(
      itemCount: allSources.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final sb = allSources[i];
        final isCurrent = sb.origin == originalBook.origin;

        return ListTile(
          selected: isCurrent,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  sb.originName ?? '未知來源',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '最新: ${sb.latestChapter}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              Row(
                children: [
                  if (sb.wordCount != null)
                    Text(
                      '${sb.wordCount!} ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                      ),
                    ),
                  if (sb.kind != null)
                    Expanded(
                      child: Text(
                        sb.kind!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing:
              isCurrent
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : null,
          onTap: () async {
            await dp.changeSource(sb);
            if (context.mounted) Navigator.pop(context);
          },
        );
      },
    );
  }
}
