import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/engine/web_book/book_list_parser.dart';
import 'package:legado_reader/core/engine/web_book/book_info_parser.dart';
import 'package:legado_reader/core/engine/web_book/chapter_list_parser.dart';
import 'package:legado_reader/core/engine/web_book/content_parser.dart';
import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:legado_reader/core/network/str_response.dart';

/// WebBook - 書源抓取業務調度 (對標 Android model/webBook/WebBook.kt)
///
/// 注意：不使用 Isolate.run()，因為 AnalyzeRule 可能呼叫 JS 引擎 (flutter_js FFI)，
/// 而 FFI 綁定無法跨 Isolate 傳遞。解析操作本身是輕量的字串處理，不會阻塞 UI。
class WebBook {
  WebBook._();

  /// 目錄翻頁上限，防止無限迴圈
  static const int _maxTocPages = 100;
  /// 正文翻頁上限
  static const int _maxContentPages = 20;

  /// 搜尋書籍 (對標 searchBookAwait)
  static Future<List<SearchBook>> searchBookAwait(
    BookSource source,
    String key, {
    int? page = 1,
    bool Function(String name, String author)? filter,
  }) async {
    final searchUrl = source.searchUrl;
    if (searchUrl == null || searchUrl.isEmpty) {
      throw Exception('搜尋 URL 不能為空');
    }

    if (BookSourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final analyzeUrl = AnalyzeUrl(
      searchUrl,
      source: source,
      key: key,
      page: page,
    );

    var res = await analyzeUrl.getStrResponse();
    res = _runLoginCheckJs(source, res);
    _checkRedirect(source, res);

    final results = BookListParser.parse(
      source: source,
      body: res.body,
      baseUrl: res.url,
      isSearch: true,
    );

    if (filter != null) {
      return results.where((b) => filter(b.name, b.author ?? '')).toList();
    }
    return results;
  }

  /// 探索書籍 (對標 exploreBookAwait)
  static Future<List<SearchBook>> exploreBookAwait(
    BookSource source,
    String url, {
    int? page = 1,
  }) async {
    if (BookSourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final analyzeUrl = AnalyzeUrl(url, source: source, page: page);
    var res = await analyzeUrl.getStrResponse();
    res = _runLoginCheckJs(source, res);
    _checkRedirect(source, res);

    return BookListParser.parse(
      source: source,
      body: res.body,
      baseUrl: res.url,
      isSearch: false,
    );
  }

  /// 獲取書籍資訊 (對標 getBookInfoAwait)
  static Future<Book> getBookInfoAwait(
    BookSource source,
    Book book, {
    bool canReName = true,
  }) async {
    if (BookSourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    if (book.infoHtml != null && book.infoHtml!.isNotEmpty) {
      return BookInfoParser.parse(
        source: source,
        book: book,
        body: book.infoHtml!,
        baseUrl: book.bookUrl,
      );
    }

    final analyzeUrl = AnalyzeUrl(book.bookUrl, source: source, ruleData: book);
    var res = await analyzeUrl.getStrResponse();
    res = _runLoginCheckJs(source, res, ruleData: book);
    _checkRedirect(source, res);

    return BookInfoParser.parse(
      source: source,
      book: book,
      body: res.body,
      baseUrl: res.url,
    );
  }

  /// 獲取目錄列表 (對標 getChapterListAwait)
  /// 支援 nextTocUrl 多頁目錄自動翻頁
  static Future<List<BookChapter>> getChapterListAwait(
    BookSource source,
    Book book,
  ) async {
    if (BookSourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final rule = AnalyzeRule(source: source, ruleData: book);
    await rule.preUpdateToc();

    final allChapters = <BookChapter>[];
    final visitedUrls = <String>{};
    String? currentUrl = book.tocUrl;

    for (var pageNum = 0; pageNum < _maxTocPages && currentUrl != null; pageNum++) {
      if (visitedUrls.contains(currentUrl)) break;
      visitedUrls.add(currentUrl);

      final analyzeUrl = AnalyzeUrl(currentUrl, source: source, ruleData: book);
      var res = await analyzeUrl.getStrResponse();
      res = _runLoginCheckJs(source, res, ruleData: book);
      _checkRedirect(source, res);

      final result = ChapterListParser.parse(
        source: source,
        book: book,
        body: res.body,
        baseUrl: res.url,
      );

      allChapters.addAll(result.chapters);
      currentUrl = result.nextUrl;
    }

    // 重新編號所有章節
    for (var i = 0; i < allChapters.length; i++) {
      allChapters[i] = allChapters[i].copyWith(index: i);
    }

    return allChapters;
  }

  /// 獲取正文內容 (對標 getContentAwait)
  /// 支援 nextContentUrl 多頁正文自動翻頁
  static Future<String> getContentAwait(
    BookSource source,
    Book book,
    BookChapter chapter, {
    String? nextChapterUrl,
  }) async {
    if (BookSourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final contentParts = <String>[];
    final visitedUrls = <String>{};
    String? currentUrl = chapter.url;

    for (var pageNum = 0; pageNum < _maxContentPages && currentUrl != null; pageNum++) {
      if (visitedUrls.contains(currentUrl)) break;
      visitedUrls.add(currentUrl);

      final analyzeUrl = AnalyzeUrl(currentUrl, source: source, ruleData: book);
      var res = await analyzeUrl.getStrResponse();
      res = _runLoginCheckJs(source, res, ruleData: book);
      _checkRedirect(source, res);

      final result = ContentParser.parse(
        source: source,
        body: res.body,
        baseUrl: res.url,
        nextChapterUrl: nextChapterUrl,
      );

      if (result.content.isNotEmpty) {
        contentParts.add(result.content);
      }
      currentUrl = result.nextUrl;
    }

    return contentParts.join('\n');
  }

  /// 執行登入檢查 JS Hook (統一抽取)
  static StrResponse _runLoginCheckJs(BookSource source, StrResponse res, {dynamic ruleData}) {
    final checkJs = source.loginCheckJs;
    if (checkJs != null && checkJs.isNotEmpty) {
      final rule = AnalyzeRule(source: source, ruleData: ruleData);
      final evalRes = rule.evalJS(checkJs, res);
      if (evalRes is StrResponse) {
        return evalRes;
      }
    }
    return res;
  }

  /// 重定向檢查 (對標 Android WebBook.checkRedirect)
  static void _checkRedirect(BookSource source, StrResponse res) {
    if (res.isRedirect) {
      debugPrint('WebBook: 偵測到重定向 → ${res.url}');
    }
  }
}
