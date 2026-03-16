import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/engine/book/book_help.dart';
import 'package:legado_reader/core/engine/web_book/book_info_parser.dart';
import 'package:legado_reader/core/utils/string_utils.dart';
import 'package:legado_reader/core/utils/html_formatter.dart';

class BookListParser {
  static List<SearchBook> parse({
    required BookSource source,
    required String body,
    required String baseUrl,
    required bool isSearch,
  }) {
    // 1. 偵測 bookUrlPattern (對標 Android BookList.analyzeBookList)
    if (isSearch && source.bookUrlPattern?.isNotEmpty == true) {
      try {
        if (RegExp(source.bookUrlPattern!).hasMatch(baseUrl)) {
          final searchBook = _getInfoItem(source: source, body: body, baseUrl: baseUrl);
          if (searchBook != null) {
            return [searchBook];
          }
        }
      } catch (_) {}
    }

    final rule = AnalyzeRule(source: source).setContent(body, baseUrl: baseUrl);
    final dynamic listRule = isSearch ? source.ruleSearch : source.ruleExplore;
    if (listRule == null) return [];

    String ruleList = listRule.bookList ?? '';
    var isReverse = false;
    if (ruleList.startsWith('-')) {
      isReverse = true;
      ruleList = ruleList.substring(1);
    }
    if (ruleList.startsWith('+')) {
      ruleList = ruleList.substring(1);
    }

    final elements = rule.getElements(ruleList);
    
    // 2. 如果列表為空且未配置 bookUrlPattern，嘗試按詳情頁解析 (對標 Android 邏輯)
    if (elements.isEmpty && (source.bookUrlPattern == null || source.bookUrlPattern!.isEmpty)) {
      final searchBook = _getInfoItem(source: source, body: body, baseUrl: baseUrl);
      if (searchBook != null) {
        return [searchBook];
      }
      return [];
    }

    final books = <SearchBook>[];

    for (final element in elements) {
      // 建立空的 SearchBook 作為 ruleData，以便儲存解析過程中產生的變數 (@put)
      final searchBook = SearchBook(
        bookUrl: '',
        name: '',
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
        originOrder: source.customOrder,
        type: source.bookSourceType,
      );

      final itemRule = AnalyzeRule(ruleData: searchBook, source: source)
          .setContent(element, baseUrl: baseUrl);
      
      final name = BookHelp.formatBookName(itemRule.getString(listRule.name ?? ''));
      if (name.isEmpty) continue;

      searchBook.name = name;
      searchBook.bookUrl = itemRule.getString(listRule.bookUrl ?? '', isUrl: true);
      searchBook.author = BookHelp.formatBookAuthor(itemRule.getString(listRule.author ?? ''));
      searchBook.kind = itemRule.getStringList(listRule.kind ?? '').join(',');
      searchBook.coverUrl = itemRule.getString(listRule.coverUrl ?? '', isUrl: true);
      searchBook.intro = HtmlFormatter.format(itemRule.getString(listRule.intro ?? ''));
      searchBook.latestChapterTitle = itemRule.getString(listRule.lastChapter ?? '');
      searchBook.wordCount = StringUtils.wordCountFormat(itemRule.getString(listRule.wordCount ?? ''));
      
      books.add(searchBook);
    }

    return isReverse ? books.reversed.toList() : books;
  }

  static SearchBook? _getInfoItem({
    required BookSource source,
    required String body,
    required String baseUrl,
  }) {
    var book = Book(
      bookUrl: baseUrl,
      origin: source.bookSourceUrl,
      originName: source.bookSourceName,
      originOrder: source.customOrder,
      type: source.bookSourceType,
    );

    book = BookInfoParser.parse(
      source: source,
      book: book,
      body: body,
      baseUrl: baseUrl,
    );

    if (book.name.isNotEmpty) {
      return book.toSearchBook();
    }
    return null;
  }
}
