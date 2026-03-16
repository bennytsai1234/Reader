import 'package:legado_reader/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/models/rss_article.dart';
import 'package:legado_reader/core/models/rss_star.dart';
import 'package:legado_reader/core/database/dao/rss_star_dao.dart';
import 'package:legado_reader/core/services/rss_parser.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';

class RssReadPage extends StatefulWidget {
  final RssSource source;
  final RssArticle article;

  const RssReadPage({super.key, required this.source, required this.article});

  @override
  State<RssReadPage> createState() => _RssReadPageState();
}

class _RssReadPageState extends State<RssReadPage> {
  late final WebViewController _controller;
  bool _useWebView = true;
  String? _parsedContent;
  bool _isLoading = true;
  
  bool _isFavorite = false;
  final RssStarDao _starDao = getIt<RssStarDao>();
  RssStar? _star;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _useWebView = widget.source.ruleContent == null || widget.source.ruleContent!.isEmpty;
    
    if (_useWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _controller.runJavaScript(
                  "var style = document.createElement('style'); style.innerHTML = 'img { max-width: 100%; height: auto; } body { padding: 10px; font-size: 16px; }'; document.head.appendChild(style);"
              );
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.article.link));
      _isLoading = false;
    } else {
      _loadParsedContent();
    }
  }

  Future<void> _checkFavorite() async {
    final stars = await _starDao.getAll();
    try {
      _star = stars.firstWhere((s) => s.link == widget.article.link);
      if (mounted) setState(() => _isFavorite = true);
    } catch (_) {
      if (mounted) setState(() => _isFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_isFavorite && _star != null) {
      await _starDao.deleteByLink(_star!.origin, _star!.link);
      setState(() { _isFavorite = false; _star = null; });
      messenger.showSnackBar(const SnackBar(content: Text('已取消收藏')));
    } else {
      final newStar = RssStar(
        origin: widget.source.sourceUrl,
        title: widget.article.title,
        link: widget.article.link,
        pubDate: widget.article.pubDate,
        description: widget.article.description,
        image: widget.article.image,
      );
      await _starDao.upsert(newStar);
      setState(() { _isFavorite = true; _star = newStar; });
      messenger.showSnackBar(const SnackBar(content: Text('已加入收藏')));
    }
  }

  Future<void> _loadParsedContent() async {
    try {
      final analyzeUrl = AnalyzeUrl(widget.article.link);
      final body = await analyzeUrl.getResponseBody();
      final content = await RssParser.parseContent(widget.source, body, widget.article.link);
      setState(() { _parsedContent = content; _isLoading = false; });
    } catch (e) {
      setState(() { _parsedContent = '加載內容失敗: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.title),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: _isFavorite ? Colors.amber : null),
            onPressed: _toggleFavorite,
            tooltip: '收藏',
          ),
          IconButton(
            icon: Icon(_useWebView ? Icons.article_outlined : Icons.language_outlined),
            onPressed: () => setState(() => _useWebView = !_useWebView),
            tooltip: _useWebView ? '查看解析內容' : '查看原始網頁',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined, size: 20), SizedBox(width: 12), Text('分享')])),
              const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.content_copy, size: 20), SizedBox(width: 12), Text('複製鏈接')])),
              const PopupMenuItem(value: 'browser', child: Row(children: [Icon(Icons.open_in_browser, size: 20), SizedBox(width: 12), Text('瀏覽器開啟')])),
            ],
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _useWebView 
          ? WebViewWidget(controller: _controller)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(_parsedContent ?? '', style: const TextStyle(fontSize: 16, height: 1.6)),
            ),
    );
  }

  void _handleMenuAction(String value) async {
    final link = widget.article.link;
    final box = context.findRenderObject() as RenderBox?;
    final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    switch (value) {
      case 'share':
        await SharePlus.instance.share(ShareParams(
          text: link,
          subject: '分享文章: ${widget.article.title}',
          sharePositionOrigin: rect,
        ));
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: link));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('鏈接已複製')));
        break;
      case 'browser':
        final uri = Uri.tryParse(link);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
    }
  }
}
