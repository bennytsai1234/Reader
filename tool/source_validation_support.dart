import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/engine/analyze_rule.dart';
import 'package:inkpage_reader/core/engine/analyze_url.dart';
import 'package:inkpage_reader/core/engine/explore_url_parser.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/network_service.dart';

import '../test/test_helper.dart';

const String sourceListUrl =
    'https://shuyuan.nyasama.net/shuyuan/382015f6ff010d7fee368c6daabd5081.json';
const String _sourceListCacheRelativePath =
    '.cache/inkpage_reader/source_lists/382015f6ff010d7fee368c6daabd5081.json';

class SourceValidationResult {
  final int index;
  final String sourceName;
  final bool passed;
  final String stage;
  final String? keyword;
  final String? bookName;
  final String? bookUrl;
  final int? chapterCount;
  final String? firstChapterTitle;
  final String? secondChapterTitle;
  final String? failure;
  final Duration duration;

  const SourceValidationResult({
    required this.index,
    required this.sourceName,
    required this.passed,
    required this.stage,
    required this.duration,
    this.keyword,
    this.bookName,
    this.bookUrl,
    this.chapterCount,
    this.firstChapterTitle,
    this.secondChapterTitle,
    this.failure,
  });

  String toSummaryLine() {
    final status = passed ? 'PASS' : 'FAIL';
    final info = <String>[
      '#$index',
      sourceName,
      status,
      'stage=$stage',
      if (keyword != null && keyword!.isNotEmpty) 'keyword="$keyword"',
      if (bookName != null && bookName!.isNotEmpty) 'book="$bookName"',
      if (chapterCount != null) 'chapters=$chapterCount',
      if (firstChapterTitle != null && firstChapterTitle!.isNotEmpty)
        'first="$firstChapterTitle"',
      if (failure != null && failure!.isNotEmpty) 'reason="$failure"',
      'time=${duration.inSeconds}s',
    ];
    return info.join(' | ');
  }
}

class _FallbackChapterDao implements ChapterDao {
  @override
  Future<List<BookChapter>> getByBook(String bookUrl) async =>
      const <BookChapter>[];

  @override
  Future<List<BookChapter>> getChapters(String bookUrl) async =>
      const <BookChapter>[];

  @override
  Future<String?> getContent(String url) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> initSourceValidationEnvironment() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupTestDI();
  if (!getIt.isRegistered<ChapterDao>()) {
    getIt.registerLazySingleton<ChapterDao>(() => _FallbackChapterDao());
  }
  HttpOverrides.global = _PassthroughHttpOverrides();
  await NetworkService().init();
}

List<BookSource> decodeSourcesPayload(String payload, {int? limit}) {
  final decoded = jsonDecode(normalizeSourcesPayload(payload));
  final items = decoded is List<dynamic> ? decoded : <dynamic>[decoded];
  return items
      .take(limit ?? items.length)
      .map((item) => BookSource.fromJson(item as Map<String, dynamic>))
      .toList();
}

Future<List<BookSource>> fetchSources({required int limit}) async {
  final singleSourceFile = Platform.environment['SOURCE_JSON_FILE']?.trim();
  if (singleSourceFile != null && singleSourceFile.isNotEmpty) {
    return _loadSourcesFromFile(singleSourceFile, limit: limit);
  }

  final sourceListFile = Platform.environment['SOURCE_LIST_FILE']?.trim();
  if (sourceListFile != null && sourceListFile.isNotEmpty) {
    try {
      return await _loadSourcesFromFile(sourceListFile, limit: limit);
    } catch (_) {
      final cached = await _tryLoadCachedSources(limit: limit);
      if (cached != null) return cached;
      rethrow;
    }
  }

  final cacheFile = _resolveSourceListCacheFile();
  final result = await Process.run('curl', <String>[
    '-L',
    '--fail',
    '--silent',
    '--show-error',
    '--max-time',
    '30',
    sourceListUrl,
  ]);
  if (result.exitCode != 0) {
    final cached = await _tryLoadCachedSources(limit: limit);
    if (cached != null) return cached;
    throw StateError('fetch source list failed: ${result.stderr}');
  }
  try {
    final payload = normalizeSourcesPayload(result.stdout as String);
    await _writeSourceListCache(cacheFile, payload);
    return decodeSourcesPayload(payload, limit: limit);
  } catch (error) {
    final cached = await _tryLoadCachedSources(limit: limit);
    if (cached != null) return cached;
    throw StateError('fetch source list returned invalid payload: $error');
  }
}

