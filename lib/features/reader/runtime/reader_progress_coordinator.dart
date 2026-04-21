import 'dart:async';

import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';

/// 管理閱讀進度的更新與持久化。
///
/// 取代原本 [ReaderProgressMixin] 的 contentCallbacksRef 繞道模式，
/// 改由建構時注入明確的依賴，讓邏輯可以獨立測試。
class ReaderProgressCoordinator {
  final ReaderChapter? Function(int chapterIndex) _chapterAt;
  final List<TextPage> Function(int chapterIndex) _pagesForChapter;
  final ReaderProgressStore _store;
  final ReaderLocation Function() _durableLocation;
  final bool Function() _shouldPersistVisiblePosition;
  final void Function(ReaderLocation location) _updateVisibleLocation;
  final void Function(ReaderLocation location) _updateSessionLocation;
  final Future<void> Function(ReaderLocation location) _persistLocation;

  Timer? scrollSaveTimer;

  ReaderProgressCoordinator({
    required ReaderChapter? Function(int) chapterAt,
    required List<TextPage> Function(int) pagesForChapter,
    required ReaderProgressStore store,
    required ReaderLocation Function() durableLocation,
    required bool Function() shouldPersistVisiblePosition,
    required void Function(ReaderLocation location) updateVisibleLocation,
    required void Function(ReaderLocation location) updateSessionLocation,
    required Future<void> Function(ReaderLocation location) persistLocation,
  }) : _chapterAt = chapterAt,
       _pagesForChapter = pagesForChapter,
       _store = store,
       _durableLocation = durableLocation,
       _shouldPersistVisiblePosition = shouldPersistVisiblePosition,
       _updateVisibleLocation = updateVisibleLocation,
       _updateSessionLocation = updateSessionLocation,
       _persistLocation = persistLocation;

  /// 更新可見章節位置，並在需要時觸發進度持久化（含 debounce）。
  ///
  /// [updateVisible] 由 caller 提供，用於回寫 visibleChapterIndex 等欄位。
  /// [updateCurrentChapterIndex] 在跨章節時更新 currentChapterIndex。
  void updateVisibleChapterPosition({
    required int chapterIndex,
    required double localOffset,
    required double alignment,
    required int pageTurnMode,
    required bool isLoading,
    required int currentPageIndex,
    required void Function(int ci, double lo, double al) updateVisible,
    required void Function(int ci) updateCurrentChapterIndex,
  }) {
    updateVisible(chapterIndex, localOffset, alignment);

    if (pageTurnMode != PageAnim.scroll || isLoading) return;
    if (!_shouldPersistVisiblePosition()) return;

    final currentLocation = _resolveScrollLocation(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
    );
    _updateVisibleLocation(currentLocation);
    final durableLocation = _durableLocation();

    if (durableLocation == currentLocation) {
      _updateSessionLocation(currentLocation);
      return;
    }
    _updateSessionLocation(currentLocation);

    final crossThreshold = _store.shouldSaveImmediately(
      currentCharOffset: currentLocation.charOffset,
      currentChapterIndex: durableLocation.chapterIndex,
      targetChapterIndex: currentLocation.chapterIndex,
    );
    updateCurrentChapterIndex(currentLocation.chapterIndex);

    if (crossThreshold) {
      scrollSaveTimer?.cancel();
      unawaited(_persistLocation(currentLocation));
    } else {
      scrollSaveTimer?.cancel();
      scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
        unawaited(_persistLocation(currentLocation));
      });
    }
  }

  /// 計算並持久化進度（slide mode 或 scroll mode）。
  void saveProgress({
    required int chapterIndex,
    required int pageIndex,
    required int pageTurnMode,
    required double visibleChapterLocalOffset,
    required List<TextPage> slidePages,
  }) {
    final location =
        pageTurnMode == PageAnim.scroll
            ? _resolveScrollLocation(
              chapterIndex: chapterIndex,
              localOffset: visibleChapterLocalOffset,
            )
            : _resolveSlideLocation(
              chapterIndex: chapterIndex,
              pageIndex: pageIndex,
              slidePages: slidePages,
            );

    _updateSessionLocation(location);

    unawaited(_persistLocation(location));
  }

  /// 更新 scroll mode 的頁面索引（不觸發持久化）。
  void updateScrollPageIndex({
    required int chapterIndex,
    required double localOffset,
    required void Function(int) setCurrentPageIndex,
    required void Function(int) setVisibleChapterIndex,
    required void Function(int) setCurrentChapterIndex,
  }) {
    setVisibleChapterIndex(chapterIndex);
    final runtimeChapter = _chapterAt(chapterIndex);
    final pages = _pagesForChapter(chapterIndex);
    final pageIndex =
        runtimeChapter != null
            ? runtimeChapter.pageIndexAtLocalOffset(localOffset)
            : ChapterPositionResolver.pageIndexAtLocalOffset(
              pages,
              localOffset,
            );
    setCurrentPageIndex(pageIndex);
    setCurrentChapterIndex(chapterIndex);
  }

  void dispose() {
    scrollSaveTimer?.cancel();
    scrollSaveTimer = null;
  }

  ReaderLocation _resolveScrollLocation({
    required int chapterIndex,
    required double localOffset,
  }) {
    final runtimeChapter = _chapterAt(chapterIndex);
    final pages = _pagesForChapter(chapterIndex);
    final charOffset =
        runtimeChapter != null
            ? runtimeChapter.charOffsetFromLocalOffset(localOffset)
            : ChapterPositionResolver.localOffsetToCharOffset(
              pages,
              localOffset,
            );
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    ).normalized();
  }

  ReaderLocation _resolveSlideLocation({
    required int chapterIndex,
    required int pageIndex,
    required List<TextPage> slidePages,
  }) {
    if (pageIndex >= 0 && pageIndex < slidePages.length) {
      final page = slidePages[pageIndex];
      final runtime = _chapterAt(page.chapterIndex);
      final chapterPages = _pagesForChapter(page.chapterIndex);
      final charOffset =
          runtime != null
              ? runtime.charOffsetForPageIndex(page.index)
              : ChapterPositionResolver.getCharOffsetForPage(
                chapterPages,
                page.index,
              );
      return ReaderLocation(
        chapterIndex: page.chapterIndex,
        charOffset: charOffset,
      );
    }
    final runtimeChapter = _chapterAt(chapterIndex);
    final pages = _pagesForChapter(chapterIndex);
    final safePageIndex = pageIndex.clamp(
      0,
      (pages.length - 1).clamp(0, 1 << 20),
    );
    final charOffset =
        runtimeChapter != null
            ? runtimeChapter.charOffsetForPageIndex(safePageIndex)
            : ChapterPositionResolver.getCharOffsetForPage(
              pages,
              safePageIndex,
            );
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    ).normalized();
  }
}
