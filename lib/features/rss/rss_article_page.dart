import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/models/rss_article.dart';
import 'rss_article_provider.dart';
import 'rss_read_page.dart';

class RssArticlePage extends StatelessWidget {
  final RssSource source;

  const RssArticlePage({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RssArticleProvider(source),
      child: Scaffold(
        appBar: AppBar(title: Text(source.sourceName)),
        body: Consumer<RssArticleProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.articles.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadArticles(refresh: true),
              child: source.articleStyle == 2
                  ? _buildGridView(context, provider)
                  : _buildListView(context, provider),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, RssArticleProvider provider) {
    return ListView.builder(
      itemCount: provider.articles.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.articles.length) {
          provider.loadArticles();
          return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
        }
        final article = provider.articles[index];
        return source.articleStyle == 1 
            ? _buildBigImageItem(context, provider, article) 
            : _buildSimpleListItem(context, provider, article);
      },
    );
  }

  Widget _buildGridView(BuildContext context, RssArticleProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: provider.articles.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.articles.length) {
          provider.loadArticles();
          return const Center(child: CircularProgressIndicator());
        }
        return _buildGridItem(context, provider, provider.articles[index]);
      },
    );
  }

  Widget _buildSimpleListItem(BuildContext context, RssArticleProvider p, RssArticle article) {
    final isStarred = p.isStarred(article);
    return ListTile(
      onTap: () => _navigateToRead(context, article),
      onLongPress: () => _showContextMenu(context, p, article),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isStarred) const Padding(padding: EdgeInsets.only(top: 2, right: 4), child: Icon(Icons.star, size: 14, color: Colors.amber)),
          Expanded(child: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
      subtitle: Text(article.pubDate ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: article.image != null && article.image!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(imageUrl: article.image!, width: 60, height: 60, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.rss_feed, size: 20)),
            )
          : null,
    );
  }

  Widget _buildBigImageItem(BuildContext context, RssArticleProvider p, RssArticle article) {
    final isStarred = p.isStarred(article);
    return InkWell(
      onTap: () => _navigateToRead(context, article),
      onLongPress: () => _showContextMenu(context, p, article),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.image != null && article.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: article.image!,
                  height: 150, width: double.infinity, fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (isStarred) const Icon(Icons.star, size: 18, color: Colors.amber),
                if (isStarred) const SizedBox(width: 6),
                Expanded(child: Text(article.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 4),
            if (article.description != null && article.description!.isNotEmpty)
              Text(article.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(article.pubDate ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, RssArticleProvider p, RssArticle article) {
    final isStarred = p.isStarred(article);
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToRead(context, article),
        onLongPress: () => _showContextMenu(context, p, article),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  article.image != null && article.image!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: article.image!, width: double.infinity, fit: BoxFit.cover, errorWidget: (_, __, ___) => _buildPlaceholder())
                      : _buildPlaceholder(),
                  if (isStarred) 
                    const Positioned(right: 4, top: 4, child: Icon(Icons.star, color: Colors.amber, size: 20)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(article.pubDate ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.rss_feed, color: Colors.white)));

  void _navigateToRead(BuildContext context, RssArticle article) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RssReadPage(source: source, article: article)));
  }

  void _showContextMenu(BuildContext context, RssArticleProvider p, RssArticle article) {
    final isStarred = p.isStarred(article);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isStarred ? Icons.star : Icons.star_border, color: isStarred ? Colors.amber : null),
              title: Text(isStarred ? '取消收藏' : '收藏文章'),
              onTap: () { p.toggleStar(article); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('複製連結'),
              onTap: () { Clipboard.setData(ClipboardData(text: article.link)); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('分享'),
              onTap: () {
                final box = context.findRenderObject() as RenderBox?;
                SharePlus.instance.share(ShareParams(
                  text: article.link,
                  sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
                ));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('瀏覽器開啟'),
              onTap: () async {
                final uri = Uri.tryParse(article.link);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
