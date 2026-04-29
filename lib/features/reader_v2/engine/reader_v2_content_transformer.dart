import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/constant/app_pattern.dart';
import 'package:inkpage_reader/core/engine/reader/chinese_text_converter.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';

import 'reader_v2_processed_chapter.dart';

class ReaderV2ContentTransformer {
  const ReaderV2ContentTransformer();

  Future<ReaderV2ProcessedChapter> process({
    required Book book,
    required BookChapter chapter,
    required String rawContent,
    required List<ReplaceRule> enabledRules,
    required int chineseConvertType,
  }) async {
    final converter = const ChineseTextConverter();
    final result = await compute(_processInBackground, <String, Object?>{
      'bookName': book.name,
      'bookOrigin': book.origin,
      'chapterTitle': chapter.title,
      'rawContent': rawContent,
      'rulesJson': enabledRules.map((rule) => rule.toJson()).toList(),
      'useReplaceRules': book.getUseReplaceRule(),
      'reSegmentEnabled': book.getReSegment(),
    });
    final effectiveRules = (result['effectiveRules'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ReplaceRule.fromJson)
        .toList(growable: false);
    return ReaderV2ProcessedChapter(
      displayTitle: converter.convert(
        result['displayTitle'] as String? ?? '',
        convertType: chineseConvertType,
      ),
      content: converter.convert(
        result['content'] as String? ?? '',
        convertType: chineseConvertType,
      ),
      effectiveReplaceRules: effectiveRules,
      sameTitleRemoved: result['sameTitleRemoved'] as bool? ?? false,
    );
  }

  static Map<String, Object?> _processInBackground(Map<String, Object?> args) {
    final bookName = args['bookName'] as String? ?? '';
    final bookOrigin = args['bookOrigin'] as String? ?? '';
    final chapterTitle = args['chapterTitle'] as String? ?? '';
    final rawContent = args['rawContent'] as String? ?? '';
    final rulesJson =
        (args['rulesJson'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    final useReplaceRules = args['useReplaceRules'] as bool? ?? true;
    final reSegmentEnabled = args['reSegmentEnabled'] as bool? ?? true;
    final rules =
        rulesJson
            .map(ReplaceRule.fromJson)
            .where((rule) => rule.isEnabled)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final titleRules = rules
        .where((rule) => rule.scopeTitle)
        .toList(growable: false);
    final contentResult = _processContent(
      bookName: bookName,
      bookOrigin: bookOrigin,
      chapterTitle: chapterTitle,
      rawContent: rawContent,
      rules: rules,
      useReplaceRules: useReplaceRules,
      reSegmentEnabled: reSegmentEnabled,
    );
    final displayTitle = _processTitle(
      chapterTitle: chapterTitle,
      rules: titleRules,
      useReplaceRules: useReplaceRules,
    );

    return <String, Object?>{
      'displayTitle': displayTitle,
      'content': contentResult.content,
      'effectiveRules': contentResult.effectiveReplaceRules
          .map((rule) => rule.toJson())
          .toList(growable: false),
      'sameTitleRemoved': contentResult.sameTitleRemoved,
    };
  }

  static ReaderV2ProcessedChapter _processContent({
    required String bookName,
    required String bookOrigin,
    required String chapterTitle,
    required String rawContent,
    required List<ReplaceRule> rules,
    required bool useReplaceRules,
    required bool reSegmentEnabled,
  }) {
    if (rawContent.isEmpty) {
      return const ReaderV2ProcessedChapter(displayTitle: '', content: '');
    }

    var content = rawContent;
    var sameTitleRemoved = false;
    final effectiveRules = <ReplaceRule>[];

    final nameRegex = RegExp.escape(bookName);
    final titleRegex = RegExp.escape(
      chapterTitle,
    ).replaceAll(AppPattern.spaceRegex, r'\s*');
    final duplicateTitlePattern = RegExp(
      '^(\\s|\\p{P}|$nameRegex)*$titleRegex(\\s)*',
      unicode: true,
    );
    final duplicateTitleMatch = duplicateTitlePattern.firstMatch(content);
    if (duplicateTitleMatch != null) {
      content = content.substring(duplicateTitleMatch.end);
      sameTitleRemoved = true;
    }

    if (reSegmentEnabled) {
      content = content
          .replaceAll(RegExp(r'\r\n?'), '\n')
          .replaceAll(RegExp(r'\n{2,}'), '\n')
          .replaceAll(RegExp(r'[ \t]+\n'), '\n');
    }

    if (useReplaceRules) {
      content = content.split('\n').map((line) => line.trim()).join('\n');
      for (final rule in rules) {
        if (!rule.scopeContent || rule.pattern.isEmpty) continue;
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
          final previous = content;
          if (rule.isRegex) {
            final reg = RegExp(rule.pattern, multiLine: true, dotAll: true);
            content = content.replaceAllMapped(reg, (match) {
              return rule.replacement.replaceAllMapped(
                RegExp(r'\\\$|\$(\d+)'),
                (groupMatch) {
                  final hit = groupMatch.group(0)!;
                  if (hit == r'\$') return r'$';
                  final idx = int.tryParse(groupMatch.group(1)!) ?? 0;
                  if (idx == 0) return match.group(0) ?? '';
                  return (idx > 0 && idx <= match.groupCount)
                      ? (match.group(idx) ?? '')
                      : hit;
                },
              );
            });
          } else {
            content = content.replaceAll(rule.pattern, rule.replacement);
          }
          if (content != previous) {
            effectiveRules.add(rule);
          }
        } catch (_) {}
      }
    }

    final paragraphs = <String>[];
    const indent = '　　';
    for (final line in content.split('\n')) {
      final paragraph = line.trim().replaceAll('\u00A0', ' ');
      if (paragraph.isNotEmpty) {
        paragraphs.add('$indent$paragraph');
      }
    }

    return ReaderV2ProcessedChapter(
      displayTitle: '',
      content: paragraphs.join('\n'),
      effectiveReplaceRules: List<ReplaceRule>.unmodifiable(effectiveRules),
      sameTitleRemoved: sameTitleRemoved,
    );
  }

  static String _processTitle({
    required String chapterTitle,
    required List<ReplaceRule> rules,
    required bool useReplaceRules,
  }) {
    var displayTitle = chapterTitle.replaceAll(RegExp(r'[\r\n]'), '');
    if (useReplaceRules) {
      for (final rule in rules) {
        if (rule.pattern.isEmpty) continue;
        try {
          if (rule.isRegex) {
            displayTitle = displayTitle.replaceAll(
              RegExp(rule.pattern),
              rule.replacement,
            );
          } else {
            displayTitle = displayTitle.replaceAll(
              rule.pattern,
              rule.replacement,
            );
          }
        } catch (_) {}
      }
    }
    return displayTitle;
  }
}
