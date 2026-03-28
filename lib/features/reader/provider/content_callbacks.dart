import 'package:legado_reader/features/reader/runtime/reader_progress_store.dart';

/// Typed callback interface for methods that [ReaderContentMixin] and
/// [ReaderProgressMixin] need to call on [ReadBookController] without
/// using `(this as dynamic)`.
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

  // ── Progress-related callbacks (used by ReaderProgressMixin) ──────────────

  /// Returns the runtime chapter object for [chapterIndex], or null.
  /// Typed as [dynamic] to avoid a circular dependency on [ReaderChapter].
  final dynamic Function(int chapterIndex)? chapterAt;

  /// Returns the pages for [chapterIndex], falling back to cache if no runtime
  /// chapter is available.
  final List<dynamic> Function(int chapterIndex)? pagesForChapter;

  /// The shared [ReaderProgressStore] owned by [ReadBookController].
  final ReaderProgressStore? progressStore;

  /// Returns true when the current scroll position should be persisted.
  final bool Function()? shouldPersistVisiblePosition;

  /// Persists the current reading progress for [chapterIndex].
  final void Function({
    required int chapterIndex,
    int? pageIndex,
    required dynamic reason,
  })? persistCurrentProgress;

  const ContentCallbacks({
    this.refreshChapterRuntime,
    this.buildSlideRuntimePages,
    this.jumpToSlidePage,
    this.jumpToChapterLocalOffset,
    this.jumpToChapterCharOffset,
    this.chapterAt,
    this.pagesForChapter,
    this.progressStore,
    this.shouldPersistVisiblePosition,
    this.persistCurrentProgress,
  });

  static const empty = ContentCallbacks();
}
