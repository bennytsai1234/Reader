import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/features/reader/provider/change_source_provider.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/widgets/change_source_item.dart';

class ReaderSourceFallbackSheet extends StatefulWidget {
  final Book book;

  const ReaderSourceFallbackSheet({super.key, required this.book});

  static Future<void> show(BuildContext context, Book book) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderSourceFallbackSheet(book: book),
    );
  }

  @override
  State<ReaderSourceFallbackSheet> createState() =>
      _ReaderSourceFallbackSheetState();
}

class _ReaderSourceFallbackSheetState extends State<ReaderSourceFallbackSheet> {
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
          return Container(
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '切換閱讀來源',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          provider.checkAuthor
                              ? Icons.person
                              : Icons.person_off,
                        ),
                        tooltip: '校驗作者',
                        onPressed: provider.toggleCheckAuthor,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: '重新搜尋',
                        onPressed: provider.startSearch,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _filterController,
                    onChanged: provider.applyFilter,
                    decoration: InputDecoration(
                      hintText: '篩選來源名稱、作者或最新章節',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _filterController.text.isEmpty
                              ? null
                              : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _filterController.clear();
                                  provider.applyFilter('');
                                },
                              ),
                    ),
                  ),
                ),
                if (provider.isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.status,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Text(
                        '共 ${provider.filteredResults.length} 個來源',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      provider.filteredResults.isEmpty && !provider.isSearching
                          ? const Center(child: Text('沒有可用的替代來源'))
                          : ListView.separated(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: provider.filteredResults.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1, indent: 16),
                            itemBuilder: (context, index) {
                              final searchBook =
                                  provider.filteredResults[index];
                              final isCurrent =
                                  searchBook.origin == widget.book.origin;
                              return ChangeSourceItem(
                                searchBook: searchBook,
                                isCurrent: isCurrent,
                                onTap:
                                    isCurrent
                                        ? null
                                        : () => _handleSelected(
                                          context,
                                          searchBook,
                                        ),
                              );
                            },
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

  Future<void> _handleSelected(
    BuildContext context,
    SearchBook searchBook,
  ) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final readerProvider = context.read<ReaderProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var loadingVisible = true;

    void dismissLoading() {
      if (!loadingVisible || !nav.mounted) return;
      loadingVisible = false;
      nav.pop();
    }

    try {
      await readerProvider.changeBookSourceTo(searchBook);
      dismissLoading();
      if (context.mounted) {
        nav.pop();
      }
    } catch (error) {
      dismissLoading();
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('換源失敗: $error')));
      }
    }
  }
}
