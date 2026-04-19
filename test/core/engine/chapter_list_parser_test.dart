import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/web_book/chapter_list_parser.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';

import '../../test_helper.dart';

void main() {
  setupTestDI();
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ChapterListParser handles sync dynamic json chapter urls', () async {
    final source = BookSource.fromJson({
      'bookSourceUrl': 'DragonQuestQBqqnv',
      'bookSourceName': '測試目錄書源',
      'ruleToc': {
        'chapterList': r'$.rows',
        'chapterName': r'$.serialName',
        'chapterUrl':
            r'https://example.com/content,{"method":"POST","body":{"bookId":"{{baseUrl.match(/bookId=(\d+)/)[1]}}","chapterId":"{{$.serialID}}"}}',
      },
    });
    final book = Book(
      bookUrl: 'https://example.com/book/1',
      tocUrl: 'https://example.com/toc?bookId=1137339371',
      origin: 'DragonQuestQBqqnv',
      originName: '測試目錄書源',
    );

    const tocJson = '''
{
  "rows": [
    {"serialID": 101, "serialName": "第一章"},
    {"serialID": 102, "serialName": "第二章"}
  ]
}
''';

    final result = await ChapterListParser.parse(
      source: source,
      book: book,
      body: tocJson,
      baseUrl: book.tocUrl,
    );

    expect(result.chapters, hasLength(2));
    expect(result.chapters[0].title, '第一章');
    expect(
      result.chapters[0].url,
      'https://example.com/content,{"method":"POST","body":{"bookId":"1137339371","chapterId":"101"}}',
    );
    expect(
      result.chapters[1].url,
      'https://example.com/content,{"method":"POST","body":{"bookId":"1137339371","chapterId":"102"}}',
    );
  });

  test('ChapterListParser respects maxChapters limit', () async {
    final source = BookSource.fromJson({
      'bookSourceUrl': 'https://example.com',
      'bookSourceName': '限制測試書源',
      'ruleToc': {
        'chapterList': r'$.rows',
        'chapterName': r'$.serialName',
        'chapterUrl': r'$.serialID',
      },
    });
    final book = Book(
      bookUrl: 'https://example.com/book/1',
      tocUrl: 'https://example.com/toc',
      origin: 'https://example.com',
      originName: '限制測試書源',
    );

    const tocJson = '''
{
  "rows": [
    {"serialID": "1", "serialName": "第一章"},
    {"serialID": "2", "serialName": "第二章"},
    {"serialID": "3", "serialName": "第三章"}
  ]
}
''';

    final result = await ChapterListParser.parse(
      source: source,
      book: book,
      body: tocJson,
      baseUrl: book.tocUrl,
      maxChapters: 2,
    );

    expect(result.chapters, hasLength(2));
    expect(result.chapters.map((chapter) => chapter.title), <String>['第一章', '第二章']);
    expect(result.nextUrls, isEmpty);
  });
}
