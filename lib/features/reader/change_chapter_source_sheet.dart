import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/reader_chapter_content_store.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';
import 'source/change_source_provider.dart';
import 'widgets/change_source_filter_bar.dart';
import 'widgets/change_source_item.dart';
import 'reader_page.dart';
import 'runtime/models/reader_open_target.dart';

class ChangeChapterSourceSheet extends StatefulWidget {
  const ChangeChapterSourceSheet({
    super.key,
    required this.book,
    required this.chapterIndex,
    required this.chapterTitle,
    this.onChapterContentChanged,
  });

  final Book book;
  final int chapterIndex;
  final String chapterTitle;
  final Future<void> Function()? onChapterContentChanged;

  static void show(
    BuildContext context,
    Book book,
    int chapterIndex,
    String chapterTitle, {
    Future<void> Function()? onChapterContentChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ChangeChapterSourceSheet(
            book: book,
            chapterIndex: chapterIndex,
            chapterTitle: chapterTitle,
            onChapterContentChanged: onChapterContentChanged,
          ),
    );
  }

  @override
  State<ChangeChapterSourceSheet> createState() =>
      _ChangeChapterSourceSheetState();
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
                    icon: Icon(
                      provider.checkAuthor ? Icons.person : Icons.person_off,
                      size: 20,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bookmark_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '目標章節: ${widget.chapterTitle}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ChangeSourceFilterBar(
                  provider: provider,
                  filterController: _filterController,
                ),

                if (provider.isSearching)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),

                Row(
                  children: [
                    Text(
                      provider.status,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Spacer(),
                    if (provider.filteredResults.isNotEmpty)
                      Text(
                        '共 ${provider.filteredResults.length} 個來源',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
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
      return const Center(
        child: Text('無搜尋結果', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: provider.filteredResults.length,
      separatorBuilder:
          (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final searchBook = provider.filteredResults[index];
        final isCurrent = searchBook.origin == widget.book.origin;
        return ChangeSourceItem(
          searchBook: searchBook,
          isCurrent: isCurrent,
          onTap:
              isCurrent
                  ? null
                  : () => _handleSourceSelected(context, provider, searchBook),
        );
      },
    );
  }

  Future<void> _handleSourceSelected(
    BuildContext context,
    ChangeSourceProvider provider,
    SearchBook searchBook,
  ) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final source = await provider.findSourceByUrl(searchBook.origin);
    if (!context.mounted) return;
    if (source == null) {
      messenger.showSnackBar(const SnackBar(content: Text('找不到對應書源')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    var loadingVisible = true;

    void dismissLoading() {
      if (!loadingVisible || !nav.mounted) return;
      loadingVisible = false;
      nav.pop();
    }

    try {
      final hydratedBook = await provider.service.getBookInfo(
        source,
        searchBook.toBook(),
      );
      final chapters = await provider.service.getChapterList(
        source,
        hydratedBook,
      );
      var targetIndex = chapters.indexWhere(
        (c) => c.title == widget.chapterTitle,
      );
      if (targetIndex == -1 && widget.chapterIndex < chapters.length) {
        targetIndex = widget.chapterIndex;
      }

      if (!mounted) {
        dismissLoading();
        return;
      }

      if (targetIndex == -1) {
        dismissLoading();
        messenger.showSnackBar(const SnackBar(content: Text('找不到對應章節')));
        return;
      }

      if (hydratedBook.type != widget.book.type) {
        dismissLoading();
        if (!context.mounted) return;
        _showMigrationDialog(
          context,
          widget.book.migrateTo(hydratedBook, chapters),
        );
        return;
      }

      final content = await provider.service.getContent(
        source,
        hydratedBook,
        chapters[targetIndex],
        nextChapterUrl: _nextReadableChapterUrl(chapters, targetIndex),
      );
      if (!mounted) {
        dismissLoading();
        return;
      }

      dismissLoading();
      await _saveReplacementContent(chapters[targetIndex], content);
      await widget.onChapterContentChanged?.call();
      nav.pop(); // Pop sheet
    } catch (e) {
      if (mounted) {
        dismissLoading();
        messenger.showSnackBar(SnackBar(content: Text('換源失敗: $e')));
      }
    }
  }

  Future<void> _saveReplacementContent(
    BookChapter chapter,
    String content,
  ) async {
    if (!getIt.isRegistered<ReaderChapterContentDao>()) return;
    final normalized = chapter.copyWith(
      index: widget.chapterIndex,
      bookUrl: widget.book.bookUrl,
    );
    await ReaderChapterContentStore(
      chapterDao: getIt<ChapterDao>(),
      contentDao: getIt<ReaderChapterContentDao>(),
    ).saveRawContent(
      book: widget.book,
      chapter: normalized,
      content: content,
      saveChapterMetadata: false,
    );
  }

  String? _nextReadableChapterUrl(
    List<BookChapter> chapters,
    int currentIndex,
  ) {
    for (var i = currentIndex + 1; i < chapters.length; i++) {
      final chapter = chapters[i];
      if (!chapter.isVolume && chapter.url.isNotEmpty) {
        return chapter.url;
      }
    }
    return null;
  }

  void _showMigrationDialog(BuildContext context, Book newBook) {
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('書籍類型變更'),
            content: Text('偵測到新來源為${newBook.type == 2 ? "有聲" : "文本"}類型，是否遷移？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  nav.pop();
                  nav.pushReplacement(
                    MaterialPageRoute(
                      builder:
                          (_) => ReaderPage(
                            book: newBook,
                            openTarget: ReaderOpenTarget.resume(newBook),
                          ),
                    ),
                  );
                },
                child: const Text('遷移並跳轉'),
              ),
            ],
          ),
    );
  }
}
