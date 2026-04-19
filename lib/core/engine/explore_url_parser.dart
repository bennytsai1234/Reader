import 'dart:convert';

import 'package:inkpage_reader/core/engine/analyze_rule.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/source/explore_kind.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';

/// ExploreUrlParser - 發現規則解析器 (對標 Android BookSource.getExploreKinds)
class ExploreUrlParser {
  /// 同步版本，僅適用於純同步 JS 或靜態 exploreUrl。
  static List<ExploreKind> parse(String? exploreUrl, {BookSource? source}) {
    if (exploreUrl == null || exploreUrl.isEmpty) return [];

    try {
      final resolved = _resolveSync(exploreUrl, source: source);
      return _parseResolvedValue(resolved);
    } catch (e) {
      AppLog.e('ExploreUrl 解析失敗: $e', error: e);
      return [ExploreKind(title: 'ERROR:${e.toString()}', url: e.toString())];
    }
  }

  /// 非同步版本，支援 `<js>` / `@js:` 規則內使用 `java.ajax(...)`
  /// 等 Promise bridge 方法。
  static Future<List<ExploreKind>> parseAsync(
    String? exploreUrl, {
    BookSource? source,
    Future<dynamic> Function(String jsSource)? jsExecutor,
  }) async {
    if (exploreUrl == null || exploreUrl.isEmpty) return [];

    try {
      final resolved = await _resolveAsync(
        exploreUrl,
        source: source,
        jsExecutor: jsExecutor,
      );
      return _parseResolvedValue(resolved);
    } catch (e) {
      AppLog.e('ExploreUrl 非同步解析失敗: $e', error: e);
      return [ExploreKind(title: 'ERROR:${e.toString()}', url: e.toString())];
    }
  }

  static dynamic _resolveSync(String exploreUrl, {BookSource? source}) {
    if (!_isJsExploreUrl(exploreUrl)) {
      return exploreUrl;
    }
    if (source == null) {
      return '';
    }

    final rule = AnalyzeRule(source: source);
    return rule.evalJS(_extractJsBody(exploreUrl), null);
  }

  static Future<dynamic> _resolveAsync(
    String exploreUrl, {
    BookSource? source,
    Future<dynamic> Function(String jsSource)? jsExecutor,
  }) async {
    if (!_isJsExploreUrl(exploreUrl)) {
      return exploreUrl;
    }

    final jsSource = _extractJsBody(exploreUrl);
    if (jsExecutor != null) {
      return jsExecutor(jsSource);
    }
    if (source == null) {
      return '';
    }

    final rule = AnalyzeRule(source: source);
    return rule.evalJSAsync(jsSource, null);
  }

  static bool _isJsExploreUrl(String exploreUrl) {
    final trimmed = exploreUrl.trimLeft();
    return trimmed.startsWith('<js>') || trimmed.startsWith('@js:');
  }

  static String _extractJsBody(String exploreUrl) {
    final trimmed = exploreUrl.trim();
    if (trimmed.startsWith('@js:')) {
      return trimmed.substring(4).trim();
    }

    var body = trimmed.substring(4);
    if (body.endsWith('</js>')) {
      body = body.substring(0, body.length - 5);
    }
    return body.trim();
  }

  static List<ExploreKind> _parseResolvedValue(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => ExploreKind.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (value is Map) {
      return [ExploreKind.fromJson(Map<String, dynamic>.from(value))];
    }

    final urlStr = value.toString().trim();
    if (urlStr.isEmpty) return [];
    if (_isJsonArray(urlStr)) {
      return _parseJsonArray(urlStr);
    }
    return _parseStatic(urlStr);
  }

  /// 檢查是否為 JSON 陣列
  static bool _isJsonArray(String str) {
    final trimmed = str.trim();
    return trimmed.startsWith('[') && trimmed.endsWith(']');
  }

  /// 解析 JSON 陣列格式的 exploreUrl
  static List<ExploreKind> _parseJsonArray(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => ExploreKind.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      AppLog.e('ExploreUrl JSON 解析失敗: $e', error: e);
      return [ExploreKind(title: 'ERROR:${e.toString()}', url: e.toString())];
    }
  }

  /// 解析靜態格式的 exploreUrl (對標 Android `&&` 和 `\n` 分隔)
  static List<ExploreKind> _parseStatic(String exploreUrl) {
    final kinds = <ExploreKind>[];

    try {
      final items = exploreUrl.split(RegExp(r'(&&|\n)+'));
      for (final item in items) {
        final trimmed = item.trim();
        if (trimmed.isEmpty) continue;

        final parts = trimmed.split('::');
        if (parts.length >= 2) {
          kinds.add(
            ExploreKind(
              title: parts[0].trim(),
              url: parts.sublist(1).join('::').trim(),
            ),
          );
        }
      }
    } catch (e) {
      AppLog.e('ExploreUrl 解析失敗: $e', error: e);
      kinds.add(ExploreKind(title: 'ERROR:${e.toString()}', url: e.toString()));
    }

    return kinds;
  }
}
