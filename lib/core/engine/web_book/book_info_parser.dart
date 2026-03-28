import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

class BookInfoParser {
  static Book parse({
    required BookSource source,
    required Book book,
    required String body,
    required String baseUrl,
  }) {
    final infoRule = source.ruleBookInfo;
    if (infoRule == null) return book;

    final rule = AnalyzeRule(source: source, ruleData: book).setContent(body, baseUrl: baseUrl);

    // 執行 init 規則 (對標 Android BookInfoRule.init)
    // init 規則用於頁面預處理，例如 Ajax 載入或 JS 解密
    if (infoRule.init != null && infoRule.init!.isNotEmpty) {
      final initResult = rule.getString(infoRule.init!);
      if (initResult.isNotEmpty) {
        // init 規則的結果替換為新的解析內容
        rule.setContent(initResult, baseUrl: baseUrl);
      }
    }

    final name = _format(rule.getString(infoRule.name ?? ''));
    final author = _format(rule.getString(infoRule.author ?? ''));

    return book.copyWith(
      name: name.isEmpty ? book.name : name,
      author: author.isEmpty ? book.author : author,
      kind: rule.getStringList(infoRule.kind ?? '').join(','),
      coverUrl: rule.getString(infoRule.coverUrl ?? '', isUrl: true),
      intro: rule.getString(infoRule.intro ?? ''),
      latestChapterTitle: rule.getString(infoRule.lastChapter ?? ''),
      tocUrl: rule.getString(infoRule.tocUrl ?? '', isUrl: true),
    );
  }

  static String _format(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');
}

