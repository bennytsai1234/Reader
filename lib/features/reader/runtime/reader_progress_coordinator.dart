import 'dart:async';

import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:legado_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';

/// 管理閱讀進度的更新與持久化。
///
/// 取代原本 [ReaderProgressMixin] 的 contentCallbacksRef 繞道模式，
/// 改由建構時注入明確的依賴，讓邏輯可以獨立測試。
class ReaderProgressCoordinator {
  final Book Function() _book;
  final List<BookChapter> Function() _chapters;
  final ReaderChapter? Function(int chapterIndex) _chapterAt;
  final List<TextPage> Function(int chapterIndex) _pagesForChapter;
  final ReaderProgressStore _store;
  final bool Function() _shouldPersistVisiblePosition;
  final void Function({
    required int chapterIndex,
    int? pageIndex,
    required ReaderCommandReason reason,
  }) _persistCurrentProgress;

  Timer? scrollSaveTimer;

  ReaderProgressCoordinator({
    required Book Function() book,
    required List<BookChapter> Function() chapters,
    required ReaderChapter? Function(int) chapterAt,
    required List<TextPage> Function(int) pagesForChapter,
    required ReaderProgressStore store,
    required bool Function() shouldPersistVisiblePosition,
    required void Function({
      required int chapterIndex,
      int? pageIndex,
      required ReaderCommandReason reason,
    }) persistCurrentProgress,
  })  : _book = book,
        _chapters = chapters,
        _chapterAt = chapterAt,
        _pagesForChapter = pagesForChapter,
        _store = store,
        _shouldPersistVisiblePosition = shouldPersistVisiblePosition,
        _persistCurrentProgress = persistCurrentProgress;

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

    final book = _book();
    final runtimeChapter = _chapterAt(chapterIndex);
    final pages = _pagesForChapter(chapterIndex);
    final currentCharOffset = runtimeChapter != null
        ? runtimeChapter.charOffsetFromLocalOffset(localOffset)
        : ChapterPositionResolver.localOffsetToCharOffset(pages, localOffset);

    if (book.durChapterIndex == chapterIndex &&
        book.durChapterPos == currentCharOffset) {
      return;
    }

    _store.updateBookProgress(
      book: book,
      chapterIndex: chapterIndex,
      charOffset: currentCharOffset,
    );

    final crossThreshold = _store.shouldSaveImmediately(
      currentCharOffset: currentCharOffset,
      currentChapterIndex: book.durChapterIndex,
      targetChapterIndex: chapterIndex,
    );
    updateCurrentChapterIndex(chapterIndex);

    if (crossThreshold) {
      scrollSaveTimer?.cancel();
      _persistCurrentProgress(
        chapterIndex: chapterIndex,
        pageIndex: currentPageIndex,
        reason: ReaderCommandReason.userScroll,
      );
    } else {
      scrollSaveTimer?.cancel();
      scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
        _persistCurrentProgress(
          chapterIndex: chapterIndex,
          pageIndex: currentPageIndex,
          reason: ReaderCommandReason.userScroll,
        );
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
    required Future<void> Function(int chapterIndex, String title, int charOffset)
        write,
  }) {
    final runtimeChapter = _chapterAt(chapterIndex);
    final pages = _pagesForChapter(chapterIndex);

    final charOffset = pageTurnMode == PageAnim.scroll
        ? (runtimeChapter != null
            ? runtimeChapter.charOffsetFromLocalOffset(visibleChapterLocalOffset)
            : ChapterPositionResolver.localOffsetToCharOffset(
                pages,
                visibleChapterLocalOffset,
              ))
        : _resolveSlideCharOffset(
            pageIndex: pageIndex,
            slidePages: slidePages,
            runtimeChapter: runtimeChapter,
            pages: pages,
          );

    unawaited(
      _store.persistCharOffset(
        write: write,
        book: _book(),
        chapters: _chapters(),
        chapterIndex: chapterIndex,
        charOffset: charOffset,
      ),
    );
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
    final pageIndex = runtimeChapter != null
        ? runtimeChapter.pageIndexAtLocalOffset(localOffset)
        : ChapterPositionResolver.pageIndexAtLocalOffset(pages, localOffset);
    setCurrentPageIndex(pageIndex);
    setCurrentChapterIndex(chapterIndex);
  }

  void dispose() {
    scrollSaveTimer?.cancel();
    scrollSaveTimer = null;
  }

  int _resolveSlideCharOffset({
    required int pageIndex,
    required List<TextPage> slidePages,
    required ReaderChapter? runtimeChapter,
    required List<TextPage> pages,
  }) {
    if (pageIndex >= 0 && pageIndex < slidePages.length) {
      final page = slidePages[pageIndex];
      final runtime = _chapterAt(page.chapterIndex);
      final chapterPages = _pagesForChapter(page.chapterIndex);
      return runtime != null
          ? runtime.charOffsetForPageIndex(page.index)
          : ChapterPositionResolver.getCharOffsetForPage(
              chapterPages, page.index);
    }
    return runtimeChapter != null
        ? runtimeChapter.charOffsetForPageIndex(
            pageIndex.clamp(0, (pages.length - 1).clamp(0, 1 << 20)),
          )
        : ChapterPositionResolver.getCharOffsetForPage(
            pages,
            pageIndex.clamp(0, (pages.length - 1).clamp(0, 1 << 20)),
          );
  }
}
