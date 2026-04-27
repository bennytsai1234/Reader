import 'dart:async';

import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/engine/reader/chinese_text_converter.dart';
import 'package:inkpage_reader/core/engine/reader/content_processor.dart'
    as engine;
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book/book_content.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_fetch_result.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_store.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_storage.dart';
import 'package:inkpage_reader/features/reader/engine/reader_perf_trace.dart';

class ReaderChapterContentLoader {
  ReaderChapterContentLoader({
    required this.book,
    this.contentStore,
    required this.replaceDao,
    required BookSourceDao sourceDao,
    required BookSourceService service,
    required this.currentChineseConvert,
    required this.getSource,
    required this.setSource,
    this.resolveNextChapterUrl,
    ReaderChapterContentStorage? contentStorage,
  }) : _contentStorage =
           contentStorage ??
           (contentStore == null
               ? null
               : ReaderChapterContentStorage.withMaterializer(
                 book: book,
                 contentStore: contentStore,
                 sourceDao: sourceDao,
                 service: service,
                 getSource: getSource,
                 setSource: setSource,
                 resolveNextChapterUrl: resolveNextChapterUrl,
               ));

  final Book book;
  final ReaderChapterContentStore? contentStore;
  final ReplaceRuleDao replaceDao;
  final int Function() currentChineseConvert;
  final BookSource? Function() getSource;
  final void Function(BookSource source) setSource;
  final String? Function(int chapterIndex)? resolveNextChapterUrl;
  final ReaderChapterContentStorage? _contentStorage;
  final ChineseTextConverter _textConverter = const ChineseTextConverter();

  List<Map<String, dynamic>>? _cachedRulesJson;
  final Map<String, String> _convertedContentCache = <String, String>{};
  final Map<String, String> _convertedTitleCache = <String, String>{};

  Future<FetchResult> load(int chapterIndex, BookChapter chapter) async {
    final storage = _contentStorage;
    if (storage == null) {
      return _failureResult(chapter, '正文 storage 不可用');
    }
    final prepared = await storage.read(
      chapterIndex: chapterIndex,
      chapter: chapter,
      saveChapterMetadata: book.origin != 'local',
    );
    final rawContent = prepared.content;
    if (prepared.isFailed || _looksLikeFailureMessage(rawContent)) {
      return _failureResult(chapter, rawContent);
    }
    final rulesJson = await _loadRulesJson();
    final chineseConvertType = currentChineseConvert();

    final BookContent bookContent = await ReaderPerfTrace.measureAsync(
      'process content chapter $chapterIndex',
      () => engine.ContentProcessor.process(
        book: book,
        chapter: chapter,
        rawContent: rawContent,
        rulesJson: rulesJson,
        useReplaceRules: book.getUseReplaceRule(),
        reSegmentEnabled: book.getReSegment(),
      ),
    );
    final convertedTitle = _getConvertedTitle(
      chapter: chapter,
      chineseConvertType: chineseConvertType,
      rulesJson: rulesJson,
    );
    final convertedContent = _getConvertedContent(
      chapterIndex: chapterIndex,
      rawContent: rawContent,
      processedContent: bookContent.content,
      chineseConvertType: chineseConvertType,
    );
    return FetchResult(content: convertedContent, displayTitle: convertedTitle);
  }

  void resetProcessingContext() {
    _cachedRulesJson = null;
    _convertedContentCache.clear();
    _convertedTitleCache.clear();
    _contentStorage?.reset();
  }

  FetchResult _failureResult(BookChapter chapter, String message) {
    final failureTitle = _textConverter.convert(
      chapter.getDisplayTitle(chineseConvertType: currentChineseConvert()),
      convertType: currentChineseConvert(),
    );
    return FetchResult(
      content: message,
      displayTitle: failureTitle,
      failureMessage: message,
    );
  }

  Future<List<Map<String, dynamic>>> _loadRulesJson() async {
    _cachedRulesJson ??=
        (await replaceDao.getEnabled())
            .map((r) => r.toJson())
            .toList()
            .cast<Map<String, dynamic>>();
    return _cachedRulesJson!;
  }

  String _getConvertedContent({
    required int chapterIndex,
    required String rawContent,
    required String processedContent,
    required int chineseConvertType,
  }) {
    final cacheKey =
        '$chapterIndex:$chineseConvertType:${rawContent.hashCode}:${processedContent.hashCode}';
    final cached = _convertedContentCache[cacheKey];
    if (cached != null) return cached;
    final converted = ReaderPerfTrace.measureSync(
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

  String _getConvertedTitle({
    required BookChapter chapter,
    required int chineseConvertType,
    required List<Map<String, dynamic>> rulesJson,
  }) {
    final cacheKey =
        '${chapter.url}:${chapter.title.hashCode}:$chineseConvertType';
    final cached = _convertedTitleCache[cacheKey];
    if (cached != null) return cached;
    final titleRules =
        rulesJson
            .map((json) => ReplaceRule.fromJson(json))
            .where((rule) => rule.isEnabled && rule.scopeTitle)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final converted = ReaderPerfTrace.measureSync(
      'convert title chapter ${chapter.index}',
      () {
        final displayTitle = chapter.getDisplayTitle(
          replaceRules: titleRules,
          useReplace: book.getUseReplaceRule(),
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

  bool _looksLikeFailureMessage(String rawContent) {
    final trimmed = rawContent.trim();
    return trimmed.startsWith('加載章節失敗') || trimmed.startsWith('章節內容為空');
  }
}
