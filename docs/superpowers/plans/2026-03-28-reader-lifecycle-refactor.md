# Reader Lifecycle & Core Reading Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Fix initialization jitter, slide-mode chapter jump bug, and scroll-mode boundary stutter by refactoring the reader's lifecycle management, slide window model, and scroll preloading strategy.

**Architecture:** Three-phase init pipeline replaces scattered notifyListeners calls. Segmented SlideWindow replaces flat page merge. Predictive scroll preload with sync-paginate fast path for local books. UI layer consolidated with init overlay + fade transition.

**Tech Stack:** Flutter/Dart, Provider + ChangeNotifier, ScrollablePositionedList, PageView

---

## File Structure

### New Files
| File | Purpose |
|------|---------|
| `lib/features/reader/provider/slide_window.dart` | `SlideWindow` + `SlideSegment` data structures for segmented slide indexing |
| `lib/features/reader/view/slide_page_controller.dart` | `SlidePageController` wrapper encapsulating PageView jump dedup/debounce |
| `lib/features/reader/provider/content_callbacks.dart` | Typed callback interface replacing `(this as dynamic)` casts |

### Modified Files
| File | Change Scope |
|------|-------------|
| `lib/features/reader/provider/reader_provider_base.dart` | Add `_batchUpdate`, override `notifyListeners`, simplify `ReaderLifecycle` enum |
| `lib/features/reader/runtime/read_book_controller.dart` | Rewrite `_init()` as three-phase pipeline, inject content callbacks, remove restoring logic |
| `lib/features/reader/provider/reader_content_mixin.dart` | Replace flat slidePages with `SlideWindow`, rewrite `onPageChanged`, add predictive preload, add `trySyncPaginate()`, remove `(this as dynamic)` |
| `lib/features/reader/provider/reader_progress_mixin.dart` | Remove `applyPendingRestore()` standalone, integrate into init phase 2, remove `(this as dynamic)` |
| `lib/features/reader/reader_page.dart` | Replace manual jump logic with `SlidePageController` |
| `lib/features/reader/view/read_view_runtime.dart` | Add init overlay + fade, simplify `_onProviderStateChanged` |
| `lib/features/reader/view/delegate/scroll_mode_delegate.dart` | Add sync-paginate fast path, estimated placeholder heights |
| `lib/features/reader/engine/chapter_content_manager.dart` | Add `paginateSync()` method |

---

### Task 1: Add `_batchUpdate` and `notifyListeners` Override to ReaderProviderBase

**Files:**
- Modify: `lib/features/reader/provider/reader_provider_base.dart:15-136`

This is the foundation — all subsequent lifecycle changes depend on batching notifications.

- [x] **Step 1: Simplify `ReaderLifecycle` enum**

In `lib/features/reader/provider/reader_provider_base.dart`, replace line 15:

```dart
// Old:
enum ReaderLifecycle { loading, restoring, ready, disposed }

// New:
enum ReaderLifecycle { loading, ready, disposed }
```

- [x] **Step 2: Add batch update fields and override `notifyListeners`**

In `lib/features/reader/provider/reader_provider_base.dart`, add after line 47 (after existing field declarations, before the DAO fields):

```dart
  // ── Batch update support ──────────────────────────────────────────
  bool _isBatching = false;
  bool _batchDirty = false;

  /// Run [fn] while suppressing intermediate notifyListeners calls.
  /// A single notifyListeners fires after [fn] completes if any state changed.
  void batchUpdate(VoidCallback fn) {
    _isBatching = true;
    _batchDirty = false;
    try {
      fn();
    } finally {
      _isBatching = false;
      if (_batchDirty) {
        notifyListeners();
      }
    }
  }

  @override
  void notifyListeners() {
    if (_isBatching) {
      _batchDirty = true;
      return;
    }
    if (_isDisposed) return;
    super.notifyListeners();
  }
```

- [x] **Step 3: Remove all `isRestoring` references in base**

In `lib/features/reader/provider/reader_provider_base.dart`, remove the `isRestoring` getter. It is currently:

```dart
  bool get isRestoring => lifecycle == ReaderLifecycle.restoring;
```

Replace with:

```dart
  // Removed: isRestoring no longer exists. lifecycle goes loading → ready → disposed.
```

Keep `isReady` and `isLoading` as-is.

- [x] **Step 4: Run analyzer to check for compile errors**

Run: `flutter analyze lib/features/reader/provider/reader_provider_base.dart`

This will show errors where `isRestoring` and `ReaderLifecycle.restoring` are referenced elsewhere — that's expected, we'll fix those in subsequent tasks.

- [x] **Step 5: Commit**

```bash
git add lib/features/reader/provider/reader_provider_base.dart
git commit -m "refactor(reader): add batchUpdate to ReaderProviderBase, simplify lifecycle enum"
```

---

### Task 2: Create `SlideWindow` and `SlideSegment` Data Structures

**Files:**
- Create: `lib/features/reader/provider/slide_window.dart`

- [x] **Step 1: Create `slide_window.dart`**

