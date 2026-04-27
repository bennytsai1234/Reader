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
import 'package:inkpage_reader/features/reader/engine/chapter_content_manager.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_loader.dart';

import 'book_content.dart';

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

  List<BookChapter> get chapters => List<BookChapter>.unmodifiable(_chapters);
  int get chapterCount => _chapters.length;

  Future<List<BookChapter>> ensureChapters() async {
    if (_chapters.isNotEmpty) return chapters;
    _chapters = await chapterDao.getByBook(book.bookUrl);
    if (_chapters.isNotEmpty) return chapters;
    final source = await _ensureSource();
    if (source == null) return chapters;
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
    final cached = _contentCache[chapterIndex];
    if (cached != null) return cached;
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
      _contentCache[chapterIndex] = content;
      return content;
    }

    var raw = (chapter.content ?? '').trim();
    if (raw.isEmpty) {
      raw = (await _readCachedContent(chapterIndex, chapter) ?? '').trim();
    }
    if (raw.isEmpty) {
      raw = (await _fetchRemoteContent(chapterIndex, chapter) ?? '').trim();
    }
    final content = BookContent.fromRaw(
      chapterIndex: chapterIndex,
      title: chapter.title,
      rawText: raw,
    );
    _contentCache[chapterIndex] = content;
    return content;
  }

  void clearContentCache() => _contentCache.clear();

  Future<String?> _readCachedContent(
    int chapterIndex,
    BookChapter chapter,
  ) async {
    final dao = contentDao;
    if (dao == null) return null;
    final contentKey = ReaderChapterContentDao.contentKey(
      origin: book.origin,
      bookUrl: book.bookUrl,
      chapterUrl: chapter.url,
    );
    return dao.getContent(contentKey: contentKey);
  }

  Future<String?> _fetchRemoteContent(
    int chapterIndex,
    BookChapter chapter,
  ) async {
    final source = await _ensureSource();
    if (source == null) return chapter.content;
    final nextChapter = chapterAt(chapterIndex + 1);
    final raw = await service.getContent(
      source,
      book,
      chapter,
      nextChapterUrl: nextChapter?.url,
    );
    final dao = contentDao;
    if (dao != null && raw.trim().isNotEmpty) {
      await dao.saveContent(
        contentKey: ReaderChapterContentDao.contentKey(
          origin: book.origin,
          bookUrl: book.bookUrl,
          chapterUrl: chapter.url,
        ),
        origin: book.origin,
        bookUrl: book.bookUrl,
        chapterUrl: chapter.url,
        chapterIndex: chapterIndex,
        content: raw,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }
    return raw;
  }

  Future<BookSource?> _ensureSource() async {
    if (_source != null) return _source;
    if (book.origin.isEmpty || book.origin == 'local') return null;
    _source = await sourceDao.getByUrl(book.origin);
    return _source;
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
