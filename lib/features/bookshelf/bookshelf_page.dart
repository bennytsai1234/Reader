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
import 'package:inkpage_reader/features/reader/reader_provider.dart';
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
    return Scaffold(
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
                            (ctx) => GroupSelectDialog(bookUrls: _selectedUrls),
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
                          MaterialPageRoute(builder: (_) => const SearchPage()),
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
                                Text('添加網址'),
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
                            value: 'import',
                            child: Row(
                              children: [
                                Icon(Icons.file_download_outlined, size: 20),
                                SizedBox(width: 12),
                                Text('匯入書架'),
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
                                kSupportedLocalBookExtensions.toList()..sort(),
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
                          await _showAddUrlDialog(context, provider);
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

  Future<void> _showAddUrlDialog(
    BuildContext context,
    BookshelfProvider provider,
  ) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('從網址匯入'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '輸入匯入網址'),
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
      ).showSnackBar(const SnackBar(content: Text('網址匯入完成')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('網址匯入失敗: $e')));
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
              '已匯入 ${imported.books} 本書、${imported.chapters} 個章節、${imported.sources} 個書源',
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

  Widget _buildListView(BookshelfProvider provider) {
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
            (_) => ChangeNotifierProvider(
              create:
                  (ctx) => ReaderProvider(
                    book: book,
                    chapterIndex: book.durChapterIndex,
                    chapterPos: book.durChapterPos,
                  ),
              child: ReaderPage(
                book: book,
                chapterIndex: book.durChapterIndex,
                chapterPos: book.durChapterPos,
              ),
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