```dart
import 'package:legado_reader/features/reader/engine/text_page.dart';

/// A segment within the slide window, representing one chapter's pages.
class SlideSegment {
  final int chapterIndex;
  final List<TextPage> pages;

  const SlideSegment({required this.chapterIndex, required this.pages});

  int get length => pages.length;
  bool get isEmpty => pages.isEmpty;
  bool get isNotEmpty => pages.isNotEmpty;
}

/// Resolved position within a [SlideWindow].
typedef SlidePosition = ({int segmentIdx, int localIdx, int chapterIndex});

/// Manages a sliding 3-chapter window for PageView-based page turning.
///
/// Instead of a flat merged list, tracks each chapter's pages as a separate
/// [SlideSegment] with offset arithmetic for global↔local index mapping.
class SlideWindow {
  final List<SlideSegment> segments;

  const SlideWindow(this.segments);

  static const empty = SlideWindow([]);

  int get totalPages => segments.fold(0, (sum, s) => sum + s.length);
  bool get isEmpty => segments.isEmpty || totalPages == 0;
  bool get isNotEmpty => !isEmpty;

  /// All pages as a flat list (for backward compatibility with PageView).
  List<TextPage> get flatPages =>
      segments.expand((s) => s.pages).toList(growable: false);

  /// The chapter index of the center segment (the "current" chapter).
  int? get centerChapterIndex {
    if (segments.isEmpty) return null;
    if (segments.length == 1) return segments[0].chapterIndex;
    // Center is the middle segment, or first if only 2
    return segments[segments.length ~/ 2].chapterIndex;
  }

  /// Resolve a global page index to its segment and local page index.
  SlidePosition resolve(int globalIndex) {
    int offset = 0;
    for (int i = 0; i < segments.length; i++) {
      if (globalIndex < offset + segments[i].length) {
        return (
          segmentIdx: i,
          localIdx: globalIndex - offset,
          chapterIndex: segments[i].chapterIndex,
        );
      }
      offset += segments[i].length;
    }
    // Clamp to last page
    if (segments.isEmpty) {
      return (segmentIdx: 0, localIdx: 0, chapterIndex: -1);
    }
    final last = segments.last;
    return (
      segmentIdx: segments.length - 1,
      localIdx: last.length - 1,
      chapterIndex: last.chapterIndex,
    );
  }

  /// Map (chapterIndex, localPageIndex) to a global index within this window.
  /// Returns -1 if the chapter is not in the window.
  int toGlobal(int chapterIndex, int localPageIndex) {
    int offset = 0;
    for (final seg in segments) {
      if (seg.chapterIndex == chapterIndex) {
        return offset + localPageIndex.clamp(0, seg.length - 1);
      }
      offset += seg.length;
    }
    return -1;
  }

  /// Find the global index of a page by chapterIndex and page.index (TextPage.index).
  int findByPage(TextPage page) {
    int offset = 0;
    for (final seg in segments) {
      if (seg.chapterIndex == page.chapterIndex) {
        for (int i = 0; i < seg.pages.length; i++) {
          if (seg.pages[i].index == page.index) {
            return offset + i;
          }
        }
        // Chapter found but page not matched — return start of chapter
        return offset;
      }
      offset += seg.length;
    }
    return -1;
  }

  /// Whether the given chapter is part of this window.
  bool containsChapter(int chapterIndex) =>
      segments.any((s) => s.chapterIndex == chapterIndex);

  /// Build a new window centered on [centerChapterIndex].
  ///
  /// Returns the new window and the remapped global index for [currentPage]
  /// so the PageView can jump to the correct position in the new window.
  static ({SlideWindow window, int mappedIndex}) build({
    required int centerChapterIndex,
    required TextPage? currentPage,
    required Map<int, List<TextPage>> cache,
    required int totalChapters,
  }) {
    final prevIdx = centerChapterIndex - 1;
    final nextIdx = centerChapterIndex + 1;

    final newSegments = <SlideSegment>[
      if (prevIdx >= 0 && (cache[prevIdx]?.isNotEmpty ?? false))
        SlideSegment(chapterIndex: prevIdx, pages: cache[prevIdx]!),
      if (cache[centerChapterIndex]?.isNotEmpty ?? false)
        SlideSegment(
            chapterIndex: centerChapterIndex,
            pages: cache[centerChapterIndex]!),
      if (nextIdx < totalChapters && (cache[nextIdx]?.isNotEmpty ?? false))
        SlideSegment(chapterIndex: nextIdx, pages: cache[nextIdx]!),
    ];

    final newWindow = SlideWindow(newSegments);

    // Remap: find the same page in the new window
    int mappedIndex = 0;
    if (currentPage != null) {
      final found = newWindow.findByPage(currentPage);
      if (found >= 0) {
        mappedIndex = found;
      }
    }

    return (window: newWindow, mappedIndex: mappedIndex);
  }
}
```

- [x] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/reader/provider/slide_window.dart`
Expected: No errors (may have info-level lints).

- [x] **Step 3: Commit**

```bash
git add lib/features/reader/provider/slide_window.dart
git commit -m "feat(reader): add SlideWindow and SlideSegment data structures"
```

---

### Task 3: Create `ContentCallbacks` to Replace `(this as dynamic)` Casts

**Files:**
- Create: `lib/features/reader/provider/content_callbacks.dart`

- [x] **Step 1: Create `content_callbacks.dart`**

```dart
/// Typed callback interface for methods that [ReaderContentMixin] needs to call
/// on [ReadBookController] without using `(this as dynamic)`.
class ContentCallbacks {
  final void Function(int chapterIndex)? refreshChapterRuntime;
  final List<dynamic> Function()? buildSlideRuntimePages;
  final void Function(int pageIndex, {required dynamic reason})? jumpToSlidePage;
  final void Function({
    required int chapterIndex,
    required double localOffset,
    required double alignment,
    required dynamic reason,
  })? jumpToChapterLocalOffset;
  final void Function({
    required int chapterIndex,
    required int charOffset,
    required dynamic reason,
    bool isRestoringJump,
  })? jumpToChapterCharOffset;

