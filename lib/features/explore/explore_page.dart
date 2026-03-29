import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'explore_provider.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/features/search/widgets/search_result_item.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreProvider(),
      child: const _ExplorePageContent(),
    );
  }
}

class _ExplorePageContent extends StatelessWidget {
  const _ExplorePageContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('發現'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: '切換書源',
            onPressed: () => _showSourcePicker(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.selectedSource != null) _buildFilterBar(context, provider),
          Expanded(
            child: _buildBookList(context, provider),
          ),
        ],
      ),
    );
  }

  /// 多級聯動過濾條 (對標 Android ExploreShowActivity 頂部標籤)
  Widget _buildFilterBar(BuildContext context, ExploreProvider p) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(
        children: [
          // 第一行：分組 (如果存在)
          if (p.groups.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: p.groups.length,
                itemBuilder: (ctx, i) {
                  final group = p.groups[i];
                  final isSelected = p.selectedGroup == group;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(group, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (v) => p.setGroup(group),
                    ),
                  );
                },
              ),
            ),
          // 第二行：具體分類
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: p.filteredKinds.length,
              itemBuilder: (ctx, i) {
                final kind = p.filteredKinds[i];
                final isSelected = p.selectedKind == kind;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(kind.title, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (v) => p.setKind(kind),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildBookList(BuildContext context, ExploreProvider p) {
    if (p.isLoading && p.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (p.errorMessage != null && p.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(p.errorMessage!, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => p.refreshExplore(),
              icon: const Icon(Icons.refresh),
              label: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (p.books.isEmpty) {
      return const Center(child: Text('暫無內容，請嘗試切換分類或書源'));
    }

    return RefreshIndicator(
      onRefresh: () => p.refreshExplore(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollNotification(scrollInfo)) {
            p.loadMore();
          }
          return true;
        },
        child: ListView.separated(
          itemCount: p.books.length + (p.isLoading ? 1 : 0),
          separatorBuilder: (ctx, i) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            if (i == p.books.length) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }
            return SearchResultItem(result: AggregatedSearchBook(book: p.books[i], sources: [p.selectedSource!.bookSourceName]));
          },
        ),
      ),
    );
  }

  bool scrollNotification(ScrollNotification scrollInfo) {
    return scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200;
  }

  void _showSourcePicker(BuildContext context, ExploreProvider p) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('選擇探索書源', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: p.sources.length,
                itemBuilder: (ctx, i) {
                  final s = p.sources[i];
                  return ListTile(
                    title: Text(s.bookSourceName),
                    subtitle: Text(s.bookSourceUrl),
                    selected: p.selectedSource?.bookSourceUrl == s.bookSourceUrl,
                    onTap: () {
                      p.setSource(s);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
