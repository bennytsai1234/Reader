import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'package:inkpage_reader/core/models/book/book_content.dart';
import 'package:inkpage_reader/core/constant/app_pattern.dart';

/// ContentProcessor - 閱讀器正文處理引擎 (對標 Android ContentProcessor.kt)
class ContentProcessor {
  /// 異步處理正文
  static Future<BookContent> process({
    required Book book,
    required BookChapter chapter,
    required String rawContent,
    required List<Map<String, dynamic>> rulesJson,
    required bool useReplaceRules,
    bool reSegmentEnabled = true,
    bool removeSameTitle = true,
  }) async {
    if (rawContent.isEmpty) return BookContent(content: '');
    final parsedRules =
        rulesJson
            .map((j) => ReplaceRule.fromJson(j))
            .where((r) => r.isEnabled)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final contentRules = parsedRules.where((r) => r.scopeContent).toList();

    // 1. 在 Isolate 中執行 CPU 密集型操作
    final resultData = await compute(_internalProcess, {
      'bookName': book.name,
      'bookOrigin': book.origin,
      'chapterTitle': chapter.title,
      'rawContent': rawContent,
      'rulesJson': contentRules.map((r) => r.toJson()).toList(),
      'useReplaceRules': useReplaceRules,
      'reSegmentEnabled': reSegmentEnabled,
      'removeSameTitle': removeSameTitle,
    });

    String content = resultData['content'];
    final effectiveRules = resultData['effectiveRules'] as List<ReplaceRule>;
    final bool sameTitleRemoved = resultData['sameTitleRemoved'];

    return BookContent(
      content: content,
      effectiveReplaceRules: effectiveRules,
      sameTitleRemoved: sameTitleRemoved,
    );
  }

  /// 內部同步處理邏輯
  static Map<String, dynamic> _internalProcess(Map<String, dynamic> args) {
    final String bookName = args['bookName'] ?? '';
    final String bookOrigin = args['bookOrigin'] ?? '';
    final String chapterTitle = args['chapterTitle'] ?? '';
    final String rawContent = args['rawContent'] ?? '';
    final List<dynamic> rulesJson = args['rulesJson'] ?? [];
    final List<ReplaceRule> rules =
        rulesJson
            .map((j) => ReplaceRule.fromJson(j))
            .where((r) => r.isEnabled)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final bool useReplaceRules = args['useReplaceRules'] ?? true;
    final bool reSegmentEnabled = args['reSegmentEnabled'] ?? true;
    final bool removeSameTitle = args['removeSameTitle'] ?? true;

    var mContent = rawContent;
    var sameTitleRemoved = false;
    final effectiveRules = <ReplaceRule>[];

    // 1. 去除重複標題 (對標 Android ContentProcessor.kt line 110)
    if (removeSameTitle) {
      final nameRegex = RegExp.escape(bookName);
      final titleRegex = RegExp.escape(
        chapterTitle,
      ).replaceAll(AppPattern.spaceRegex, r'\s*');
      final pattern = RegExp(
        '^(\\s|\\p{P}|$nameRegex)*$titleRegex(\\s)*',
        unicode: true,
      );

      final match = pattern.firstMatch(mContent);
      if (match != null) {
        mContent = mContent.substring(match.end);
        sameTitleRemoved = true;
      }
    }

    // 2. 重新分段 (對標 Android line 135)
    if (reSegmentEnabled) {
      mContent = _reSegment(mContent);
    }

    if (useReplaceRules) {
      // 3. 預處理：修剪每行空白
      mContent = mContent.split('\n').map((line) => line.trim()).join('\n');

      // 4. 執行淨化規則替換 (對標 Android line 150)
      for (final rule in rules) {
        if (!rule.isEnabled || !rule.scopeContent) continue;
        if (rule.pattern.isEmpty) continue;

        if (rule.scope?.isNotEmpty == true) {
          if (!rule.scope!.contains(bookName) &&
              !rule.scope!.contains(bookOrigin)) {
            continue;
          }
        }
        if (rule.excludeScope?.isNotEmpty == true) {
          if (rule.excludeScope!.contains(bookName) ||
              rule.excludeScope!.contains(bookOrigin)) {
            continue;
          }
        }

        try {
          final String oldContent = mContent;
          if (rule.isRegex) {
            final reg = RegExp(rule.pattern, multiLine: true, dotAll: true);
            mContent = mContent.replaceAllMapped(reg, (match) {
              return rule.replacement.replaceAllMapped(
                RegExp(r'\\\$|\$(\d+)'),
                (m) {
                  final hit = m.group(0)!;
                  if (hit == r'\$') return r'$';
                  final idx = int.tryParse(m.group(1)!) ?? 0;
                  if (idx == 0) return match.group(0) ?? '';
                  return (idx > 0 && idx <= match.groupCount)
                      ? (match.group(idx) ?? '')
                      : hit;
                },
              );
            });
          } else {
            mContent = mContent.replaceAll(rule.pattern, rule.replacement);
          }

          if (mContent != oldContent) {
            effectiveRules.add(rule);
          }
        } catch (_) {}
      }
    }

    // 5. 段落美化與縮進 (對標 Android line 195)
    final finalParagraphs = <String>[];
    const indent = '　　'; // 預設使用兩個全形空格作為縮進

    mContent.split('\n').forEach((line) {
      final p = line.trim().replaceAll('\u00A0', ' ');
      if (p.isNotEmpty) {
        finalParagraphs.add('$indent$p');
      }
    });

    return {
      'content': finalParagraphs.join('\n'),
      'effectiveRules': effectiveRules,
      'sameTitleRemoved': sameTitleRemoved,
    };
  }

  static String _reSegment(String content) {
    return content
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n');
  }
}