  const ContentCallbacks({
    this.refreshChapterRuntime,
    this.buildSlideRuntimePages,
    this.jumpToSlidePage,
    this.jumpToChapterLocalOffset,
    this.jumpToChapterCharOffset,
  });

  static const empty = ContentCallbacks();
}
```

- [x] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/reader/provider/content_callbacks.dart`
Expected: No errors.

- [x] **Step 3: Commit**

```bash
git add lib/features/reader/provider/content_callbacks.dart
git commit -m "feat(reader): add ContentCallbacks typed interface"
```

---

### Task 4: Create `SlidePageController` Wrapper

**Files:**
- Create: `lib/features/reader/view/slide_page_controller.dart`

- [x] **Step 1: Create `slide_page_controller.dart`**

```dart
import 'package:flutter/widgets.dart';

/// Encapsulates PageView jump logic with deduplication and debouncing.
///
/// Replaces the manual `_deferredPendingJump` + `_schedulePendingJump()`
/// pattern previously in [ReaderPage].
class SlidePageController {
  final PageController pageController;
  int? _pendingJump;
  bool _scheduled = false;
  bool _disposed = false;

  SlidePageController(this.pageController);

  /// Schedule a jump to [pageIndex]. Multiple calls before the next frame
  /// coalesce — only the last target is used.
  void jumpTo(int pageIndex) {
    _pendingJump = pageIndex;
    if (_scheduled || _disposed) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final target = _pendingJump;
      _pendingJump = null;
      if (_disposed || target == null || !pageController.hasClients) return;
      if (pageController.position.isScrollingNotifier.value) {
        // User is actively scrolling — retry next frame
        jumpTo(target);
        return;
      }
      if (pageController.page?.round() != target) {
        pageController.jumpToPage(target);
      }
    });
  }

  void dispose() {
    _disposed = true;
    _pendingJump = null;
  }
}
```

- [x] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/reader/view/slide_page_controller.dart`
Expected: No errors.

- [x] **Step 3: Commit**

```bash
git add lib/features/reader/view/slide_page_controller.dart
git commit -m "feat(reader): add SlidePageController wrapper for PageView jumps"
```

---

### Task 5: Add `paginateSync()` to ChapterContentManager

**Files:**
- Modify: `lib/features/reader/engine/chapter_content_manager.dart`

- [x] **Step 1: Add `paginateSync()` method**

In `lib/features/reader/engine/chapter_content_manager.dart`, add after the existing `getCachedContent` method (around line 183):

```dart
  /// Synchronously paginate a chapter whose content is already cached.
  /// Returns empty list if config is not set or content is not cached.
  /// Used as a fast path for local books in scroll mode to avoid placeholder flash.
  List<TextPage> paginateSyncIfCached(int index) {
    final content = _contentCache[index];
    if (content == null) return [];
    final config = _config;
    if (config == null ||
        config.viewSize.width <= 0 ||
        config.viewSize.height <= 0) {
      return [];
    }
    if (index < 0 || index >= _chapters.length) return [];

    // Check if already paginated
    final existing = _paginatedCache[index];
    if (existing != null && existing.isNotEmpty) return existing;

    // Synchronous pagination (ChapterProvider.paginate is sync-capable)
    final pages = ChapterProvider.paginate(
      content: content,
      chapter: _chapters[index],
      chapterIndex: index,
      chapterSize: _chapters.length,
      viewSize: config.viewSize,
      titleStyle: config.titleStyle,
      contentStyle: config.contentStyle,
      paragraphSpacing: config.paragraphSpacing,
      textIndent: config.textIndent,
      textFullJustify: config.textFullJustify,
    );

    if (pages.isNotEmpty) {
      _paginatedCache[index] = pages;
    }
    return pages;
  }
```

- [x] **Step 2: Verify `ChapterProvider.paginate` is synchronous**

Check `lib/features/reader/engine/chapter_provider.dart` — the `paginate` static method. If it returns `Future<List<TextPage>>`, then we need to keep this async. If it returns `List<TextPage>` synchronously, this step works as-is.

Run: `grep -n 'static.*paginate' lib/features/reader/engine/chapter_provider.dart`

If `paginate` is async (returns Future), change `paginateSyncIfCached` to return `Future<List<TextPage>>` and add `await`. In that case, rename to `paginateIfCached` (drop the Sync prefix).

- [x] **Step 3: Run analyzer**

Run: `flutter analyze lib/features/reader/engine/chapter_content_manager.dart`
Expected: No errors.

- [x] **Step 4: Commit**

```bash
git add lib/features/reader/engine/chapter_content_manager.dart
git commit -m "feat(reader): add paginateSyncIfCached to ChapterContentManager"
```

---

### Task 6: Rewrite `ReaderContentMixin` — SlideWindow Integration + Predictive Preload

**Files:**
- Modify: `lib/features/reader/provider/reader_content_mixin.dart`

This is the largest task. It replaces the flat `slidePages` merge with `SlideWindow`, rewrites `onPageChanged`, removes `(this as dynamic)`, and adds predictive scroll preloading.

- [x] **Step 1: Add imports and `SlideWindow` field**

In `lib/features/reader/provider/reader_content_mixin.dart`, add to imports (after line 9):

```dart
import 'package:legado_reader/features/reader/provider/slide_window.dart';
import 'package:legado_reader/features/reader/provider/content_callbacks.dart';
```

Add field near other private fields (around line 30):

```dart
  SlideWindow _slideWindow = SlideWindow.empty;
  ContentCallbacks _contentCallbacks = ContentCallbacks.empty;

  /// Inject typed callbacks from ReadBookController.
  set contentCallbacks(ContentCallbacks callbacks) => _contentCallbacks = callbacks;

  /// The current slide window (for external access).
  SlideWindow get slideWindow => _slideWindow;