String normalizeSourcesPayload(String payload) {
  final trimmed = payload.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('source list payload is empty');
  }
  final normalized = _extractJsonPayload(trimmed);
  final first = normalized[0];
  if (first != '[' && first != '{') {
    throw FormatException(
      'source list payload is not JSON: ${normalized.substring(0, math.min(80, normalized.length))}',
    );
  }
  return normalized;
}

Future<List<BookSource>> _loadSourcesFromFile(
  String filePath, {
  required int limit,
}) async {
  final payload = await File(filePath).readAsString();
  final normalized = normalizeSourcesPayload(payload);
  if (filePath != _resolveSourceListCacheFile().path &&
      _looksLikeSourceListPayload(normalized)) {
    await _writeSourceListCache(_resolveSourceListCacheFile(), normalized);
  }
  return decodeSourcesPayload(normalized, limit: limit);
}

Future<List<BookSource>?> _tryLoadCachedSources({required int limit}) async {
  final cacheFile = _resolveSourceListCacheFile();
  if (!await cacheFile.exists()) return null;
  try {
    return await _loadSourcesFromFile(cacheFile.path, limit: limit);
  } catch (_) {
    return null;
  }
}

File _resolveSourceListCacheFile() {
  final override = Platform.environment['SOURCE_LIST_CACHE_FILE']?.trim();
  if (override != null && override.isNotEmpty) {
    return File(override);
  }
  final homeDir =
      Platform.environment['HOME']?.trim().isNotEmpty == true
          ? Platform.environment['HOME']!.trim()
          : Directory.current.path;
  return File('$homeDir/$_sourceListCacheRelativePath');
}

Future<void> _writeSourceListCache(File file, String payload) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(payload);
}

String _extractJsonPayload(String payload) {
  if (payload.startsWith('[') || payload.startsWith('{')) {
    return payload;
  }

  final htmlEnd = payload.lastIndexOf('</html>');
  if (htmlEnd != -1) {
    final trailing = payload.substring(htmlEnd + '</html>'.length).trim();
    if (trailing.startsWith('[') || trailing.startsWith('{')) {
      return trailing;
    }
  }

  final firstSourceName = payload.indexOf('"bookSourceName"');
  if (firstSourceName != -1) {
    final arrayStart = payload.lastIndexOf('[', firstSourceName);
    final objectStart = payload.lastIndexOf('{', firstSourceName);
    final start =
        arrayStart != -1 && arrayStart < objectStart ? arrayStart : objectStart;
    if (start != -1) {
      final candidate = payload.substring(start).trim();
      if (candidate.startsWith('[') || candidate.startsWith('{')) {
        return candidate;
      }
    }
  }

  return payload;
}

bool _looksLikeSourceListPayload(String payload) =>
    payload.contains('"bookSourceName"') && payload.contains('"bookSourceUrl"');

