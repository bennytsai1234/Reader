import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/utils/html_formatter.dart';
import 'package:legado_reader/core/utils/network_utils.dart';

/// 正文解析結果
class ContentResult {
  final String content;

  /// 下一頁正文 URL 清單 (對標 Android BookContent.analyzeContent 返回的 nextUrlList)
  /// - 長度 0：沒有下一頁
  /// - 長度 1：daisy-chain
  /// - 長度 > 1：可並發
  final List<String> nextUrls;

  const ContentResult({required this.content, this.nextUrls = const []});
}

class ContentParser {
  /// 解析正文頁，返回正文內容與下一頁 URL
  /// (對標 Android BookContent.analyzeContent)
  static Future<ContentResult> parse({
    required BookSource source,
    Book? book,
    BookChapter? chapter,
    required String body,
    required String baseUrl,
    String? nextChapterUrl,
  }) async {
    final rule = AnalyzeRule(source: source, ruleData: book)
        .setContent(body, baseUrl: baseUrl)
        .setChapter(chapter)
        .setNextChapterUrl(nextChapterUrl);

    final contentRule = source.ruleContent;
    if (contentRule == null) return ContentResult(content: body);

    // 取得正文內容 (關鍵: unescape=false 與 Android 一致)
    // 因為 HtmlFormatter.formatKeepImg 之後才做 HTML 實體反轉義
    var content = await rule.getStringAsync(
      contentRule.content ?? '',
      unescape: false,
    );

    // HTML 清理並保留 <img>，同時將相對路徑圖片補成絕對
    content = HtmlFormatter.formatKeepImg(content, baseUrl: baseUrl);

    // 若仍包含 HTML 實體，做一次反轉義 (對標 Android StringEscapeUtils.unescapeHtml4)
    if (content.contains('&')) {
      content = AnalyzeRuleBase.htmlUnescape.convert(content);
    }

    // 解析下一頁正文 URL 清單 (對標 Android nextContentUrl, getStringList)
    final nextUrls = <String>[];
    if (contentRule.nextContentUrl != null &&
        contentRule.nextContentUrl!.isNotEmpty) {
      final list = await rule.getStringListAsync(
        contentRule.nextContentUrl!,
        isUrl: true,
      );
      for (final u in list) {
        if (u.isEmpty || u == baseUrl) continue;
        // 避免跳到下一章 (對標 Android NetworkUtils.getAbsoluteURL 比對)
        if (nextChapterUrl != null) {
          final absNext = NetworkUtils.getAbsoluteURL(baseUrl, u);
          final absChapter = NetworkUtils.getAbsoluteURL(
            baseUrl,
            nextChapterUrl,
          );
          if (absNext == absChapter) continue;
        }
        nextUrls.add(u);
      }
    }

    return ContentResult(content: content, nextUrls: nextUrls);
  }

  /// 多頁正文合併後的最終替換清理 (對標 Android BookContent.analyzeContent 尾段)
  /// replaceRegex 走 AnalyzeRule.getStringAsync 以支援內嵌 @js: / {{js}} 等表達式
  static Future<String> finalizeContent({
    required BookSource source,
    Book? book,
    BookChapter? chapter,
    required String contentStr,
    String? baseUrl,
  }) async {
    final replaceRegex = source.ruleContent?.replaceRegex;
    if (replaceRegex == null || replaceRegex.isEmpty) return contentStr;

    // 拆行 trim (對標 Android LFRegex split+trim)
    var str = contentStr
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .join('\n');

    try {
      final rule = AnalyzeRule(source: source, ruleData: book)
          .setContent(str, baseUrl: baseUrl)
          .setChapter(chapter);
      str = await rule.getStringAsync(replaceRegex);
    } catch (_) {
      // 若規則解析失敗則保留 trim 後的原文
    }

    // 段落縮排 (對標 Android "　　$it" join)
    str = str.split(RegExp(r'\r?\n')).map((e) => '　　$e').join('\n');
    return str;
  }
}