```

- [x] **Step 2: Add `trySyncPaginate()` method**

Add after `updateScrollPreloadForVisibleChapter` (around line 366):

```dart
  /// Synchronous fast path: if raw content is cached, paginate immediately.
  /// Used by ScrollModeDelegate to avoid placeholder flash for local books.
  List<TextPage>? trySyncPaginate(int chapterIndex) {
    if (!hasContentManager) return null;
    final pages = contentManager.paginateSyncIfCached(chapterIndex);
    if (pages.isEmpty) return null;
    chapterPagesCache[chapterIndex] = pages;
    _contentCallbacks.refreshChapterRuntime?.call(chapterIndex);
    return pages;
  }
```

- [x] **Step 3: Replace `_mergeAdjacentSlidePages` and `_refreshSlidePages` with SlideWindow**

Replace lines 218-235 (`_refreshSlidePages`) with:

```dart
  void _refreshSlidePages() {
    final currentPage =
        currentPageIndex >= 0 && currentPageIndex < slidePages.length
            ? slidePages[currentPageIndex]
            : null;

    // Try runtime pages first (if ReadBookController provides them)
    final runtimePages = _contentCallbacks.buildSlideRuntimePages?.call();
    if (runtimePages is List<TextPage> && runtimePages.isNotEmpty) {
      _applySlidePages(runtimePages, previousPage: currentPage);
      return;
    }

    // Build window from cache
    final result = SlideWindow.build(
      centerChapterIndex: currentChapterIndex,
      currentPage: currentPage,
      cache: chapterPagesCache,
      totalChapters: chapters.length,
    );

    _slideWindow = result.window;
    slidePages = result.window.flatPages;

    if (slidePages.isEmpty) {
      currentPageIndex = 0;
      return;
    }

    final clampedIndex = result.mappedIndex.clamp(0, slidePages.length - 1);
    final indexChanged = clampedIndex != currentPageIndex;
    currentPageIndex = clampedIndex;
    if (indexChanged) {
      requestJumpToPage(currentPageIndex, reason: ReaderCommandReason.system);
    }
  }
```

Replace lines 576-590 (`_mergeAdjacentSlidePages`) — **delete entirely**. It's no longer needed; `SlideWindow.build` replaces it.

Replace lines 592-637 (`_applySlidePages` and `_resolveSlideTargetIndex`) with a simplified version that only handles the runtime-pages path:

```dart
  void _applySlidePages(
    List<TextPage> pages, {
    required TextPage? previousPage,
  }) {
    slidePages = pages;
    if (slidePages.isEmpty) {
      currentPageIndex = 0;
      return;
    }

    // Rebuild _slideWindow from the flat pages (for runtime pages path)
    final segmentMap = <int, List<TextPage>>{};
    for (final page in pages) {
      segmentMap.putIfAbsent(page.chapterIndex, () => []).add(page);
    }
    _slideWindow = SlideWindow(
      segmentMap.entries
          .map((e) => SlideSegment(chapterIndex: e.key, pages: e.value))
          .toList(),
    );

    final targetIndex = _resolveSlideTargetIndex(previousPage);
    final clampedIndex = targetIndex.clamp(0, slidePages.length - 1);
    final indexChanged = clampedIndex != currentPageIndex;
    currentPageIndex = clampedIndex;
    if (indexChanged) {
      requestJumpToPage(currentPageIndex, reason: ReaderCommandReason.system);
    }
  }

  int _resolveSlideTargetIndex(TextPage? previousPage) {
    final pinnedChapterIndex = _pinnedSlideChapterIndex;
    if (pinnedChapterIndex != null) {
      final pinnedIndex = _findSlidePageIndexByCharOffset(
        chapterIndex: pinnedChapterIndex,
        charOffset: _pinnedSlideCharOffset,
        fromEnd: _pinnedSlideFromEnd,
      );
      if (slidePages.isNotEmpty) {
        return pinnedIndex;
      }
    }
    if (previousPage != null) {
      final found = _slideWindow.findByPage(previousPage);
      if (found >= 0) return found;
    }
    return _findSlidePageIndexByCharOffset(
      chapterIndex: currentChapterIndex,
      charOffset: book.durChapterPos,
    );
  }
