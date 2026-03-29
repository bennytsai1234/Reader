import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/widgets/book_cover_widget.dart';
import '../../book_detail/book_detail_page.dart';

class SearchResultItem extends StatefulWidget {
  final AggregatedSearchBook result;

  const SearchResultItem({super.key, required this.result});

  @override
  State<SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<SearchResultItem> {
  bool _sourcesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.result.book;
    final sourceCount = widget.result.sources.length;
    return ListTile(
      leading: BookCoverWidget(
        coverUrl: book.coverUrl,
        bookName: book.name,
        author: book.author,
        width: 45,
        height: 60,
        borderRadius: BorderRadius.circular(4),
      ),
      title: Row(
        children: [
          Expanded(child: Text(book.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          if (sourceCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$sourceCount 源',
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            '${book.author ?? '未知'} · ${book.kind ?? '未知'} · ${book.wordCount ?? ''}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            '最新: ${book.latestChapterTitle ?? '暫無'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: sourceCount > 1 ? () => setState(() => _sourcesExpanded = !_sourcesExpanded) : null,
            child: _sourcesExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('來源 ($sourceCount):', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_less, size: 14, color: Colors.grey.shade600),
                      ]),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: widget.result.sources.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(s, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        )).toList(),
                      ),
                    ],
                  )
                : Row(children: [
                    Expanded(
                      child: Text(
                        '來源: ${widget.result.sources.join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    if (sourceCount > 1)
                      Icon(Icons.expand_more, size: 14, color: Colors.grey.shade600),
                  ]),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailPage(searchBook: widget.result),
          ),
        );
      },
    );
  }
}

