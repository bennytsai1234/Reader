import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:inkpage_reader/features/book_detail/book_detail_provider.dart';
import 'package:inkpage_reader/features/book_detail/change_cover_sheet.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/export_book_service.dart';
import 'package:inkpage_reader/features/source_manager/source_editor_page.dart';
import 'package:inkpage_reader/features/source_manager/source_debug_page.dart';
import 'package:inkpage_reader/features/cache_manager/download_manager_page.dart';
import 'package:inkpage_reader/features/reader/reader_page.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';

import 'widgets/book_info_header.dart';
import 'widgets/book_info_intro.dart';
import 'widgets/book_info_toc_bar.dart';
import 'widgets/change_source_sheet.dart';

class BookDetailPage extends StatelessWidget {
  final Book? book;
  final AggregatedSearchBook? searchBook;

  const BookDetailPage({super.key, this.book, this.searchBook})
    : assert(book != null || searchBook != null);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => BookDetailProvider(
            searchBook ?? AggregatedSearchBook(book: book!, sources: []),
          ),
      child: Consumer<BookDetailProvider>(
        builder: (context, provider, child) {
          final currentBook = provider.book;
          return Scaffold(
            appBar: _buildAppBar(context, provider),
            body:
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                      slivers: [
                        if ((provider.sourceIssueMessage ?? '').isNotEmpty)
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(provider.sourceIssueMessage!),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => _showChangeSourceDialog(
                                          context,
                                          provider,
                                        ),
                                    child: const Text('換源'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: BookInfoHeader(
                            book: currentBook,
                            provider: provider,
                            showPhotoView: _showPhotoView,
                            onEdit:
                                () =>
                                    _showEditBookInfoDialog(context, provider),
                            onCacheOffline:
                                () => _showDownloadSheet(context, provider),
                            showSourceOptions: _showSourceOptions,
                            navigateToReader: _navigateToReader,
                            showChangeSource: _showChangeSourceDialog,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: BookInfoIntro(book: currentBook),
                        ),
                        BookInfoTocBar(
                          provider: provider,
                          onSearch:
                              () => _showSearchTocDialog(context, provider),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((ctx, i) {
                            final chapter = provider.filteredChapters[i];
                            return ListTile(
                              title: Text(
                                chapter.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap:
                                  () => _navigateToReader(
                                    context,
                                    currentBook,
                                    chapter.index,
                                    provider.allChapters,
                                  ),
                            );
                          }, childCount: provider.filteredChapters.length),
                        ),
                      ],
                    ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    BookDetailProvider provider,
  ) {
    return AppBar(
      title: const Text('書籍詳情'),
      actions: [
        IconButton(
          icon: Icon(
            provider.isInBookshelf
                ? Icons.library_add_check
                : Icons.library_add,
          ),
          onPressed: provider.toggleInBookshelf,
        ),
        PopupMenuButton<String>(
          onSelected: (v) => _handleMenuSelection(context, provider, v),
          itemBuilder:
              (ctx) => [
                const PopupMenuItem(value: 'change_cover', child: Text('換封面')),
                const PopupMenuItem(value: 'export', child: Text('匯出全書')),
                const PopupMenuItem(value: 'clear_cache', child: Text('清理快取')),
                const PopupMenuItem(value: 'edit', child: Text('編輯資訊')),
              ],
        ),
      ],
    );
  }

  void _handleMenuSelection(
    BuildContext context,
    BookDetailProvider provider,
    String val,
  ) {
    if (val == 'export') {
      ExportBookService().exportToTxt(provider.book);
    } else if (val == 'clear_cache') {
      provider.clearCache();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已清理快取')));
    } else if (val == 'edit') {
      _showEditBookInfoDialog(context, provider);
    } else if (val == 'change_cover') {
      _showChangeCoverSheet(context, provider);
    }
  }

  void _showPhotoView(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (ctx) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(backgroundColor: Colors.transparent),
              body: Center(
                child: Hero(
                  tag: 'book_cover',
                  child: CachedNetworkImage(imageUrl: url),
                ),
              ),
            ),
      ),
    );
  }

  void _showSourceOptions(BuildContext context, Book b) {
    final provider = context.read<BookDetailProvider>();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(b.originName),
            actions: [
              TextButton(
                onPressed: () {
                  final s = provider.currentSource;
                  Navigator.pop(ctx);
                  if (s != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SourceEditorPage(source: s),
                      ),
                    );
                  }
                },
                child: const Text('詳情'),
              ),
              TextButton(
                onPressed: () {
                  final s = provider.currentSource;
                  Navigator.pop(ctx);
                  if (s != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SourceDebugPage(source: s, debugKey: b.name),
                      ),
                    );
                  }
                },
                child: const Text('調試'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('關閉'),
              ),
            ],
          ),
    );
  }

  void _navigateToReader(
    BuildContext context,
    Book b,
    int index,
    List<BookChapter> initialChapters,
  ) => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (ctx) => ChangeNotifierProvider(
            create:
                (_) => ReaderProvider(
                  book: b,
                  chapterIndex: index,
                  initialChapters: initialChapters,
                ),
            child: ReaderPage(book: b, chapterIndex: index),
          ),
    ),
  );

  void _showChangeSourceDialog(BuildContext context, BookDetailProvider p) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => ChangeSourceSheet(book: p.book, detailProvider: p),
      );

  void _showDownloadSheet(BuildContext context, BookDetailProvider provider) {
    if (!provider.supportsOfflineCache) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('這本書已在裝置內，不需要再加入離線快取')));
      return;
    }
    showModalBottomSheet(
      context: context,
      builder:
          (sheetContext) => SafeArea(
            child: Wrap(
              children: [
                const ListTile(
                  title: Text('離線快取章節'),
                  subtitle: Text('只會保存章節內容供離線閱讀，不會匯出成本地檔案'),
                ),
                ListTile(
                  leading: const Icon(Icons.download_for_offline_outlined),
                  title: const Text('快取全部章節'),
                  subtitle: Text('共 ${provider.totalChapterCount} 章'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final result = await provider.queueDownloadAll();
                    if (!context.mounted) return;
                    _showDownloadQueuedSnackBar(context, result.message);
                  },
                ),
                if (provider.book.durChapterIndex < provider.totalChapterCount)
                  ListTile(
                    leading: const Icon(Icons.playlist_play_rounded),
                    title: const Text('從目前進度往後快取'),
                    subtitle: Text(
                      '從第 ${provider.book.durChapterIndex + 1} 章開始',
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final result = await provider.queueDownloadFromCurrent();
                      if (!context.mounted) return;
                      _showDownloadQueuedSnackBar(context, result.message);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.offline_pin_outlined),
                  title: const Text('只快取未快取章節'),
                  subtitle: const Text('跳過已經存在本機的章節內容'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final result = await provider.queueDownloadUncached();
                    if (!context.mounted) return;
                    _showDownloadQueuedSnackBar(context, result.message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.manage_history_outlined),
                  title: const Text('查看離線快取佇列'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DownloadManagerPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDownloadQueuedSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSearchTocDialog(BuildContext context, BookDetailProvider p) =>
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('搜尋目錄'),
              content: TextField(autofocus: true, onChanged: p.setSearchQuery),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('關閉'),
                ),
              ],
            ),
      );

  void _showEditBookInfoDialog(BuildContext context, BookDetailProvider p) {
    final n = TextEditingController(text: p.book.name),
        a = TextEditingController(text: p.book.author),
        i = TextEditingController(text: p.book.intro),
        c = TextEditingController(text: p.book.coverUrl);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('編輯'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: n,
                    decoration: const InputDecoration(labelText: '書名'),
                  ),
                  TextField(
                    controller: a,
                    decoration: const InputDecoration(labelText: '作者'),
                  ),
                  TextField(
                    controller: c,
                    decoration: const InputDecoration(labelText: '封面'),
                  ),
                  TextField(
                    controller: i,
                    decoration: const InputDecoration(labelText: '簡介'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  p.updateBookInfo(n.text, a.text, i.text, c.text);
                  Navigator.pop(ctx);
                },
                child: const Text('儲存'),
              ),
            ],
          ),
    );
  }

  void _showChangeCoverSheet(BuildContext context, BookDetailProvider p) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder:
            (ctx) => ChangeNotifierProvider.value(
              value: p,
              child: ChangeCoverSheet(
                bookName: p.book.name,
                author: p.book.author,
              ),
            ),
      );
}
