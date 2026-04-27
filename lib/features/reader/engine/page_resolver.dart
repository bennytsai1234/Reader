import 'chapter_layout.dart';
import 'chapter_repository.dart';
import 'layout_engine.dart';
import 'layout_spec.dart';
import 'reader_location.dart';
import 'text_page.dart';
import '../runtime/page_window.dart';

class PageAddress {
  const PageAddress({required this.chapterIndex, required this.pageIndex});

  final int chapterIndex;
  final int pageIndex;
}

class PageResolver {
  PageResolver({
    required this.repository,
    required this.layoutEngine,
    required this.layoutSpec,
  });

  final ChapterRepository repository;
  final LayoutEngine layoutEngine;
  LayoutSpec layoutSpec;
  final Map<int, ChapterLayout> _layouts = <int, ChapterLayout>{};
  final Map<String, Future<ChapterLayout>> _inFlight =
      <String, Future<ChapterLayout>>{};
  final Map<int, String> _layoutErrors = <int, String>{};

  int get chapterCount => repository.chapterCount;

  void updateLayoutSpec(LayoutSpec spec) {
    if (layoutSpec.layoutSignature == spec.layoutSignature) return;
    layoutSpec = spec;
    _layouts.clear();
  }

  ChapterLayout? cachedLayout(int chapterIndex) => _layouts[chapterIndex];

  void clearCachedLayouts() {
    _layouts.clear();
    _inFlight.clear();
    _layoutErrors.clear();
  }

  Future<ChapterLayout> ensureLayout(int chapterIndex) async {
    await repository.ensureChapters();
    final safeIndex = _normalizeChapterIndex(chapterIndex);
    final cached = _layouts[safeIndex];
    if (cached != null &&
        cached.layoutSignature == layoutSpec.layoutSignature) {
      return cached;
    }
    final spec = layoutSpec;
    final taskKey = '$safeIndex|${spec.layoutSignature}';
    final inFlight = _inFlight[taskKey];
    if (inFlight != null) return inFlight;
    late final Future<ChapterLayout> task;
    task = () async {
      try {
        final content = await repository.loadContent(safeIndex);
        final layout = layoutEngine.layout(
          content,
          spec,
          chapterSize: repository.chapterCount,
        );
        if (layoutSpec.layoutSignature == spec.layoutSignature) {
          _layouts[safeIndex] = layout;
          _layoutErrors.remove(safeIndex);
        }
        return layout;
      } catch (e) {
        _layoutErrors[safeIndex] = e.toString();
        rethrow;
      }
    }();
    _inFlight[taskKey] = task;
    try {
      return await task;
    } finally {
      if (identical(_inFlight[taskKey], task)) {
        _inFlight.remove(taskKey);
      }
    }
  }

  bool isLoading(int chapterIndex) {
    final prefix = '$chapterIndex|';
    return _inFlight.keys.any((key) => key.startsWith(prefix));
  }

  Future<TextPage> pageForLocation(ReaderLocation location) async {
    final layout = await ensureLayout(location.chapterIndex);
    return layout.pageForCharOffset(location.charOffset);
  }

  Future<PageWindow> buildWindowAround(
    ReaderLocation location, {
    int lookAheadCount = 0,
  }) async {
    final current = await pageForLocation(location);
    final prev = await prevPage(current, allowAsyncLoad: true);
    final next = await nextPage(current, allowAsyncLoad: true);
    return PageWindow(
      prev: prev,
      current: current,
      next: next,
      lookAhead:
          lookAheadCount <= 0
              ? const <TextPage>[]
              : await lookAheadPages(after: next, maxCount: lookAheadCount),
    );
  }

  Future<TextPage?> nextPage(
    TextPage page, {
    bool allowAsyncLoad = false,
  }) async {
    final layout =
        allowAsyncLoad
            ? await ensureLayout(page.chapterIndex)
            : cachedLayout(page.chapterIndex);
    final pages = layout?.pages ?? const <TextPage>[];
    if (page.pageIndex + 1 < pages.length) {
      return pages[page.pageIndex + 1];
    }
    final nextChapterIndex = page.chapterIndex + 1;
    if (nextChapterIndex >= repository.chapterCount) return null;
    final nextLayout =
        allowAsyncLoad
            ? await ensureLayout(nextChapterIndex)
            : cachedLayout(nextChapterIndex);
    if (nextLayout == null || nextLayout.pages.isEmpty) return null;
    return nextLayout.pages.first;
  }

