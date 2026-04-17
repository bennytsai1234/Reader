import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';
import 'provider/change_source_provider.dart';
import 'widgets/change_source_filter_bar.dart';
import 'widgets/change_source_item.dart';
import 'reader_provider.dart';
import 'reader_page.dart';

class ChangeChapterSourceSheet extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  final String chapterTitle;

  const ChangeChapterSourceSheet({super.key, required this.book, required this.chapterIndex, required this.chapterTitle});

  static void show(BuildContext context, Book book, int chapterIndex, String chapterTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeChapterSourceSheet(book: book, chapterIndex: chapterIndex, chapterTitle: chapterTitle),
    );
  }

  @override
  State<ChangeChapterSourceSheet> createState() => _ChangeChapterSourceSheetState();
}

class _ChangeChapterSourceSheetState extends State<ChangeChapterSourceSheet> {
  final TextEditingController _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ChangeNotifierProvider(
      create: (_) => ChangeSourceProvider(widget.book),
      child: Consumer<ChangeSourceProvider>(
        builder: (context, provider, child) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: AppBottomSheet(
              title: '單章換源',
              icon: Icons.find_replace_rounded,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(provider.checkAuthor ? Icons.person : Icons.person_off, size: 20),
                    onPressed: provider.toggleCheckAuthor,
                    tooltip: '校驗作者',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: provider.startSearch,
                    tooltip: '重新搜尋',
                  ),
                ],
              ),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '目標章節: ${widget.chapterTitle}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ChangeSourceFilterBar(provider: provider, filterController: _filterController),
                
                if (provider.isSearching) 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                
                Row(
                  children: [
                    Text(provider.status, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const Spacer(),
                    if (provider.filteredResults.isNotEmpty)
                      Text('共 ${provider.filteredResults.length} 個來源', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: _buildSourceList(provider),
                  ),
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourceList(ChangeSourceProvider provider) {
    if (provider.filteredResults.isEmpty && !provider.isSearching) {
      return const Center(child: Text('無搜尋結果', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: provider.filteredResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) => ChangeSourceItem(
        searchBook: provider.filteredResults[index],
        onTap: () => _handleSourceSelected(context, provider, provider.filteredResults[index]),
      ),
    );
  }

  Future<void> _handleSourceSelected(BuildContext context, ChangeSourceProvider provider, SearchBook searchBook) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final readerProvider = context.read<ReaderProvider>();

    final source = await provider.findSourceByUrl(searchBook.origin);
    if (!context.mounted) return;
    if (source == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));

    try {
      final tempBook = searchBook.toBook();
      final chapters = await provider.service.getChapterList(source, tempBook);
      var targetIndex = chapters.indexWhere((c) => c.title == widget.chapterTitle);
      if (targetIndex == -1 && widget.chapterIndex < chapters.length) {
        targetIndex = widget.chapterIndex;
      }

      if (!mounted) return;
      nav.pop(); // Pop loading
      
      if (targetIndex != -1) {
        final content = await provider.service.getContent(source, tempBook, chapters[targetIndex]);
        if (!mounted) return;
        
        if (tempBook.type != widget.book.type) {
          if (!context.mounted) return;
          _showMigrationDialog(context, widget.book.migrateTo(tempBook, chapters));
        } else {
          readerProvider.replaceChapterSource(widget.chapterIndex, source, content);
          nav.pop(); // Pop sheet
        }
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('找不到對應章節')));
      }
    } catch (e) {
      if (mounted) {
        nav.pop();
        messenger.showSnackBar(SnackBar(content: Text('換源失敗: $e')));
      }
    }
  }

  void _showMigrationDialog(BuildContext context, Book newBook) {
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('書籍類型變更'),
        content: Text('偵測到新來源為${newBook.type == 2 ? "有聲" : "文本"}類型，是否遷移？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              nav.pop();
              nav.pushReplacement(
                MaterialPageRoute(builder: (_) => ReaderPage(book: newBook)),
              );
            },
            child: const Text('遷移並跳轉'),
          ),
        ],
      ),
    );
  }
}