```

- [x] **Step 4: Rewrite `onPageChanged` to use SlideWindow**

Replace lines 380-410 with:

```dart
  void onPageChanged(int i) {
    if (i < 0 || i >= slidePages.length) return;

    final page = slidePages[i];
    final resolved = _slideWindow.resolve(i);
    final newChapterIndex = resolved.chapterIndex;

    currentPageIndex = i;
    visibleChapterIndex = newChapterIndex;
    visibleChapterLocalOffset = ChapterPositionResolver.charOffsetToLocalOffset(
      chapterPagesCache[newChapterIndex] ?? const <TextPage>[],
      ChapterPositionResolver.getCharOffsetForPage(
        chapterPagesCache[newChapterIndex] ?? const <TextPage>[],
        page.index,
      ),
    );

    if (_isPinnedSlideTargetReached()) {
      _clearPinnedSlideTarget();
    }

    // Only recenter the window when the chapter actually changes
    final needsRecenter = newChapterIndex != currentChapterIndex;
    currentChapterIndex = newChapterIndex;

    if (needsRecenter) {
      // Atomic: build new window + remap index in one step
      final currentPage = slidePages[i];
      final result = SlideWindow.build(
        centerChapterIndex: newChapterIndex,
        currentPage: currentPage,
        cache: chapterPagesCache,
        totalChapters: chapters.length,
      );
      _slideWindow = result.window;
      slidePages = result.window.flatPages;
      currentPageIndex = result.mappedIndex.clamp(0, slidePages.length - 1);
      requestJumpToPage(currentPageIndex, reason: ReaderCommandReason.system);

      // Preload the new neighbor chapter
      _preloadSlideNeighbors(newChapterIndex);
    }

    notifyListeners();
    final title = chapters.isNotEmpty ? chapters[currentChapterIndex].title : '';
    unawaited(
      bookDao.updateProgress(
        book.bookUrl,
        page.chapterIndex,
        title,
        ChapterPositionResolver.getCharOffsetForPage(
          chapterPagesCache[page.chapterIndex] ?? const <TextPage>[],
          page.index,
        ),
      ),
    );
  }
```

- [x] **Step 5: Replace all `(this as dynamic)` calls with `_contentCallbacks`**

Search for all `(this as dynamic)` in reader_content_mixin.dart and replace:

| Old | New |
|-----|-----|
| `(this as dynamic).refreshChapterRuntime?.call(index)` | `_contentCallbacks.refreshChapterRuntime?.call(index)` |
| `(this as dynamic).buildSlideRuntimePages?.call()` | `_contentCallbacks.buildSlideRuntimePages?.call()` |
| `(this as dynamic).jumpToSlidePage(...)` | `_contentCallbacks.jumpToSlidePage?.call(...)` |
| `(this as dynamic).jumpToChapterLocalOffset(...)` | `_contentCallbacks.jumpToChapterLocalOffset?.call(...)` |
| `(this as dynamic).jumpToChapterCharOffset(...)` | `_contentCallbacks.jumpToChapterCharOffset?.call(...)` |

Apply to ALL occurrences (~12 in the file).

- [x] **Step 6: Add predictive scroll preload**

In `updateScrollPreloadForVisibleChapter` (lines 339-366), add the predictive preload logic. Replace the method body:

```dart
  void updateScrollPreloadForVisibleChapter(
    int visibleChapter, {
    double? localOffset,
  }) {
    if (!hasContentManager || !_isScrollMode) return;
    ReaderPerfTrace.mark(
      'scroll preload update center=$visibleChapter '
      '(cached: ${chapterPagesCache[visibleChapter]?.isNotEmpty == true}, '
      'loading: ${loadingChapters.contains(visibleChapter)})',
    );
    _activateScrollWindow(
      visibleChapter,
      preloadRadius: _scrollPreloadRadius,
      preload: !_isLocalScrollMode,
    );
    final visiblePages = chapterPagesCache[visibleChapter];
    if ((visiblePages == null || visiblePages.isEmpty) &&
        !loadingChapters.contains(visibleChapter)) {
      unawaited(
        ensureChapterCached(
          visibleChapter,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        ),
      );
    }
    if (_isLocalScrollMode) {
      _scheduleAdjacentScrollLoad(visibleChapter, immediate: true);
    }

    // ── Predictive preload based on scroll position ──
    if (localOffset != null && visiblePages != null && visiblePages.isNotEmpty) {
      final chapterHeight =
          ChapterPositionResolver.chapterHeight(visiblePages);
      if (chapterHeight > 0) {
        final progress = localOffset / chapterHeight;
        // Approaching end → preload next
        if (progress > 0.8) {
          final nextIdx = visibleChapter + 1;
          if (nextIdx < chapters.length &&
              !(chapterPagesCache[nextIdx]?.isNotEmpty ?? false) &&
              !loadingChapters.contains(nextIdx)) {
            unawaited(ensureChapterCached(nextIdx, silent: true, prioritize: true));
          }
        }
        // Approaching start → preload prev
        if (progress < 0.2) {
          final prevIdx = visibleChapter - 1;
          if (prevIdx >= 0 &&
              !(chapterPagesCache[prevIdx]?.isNotEmpty ?? false) &&
              !loadingChapters.contains(prevIdx)) {
            unawaited(ensureChapterCached(prevIdx, silent: true, prioritize: true));
          }
        }
      }
    }
  }
