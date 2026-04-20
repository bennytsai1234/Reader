import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/reader/reader_page.dart';

void main() {
  test('ReaderPage can be constructed', () {
    expect(
      () => ReaderPage(
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
