import 'dart:async';

import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/engine/reader/chinese_text_converter.dart';
import 'package:legado_reader/core/engine/reader/content_processor.dart'
    as engine;
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book/book_content.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/replace_rule.dart';
import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:legado_reader/core/services/local_book_service.dart';
import 'package:legado_reader/features/reader/engine/chapter_content_manager.dart';
import 'package:legado_reader/features/reader/engine/reader_perf_trace.dart';

class ReaderChapterContentLoader {
  ReaderChapterContentLoader({
    required this.book,
    required this.chapterDao,
    required this.replaceDao,
    required this.sourceDao,
    required this.service,
    required this.currentChineseConvert,
    required this.getSource,
    required this.setSource,
  });

  final Book book;
  final ChapterDao chapterDao;
  final ReplaceRuleDao replaceDao;
  final BookSourceDao sourceDao;
  final BookSourceService service;
  final int Function() currentChineseConvert;
  final BookSource? Function() getSource;
  final void Function(BookSource source) setSource;
  final ChineseTextConverter _textConverter = const ChineseTextConverter();

  List<Map<String, dynamic>>? _cachedRulesJson;
  final Map<String, String> _convertedContentCache = <String, String>{};
  final Map<String, String> _convertedTitleCache = <String, String>{};

  Future<FetchResult> load(int chapterIndex, BookChapter chapter) async {
    final rawContent = await _loadRawContent(chapterIndex, chapter);
    final rulesJson = await _loadRulesJson();
    final chineseConvertType = currentChineseConvert();

    final BookContent bookContent = await ReaderPerfTrace.measureAsync(
      'process content chapter $chapterIndex',
      () => engine.ContentProcessor.process(
        book: book,
        chapter: chapter,
        rawContent: rawContent,
        rulesJson: rulesJson,
        reSegmentEnabled: true,
      ),
    );
    final convertedTitle = await _getConvertedTitle(
      chapter: chapter,
      chineseConvertType: chineseConvertType,
      rulesJson: rulesJson,
    );
    final convertedContent = await _getConvertedContent(
      chapterIndex: chapterIndex,
      rawContent: rawContent,
      processedContent: bookContent.content,
      chineseConvertType: chineseConvertType,
    );
    return FetchResult(content: '$convertedTitle\n$convertedContent');
  }

  void resetProcessingContext() {
    _cachedRulesJson = null;
    _convertedContentCache.clear();
    _convertedTitleCache.clear();
  }

  Future<String> _loadRawContent(int chapterIndex, BookChapter chapter) async {
    if (book.origin == 'local') {
      return ReaderPerfTrace.measureAsync(
        'local content chapter $chapterIndex',
        () => LocalBookService().getContent(book, chapter),
      );
    }

    var source = getSource();
    source ??= await sourceDao.getByUrl(book.origin);
    if (source != null) {
      setSource(source);
    }
    if (source == null) {
      return '加載章節失敗: 找不到書源';
    }
    final resolvedSource = source;
    try {
      final raw = await ReaderPerfTrace.measureAsync(
        'remote content chapter $chapterIndex',
        () => service.getContent(resolvedSource, book, chapter),
      );
      if (raw.isNotEmpty) {
        return raw;
      }
      return '章節內容為空 (可能解析規則有誤)';
    } catch (e) {
      return '加載章節失敗: $e';
    }
  }

  Future<List<Map<String, dynamic>>> _loadRulesJson() async {
    _cachedRulesJson ??=
        (await replaceDao.getEnabled()).map((r) => r.toJson()).toList().cast<Map<String, dynamic>>();
    return _cachedRulesJson!;
  }

  Future<String> _getConvertedContent({
    required int chapterIndex,
    required String rawContent,
    required String processedContent,
    required int chineseConvertType,
  }) async {
    final cacheKey =
        '$chapterIndex:$chineseConvertType:${rawContent.hashCode}:${processedContent.hashCode}';
    final cached = _convertedContentCache[cacheKey];
    if (cached != null) return cached;
    final converted = await ReaderPerfTrace.measureAsync(
      'convert content chapter $chapterIndex',
      () => _textConverter.convert(
        processedContent,
        convertType: chineseConvertType,
      ),
    );
    _convertedContentCache[cacheKey] = converted;
    if (_convertedContentCache.length > 12) {
      _convertedContentCache.remove(_convertedContentCache.keys.first);
    }
    return converted;
  }

  Future<String> _getConvertedTitle({
    required BookChapter chapter,
    required int chineseConvertType,
    required List<Map<String, dynamic>> rulesJson,
  }) async {
    final cacheKey =
        '${chapter.url}:${chapter.title.hashCode}:$chineseConvertType';
    final cached = _convertedTitleCache[cacheKey];
    if (cached != null) return cached;
    final titleRules = rulesJson
        .map((json) => ReplaceRule.fromJson(json))
        .where((rule) => rule.isEnabled && rule.scopeTitle)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final converted = await ReaderPerfTrace.measureAsync(
      'convert title chapter ${chapter.index}',
      () async {
        final displayTitle = await chapter.getDisplayTitle(
          replaceRules: titleRules,
          chineseConvertType: 0,
        );
        return _textConverter.convert(
          displayTitle,
          convertType: chineseConvertType,
        );
      },
    );
    _convertedTitleCache[cacheKey] = converted;
    if (_convertedTitleCache.length > 24) {
      _convertedTitleCache.remove(_convertedTitleCache.keys.first);
    }
    return converted;
  }
}
