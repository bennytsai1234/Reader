import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/web_book/book_list_parser.dart';
import 'package:inkpage_reader/core/models/book_source.dart';

import '../../test_helper.dart';

void main() {
  setupTestDI();
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'search bookUrl can reference fields populated earlier on SearchBook',
    () async {
      final source = BookSource(
        bookSourceUrl: 'source://test',
        bookSourceName: 'Test Source',
        ruleSearch: SearchRule(
          bookList: r'$.data[*]',
          name: r'$.name',
          kind: r'$.kind',
          bookUrl: r'https://example.com/book/{{book.kind}}',
        ),
      );

      final books = await BookListParser.parse(
        source: source,
        body: '{"data":[{"name":"測試書","kind":"47749"}]}',
        baseUrl: 'https://example.com/search',
        isSearch: true,
      );

      expect(books, hasLength(1));
      expect(books.first.kind, '47749');
      expect(books.first.bookUrl, 'https://example.com/book/47749');
    },
  );
}
