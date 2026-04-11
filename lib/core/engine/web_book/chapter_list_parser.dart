import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

/// 目錄解析結果
class ChapterListResult {
  final List<BookChapter> chapters;

  /// 下一頁 URL 清單 (對標 Android BookChapterList.analyzeChapterList 返回的 nextUrlList)
  /// - 長度 0：沒有下一頁
  /// - 長度 1：daisy-chain (每頁解析後再跟下一頁)
  /// - 長度 > 1：首頁列出所有分頁，可並發抓取
  final List<String> nextUrls;

  /// 是否使用反向排序 (對標 Android `-` 前綴)
  /// 只在首頁 (list rule 解析時) 計算；後續翻頁沿用首頁的值
  final bool isReverse;

  const ChapterListResult({
    required this.chapters,
    this.nextUrls = const [],
    this.isReverse = false,
  });
}

class ChapterListParser {
  /// 解析目錄頁，返回章節列表與下一頁 URL
  /// (對標 Android BookChapterList.analyzeChapterList)
  static Future<ChapterListResult> parse({
    required BookSource source,
    required Book book,
    required String body,
    required String baseUrl,
  }) async {
    final tocRule = source.ruleToc;
    if (tocRule == null) return const ChapterListResult(chapters: []);

    // 處理 -/+ 前綴 (對標 Android BookChapterList.analyzeChapterList 開頭邏輯)
    var listRule = tocRule.chapterList ?? '';
    var isReverse = false;
    if (listRule.startsWith('-')) {
      isReverse = true;
      listRule = listRule.substring(1);
    }
    if (listRule.startsWith('+')) {
      listRule = listRule.substring(1);
    }

    final rule = AnalyzeRule(
      source: source,
      ruleData: book,
    ).setContent(body, baseUrl: baseUrl);
    final elements = rule.getElements(listRule);

    final chapters = <BookChapter>[];
    for (var i = 0; i < elements.length; i++) {
      final itemRule = AnalyzeRule(
        source: source,
        ruleData: book,
      ).setContent(elements[i], baseUrl: baseUrl);

      final title = await itemRule.getStringAsync(tocRule.chapterName ?? '');
      if (title.isEmpty) continue;

      var url = await itemRule.getStringAsync(
        tocRule.chapterUrl ?? '',
        isUrl: true,
      );
      final updateTime = await itemRule.getStringAsync(
        tocRule.updateTime ?? '',
      );
      final isVolume = _isTrue(
        await itemRule.getStringAsync(tocRule.isVolume ?? ''),
      );
      final isVip = _isTrue(
        await itemRule.getStringAsync(tocRule.isVip ?? ''),
      );
      final isPay = _isTrue(
        await itemRule.getStringAsync(tocRule.isPay ?? ''),
      );

      // 空 URL 後備處理 (對標 Android 邏輯)
      if (url.isEmpty) {
        if (isVolume) {
          // 卷標題若無 url，使用 "title + index" 構造唯一標識避免 LinkedHashSet 去重誤判
          url = '$title$i';
        } else {
          url = baseUrl;
        }
      }

      chapters.add(
        BookChapter(
          title: title,
          url: url,
          baseUrl: baseUrl,
          bookUrl: book.bookUrl,
          isVolume: isVolume,
          isVip: isVip,
          isPay: isPay,
          tag: updateTime.isNotEmpty ? updateTime : null,
          // index 在 WebBook 統一重新編號後才是最終值
          index: i,
        ),
      );
    }

    // 解析下一頁目錄 URL 清單 (對標 Android nextTocUrl, getStringList)
    final nextUrls = <String>[];
    if (tocRule.nextTocUrl != null && tocRule.nextTocUrl!.isNotEmpty) {
      final list = await rule.getStringListAsync(
        tocRule.nextTocUrl!,
        isUrl: true,
      );
      for (final u in list) {
        if (u.isNotEmpty && u != baseUrl) nextUrls.add(u);
      }
    }

    return ChapterListResult(
      chapters: chapters,
      nextUrls: nextUrls,
      isReverse: isReverse,
    );
  }

  /// 解析布林字串 (對標 Android String.isTrue)
  /// 認可: true / yes / 1 / 是
  static bool _isTrue(String s) {
    if (s.isEmpty) return false;
    final lower = s.trim().toLowerCase();
    return lower == 'true' ||
        lower == 'yes' ||
        lower == '1' ||
        lower == '是';
  }
}
