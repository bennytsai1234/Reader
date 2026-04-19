import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'explore_show_provider.dart';
import 'widgets/explore_book_item.dart';

/// ExploreShowPage - 探索結果列表頁面
/// (對標 Android ExploreShowActivity)
///
/// 顯示某個書源的某個分類下的書籍列表，支援無限滾動加載。
class ExploreShowPage extends StatelessWidget {
  final String sourceUrl;
  final String exploreUrl;
  final String exploreName;

  const ExploreShowPage({
    super.key,
    required this.sourceUrl,
    required this.exploreUrl,
    required this.exploreName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => ExploreShowProvider(
            sourceUrl: sourceUrl,
            exploreUrl: exploreUrl,
            exploreName: exploreName,
          ),
      child: _ExploreShowContent(exploreName: exploreName),
    );
  }
}

class _ExploreShowContent extends StatelessWidget {
  final String exploreName;

  const _ExploreShowContent({required this.exploreName});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreShowProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(exploreName)),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, ExploreShowProvider provider) {
    // 初始載入中
    if (provider.isLoading && provider.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 錯誤且無數據
    if (provider.errorMessage != null && provider.books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('重試'),
              ),
            ],
          ),
        ),
      );
    }

    // 空數據
    if (provider.isEmpty) {
      return const Center(
        child: Text('暫無內容', style: TextStyle(color: Colors.grey)),
      );
    }

    // 書籍列表 (對標 Android ExploreShowActivity RecyclerView)
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        itemCount: provider.books.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.books.length) {
            // LoadMore 指示器 (對標 Android LoadMoreView)
            provider.loadMore();
            return _buildLoadMoreIndicator(provider);
          }
          return ExploreBookItem(
            book: provider.books[index],
            isInBookshelf: provider.isInBookshelf(provider.books[index]),
            sourceName: exploreName,
          );
        },
      ),
    );
  }

  /// 載入更多指示器 (對標 Android LoadMoreView)
  Widget _buildLoadMoreIndicator(ExploreShowProvider provider) {
    if (provider.errorMessage != null) {
      return InkWell(
        onTap: () => provider.loadMore(),
        child: Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text(
            '載入失敗，點擊重試',
            style: TextStyle(color: Colors.red[400], fontSize: 13),
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