```

- [x] **Step 7: Run analyzer**

Run: `flutter analyze lib/features/reader/provider/reader_content_mixin.dart`

Fix any issues. Expect possible errors from callers of the old method signature — those are fixed in Task 7.

- [x] **Step 8: Commit**

```bash
git add lib/features/reader/provider/reader_content_mixin.dart
git commit -m "refactor(reader): replace flat slidePages with SlideWindow, add predictive preload"
```

---

### Task 7: Rewrite `ReadBookController._init()` + Wire ContentCallbacks + Remove Restoring

**Files:**
- Modify: `lib/features/reader/runtime/read_book_controller.dart`
- Modify: `lib/features/reader/provider/reader_progress_mixin.dart`

- [x] **Step 1: Add import for ContentCallbacks**

In `lib/features/reader/runtime/read_book_controller.dart`, add import:

```dart
import 'package:legado_reader/features/reader/provider/content_callbacks.dart';
```

- [x] **Step 2: Wire `ContentCallbacks` in `_init()`**

Replace the existing `_init()` method (lines 373-397) with the three-phase pipeline:

```dart
  final Completer<Size> _viewSizeCompleter = Completer<Size>();

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this);
    lifecycle = ReaderLifecycle.loading;

    // Wire typed callbacks (replaces `this as dynamic` casts)
    contentCallbacks = ContentCallbacks(
      refreshChapterRuntime: refreshChapterRuntime,
      buildSlideRuntimePages: buildSlideRuntimePages,
      jumpToSlidePage: (pageIndex, {required reason}) =>
          jumpToSlidePage(pageIndex, reason: reason as ReaderCommandReason),
      jumpToChapterLocalOffset: ({
        required chapterIndex,
        required localOffset,
        required alignment,
        required reason,
      }) =>
          jumpToChapterLocalOffset(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        alignment: alignment,
        reason: reason as ReaderCommandReason,
      ),
      jumpToChapterCharOffset: ({
        required chapterIndex,
        required charOffset,
        required reason,
        bool isRestoringJump = false,
      }) =>
          jumpToChapterCharOffset(
        chapterIndex: chapterIndex,
        charOffset: charOffset,
        reason: reason as ReaderCommandReason,
        isRestoringJump: isRestoringJump,
      ),
    );

    // ── Phase 1: PREPARE (parallel data loading, no UI updates) ──
    await Future.wait([
      loadSettings(),
      _loadReadAloudPreferences(),
      _loadChapters(),
      _loadSource(),
    ]);
    if (isDisposed) return;

    initContentManager();
    onSettingsChangedRepaginate = () {
      updatePaginationConfig();
      doPaginate();
    };

    // ── Phase 2: RENDER (wait for viewSize, single UI update) ──
    final size = viewSize ?? await _viewSizeCompleter.future;
    if (isDisposed) return;

    batchUpdate(() {
      viewSize = size;
      updatePaginationConfig();
    });

    // Load initial chapter content (async but batched result)
    if (!_initialSessionPrimed) {
      _initialSessionPrimed = true;
      final initialPreloadRadius =
          pageTurnMode == PageAnim.scroll && book.origin == 'local' ? 1 : 0;
      await loadChapterWithPreloadRadius(
        currentChapterIndex,
        preloadRadius: pageTurnMode == PageAnim.scroll ? initialPreloadRadius : 1,
      );
      if (isDisposed) return;
    }

    // Apply restore position + transition to ready in ONE update
    batchUpdate(() {
      bootstrapChapterWindow(currentChapterIndex);
      // Inline restore (replaces applyPendingRestore)
      if (initialCharOffset > 0) {
        jumpToChapterCharOffset(
          chapterIndex: currentChapterIndex,
          charOffset: initialCharOffset,
          reason: ReaderCommandReason.restore,
          isRestoringJump: false, // No restoring state needed
        );
      }
      lifecycle = ReaderLifecycle.ready;
    });

    // ── Phase 3: WARMUP (background, non-blocking) ──
    _startHeartbeat();
    _readAloudController.attach();
    scheduleDeferredWindowWarmup(currentChapterIndex);
    if (pageTurnMode == PageAnim.scroll) {
      updateScrollPreloadForVisibleChapter(visibleChapterIndex);
      triggerSilentPreload();
    }
  }
```

- [x] **Step 3: Rewrite `setViewSize()` to use Completer during init**

Replace lines 428-451:

```dart
  void setViewSize(Size size) {
    // During init phase 1: just complete the completer, don't paginate
    if (!_viewSizeCompleter.isCompleted) {
      _viewSizeCompleter.complete(size);
      return;
    }

    // Post-init: handle viewport changes (orientation, keyboard, etc.)
    if (viewSize == null) {
      viewSize = size;
      if (!hasContentManager) return;
      updatePaginationConfig();
      if (contentManager.getCachedContent(currentChapterIndex) != null &&
          (chapterPagesCache[currentChapterIndex]?.isEmpty ?? true)) {
        unawaited(doPaginate());
      }
      return;
    }

    if (_shouldIgnoreViewSizeChange(size)) return;

    viewSize = size;
    if (hasContentManager &&
        contentManager.getCachedContent(currentChapterIndex) != null) {
      unawaited(doPaginate());
    }
  }
```

- [x] **Step 4: Remove `completeRestoreTransition` and all `isRestoring` references**

In `read_book_controller.dart`:

1. Delete the `completeRestoreTransition()` method (lines 277-291).
2. Replace `handleSlidePageChanged()` (lines 472-479):

```dart
  void handleSlidePageChanged(int index) {
    if (slidePages.isEmpty) return;
    onPageChanged(index);
  }
