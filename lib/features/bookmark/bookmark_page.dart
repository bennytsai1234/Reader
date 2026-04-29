import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'bookmark_provider.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_open_target.dart';
import 'package:inkpage_reader/features/reader_v2/page/reader_v2_page.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookmarkProvider(),
      child: Consumer<BookmarkProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title:
                  _isSearching
                      ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: '搜尋書籤內容',
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => provider.search(val),
                      )
                      : const Text('所有書籤'),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        provider.search('');
                      }
                    });
                  },
                ),
                if (!_isSearching)
                  PopupMenuButton(
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'clear',
                            child: Text('清空所有'),
                          ),
                        ],
                    onSelected: (val) {
                      if (val == 'clear') {
                        _showClearAllConfirm(context, provider);
                      }
                    },
                  ),
              ],
            ),
            body:
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.bookmarks.isEmpty
                    ? const Center(child: Text('暫無書籤'))
                    : ListView.separated(
                      itemCount: provider.bookmarks.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder:
                          (ctx, i) => _buildBookmarkItem(
                            context,
                            provider,
                            provider.bookmarks[i],
                          ),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildBookmarkItem(
    BuildContext context,
    BookmarkProvider p,
    Bookmark bookmark,
  ) {
    final timeStr = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(bookmark.time));

    return ListTile(
      title: Text(
        '${bookmark.bookName} · ${bookmark.chapterName}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            bookmark.content.isEmpty ? bookmark.bookText : bookmark.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(timeStr, style: const TextStyle(fontSize: 11)),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () => p.deleteBookmark(bookmark),
      ),
      onTap: () => _jumpToBook(context, bookmark),
    );
  }

  Future<void> _jumpToBook(BuildContext context, Bookmark bookmark) async {
    final book = await context.read<BookmarkProvider>().lookupBook(
      bookmark.bookUrl,
    );
    if (!context.mounted) return;

    if (book != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ReaderV2Page(
                book: book,
                openTarget: ReaderV2OpenTarget.bookmark(bookmark),
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('書籍不在書架中，無法跳轉')));
    }
  }

  void _showClearAllConfirm(BuildContext context, BookmarkProvider p) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('確認清空'),
            content: const Text('是否清空所有書籤？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  p.clearAll();
                  Navigator.pop(ctx);
                },
                child: const Text('清空'),
              ),
            ],
          ),
    );
  }
}