  Future<TextPage?> prevPage(
    TextPage page, {
    bool allowAsyncLoad = false,
  }) async {
    final layout =
        allowAsyncLoad
            ? await ensureLayout(page.chapterIndex)
            : cachedLayout(page.chapterIndex);
    final pages = layout?.pages ?? const <TextPage>[];
    if (page.pageIndex > 0 && page.pageIndex <= pages.length - 1) {
      return pages[page.pageIndex - 1];
    }
    final prevChapterIndex = page.chapterIndex - 1;
    if (prevChapterIndex < 0) return null;
    final prevLayout =
        allowAsyncLoad
            ? await ensureLayout(prevChapterIndex)
            : cachedLayout(prevChapterIndex);
    if (prevLayout == null || prevLayout.pages.isEmpty) return null;
    return prevLayout.pages.last;
  }

  TextPage? nextPageSync(TextPage page) {
    if (page.isPlaceholder) return null;
    final layout = cachedLayout(page.chapterIndex);
    final pages = layout?.pages ?? const <TextPage>[];
    if (page.pageIndex + 1 < pages.length) {
      return pages[page.pageIndex + 1];
    }
    final nextLayout = cachedLayout(page.chapterIndex + 1);
    if (nextLayout == null || nextLayout.pages.isEmpty) return null;
    return nextLayout.pages.first;
  }

  TextPage? prevPageSync(TextPage page) {
    if (page.isPlaceholder) return null;
    final layout = cachedLayout(page.chapterIndex);
    final pages = layout?.pages ?? const <TextPage>[];
    if (page.pageIndex > 0 && page.pageIndex <= pages.length - 1) {
      return pages[page.pageIndex - 1];
    }
    final prevLayout = cachedLayout(page.chapterIndex - 1);
    if (prevLayout == null || prevLayout.pages.isEmpty) return null;
    return prevLayout.pages.last;
  }

  TextPage? nextPageOrPlaceholder(TextPage page) {
    final next = nextPageSync(page);
    if (next != null) return next;
    final nextChapterIndex = page.chapterIndex + 1;
    if (nextChapterIndex >= repository.chapterCount) return null;
    return placeholderPageFor(nextChapterIndex);
  }

  TextPage? prevPageOrPlaceholder(TextPage page) {
    final prev = prevPageSync(page);
    if (prev != null) return prev;
    final prevChapterIndex = page.chapterIndex - 1;
    if (prevChapterIndex < 0) return null;
    return placeholderPageFor(prevChapterIndex);
  }

  TextPage placeholderPageFor(int chapterIndex) {
    final error = _layoutErrors[chapterIndex];
    final message = error == null ? '載入中...' : '章節載入失敗';
    final height =
        layoutSpec.contentHeight <= 0 ? 1.0 : layoutSpec.contentHeight;
    final top = (height / 2 - layoutSpec.style.fontSize).clamp(0.0, height);
    return TextPage(
      pageIndex: 0,
      chapterIndex: chapterIndex,
      chapterSize: repository.chapterCount,
      title: repository.titleFor(chapterIndex),
      height: height,
      startCharOffset: 0,
      endCharOffset: 0,
      isChapterStart: true,
      isChapterEnd: true,
      isLoading: error == null,
      errorMessage: error,
      lines: <TextLine>[
        TextLine(
          text: message,
          width: layoutSpec.contentWidth,
          height: layoutSpec.style.fontSize * layoutSpec.style.lineHeight,
          isTitle: true,
          chapterPosition: 0,
          startCharOffset: 0,
          endCharOffset: 0,
          lineTop: top,
          lineBottom:
              top + layoutSpec.style.fontSize * layoutSpec.style.lineHeight,
        ),
      ],
    );
  }

  Future<List<TextPage>> lookAheadPages({
    required TextPage? after,
    required int maxCount,
  }) async {
    if (after == null || maxCount <= 0) return const <TextPage>[];
    final pages = <TextPage>[];
    var cursor = after;
    while (pages.length < maxCount) {
      final next = await nextPage(cursor, allowAsyncLoad: true);
      if (next == null) break;
      pages.add(next);
      cursor = next;
    }
    return List<TextPage>.unmodifiable(pages);
  }

  PageAddress addressOf(TextPage page) {
    return PageAddress(
      chapterIndex: page.chapterIndex,
      pageIndex: page.pageIndex,
    );
  }

  int _normalizeChapterIndex(int chapterIndex) {
    final count = repository.chapterCount;
    if (count <= 0) return chapterIndex < 0 ? 0 : chapterIndex;
    return chapterIndex.clamp(0, count - 1).toInt();
  }
}
