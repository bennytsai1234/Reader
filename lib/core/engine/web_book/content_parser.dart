import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

/// 正文解析結果
class ContentResult {
  final String content;
  final String? nextUrl;

  const ContentResult({required this.content, this.nextUrl});
}

class ContentParser {
  /// 解析正文頁，返回正文內容與下一頁 URL
  static ContentResult parse({
    required BookSource source,
    required String body,
    required String baseUrl,
    String? nextChapterUrl,
  }) {
    final rule = AnalyzeRule(source: source)
        .setContent(body, baseUrl: baseUrl)
        .setNextChapterUrl(nextChapterUrl);
    final contentRule = source.ruleContent;
    if (contentRule == null) return ContentResult(content: body);

    // 取得正文內容
    var content = rule.getString(contentRule.content ?? '');

    // 套用正文淨化規則 (replaceRegex) (對標 Android ContentRule.replaceRegex)
    if (contentRule.replaceRegex != null && contentRule.replaceRegex!.isNotEmpty) {
      content = _applyReplaceRegex(content, contentRule.replaceRegex!);
    }

    // 解析下一頁正文 URL (對標 Android nextContentUrl)
    String? nextUrl;
    if (contentRule.nextContentUrl != null && contentRule.nextContentUrl!.isNotEmpty) {
      nextUrl = rule.getString(contentRule.nextContentUrl!, isUrl: true);
      // 避免指向自身或下一章造成無限迴圈
      if (nextUrl == baseUrl || nextUrl.isEmpty) {
        nextUrl = null;
      }
      if (nextUrl != null && nextChapterUrl != null && nextUrl == nextChapterUrl) {
        nextUrl = null;
      }
    }

    return ContentResult(content: content, nextUrl: nextUrl);
  }

  /// 套用 replaceRegex 淨化正文
  /// 格式: "regex##replacement" 或多條以 "&&" 分隔
  static String _applyReplaceRegex(String content, String replaceRegex) {
    if (content.isEmpty) return content;

    final rules = replaceRegex.split('&&');
    var result = content;
    for (final rule in rules) {
      if (rule.trim().isEmpty) continue;
      final parts = rule.split('##');
      if (parts.isEmpty) continue;
      try {
        final pattern = RegExp(parts[0], multiLine: true, dotAll: true);
        final replacement = parts.length > 1 ? parts[1] : '';
        result = result.replaceAll(pattern, replacement);
      } catch (_) {
        // 跳過無效的正則
      }
    }
    return result;
  }
}