```

3. Search for all `isRestoring` references in the file and remove them. If a block checks `if (isRestoring)`, remove the condition and the special-case code for restoring.

4. Search for `ReaderLifecycle.restoring` references and remove them.

- [x] **Step 5: Update `reader_progress_mixin.dart`**

In `lib/features/reader/provider/reader_progress_mixin.dart`:

1. Remove `pendingRestorePos` field (line 14) — no longer needed.
2. Remove `applyPendingRestore()` method (lines 143-153) — restore is now inline in `_init()`.
3. In `jumpToPosition()` (line 89), remove `if (isRestoringJump) lifecycle = ReaderLifecycle.restoring;` — the restoring state no longer exists.
4. Replace `(this as dynamic)` calls with `_contentCallbacks` calls. Since this mixin has `on ReaderContentMixin`, it can access `_contentCallbacks` through the mixin chain. If not accessible, pass through a helper method.

- [x] **Step 6: Update `updateScrollPreloadForVisibleChapter` call site**

In `read_book_controller.dart`, wherever `handleVisibleScrollState` calls `updateScrollPreloadForVisibleChapter`, pass `localOffset`:

Find the call:
```dart
updateScrollPreloadForVisibleChapter(visibleChapterIndex);
```

Replace with:
```dart
updateScrollPreloadForVisibleChapter(
  visibleChapterIndex,
  localOffset: visibleChapterLocalOffset,
);
```

- [x] **Step 7: Run analyzer on both files**

Run: `flutter analyze lib/features/reader/runtime/read_book_controller.dart lib/features/reader/provider/reader_progress_mixin.dart`

Fix compilation errors. Common issues:
- `isRestoring` references in other files → search and remove
- `pendingRestorePos` references → remove
- `applyPendingRestore()` calls → remove
- `completeRestoreTransition()` calls → remove

- [x] **Step 8: Commit**

```bash
git add lib/features/reader/runtime/read_book_controller.dart lib/features/reader/provider/reader_progress_mixin.dart
git commit -m "refactor(reader): three-phase init pipeline, remove restoring lifecycle state"
```

---

### Task 8: Update `ReaderPage` to Use `SlidePageController`

**Files:**
- Modify: `lib/features/reader/reader_page.dart`

- [x] **Step 1: Replace manual jump logic with SlidePageController**

In `lib/features/reader/reader_page.dart`:

Add import:
```dart
import 'package:legado_reader/features/reader/view/slide_page_controller.dart';
```

Replace field (line 32):
```dart
// Old:
int? _deferredPendingJump;

// New:
late final SlidePageController _slideCtrl;
```

In `initState()` (around line 37), after `_pageCtrl = PageController(initialPage: 0);`, add:
```dart
_slideCtrl = SlidePageController(_pageCtrl);
```

In `dispose()`, add:
```dart
_slideCtrl.dispose();
```

- [x] **Step 2: Remove `_schedulePendingJump` method**

Delete lines 43-58 entirely.

- [x] **Step 3: Replace all calls to `_schedulePendingJump` with `_slideCtrl.jumpTo`**

In the `build` method (around line 86-90), replace:

```dart
// Old:
final pendingJump = p.consumePendingJump();
if (pendingJump != null) {
  p.consumePendingSlideJumpReason();
  _schedulePendingJump(pendingJump);
}

// New:
final pendingJump = p.consumePendingJump();
if (pendingJump != null) {
  p.consumePendingSlideJumpReason();
  _slideCtrl.jumpTo(pendingJump);
}
```

- [x] **Step 4: Run analyzer**

Run: `flutter analyze lib/features/reader/reader_page.dart`
Expected: No errors.

- [x] **Step 5: Commit**

```bash
git add lib/features/reader/reader_page.dart
git commit -m "refactor(reader): use SlidePageController in ReaderPage"
```

---

### Task 9: Update `ReadViewRuntime` — Init Overlay + Fade Transition

**Files:**
- Modify: `lib/features/reader/view/read_view_runtime.dart`

- [x] **Step 1: Add fade animation controller**

In `_ReadViewRuntimeState`, add fields:

```dart
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnimation;
  bool _contentRevealed = false;
```

In `initState()`, initialize:

```dart
  _fadeCtrl = AnimationController(
    duration: const Duration(milliseconds: 150),
    vsync: this,
  );
  _fadeAnimation = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
```

In `dispose()`, add `_fadeCtrl.dispose();`.

- [x] **Step 2: Trigger fade when lifecycle transitions to ready**

In `_onProviderStateChanged()`, add at the top (after `if (!mounted) return;`):

```dart
    // Reveal content with fade when ready
    if (!_contentRevealed && widget.provider.isReady) {
      _contentRevealed = true;
      _fadeCtrl.forward();
    }
```

- [x] **Step 3: Wrap content in init overlay + FadeTransition**

In the `build()` method, replace the loading check section. Find the section around lines 186-190 where it shows `CircularProgressIndicator`. Replace with:

```dart
    if (provider.lifecycle == ReaderLifecycle.loading && !_contentRevealed) {
      return Container(color: provider.currentTheme.backgroundColor);
    }

    return FadeTransition(
      opacity: _contentRevealed ? _fadeAnimation : const AlwaysStoppedAnimation(1.0),
      child: _buildContent(provider, size),
    );
```

Extract the existing content building logic into `_buildContent(provider, size)` if not already separated.

- [x] **Step 4: Remove `isRestoring` checks in build**

Search for any `isRestoring` or `ReaderLifecycle.restoring` references in `read_view_runtime.dart`. Remove them or replace with `lifecycle == ReaderLifecycle.loading` checks where appropriate.

The `holdScrollUntilRestored` logic (line 180) should be replaced:
```dart
// Old:
final holdScrollUntilRestored = _coordinator.shouldHoldScrollUntilRestored(...)

