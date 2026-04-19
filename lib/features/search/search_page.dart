import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'search_provider.dart';
import 'models/search_scope.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'widgets/search_app_bar.dart';
import 'widgets/search_history_view.dart';
import 'widgets/search_result_item.dart';
import 'widgets/search_scope_sheet.dart';

/// SearchPage - 搜尋頁面
/// (對標 Legado SearchActivity)
class SearchPage extends StatelessWidget {
  final String? initialQuery;
  final BookSource? initialSource;

  const SearchPage({super.key, this.initialQuery, this.initialSource});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: _SearchPageContent(
        initialQuery: initialQuery,
        initialSource: initialSource,
      ),
    );
  }
}

class _SearchPageContent extends StatefulWidget {
  final String? initialQuery;
  final BookSource? initialSource;

  const _SearchPageContent({this.initialQuery, this.initialSource});

  @override
  State<_SearchPageContent> createState() => _SearchPageContentState();
}

class _SearchPageContentState extends State<_SearchPageContent> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null || widget.initialSource != null) {
      _controller.text = widget.initialQuery ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<SearchProvider>();
        if (widget.initialSource != null) {
          provider.searchInSource(widget.initialSource!, _controller.text);
        } else if (_controller.text.isNotEmpty) {
          provider.search(_controller.text);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    if (value.isNotEmpty) {
      context.read<SearchProvider>().search(value);
    }
  }

  void _openScopeSheet() {
    final provider = context.read<SearchProvider>();
    SearchScopeSheet.show(
      context,
      currentScope: provider.searchScope,
      groups: provider.sourceGroups,
      onScopeChanged: (newScope) {
        provider.updateSearchScope(newScope);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: SearchAppBar(
            controller: _controller,
            provider: provider,
            onSearch: _onSearch,
            onScopePressed: _openScopeSheet,
          ),
          body: Column(
            children: [
              // 搜尋進度
              if (provider.isSearching) ...[
                LinearProgressIndicator(
                  value: provider.progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                _buildCurrentSourcePanel(provider),
              ],
              // 失敗書源提示
              if (!provider.isSearching && provider.failedSources > 0)
                _buildFailedSourcesPanel(provider),
              // 篩選狀態提示
              if (provider.precisionSearch || !provider.searchScope.isAll)
                _buildFilterStatusPanel(provider),
              // 主體內容
              Expanded(
                child:
                    provider.results.isEmpty && !provider.isSearching
                        ? _buildEmptyOrHistory(provider)
                        : _buildResults(provider),
              ),
            ],
          ),
          // FAB 開始/停止搜尋 (對標 Legado fb_start_stop)
          floatingActionButton:
              provider.lastSearchKey.isNotEmpty
                  ? FloatingActionButton(
                    mini: true,
                    onPressed:
                        () =>
                            provider.isSearching
                                ? provider.stopSearch()
                                : provider.search(provider.lastSearchKey),
                    child: Icon(
                      provider.isSearching ? Icons.stop : Icons.refresh,
                    ),
                  )
                  : null,
        );
      },
    );
  }

  Widget _buildEmptyOrHistory(SearchProvider provider) {
    if (provider.lastSearchKey.isNotEmpty && provider.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '找不到相關書籍',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (provider.precisionSearch)
              ElevatedButton(
                onPressed: () => provider.togglePrecisionSearch(),
                child: const Text('關閉精準搜尋並重試'),
              ),
            if (!provider.searchScope.isAll) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed:
                    () => provider.updateSearchScope(
                      provider.searchScope..updateAll(),
                    ),
                child: Text('「${provider.searchScope.display}」結果為空，切換至全部書源'),
              ),
            ],
          ],
        ),
      );
    }
    return SearchHistoryView(
      provider: provider,
      controller: _controller,
      onSearch: _onSearch,
    );
  }

  Widget _buildFailedSourcesPanel(SearchProvider p) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    width: double.infinity,
    color: Colors.red.withValues(alpha: 0.08),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
        const SizedBox(width: 8),
        Text(
          '${p.failedSources} 個書源搜尋失敗（共 ${p.totalSources} 個）',
          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
        ),
      ],
    ),
  );

  Widget _buildCurrentSourcePanel(SearchProvider p) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    width: double.infinity,
    color: Colors.blue.withValues(alpha: 0.05),
    child: Text(
      '正在搜尋: ${p.currentSource}  (${p.progress * 100 ~/ 1}%)',
      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _buildFilterStatusPanel(SearchProvider p) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    color: Colors.orange.withValues(alpha: 0.1),
    child: Row(
      children: [
        Icon(Icons.filter_alt, size: 14, color: Colors.orange.shade800),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '已開啟: ${p.precisionSearch ? "精準搜尋" : ""} ${!p.searchScope.isAll ? "範圍(${p.searchScope.display})" : ""}',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (p.precisionSearch) p.togglePrecisionSearch();
            if (!p.searchScope.isAll) {
              p.updateSearchScope(SearchScope());
            }
          },
          child: Text(
            '全部重設',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildResults(SearchProvider p) => ListView.separated(
    itemCount: p.results.length,
    separatorBuilder: (ctx, i) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final book = p.results[i];
      return SearchResultItem(
        result: AggregatedSearchBook(
          book: book,
          sources:
              book.sourceLabels.isNotEmpty
                  ? book.sourceLabels
                  : [book.originName ?? '未知來源'],
        ),
        isInBookshelf: p.isInBookshelf(book),
      );
    },
  );
}