Future<SourceValidationResult> validateSourceFlow(
  BookSourceService service,
  BookSource source, {
  required int index,
}) async {
  final stopwatch = Stopwatch()..start();
  const maxContentProbe = 5;
  var stage = 'init';
  String? keyword;
  Book? selectedBook;
  Book? hydratedBook;
  List<BookChapter> chapters = const <BookChapter>[];
  List<BookChapter> readableChapters = const <BookChapter>[];
  BookChapter? firstReadableChapter;
  BookChapter? secondReadableChapter;
  int? firstReadableIndex;
  final contentCache = <int, String>{};

  try {
    stage = 'keyword';
    keyword = await pickKeyword(service, source);

    stage = 'search';
    final searchBooks = await service.searchBooks(source, keyword);
    if (searchBooks.isEmpty) {
      throw StateError('搜尋 "$keyword" 沒有結果');
    }

    selectedBook = selectBook(searchBooks);

    stage = 'detail';
    hydratedBook = await service.getBookInfo(source, selectedBook);
    if (hydratedBook.name.trim().isEmpty) {
      throw StateError('詳情頁書名為空');
    }
    if (hydratedBook.bookUrl.trim().isEmpty) {
      throw StateError('詳情頁 bookUrl 為空');
    }

    stage = 'toc';
    chapters = await service.getChapterList(source, hydratedBook);
    readableChapters = chapters.where((chapter) => !chapter.isVolume).toList();
    if (readableChapters.isEmpty) {
      throw StateError('目錄沒有可閱讀章節');
    }

    Future<String> loadChapterContent(int chapterIndex) async {
      final cached = contentCache[chapterIndex];
      if (cached != null) {
        return cached;
      }
      final chapter = readableChapters[chapterIndex];
      final content = await service.getContent(
        source,
        hydratedBook!,
        chapter,
        nextChapterUrl:
            readableChapters.length > chapterIndex + 1
                ? readableChapters[chapterIndex + 1].url
                : null,
      );
      contentCache[chapterIndex] = content;
      return content;
    }

    stage = 'content:first';
    final firstProbeIndexes = buildContentProbeIndexes(
      readableChapters,
      maxContentProbe,
    );
    for (final i in firstProbeIndexes) {
      final chapter = readableChapters[i];
      final content = await loadChapterContent(i);
      if (looksReadable(content)) {
        firstReadableChapter = chapter;
        firstReadableIndex = i;
        if (readableChapters.length <= 1) {
          break;
        }

        stage = 'content:second';
        final secondProbeIndexes = buildNeighborProbeIndexes(
          readableChapters,
          i,
          maxContentProbe,
        );
        for (final secondIndex in secondProbeIndexes) {
          final secondChapter = readableChapters[secondIndex];
          final secondContent = await loadChapterContent(secondIndex);
          if (looksReadable(secondContent)) {
            secondReadableChapter = secondChapter;
            break;
          }
        }
        if (secondReadableChapter != null || secondProbeIndexes.isEmpty) {
          break;
        }
        stage = 'content:first';
      }
    }
    if (firstReadableChapter == null) {
      throw StateError('前幾章正文疑似解析失敗');
    }

    if (readableChapters.length > 1 && secondReadableChapter == null) {
      stage = 'content:second';
      final secondProbeIndexes = buildNeighborProbeIndexes(
        readableChapters,
        firstReadableIndex!,
        maxContentProbe,
      );
      if (secondProbeIndexes.isNotEmpty) {
        throw StateError('後續章節正文疑似解析失敗');
      }
    }

    stopwatch.stop();
    return SourceValidationResult(
      index: index,
      sourceName: source.bookSourceName,
      passed: true,
      stage: stage,
      duration: stopwatch.elapsed,
      keyword: keyword,
      bookName: hydratedBook.name,
      bookUrl: hydratedBook.bookUrl,
      chapterCount: chapters.length,
      firstChapterTitle: firstReadableChapter.title,
      secondChapterTitle: secondReadableChapter?.title,
    );
  } catch (error) {
    stopwatch.stop();
    return SourceValidationResult(
      index: index,
      sourceName: source.bookSourceName,
      passed: false,
      stage: stage,
      duration: stopwatch.elapsed,
      keyword: keyword,
      bookName: hydratedBook?.name ?? selectedBook?.name,
      bookUrl: hydratedBook?.bookUrl ?? selectedBook?.bookUrl,
      chapterCount: chapters.isEmpty ? null : chapters.length,
      firstChapterTitle:
          firstReadableChapter?.title ??
          (readableChapters.isNotEmpty ? readableChapters.first.title : null),
      secondChapterTitle: secondReadableChapter?.title,
      failure: compactError(error),
    );
  }
}

String compactError(Object error) {
  final message = error.toString().trim();
  if (message.isEmpty) return 'unknown error';
  final firstLine = message.split('\n').first.trim();
  return firstLine.length > 160 ? firstLine.substring(0, 160) : firstLine;
}

