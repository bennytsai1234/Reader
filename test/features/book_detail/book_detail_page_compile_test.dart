import 'package:flutter_test/flutter_test.dart';

import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/book_detail/book_detail_page.dart';

void main() {
  test('BookDetailPage can be constructed', () {
    expect(
      () => BookDetailPage(
        book: Book(
          bookUrl: 'https://example.com/book',
          name: '示例書籍',
          author: '作者',
          origin: 'source://demo',
          originName: '測試書源',
        ),
      ),
      returnsNormally,
    );
  });
}
