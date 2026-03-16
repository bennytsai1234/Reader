import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/features/bookshelf/bookshelf_provider.dart';
import 'package:legado_reader/features/reader/reader_page.dart';
import 'package:legado_reader/features/search/search_page.dart';
import 'package:legado_reader/features/explore/explore_page.dart';
import 'package:legado_reader/features/source_manager/source_manager_page.dart';
import 'package:legado_reader/features/settings/settings_page.dart';
import 'package:legado_reader/features/reader/audio_player_page.dart';
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
        title: _isMultiSelect ? Text('已選擇 ${_selectedUrls.length} 本') : const Text('書架'),
        leading: _isMultiSelect ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isMultiSelect = false; _selectedUrls.clear(); })) : null,
        actions: _isMultiSelect 
          ? [
              IconButton(
                icon: const Icon(Icons.drive_file_move_outlined), 
                tooltip: '移入分組',
                onPressed: () async {
                  final success = await showDialog<bool>(
                    context: context, 
                    builder: (ctx) => GroupSelectDialog(bookUrls: _selectedUrls)
                  );
                  if (success == true) {
                    setState(() { _isMultiSelect = false; _selectedUrls.clear(); });
                  }
                }
              ),
              IconButton(icon: const Icon(Icons.delete_outline), tooltip: '刪除', onPressed: () => _showDeleteConfirm(context, provider)),
              IconButton(icon: const Icon(Icons.select_all), tooltip: '全選', onPressed: () => setState(() {
                if (_selectedUrls.length == provider.books.length) { _selectedUrls.clear(); }
                else { _selectedUrls.addAll(provider.books.map((b) => b.bookUrl)); }
              })),
            ]
          : [
              IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()))),
              IconButton(icon: const Icon(Icons.explore), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage()))),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'grid', child: Row(children: [Icon(Icons.view_quilt_outlined, size: 20, color: Theme.of(context).iconTheme.color), const SizedBox(width: 12), Text(provider.isGridView ? '列表視圖' : '網格視圖')])),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'update_toc', child: Row(children: [Icon(Icons.refresh, size: 20), SizedBox(width: 12), Text('更新目錄')])),
                  const PopupMenuItem(value: 'add_local', child: Row(children: [Icon(Icons.file_open_outlined, size: 20), SizedBox(width: 12), Text('添加本地')])),
                  const PopupMenuItem(value: 'add_url', child: Row(children: [Icon(Icons.link, size: 20), SizedBox(width: 12), Text('添加網址')])),
                  const PopupMenuItem(value: 'manage', child: Row(children: [Icon(Icons.format_list_bulleted, size: 20), SizedBox(width: 12), Text('書架管理')])),
                  const PopupMenuItem(value: 'group_manage', child: Row(children: [Icon(Icons.groups_outlined, size: 20), SizedBox(width: 12), Text('分組管理')])),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'import', child: Row(children: [Icon(Icons.file_download_outlined, size: 20), SizedBox(width: 12), Text('匯入書架')])),
                  const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.file_upload_outlined, size: 20), SizedBox(width: 12), Text('匯出書架')])),
                  const PopupMenuItem(value: 'log', child: Row(children: [Icon(Icons.bug_report_outlined, size: 20), SizedBox(width: 12), Text('日誌')])),
                ],
import 'package:file_picker/file_picker.dart';
...
                onSelected: (value) async {
                  switch (value) {
                    case 'grid': provider.setGridView(!provider.isGridView); break;
                    case 'update_toc': ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在背景更新...'))); break;
                    case 'add_local': 
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['txt', 'epub'],
                      );
                      if (result != null && result.files.single.path != null) {
                        await provider.importLocalBookPath(result.files.single.path!);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在解析本地書籍...')));
                      }
                      break;
                    case 'manage': setState(() { _isMultiSelect = true; }); break;
                    case 'group_manage': ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分組管理開發中'))); break;
                    case 'log': Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())); break; // 暫代
                  }
                },
              ),
            ],
      ),
      body: Column(
        children: [
          if (!_isMultiSelect) _buildGroupTabs(provider),
          Expanded(
            child: provider.isLoading && provider.books.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.books.isEmpty
                    ? const Center(child: Text('書架空空如也，去搜尋看看吧'))
                    : RefreshIndicator(
                        onRefresh: () => provider.refreshBookshelf(),
                        child: provider.isGridView ? _buildGridView(provider) : _buildListView(provider),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTabs(BookshelfProvider p) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: p.groups.length + 2,
        itemBuilder: (context, index) {
          int gid;
          String name;
          if (index == 0) { gid = -1; name = '全部'; }
          else if (index == 1) { gid = 0; name = '未分組'; }
          else {
            final g = p.groups[index - 2];
            gid = g.groupId;
            name = g.groupName;
          }

          final isSelected = p.currentGroupId == gid;
          final count = p.groupCounts[gid] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('$name ($count)'),
              selected: isSelected,
              onSelected: (_) => p.setGroup(gid),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView(BookshelfProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: provider.books.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildBookItem(context, provider.books[index]),
    );
  }

  Widget _buildGridView(BookshelfProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        childAspectRatio: 0.55, 
        crossAxisSpacing: 12, 
        mainAxisSpacing: 12
      ),
      itemCount: provider.books.length,
      itemBuilder: (context, index) => _buildGridItem(context, provider.books[index]),
    );
  }

  Widget _buildGridItem(BuildContext context, Book book) {
    final isSelected = _selectedUrls.contains(book.bookUrl);
    return InkWell(
      onLongPress: () => setState(() { _isMultiSelect = true; _selectedUrls.add(book.bookUrl); }),
      onTap: () {
        if (_isMultiSelect) {
          setState(() { isSelected ? _selectedUrls.remove(book.bookUrl) : _selectedUrls.add(book.bookUrl); });
        } else {
          _openBook(context, book);
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: book.coverUrl ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
                    errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(book.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          if (_isMultiSelect) 
            Positioned(
              right: 4, 
              top: 4, 
              child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.blue : Colors.white)
            ),
        ],
      ),
    );
  }

  Widget _buildBookItem(BuildContext context, Book book) {
    final isSelected = _selectedUrls.contains(book.bookUrl);
    return InkWell(
      onLongPress: () => setState(() { _isMultiSelect = true; _selectedUrls.add(book.bookUrl); }),
      onTap: () {
        if (_isMultiSelect) {
          setState(() { isSelected ? _selectedUrls.remove(book.bookUrl) : _selectedUrls.add(book.bookUrl); });
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: CachedNetworkImage(
                imageUrl: book.coverUrl ?? '',
                width: 80, height: 110, fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(width: 80, color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(book.author, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1),
                    const Spacer(),
                    Text('讀至: ${book.durChapterTitle}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('最新: ${book.latestChapterTitle}', style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            if (_isMultiSelect) Padding(padding: const EdgeInsets.all(8.0), child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  void _openBook(BuildContext context, Book book) {
    if (book.type == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AudioPlayerPage(book: book, chapterIndex: book.durChapterIndex)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(book: book, chapterIndex: book.durChapterIndex, chapterPos: book.durChapterPos)));
    }
  }

  void _showDeleteConfirm(BuildContext context, BookshelfProvider p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('確認刪除'),
      content: Text('是否從書架刪除這 ${_selectedUrls.length} 本書？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          for (var url in _selectedUrls) { await p.removeFromBookshelf(url); }
          setState(() { _isMultiSelect = false; _selectedUrls.clear(); });
        }, child: const Text('刪除')),
      ],
    ));
  }
}

