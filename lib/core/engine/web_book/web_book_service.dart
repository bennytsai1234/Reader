import 'dart:isolate';
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
class WebBook {
  WebBook._();

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

    // 獲取響應
    var res = await analyzeUrl.getStrResponse();

    // 執行登入檢查 JS Hook (對標 Android WebBook.kt line 85)
    final checkJs = source.loginCheckJs;
    if (checkJs != null && checkJs.isNotEmpty) {
      final rule = AnalyzeRule(source: source);
      final evalRes = rule.evalJS(checkJs, res);
      if (evalRes is StrResponse) {
        res = evalRes;
      }
    }

    _checkRedirect(source, res);

    // 解析 (利用 Isolate 避免阻塞 UI)
    final results = await Isolate.run(() => BookListParser.parse(
      source: source,
      body: res.body,
      baseUrl: res.url,
      isSearch: true,
    ));

    // 過濾
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

    // 執行登入檢查 JS Hook
    final checkJs = source.loginCheckJs;
    if (checkJs != null && checkJs.isNotEmpty) {
      final rule = AnalyzeRule(source: source);
      final evalRes = rule.evalJS(checkJs, res);
      if (evalRes is StrResponse) {
        res = evalRes;
      }
    }

    _checkRedirect(source, res);

    return Isolate.run(() => BookListParser.parse(
      source: source,
      body: res.body,
      baseUrl: res.url,
      isSearch: false,
    ));
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

    // 如果已經有緩存的 HTML (對標 Android WebBook.kt line 164)
    if (book.infoHtml != null && book.infoHtml!.isNotEmpty) {
      return Isolate.run(() => BookInfoParser.parse(
        source: source,
        book: book,
        body: book.infoHtml!,
        baseUrl: book.bookUrl,
      ));
    }

    final analyzeUrl = AnalyzeUrl(book.bookUrl, source: source, ruleData: book);
    var res = await analyzeUrl.getStrResponse();

    // 執行登入檢查 JS Hook
    final checkJs = source.loginCheckJs;
    if (checkJs != null && checkJs.isNotEmpty) {
      final rule = AnalyzeRule(source: source, ruleData: book);
      final evalRes = rule.evalJS(checkJs, res);
      if (evalRes is StrResponse) {
        res = evalRes;
      }
    }

    _checkRedirect(source, res);

    return Isolate.run(() => BookInfoParser.parse(
      source: source,
      book: book,
      body: res.body,
      baseUrl: res.url,
    ));
  }

  /// 獲取目錄列表 (對標 getChapterListAwait)
  static Future<List<BookChapter>> getChapterListAwait(
    BookSource source,
    Book book,
  ) async {
    if (BookSourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final analyzeUrl = AnalyzeUrl(book.tocUrl, source: source, ruleData: book);
    final rule = AnalyzeRule(source: source, ruleData: book);
    
    // 預處理 Hook (對標 Android WebBook.kt line 231)
    await rule.preUpdateToc();

    var res = await analyzeUrl.getStrResponse();

    // 執行登入檢查 JS Hook
    final checkJs = source.loginCheckJs;
    if (checkJs != null && checkJs.isNotEmpty) {
      final evalRes = rule.evalJS(checkJs, res);
      if (evalRes is StrResponse) {
        res = evalRes;
      }
    }

    _checkRedirect(source, res);

    return Isolate.run(() => ChapterListParser.parse(
      source: source,
      book: book,
      body: res.body,
      baseUrl: res.url,
    ));
  }

  /// 獲取正文內容 (對標 getContentAwait)
  static Future<String> getContentAwait(
    BookSource source,
    Book book,
    BookChapter chapter, {
    String? nextChapterUrl,
  }) async {
    if (BookSourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final analyzeUrl = AnalyzeUrl(chapter.url, source: source, ruleData: book);
    var res = await analyzeUrl.getStrResponse();

    // 執行登入檢查 JS Hook
    final checkJs = source.loginCheckJs;
    if (checkJs != null && checkJs.isNotEmpty) {
      final rule = AnalyzeRule(source: source, ruleData: book);
      final evalRes = rule.evalJS(checkJs, res);
      if (evalRes is StrResponse) {
        res = evalRes;
      }
    }

    _checkRedirect(source, res);

    return Isolate.run(() => ContentParser.parse(
      source: source,
      body: res.body,
      baseUrl: res.url,
      nextChapterUrl: nextChapterUrl,
    ));
  }

  /// 重定向檢查 (對標 Android WebBook.checkRedirect)
  static void _checkRedirect(BookSource source, StrResponse res) {
    // 實作重定向偵測邏輯，如果重定向到了登入頁面，應拋出異常或更新 Cookie
    if (res.isRedirect) {
      // 這裡可以加入具體的重定向攔截邏輯
    }
  }
}
