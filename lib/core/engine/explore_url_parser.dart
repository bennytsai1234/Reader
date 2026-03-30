import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/models/book_source.dart';

/// ExploreKind - 探索分類模型 (對標 Android ExploreKind)
class ExploreKind {
  final String title;
  final String url;
  final String? group;

  ExploreKind({required this.title, required this.url, this.group});
}

/// ExploreUrlParser - 發現規則解析器 (對標 Android BookSource.getExploreKinds)
class ExploreUrlParser {
  /// 將 exploreUrl 字符串解析為分類列表
  /// 支援 JS 動態規則 (`@js:` 或 `<js>...</js>`)
  static List<ExploreKind> parse(String? exploreUrl, {BookSource? source}) {
    if (exploreUrl == null || exploreUrl.isEmpty) return [];

    var urlStr = exploreUrl;

    try {
      // 處理 JS 動態發現規則 (對標 Android BookSource.getExploreKinds)
      if (urlStr.contains('@js:') || urlStr.contains('<js>')) {
        if (source != null) {
          final rule = AnalyzeRule(source: source);
          final result = rule.evalJS(
            urlStr.replaceFirst(RegExp(r'^@js:\s*'), '').replaceAll(RegExp(r'</?js>'), ''),
            null,
          );
          if (result != null && result.toString().isNotEmpty) {
            urlStr = result.toString();
          } else {
            return [];
          }
        } else {
          // 沒有 source context 時無法執行 JS
          return [];
        }
      }
    } catch (e) {
      AppLog.e('ExploreUrl JS 執行失敗: $e', error: e);
      return [];
    }

    return _parseStatic(urlStr);
  }

  /// 解析靜態格式的 exploreUrl
  static List<ExploreKind> _parseStatic(String exploreUrl) {
    final List<ExploreKind> kinds = [];

    try {
      // 1. 處理分組 (||)
      final groups = exploreUrl.split(RegExp(r'\s*\|\|\s*'));
      for (var groupStr in groups) {
        // 2. 處理分類 (&& 或 \n)
        final items = groupStr.split(RegExp(r'\s*&&\s*|\n'));
        for (var item in items) {
          if (item.trim().isEmpty) continue;

          // 3. 解析標題與網址 (::)
          final parts = item.split('::');
          if (parts.length >= 3) {
            // 帶分組格式: 分組::標題::網址
            kinds.add(ExploreKind(group: parts[0].trim(), title: parts[1].trim(), url: parts[2].trim()));
          } else if (parts.length == 2) {
            // 普通格式: 標題::網址
            kinds.add(ExploreKind(title: parts[0].trim(), url: parts[1].trim()));
          }
        }
      }
    } catch (e) {
      AppLog.e('ExploreUrl解析失敗: $e', error: e);
    }

    return kinds;
  }
}
