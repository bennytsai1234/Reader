import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/reader_chapter_content_store.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_fetch_result.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_loader.dart';

import 'book_content.dart';

class ChapterRepositoryException implements Exception {
  const ChapterRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ChapterRepository {
  ChapterRepository({
    required this.book,
    List<BookChapter> initialChapters = const <BookChapter>[],
    BookDao? bookDao,
    ChapterDao? chapterDao,
    ReplaceRuleDao? replaceDao,
    BookSourceDao? sourceDao,
    ReaderChapterContentDao? contentDao,
    BookSourceService? service,
    int Function()? currentChineseConvert,
  }) : bookDao = bookDao ?? getIt<BookDao>(),
       chapterDao = chapterDao ?? getIt<ChapterDao>(),
       replaceDao =
           replaceDao ??
           (getIt.isRegistered<ReplaceRuleDao>()
               ? getIt<ReplaceRuleDao>()
               : null),
       sourceDao = sourceDao ?? getIt<BookSourceDao>(),
       contentDao =
           contentDao ??
           (getIt.isRegistered<ReaderChapterContentDao>()
               ? getIt<ReaderChapterContentDao>()
               : null),
       service = service ?? BookSourceService(),
       currentChineseConvert = currentChineseConvert ?? (() => 0),
       _chapters = List<BookChapter>.from(initialChapters);

  final Book book;
  final BookDao bookDao;
  final ChapterDao chapterDao;
  final ReplaceRuleDao? replaceDao;
  final BookSourceDao sourceDao;
  final ReaderChapterContentDao? contentDao;
  final BookSourceService service;
  final int Function() currentChineseConvert;

  List<BookChapter> _chapters;
  BookSource? _source;
  final Map<int, BookContent> _contentCache = <int, BookContent>{};
  final Map<int, Future<BookContent>> _contentInFlight =
      <int, Future<BookContent>>{};
  int _contentCacheGeneration = 0;

  List<BookChapter> get chapters => List<BookChapter>.unmodifiable(_chapters);
  int get chapterCount => _chapters.length;

  Future<List<BookChapter>> ensureChapters() async {
    if (_chapters.isNotEmpty) return chapters;
    _chapters = await chapterDao.getByBook(book.bookUrl);
    if (_chapters.isNotEmpty) return chapters;
    final source = await _ensureSource();
    if (source == null) {
      if (book.origin == 'local') {
        throw const ChapterRepositoryException('本地書籍章節目錄不存在，請重新匯入');
      }
      throw const ChapterRepositoryException('章節目錄載入失敗: 找不到書源');
    }
    final fetched = await service.getChapterList(source, book);
    for (var i = 0; i < fetched.length; i++) {
      fetched[i].index = i;
      fetched[i].bookUrl = book.bookUrl;
    }
    if (fetched.isNotEmpty) {
      await chapterDao.insertChapters(fetched);
      _chapters = fetched;
    }
    return chapters;
  }

  BookChapter? chapterAt(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= _chapters.length) return null;
    return _chapters[chapterIndex];
  }

  String titleFor(int chapterIndex) {
    return chapterAt(chapterIndex)?.title ?? '';
  }

  Future<BookContent> loadContent(int chapterIndex) async {
    await ensureChapters();
    final safeIndex = _normalizeChapterIndex(chapterIndex);
    final cached = _contentCache[safeIndex];
    if (cached != null) return cached;
    final inFlight = _contentInFlight[safeIndex];
    if (inFlight != null) return inFlight;
    late final Future<BookContent> task;
    task = _loadContentUncached(safeIndex, _contentCacheGeneration);
    _contentInFlight[safeIndex] = task;
    try {
      return await task;
    } finally {
      if (identical(_contentInFlight[safeIndex], task)) {
        _contentInFlight.remove(safeIndex);
      }
    }
  }

  Future<BookContent?> preloadContent(int chapterIndex) async {
    await ensureChapters();
    if (!_isValidChapterIndex(chapterIndex)) return null;
    return loadContent(chapterIndex);
  }

  Future<void> preloadContentAround(int chapterIndex, {int radius = 1}) async {
    await ensureChapters();
    if (_chapters.isEmpty) return;
    final safeCenter = _normalizeChapterIndex(chapterIndex);
    final tasks = <Future<BookContent?>>[];
    for (
      var index = safeCenter - radius;
      index <= safeCenter + radius;
      index++
    ) {
      if (_isValidChapterIndex(index)) {
        tasks.add(preloadContent(index));
      }
    }
    await Future.wait(tasks);
  }

  BookContent? cachedContent(int chapterIndex) {
    return _contentCache[chapterIndex];
  }

  bool isContentLoading(int chapterIndex) {
    return _contentInFlight.containsKey(chapterIndex);
  }

  Future<BookContent> _loadContentUncached(
    int chapterIndex,
    int cacheGeneration,
  ) async {
    final chapter = chapterAt(chapterIndex);
    if (chapter == null) {
      return BookContent.fromRaw(
        chapterIndex: chapterIndex,
        title: '',
        rawText: '',
      );
    }
    final loaded = await _loadViaExistingContentPipeline(chapterIndex, chapter);
    if (loaded != null) {
      final content = BookContent.fromRaw(
        chapterIndex: chapterIndex,
        title: loaded.displayTitle ?? chapter.title,
        rawText: loaded.content,
      );
      if (cacheGeneration == _contentCacheGeneration) {
        _contentCache[chapterIndex] = content;
      }
      return content;
    }

    final content = BookContent.fromRaw(
      chapterIndex: chapterIndex,
      title: chapter.title,
      rawText: (chapter.content ?? '').trim(),
    );
    if (cacheGeneration == _contentCacheGeneration) {
      _contentCache[chapterIndex] = content;
    }
    return content;
  }

  void clearContentCache() {
    _contentCacheGeneration += 1;
    _contentCache.clear();
    _contentInFlight.clear();
  }

  Future<BookSource?> _ensureSource() async {
    if (_source != null) return _source;
    if (book.origin.isEmpty || book.origin == 'local') return null;
    _source = await sourceDao.getByUrl(book.origin);
    return _source;
  }

  bool _isValidChapterIndex(int chapterIndex) {
    return chapterIndex >= 0 && chapterIndex < _chapters.length;
  }

  int _normalizeChapterIndex(int chapterIndex) {
    if (_chapters.isEmpty) return chapterIndex < 0 ? 0 : chapterIndex;
    return chapterIndex.clamp(0, _chapters.length - 1).toInt();
  }

  Future<FetchResult?> _loadViaExistingContentPipeline(
    int chapterIndex,
    BookChapter chapter,
  ) async {
    final contentDao = this.contentDao;
    final replaceDao = this.replaceDao;
    if (contentDao == null || replaceDao == null) return null;
    final loader = ReaderChapterContentLoader(
      book: book,
      contentStore: ReaderChapterContentStore(
        chapterDao: chapterDao,
        contentDao: contentDao,
      ),
      replaceDao: replaceDao,
      sourceDao: sourceDao,
      service: service,
      currentChineseConvert: currentChineseConvert,
      getSource: () => _source,
      setSource: (source) => _source = source,
      resolveNextChapterUrl: (index) => chapterAt(index + 1)?.url,
    );
    return loader.load(chapterIndex, chapter);
  }
}
