import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/local_book/local_book_formats.dart';
import 'package:inkpage_reader/core/services/bookshelf_exchange_service.dart';
import 'package:inkpage_reader/core/services/restore_service.dart';
import 'package:inkpage_reader/core/widgets/book_cover_widget.dart';
import 'package:inkpage_reader/features/bookshelf/bookshelf_provider.dart';
import 'package:inkpage_reader/features/bookshelf/group_manage_page.dart';
import 'package:inkpage_reader/features/reader/reader_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_open_target.dart';
import 'package:inkpage_reader/features/search/search_page.dart';
import 'package:file_picker/file_picker.dart';
import 'widgets/group_select_dialog.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  bool _isMultiSelect = false;
  final Set<String> _selectedUrls = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookshelfProvider>().refreshBookshelf();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookshelfProvider>();
    return PopScope<void>(
      canPop: !_isMultiSelect,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_isMultiSelect) return;
        setState(() {
          _isMultiSelect = false;
          _selectedUrls.clear();
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              _isMultiSelect
                  ? Text('已選擇 ${_selectedUrls.length} 本')
                  : const Text('書架'),
          leading:
              _isMultiSelect
                  ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                        () => setState(() {
                          _isMultiSelect = false;
                          _selectedUrls.clear();
                        }),
                  )
                  : null,
          actions:
              _isMultiSelect
                  ? [
                    IconButton(
                      icon: const Icon(Icons.drive_file_move_outlined),
                      tooltip: '移入分組',
                      onPressed: () async {
                        final success = await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) =>
                                  GroupSelectDialog(bookUrls: _selectedUrls),
                        );
                        if (success == true) {
                          setState(() {
                            _isMultiSelect = false;
                            _selectedUrls.clear();
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_outlined),
                      tooltip: '批次下載',
                      onPressed:
                          _selectedUrls.isEmpty
                              ? null
                              : () => _batchDownload(context, provider),
                    ),
                    IconButton(
                      icon: const Icon(Icons.update),
                      tooltip: '批次檢查更新',
                      onPressed:
                          _selectedUrls.isEmpty
                              ? null
                              : () => _batchCheckUpdate(context, provider),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '刪除',
                      onPressed: () => _showDeleteConfirm(context, provider),
                    ),
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      tooltip: '全選',
                      onPressed:
                          () => setState(() {
                            if (_selectedUrls.length == provider.books.length) {
                              _selectedUrls.clear();
                            } else {
                              _selectedUrls.addAll(
                                provider.books.map((b) => b.bookUrl),
                              );
                            }
                          }),
                    ),
                  ]
                  : [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchPage(),
                            ),
                          ),
                    ),

                    PopupMenuButton<String>(
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'grid',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.view_quilt_outlined,
                                    size: 20,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(provider.isGridView ? '列表視圖' : '網格視圖'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add_local',
                              child: Row(
                                children: [
                                  Icon(Icons.file_open_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('添加本地'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add_url',
                              child: Row(
                                children: [
                                  Icon(Icons.link, size: 20),
                                  SizedBox(width: 12),
                                  Text('添加網址書籍'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'sort',
                              child: Row(
                                children: [
                                  Icon(Icons.sort, size: 20),
                                  SizedBox(width: 12),
                                  Text('排序'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'manage',
                              child: Row(
                                children: [
                                  Icon(Icons.format_list_bulleted, size: 20),
                                  SizedBox(width: 12),
                                  Text('書架管理'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'group_manage',
                              child: Row(
                                children: [
                                  Icon(Icons.groups_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('分組管理'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'import_url',
                              child: Row(
                                children: [
                                  Icon(Icons.file_download_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('從網址匯入書架'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'import',
                              child: Row(
                                children: [
                                  Icon(Icons.file_download_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('從檔案匯入書架'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'export',
                              child: Row(
                                children: [
                                  Icon(Icons.file_upload_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('匯出書架'),
                                ],
                              ),
                            ),
                          ],
                      onSelected: (value) async {
                        switch (value) {
                          case 'grid':
                            provider.setGridView(!provider.isGridView);
                            break;
                          case 'add_local':
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions:
                                  kSupportedLocalBookExtensions.toList()
                                    ..sort(),
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              if (!context.mounted) break;
                              await _importLocalBook(
                                context,
                                provider,
                                result.files.single.path!,
                              );
                            }
                            break;
                          case 'add_url':
                            await _showAddBookUrlDialog(context, provider);
                            break;
                          case 'sort':
                            await _showSortSheet(context, provider);
                            break;
                          case 'manage':
                            setState(() {
                              _isMultiSelect = true;
                            });
                            break;
                          case 'group_manage':
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GroupManagePage(),
                              ),
                            );
                            break;
                          case 'import':
                            await _handleBookshelfImport(context);
                            break;
                          case 'import_url':
                            await _showImportBookshelfUrlDialog(
                              context,
                              provider,
                            );
                            break;
                          case 'export':
                            await _handleBookshelfExport(context, provider);
                            break;
                        }
                      },
                    ),
                  ],
        ),
        body: Column(
          children: [
            if (!_isMultiSelect) _buildGroupBar(provider),
            Expanded(
              child:
                  provider.isLoading && provider.books.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : provider.books.isEmpty
                      ? const Center(child: Text('書架空空如也，去搜尋看看吧'))
                      : RefreshIndicator(
                        onRefresh: () => provider.refreshBookshelf(),
                        child:
                            provider.isGridView
                                ? _buildGridView(provider)
                                : _buildListView(provider),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importLocalBook(
    BuildContext context,
    BookshelfProvider provider,
    String path,
  ) async {
    try {
      final ok = await provider.importLocalBookPath(path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ok ? '匯入成功' : '匯入失敗')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('匯入失敗: $e')));
    }
  }

  Future<void> _showAddBookUrlDialog(
    BuildContext context,
    BookshelfProvider provider,
  ) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('添加網址書籍'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '輸入小說詳情頁網址'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('匯入'),
              ),
            ],
          ),
    );
    if (url == null || url.isEmpty || !context.mounted) return;
    try {
      final book = await provider.importBookFromUrl(url);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已加入「${book.name}」')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('添加網址書籍失敗: $e')));
    }
  }

  Future<void> _showImportBookshelfUrlDialog(
    BuildContext context,
    BookshelfProvider provider,
  ) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('從網址匯入書架'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '輸入書架 JSON 網址'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('匯入'),
              ),
            ],
          ),
    );
    if (url == null || url.isEmpty || !context.mounted) return;
    try {
      await provider.importBookshelfFromUrl(url);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('書架網址匯入完成')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('書架網址匯入失敗: $e')));
    }
  }

  Future<void> _handleBookshelfImport(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'zip'],
    );
    if (result == null ||
        result.files.single.path == null ||
        !context.mounted) {
      return;
    }
    final path = result.files.single.path!;
    try {
      if (path.toLowerCase().endsWith('.zip')) {
        final restored = await RestoreService().restoreFromZip(File(path));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(restored ? '備份還原完成，請重新開啟相關頁面確認資料' : '備份還原失敗')),
        );
      } else {
        final imported = await BookshelfExchangeService().importFromFile(
          File(path),
        );
        if (!context.mounted) return;
        context.read<BookshelfProvider>().loadBooks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已匯入 ${imported.books} 本書、${imported.chapters} 個章節、${imported.sources} 個書源'
              '${imported.contents > 0 ? '，${imported.contents} 份正文快取' : ''}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('匯入失敗: $e')));
    }
  }

  Future<void> _handleBookshelfExport(
    BuildContext context,
    BookshelfProvider provider,
  ) async {
    try {
      await BookshelfExchangeService().shareBookshelf(books: provider.books);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('書架已匯出')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('匯出失敗: $e')));
    }
  }

  Widget _buildGroupBar(BookshelfProvider provider) {
    final visibleGroups = provider.groups.where((group) => group.show).toList();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('全部'),
              selected: provider.currentGroupId == -1,
              onSelected: (_) => provider.setGroup(-1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('未分組'),
              selected: provider.currentGroupId == 0,
              onSelected: (_) => provider.setGroup(0),
            ),
          ),
          for (final group in visibleGroups)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(group.groupName),
                selected: provider.currentGroupId == group.groupId,
                onSelected: (_) => provider.setGroup(group.groupId),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showSortSheet(
    BuildContext context,
    BookshelfProvider provider,
  ) async {
    final selected = await showModalBottomSheet<BookshelfSortMode>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: RadioGroup<BookshelfSortMode>(
              groupValue: provider.sortMode,
              onChanged: (value) => Navigator.pop(ctx, value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mode in BookshelfSortMode.values)
                    ListTile(
                      leading: Radio<BookshelfSortMode>(value: mode),
                      title: Text(mode.label),
                      onTap: () => Navigator.pop(ctx, mode),
                    ),
                ],
              ),
            ),
          ),
    );
    if (selected != null) {
      await provider.setSortMode(selected);
    }
  }

  Future<void> _batchDownload(
    BuildContext context,
    BookshelfProvider provider,
  ) async {
    try {
      final result = await provider.batchDownload(_selectedUrls);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已加入 ${result.queuedBooks} 本、${result.queuedChapters} 章；略過 ${result.skippedBooks} 本',
          ),
        ),
      );
      setState(() {
        _isMultiSelect = false;
        _selectedUrls.clear();
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('批次下載失敗: $e')));
    }
  }

  Future<void> _batchCheckUpdate(
    BuildContext context,
    BookshelfProvider provider,
  ) async {
    try {
      final results = await provider.batchCheckUpdate(_selectedUrls);
      final updated = results.where((result) => result.hasUpdate).length;
      final chapters = results.fold<int>(
        0,
        (sum, result) => sum + result.newChapterCount,
      );
      final failed = results.where((result) => result.failed).length;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('檢查完成：$updated 本有更新、$chapters 個新章節、$failed 本失敗'),
        ),
      );
      setState(() {
        _isMultiSelect = false;
        _selectedUrls.clear();
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('批次檢查更新失敗: $e')));
    }
  }

  Widget _buildListView(BookshelfProvider provider) {
    if (!_isMultiSelect && provider.sortMode == BookshelfSortMode.custom) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.books.length,
        onReorder: provider.reorderBooks,
        itemBuilder:
            (context, index) => Padding(
              key: ValueKey(provider.books[index].bookUrl),
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBookItem(context, provider.books[index]),
            ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: provider.books.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder:
          (context, index) => _buildBookItem(context, provider.books[index]),
    );
  }

  Widget _buildGridView(BookshelfProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.books.length,
      itemBuilder:
          (context, index) => _buildGridItem(context, provider.books[index]),
    );
  }

  Widget _buildGridItem(BuildContext context, Book book) {
    final isSelected = _selectedUrls.contains(book.bookUrl);

    return InkWell(
      onLongPress:
          () => setState(() {
            _isMultiSelect = true;
            _selectedUrls.add(book.bookUrl);
          }),
      onTap: () {
        if (_isMultiSelect) {
          setState(() {
            isSelected
                ? _selectedUrls.remove(book.bookUrl)
                : _selectedUrls.add(book.bookUrl);
          });
        } else {
          _openBook(context, book);
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.72,
                child: BookCoverWidget(
                  bookName: book.name,
                  coverUrl: book.getDisplayCover(),
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: Text(
                  book.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_isMultiSelect)
            Positioned(
              right: 4,
              top: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue : Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookItem(BuildContext context, Book book) {
    final isSelected = _selectedUrls.contains(book.bookUrl);

    return InkWell(
      onLongPress:
          () => setState(() {
            _isMultiSelect = true;
            _selectedUrls.add(book.bookUrl);
          }),
      onTap: () {
        if (_isMultiSelect) {
          setState(() {
            isSelected
                ? _selectedUrls.remove(book.bookUrl)
                : _selectedUrls.add(book.bookUrl);
          });
        } else {
          _openBook(context, book);
        }
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            BookCoverWidget(
              bookName: book.name,
              coverUrl: book.getDisplayCover(),
              width: 80,
              height: 110,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                    ),
                    const Spacer(),
                    Text(
                      '讀至: ${book.durChapterTitle}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '最新: ${book.latestChapterTitle}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (_isMultiSelect)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openBook(BuildContext context, Book book) {
    if (book.type == 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('有聲書播放功能已移除，請選擇文本書籍。')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ReaderPage(
              book: book,
              openTarget: ReaderOpenTarget.resume(book),
            ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, BookshelfProvider p) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('確認刪除'),
            content: Text('是否從書架刪除這 ${_selectedUrls.length} 本書？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  for (var url in _selectedUrls) {
                    await p.removeFromBookshelf(url);
                  }
                  setState(() {
                    _isMultiSelect = false;
                    _selectedUrls.clear();
                  });
                },
                child: const Text('刪除'),
              ),
            ],
          ),
    );
  }
}
