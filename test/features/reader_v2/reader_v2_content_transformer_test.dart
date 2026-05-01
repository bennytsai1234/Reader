import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'package:inkpage_reader/features/reader_v2/content/reader_v2_content_transformer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderV2ContentTransformer', () {
    test(
      'applies scoped content rules through the shared replace engine',
      () async {
        final transformer = ReaderV2ContentTransformer();
        final result = await transformer.process(
          book: Book(
            bookUrl: 'book://1',
            origin: 'https://source.example',
            name: '測試書',
            readConfig: ReadConfig(useReplaceRule: true),
          ),
          chapter: BookChapter(title: '第1章 廣告'),
          rawContent: '第1章 廣告\n正文 junk123\nad999',
          enabledRules: [
            ReplaceRule(
              name: '正文替換',
              pattern: r'junk(\d+)',
              replacement: r'ok$1',
              scope: '測試書',
              scopeContent: true,
              order: 0,
            ),
            ReplaceRule(
              name: '外書規則',
              pattern: '正文',
              replacement: '不應套用',
              scope: '其他書',
              scopeContent: true,
              order: 1,
            ),
            ReplaceRule(
              name: '標題替換',
              pattern: '廣告',
              replacement: '',
              scope: 'https://source.example',
              scopeTitle: true,
              scopeContent: false,
              order: 2,
            ),
          ],
          chineseConvertType: 0,
        );

        expect(result.displayTitle, '第1章 ');
        expect(result.content, contains('ok123'));
        expect(result.content, isNot(contains('junk123')));
        expect(result.content, isNot(contains('不應套用')));
        expect(result.sameTitleRemoved, isTrue);
        expect(result.effectiveReplaceRules.map((rule) => rule.name), ['正文替換']);
      },
    );

    test(
      'removes duplicate title after title replace rules are applied',
      () async {
        final transformer = ReaderV2ContentTransformer();
        final result = await transformer.process(
          book: Book(
            bookUrl: 'book://1',
            origin: 'https://source.example',
            name: '測試書',
            readConfig: ReadConfig(useReplaceRule: true),
          ),
          chapter: BookChapter(title: '第1章 正文'),
          rawContent: '正文\n真正內容',
          enabledRules: [
            ReplaceRule(
              name: '標題裁切',
              pattern: r'^第1章\s*',
              replacement: '',
              scopeTitle: true,
              scopeContent: false,
            ),
          ],
          chineseConvertType: 0,
        );

        expect(result.displayTitle, '正文');
        expect(result.content, isNot(contains('正文\n')));
        expect(result.content, contains('真正內容'));
        expect(result.sameTitleRemoved, isTrue);
      },
    );
  });
}
