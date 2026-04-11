import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

class BookInfoParser {
  static Future<Book> parse({
    required BookSource source,
    required Book book,
    required String body,
    required String baseUrl,
  }) async {
    final infoRule = source.ruleBookInfo;
    if (infoRule == null) return book;

    final rule = AnalyzeRule(
      source: source,
      ruleData: book,
    ).setContent(body, baseUrl: baseUrl);

    // 執行 init 規則 (對標 Android BookInfoRule.init)
    // init 規則用於頁面預處理，例如 Ajax 載入或 JS 解密
    if (infoRule.init != null && infoRule.init!.isNotEmpty) {
      final initResult = await rule.getStringAsync(infoRule.init!);
      if (initResult.isNotEmpty) {
        // init 規則的結果替換為新的解析內容
        rule.setContent(initResult, baseUrl: baseUrl);
      }
    }

    final name = _format(await rule.getStringAsync(infoRule.name ?? ''));
    final author = _format(await rule.getStringAsync(infoRule.author ?? ''));

    final tocUrl = await rule.getStringAsync(
      infoRule.tocUrl ?? '',
      isUrl: true,
    );
    final kind = (await rule.getStringListAsync(infoRule.kind ?? '')).join(',');
    final coverUrl = await rule.getStringAsync(
      infoRule.coverUrl ?? '',
      isUrl: true,
    );
    final intro = await rule.getStringAsync(infoRule.intro ?? '');
    final latestChapterTitle =
        await rule.getStringAsync(infoRule.lastChapter ?? '');

    return book.copyWith(
      name: name.isEmpty ? book.name : name,
      author: author.isEmpty ? book.author : author,
      kind: kind,
      coverUrl: coverUrl,
      intro: intro,
      latestChapterTitle: latestChapterTitle,
      // tocUrl: 若規則解析結果為空，以 bookUrl 作為預設目錄頁 (對標 Android 邏輯)
      tocUrl: tocUrl.isNotEmpty ? tocUrl : book.bookUrl,
    );
  }

  static String _format(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');
}

