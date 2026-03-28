import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

/// 目錄解析結果
class ChapterListResult {
  final List<BookChapter> chapters;
  final String? nextUrl;

  const ChapterListResult({required this.chapters, this.nextUrl});
}

class ChapterListParser {
  /// 解析目錄頁，返回章節列表與下一頁 URL
  static ChapterListResult parse({
    required BookSource source,
    required Book book,
    required String body,
    required String baseUrl,
  }) {
    final rule = AnalyzeRule(source: source, ruleData: book).setContent(body, baseUrl: baseUrl);
    final tocRule = source.ruleToc;
    if (tocRule == null) return const ChapterListResult(chapters: []);

    final chapters = <BookChapter>[];
    final elements = rule.getElements(tocRule.chapterList ?? '');

    for (var i = 0; i < elements.length; i++) {
      final itemRule = AnalyzeRule(source: source, ruleData: book).setContent(elements[i], baseUrl: baseUrl);
      final title = itemRule.getString(tocRule.chapterName ?? '');
      if (title.isEmpty) continue;

      chapters.add(BookChapter(
        index: i,
        title: title,
        url: itemRule.getString(tocRule.chapterUrl ?? '', isUrl: true),
        bookUrl: book.bookUrl,
      ));
    }

    // 解析下一頁目錄 URL (對標 Android nextTocUrl)
    String? nextUrl;
    if (tocRule.nextTocUrl != null && tocRule.nextTocUrl!.isNotEmpty) {
      nextUrl = rule.getString(tocRule.nextTocUrl!, isUrl: true);
      // 避免指向自身造成無限迴圈
      if (nextUrl == baseUrl || nextUrl.isEmpty) {
        nextUrl = null;
      }
    }

    return ChapterListResult(chapters: chapters, nextUrl: nextUrl);
  }
}