// New: hold scroll until ready
final holdScrollUntilReady = !provider.isReady;
```

- [x] **Step 5: Run analyzer**

Run: `flutter analyze lib/features/reader/view/read_view_runtime.dart`
Expected: No errors.

- [x] **Step 6: Commit**

```bash
git add lib/features/reader/view/read_view_runtime.dart
git commit -m "refactor(reader): add init overlay with fade transition, remove restoring checks"
```

---

### Task 10: Update `ScrollModeDelegate` — Sync Paginate + Placeholder Heights

**Files:**
- Modify: `lib/features/reader/view/delegate/scroll_mode_delegate.dart`

- [x] **Step 1: Add sync-paginate fast path for local books**

In `scroll_mode_delegate.dart`, in the `itemBuilder` callback (around line 52-55), replace:

```dart
// Old:
final runtimeChapter = provider.chapterAt(chapterIndex);
final pages = runtimeChapter?.pages;
if (pages == null || pages.isEmpty) {

// New:
final runtimeChapter = provider.chapterAt(chapterIndex);
var pages = runtimeChapter?.pages;

// Fast path: sync-paginate for local books to avoid placeholder flash
if ((pages == null || pages.isEmpty) && provider.book.origin == 'local') {
  final syncPages = provider.trySyncPaginate(chapterIndex);
  if (syncPages != null && syncPages.isNotEmpty) {
    pages = syncPages;
  }
}

if (pages == null || pages.isEmpty) {
```

- [x] **Step 2: Replace fixed placeholder height with estimated height**

Replace the placeholder Container (lines 56-80):

```dart
if (pages == null || pages.isEmpty) {
  // Estimate height from adjacent cached chapters to reduce layout jump
  final estimatedHeight = _estimateChapterHeight(provider, chapterIndex);
  return Container(
    color: provider.currentTheme.backgroundColor,
    height: estimatedHeight,
    alignment: Alignment.center,
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: provider.currentTheme.textColor.withValues(alpha: 0.3),
      ),
    ),
  );
}
```

Add the helper method to the delegate class:

```dart
double _estimateChapterHeight(ReaderProvider provider, int chapterIndex) {
  final heights = <double>[];
  for (final offset in [-1, 1]) {
    final neighbor = chapterIndex + offset;
    final neighborPages = provider.chapterPagesCache[neighbor];
    if (neighborPages != null && neighborPages.isNotEmpty) {
      heights.add(ChapterPositionResolver.chapterHeight(neighborPages));
    }
  }
  if (heights.isEmpty) return provider.viewSize?.height ?? 600;
  return heights.reduce((a, b) => a + b) / heights.length;
}
```

Add import for `ChapterPositionResolver`:
```dart
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
```

- [x] **Step 3: Run analyzer**

Run: `flutter analyze lib/features/reader/view/delegate/scroll_mode_delegate.dart`
Expected: No errors.

- [x] **Step 4: Commit**

```bash
git add lib/features/reader/view/delegate/scroll_mode_delegate.dart
git commit -m "refactor(reader): sync-paginate fast path and estimated placeholder heights in scroll mode"
```

---

### Task 11: Fix Remaining `isRestoring` and `(this as dynamic)` References

**Files:**
- Various files across the reader module

- [x] **Step 1: Find all remaining `isRestoring` references**

Run: `grep -rn 'isRestoring\|ReaderLifecycle\.restoring\|lifecycle == ReaderLifecycle\.restoring' lib/features/reader/`

For each reference found:
- If it's a guard that prevents action during restore: remove the guard (restore no longer exists as a separate state; `loading` covers it)
- If it's a check that triggers on restore completion: replace with `isReady` check
- If it's setting `lifecycle = ReaderLifecycle.restoring`: delete the line

- [x] **Step 2: Find all remaining `(this as dynamic)` references**

Run: `grep -rn '(this as dynamic)' lib/features/reader/`

For each reference found:
- In `reader_content_mixin.dart`: should already be handled in Task 6 Step 5
- In `reader_progress_mixin.dart`: replace with `_contentCallbacks` calls (need to make `_contentCallbacks` accessible, possibly through a getter on `ReaderContentMixin`)
- In any other file: replace with typed callback or direct method call

- [x] **Step 3: Run full project analyzer**

Run: `flutter analyze`
Expected: No errors related to the reader module changes.

- [x] **Step 4: Commit**

```bash
git add -A lib/features/reader/
git commit -m "refactor(reader): remove all isRestoring references and dynamic casts"
```

---

### Task 12: Integration Smoke Test

**Files:**
- No file changes — testing only

- [x] **Step 1: Run existing tests**

Run: `flutter test`

Fix any failures caused by the refactoring. Common issues:
- Tests referencing `ReaderLifecycle.restoring` → update to use `loading` or `ready`
- Tests calling `applyPendingRestore()` → remove those calls
- Tests referencing `isRestoring` → update

- [x] **Step 2: Run analyzer to ensure clean build**

Run: `flutter analyze`
Expected: No errors.

- [x] **Step 3: Build to verify compilation**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: Build successful.

- [x] **Step 4: Commit any test fixes**

```bash
git add -A test/
git commit -m "test(reader): update tests for lifecycle refactor"
```

---

## Manual Testing Checklist

After all tasks are complete, test these scenarios on device:

1. **Open a local book** → should fade in smoothly, no jitter
2. **Open a remote book** → theme-colored placeholder, then smooth fade to content
3. **Slide mode: last page of chapter → slide right** → should go to next chapter's first page, NO flash of chapter+2
4. **Slide mode: first page of chapter → slide left** → should go to previous chapter's last page, no wrong chapter flash
5. **Slide mode: rapid next/prev chapter taps** → chapters advance correctly
6. **Scroll mode: continuous scroll across 3+ chapter boundaries** → no placeholder flash for local books
7. **Scroll mode: scroll backward across boundary** → smooth, no stutter
8. **Change font size mid-read** → repaginates and stays at correct position
9. **Orientation change** → re-layouts correctly
10. **TTS playback across chapter boundary** → continues correctly
11. **Auto-page across chapter boundary** → advances correctly
12. **App background → foreground** → correct state preserved
