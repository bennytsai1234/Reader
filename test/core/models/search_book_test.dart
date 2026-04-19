import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/search_book.dart';

void main() {
  test('sourceLabels 會保留各來源的名稱', () {
    final book = SearchBook(
      bookUrl: 'https://example.com/book/1',
      name: '測試書',
      author: '作者甲',
      origin: 'source://a',
      originName: '書源 A',
    );

    book.addOrigin('source://b', name: '書源 B');
    book.addOrigin('source://c');

    expect(
      book.sourceLabels,
      containsAll(<String>['書源 A', '書源 B', 'source://c']),
    );
  });
}