Future<String> pickKeyword(BookSourceService service, BookSource source) async {
  final checkKeyword = source.ruleSearch?.checkKeyWord;
  if (checkKeyword != null && checkKeyword.trim().isNotEmpty) {
    final keyword = checkKeyword.trim();
    try {
      final results = await service.searchBooks(source, keyword);
      if (results.isNotEmpty) {
        return keyword;
      }
    } catch (_) {}
  }

  final browseKeyword = await pickKeywordFromBrowse(service, source);
  if (browseKeyword != null && browseKeyword.isNotEmpty) {
    return browseKeyword;
  }

  const fallbackKeywords = <String>[
    '我的',
    '系统',
    '都市',
    '后宫',
    '修仙',
    '校花',
    '同人',
    '人妻',
    '萝莉',
    '保育',
    '龙王殿',
    '爱',
  ];

  for (final keyword in fallbackKeywords) {
    try {
      final results = await service.searchBooks(source, keyword);
      if (results.isNotEmpty) {
        return keyword;
      }
    } catch (_) {
      continue;
    }
  }

  throw StateError('${source.bookSourceName} 找不到可用測試關鍵詞');
}

Future<String?> findWorkingKeywordCandidate(
  BookSourceService service,
  BookSource source,
  String seed,
) async {
  String? fallbackKeyword;
  for (final keyword in buildKeywordCandidates(seed)) {
    try {
      final results = await service.searchBooks(source, keyword);
      if (results.isEmpty) {
        continue;
      }
      if (_plainKeywordPattern.hasMatch(keyword)) {
        return keyword;
      }
      final confirmed = await service.searchBooks(source, keyword);
      if (confirmed.isNotEmpty) {
        fallbackKeyword ??= keyword;
      }
    } catch (_) {
      continue;
    }
  }
  return fallbackKeyword;
}

Future<String?> pickKeywordFromBrowse(
  BookSourceService service,
  BookSource source,
) async {
  final fromExplore = await pickKeywordFromExplore(service, source);
  if (fromExplore != null && fromExplore.isNotEmpty) {
    return fromExplore;
  }
  return pickKeywordFromHomepage(service, source);
}

Future<String?> pickKeywordFromExplore(
  BookSourceService service,
  BookSource source,
) async {
  final exploreUrl = source.exploreUrl;
  if (exploreUrl == null || exploreUrl.trim().isEmpty) {
    return null;
  }
  try {
    final kinds = await ExploreUrlParser.parseAsync(exploreUrl, source: source);
    for (final kind in kinds) {
      final url = kind.url?.trim() ?? '';
      if (url.isEmpty) {
        continue;
      }
      final books = await service.exploreBooks(source, url, page: 1);
      for (final book in books.take(5)) {
        final name = book.name.trim();
        if (!looksLikeBookName(name)) {
          continue;
        }
        final matched = await findWorkingKeywordCandidate(
          service,
          source,
          name,
        );
        if (matched != null) {
          return matched;
        }
      }
    }
  } catch (_) {}
  return null;
}

Future<String?> pickKeywordFromHomepage(
  BookSourceService service,
  BookSource source,
) async {
  final searchRule = source.ruleSearch;
  if (searchRule?.bookList == null || searchRule!.bookList!.isEmpty) {
    return null;
  }
  final homeUrl = source.bookSourceUrl.split('#').first;
  final analyzeUrl = await AnalyzeUrl.create(homeUrl, source: source);
  final response = await analyzeUrl.getStrResponse();
  final listRule = AnalyzeRule(
    source: source,
  ).setContent(response.body, baseUrl: response.url);
  final items = listRule.getElements(searchRule.bookList!);
  for (final item in items.take(5)) {
    final itemRule = AnalyzeRule(
      source: source,
    ).setContent(item, baseUrl: response.url);
    final name = itemRule.getString(searchRule.name ?? '').trim();
    if (!looksLikeBookName(name)) {
      continue;
    }
    final matched = await findWorkingKeywordCandidate(service, source, name);
    if (matched != null) {
      return matched;
    }
  }

  final fallbackRule = AnalyzeRule(
    source: source,
  ).setContent(response.body, baseUrl: response.url);
  final anchorTexts = fallbackRule.getStringList('a@text');
  for (final text in anchorTexts) {
    final name = text.trim();
    if (!looksLikeBookName(name)) {
      continue;
    }
    final matched = await findWorkingKeywordCandidate(service, source, name);
    if (matched != null) {
      return matched;
    }
  }
  return null;
}

Book selectBook(List<SearchBook> searchBooks) {
  final selected = searchBooks.firstWhere(
    (book) => book.bookUrl.trim().isNotEmpty,
    orElse: () => searchBooks.first,
  );
  return selected.toBook();
}

bool looksReadable(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('加載章節失敗')) return false;
  if (trimmed.startsWith('章節內容為空')) return false;
  return trimmed.runes.length >= 20;
}

List<int> buildContentProbeIndexes(List<BookChapter> chapters, int maxProbe) {
  final preferred = <int>[];
  final fallback = <int>[];

  void addProbe(int index) {
    if (index < 0 || index >= chapters.length) return;
    if (preferred.contains(index) || fallback.contains(index)) return;
    if (isLikelyLockedChapter(chapters[index])) {
      fallback.add(index);
    } else {
      preferred.add(index);
    }
  }

  final headCount = math.min(maxProbe, chapters.length);
  for (var i = 0; i < headCount; i++) {
    addProbe(i);
  }

  final tailStart = math.max(chapters.length - maxProbe, 0);
  for (var i = tailStart; i < chapters.length; i++) {
    addProbe(i);
  }

  return <int>[...preferred, ...fallback];
}

List<int> buildNeighborProbeIndexes(
  List<BookChapter> chapters,
  int anchorIndex,
  int maxProbe,
) {
  final preferred = <int>[];
  final fallback = <int>[];

  void addProbe(int index) {
    if (index < 0 || index >= chapters.length) return;
    if (preferred.contains(index) || fallback.contains(index)) return;
    if (isLikelyLockedChapter(chapters[index])) {
      fallback.add(index);
    } else {
      preferred.add(index);
    }
  }

  final nextEnd = math.min(anchorIndex + 1 + maxProbe, chapters.length);
  for (var i = anchorIndex + 1; i < nextEnd; i++) {
    addProbe(i);
  }

  final prevStart = math.max(anchorIndex - maxProbe, 0);
  for (var i = anchorIndex - 1; i >= prevStart; i--) {
    addProbe(i);
  }

  return <int>[...preferred, ...fallback];
}

bool isLikelyLockedChapter(BookChapter chapter) {
  final title = chapter.title.trim().toUpperCase();
  return chapter.isVip || title.contains('🔒') || title.contains('VIP');
}

List<String> buildKeywordCandidates(String seed) {
  final candidates = <String>[];
  final trimmedSeed = seed.trim();

  void addCandidate(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) return;
    if (keyword.runes.length < 2) return;
    if (candidates.contains(keyword)) return;
    candidates.add(keyword);
  }

  if (_plainKeywordPattern.hasMatch(trimmedSeed)) {
    addCandidate(trimmedSeed);
  }

  final normalized =
      trimmedSeed
          .replaceAll(RegExp(r'[《》【】\[\]（）()<>]'), ' ')
          .replaceAll(RegExp(r'[:：,，.。!！?？/\\|_\-]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
  addCandidate(normalized);

  final joined = normalized.replaceAll(' ', '');
  addCandidate(joined);

  final tokenPattern = RegExp(r'[\u4e00-\u9fffA-Za-z0-9]+', unicode: true);
  final tokens =
      tokenPattern
          .allMatches(normalized)
          .map((match) => match.group(0)!)
          .where(looksLikeBookName)
          .toList();
  for (final token in tokens) {
    addCandidate(token);
  }

  for (var len = math.min(joined.runes.length, 6); len >= 2; len--) {
    addCandidate(String.fromCharCodes(joined.runes.take(len)));
  }

  addCandidate(trimmedSeed);

  return candidates;
}

bool looksLikeBookName(String text) {
  final value = text.trim();
  if (value.runes.length < 2 || value.runes.length > 24) {
    return false;
  }
  if (value.contains('登录') ||
      value.contains('注册') ||
      value.contains('首页') ||
      value.contains('上一章') ||
      value.contains('下一章')) {
    return false;
  }
  return RegExp(r'[\u4e00-\u9fffA-Za-z0-9]', unicode: true).hasMatch(value);
}

class _PassthroughHttpOverrides extends HttpOverrides {}

final RegExp _plainKeywordPattern = RegExp(
  r'^[\u4e00-\u9fffA-Za-z0-9]{2,24}$',
  unicode: true,
);
