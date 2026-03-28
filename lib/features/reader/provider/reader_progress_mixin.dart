import 'dart:async';

import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';

import 'reader_content_mixin.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';

mixin ReaderProgressMixin
    on ReaderProviderBase, ReaderSettingsMixin, ReaderContentMixin {
  int initialCharOffset = 0;
  Timer? scrollSaveTimer;

  List<TextPage> _pagesForChapter(int chapterIndex) =>
      (this as dynamic).pagesForChapter(chapterIndex) as List<TextPage>;

  dynamic _runtimeChapterFor(int chapterIndex) =>
      (this as dynamic).chapterAt?.call(chapterIndex);

  dynamic get _progressStore => (this as dynamic).progressStore;

  void updateVisibleChapterPosition({
    required int chapterIndex,
    required double localOffset,
    required double alignment,
  }) {
    visibleChapterIndex = chapterIndex;
    visibleChapterLocalOffset = localOffset;
    visibleChapterAlignment = alignment;

    if (pageTurnMode != PageAnim.scroll || isLoading) return;
    if (!((this as dynamic).shouldPersistVisiblePosition() as bool)) return;

    final runtimeChapter = _runtimeChapterFor(chapterIndex);
    final pages = _pagesForChapter(chapterIndex);
    final currentCharOffset = runtimeChapter != null
        ? runtimeChapter.charOffsetFromLocalOffset(localOffset) as int
        : ChapterPositionResolver.localOffsetToCharOffset(pages, localOffset);
    if (book.durChapterIndex == chapterIndex &&
        book.durChapterPos == currentCharOffset) {
      return;
    }

    _progressStore.updateBookProgress(
      book: book,
      chapterIndex: chapterIndex,
      charOffset: currentCharOffset,
    );
    final crossThreshold = _progressStore.shouldSaveImmediately(
      currentCharOffset: currentCharOffset,
      currentChapterIndex: currentChapterIndex,
      targetChapterIndex: chapterIndex,
    ) as bool;
    currentChapterIndex = chapterIndex;

    if (crossThreshold) {
      scrollSaveTimer?.cancel();
      (this as dynamic).persistCurrentProgress(
        chapterIndex: chapterIndex,
        pageIndex: currentPageIndex,
        reason: ReaderCommandReason.userScroll,
      );
    } else {
      scrollSaveTimer?.cancel();
      scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
        if (!isDisposed) {
          (this as dynamic).persistCurrentProgress(
            chapterIndex: chapterIndex,
            pageIndex: currentPageIndex,
            reason: ReaderCommandReason.userScroll,
          );
        }
      });
    }
  }

  @override
  void jumpToPosition({
    int? chapterIndex,
    int? charOffset,
    int? pageIndex,
    bool isRestoringJump = false,
  }) {
    final targetChapter = chapterIndex ?? currentChapterIndex;

    if (pageTurnMode == PageAnim.scroll) {
      final runtimeChapter = _runtimeChapterFor(targetChapter);
      final pages = _pagesForChapter(targetChapter);
      final targetCharOffset = charOffset ?? 0;
      final localOffset = runtimeChapter != null
          ? runtimeChapter.localOffsetFromCharOffset(targetCharOffset) as double
          : ChapterPositionResolver.charOffsetToLocalOffset(
              pages,
              targetCharOffset,
            );
      final alignment = runtimeChapter != null
          ? runtimeChapter.alignmentForCharOffset(targetCharOffset) as double
          : ChapterPositionResolver.charOffsetToAlignment(
              pages,
              targetCharOffset,
            );
      contentCallbacksRef.jumpToChapterLocalOffset?.call(
        chapterIndex: targetChapter,
        localOffset: localOffset,
        alignment: alignment,
        reason: isRestoringJump
            ? ReaderCommandReason.restore
            : ReaderCommandReason.system,
      );
      notifyListeners();
      return;
    }

    final pages = _pagesForChapter(targetChapter);
    var targetPage = 0;
    if (charOffset != null && charOffset > 0) {
      final runtimeChapter = _runtimeChapterFor(targetChapter);
      final localPageIndex = runtimeChapter != null
          ? runtimeChapter.getPageIndexByCharIndex(charOffset) as int
          : ChapterPositionResolver.findPageIndexByCharOffset(pages, charOffset);
      final globalIndex = slidePages.indexWhere(
        (page) =>
            page.chapterIndex == targetChapter && page.index == localPageIndex,
      );
      targetPage = globalIndex >= 0 ? globalIndex : 0;
    } else if (pageIndex != null) {
      targetPage = pageIndex.clamp(0, slidePages.length - 1);
    }
    currentPageIndex = targetPage;
    contentCallbacksRef.jumpToSlidePage?.call(
      targetPage,
      reason: isRestoringJump
          ? ReaderCommandReason.restore
          : ReaderCommandReason.system,
    );
    notifyListeners();
  }

  void saveProgress(
    int chapterIndex,
    int pageIndex, {
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    final runtimeChapter = _runtimeChapterFor(chapterIndex);
    final pages = _pagesForChapter(chapterIndex);
    final charOffset = pageTurnMode == PageAnim.scroll
        ? (runtimeChapter != null
            ? runtimeChapter.charOffsetFromLocalOffset(visibleChapterLocalOffset)
                as int
            : ChapterPositionResolver.localOffsetToCharOffset(
                _pagesForChapter(chapterIndex),
                visibleChapterLocalOffset,
              ))
        : () {
            if (pageIndex >= 0 && pageIndex < slidePages.length) {
              final page = slidePages[pageIndex];
              final runtime = _runtimeChapterFor(page.chapterIndex);
              final chapterPages = _pagesForChapter(page.chapterIndex);
              return runtime != null
                  ? runtime.charOffsetForPageIndex(page.index) as int
                  : ChapterPositionResolver.getCharOffsetForPage(
                      chapterPages,
                      page.index,
                    );
            }
            return runtimeChapter != null
                ? runtimeChapter.charOffsetForPageIndex(
                    pageIndex.clamp(0, (pages.length - 1).clamp(0, 1 << 20)),
                  ) as int
                : ChapterPositionResolver.getCharOffsetForPage(
                    pages,
                    pageIndex.clamp(0, (pages.length - 1).clamp(0, 1 << 20)),
                  );
          }();

    unawaited(
      _progressStore.persistCharOffset(
        write: (chapterIndex, title, charOffset) => bookDao.updateProgress(
          book.bookUrl,
          chapterIndex,
          title,
          charOffset,
        ),
        book: book,
        chapters: chapters,
        chapterIndex: chapterIndex,
        charOffset: charOffset,
      ),
    );
  }

  void updateScrollPageIndex(int chapterIndex, double localOffset) {
    visibleChapterIndex = chapterIndex;
    final runtimeChapter = _runtimeChapterFor(chapterIndex);
    final pages = _pagesForChapter(chapterIndex);
    currentPageIndex = runtimeChapter != null
        ? runtimeChapter.pageIndexAtLocalOffset(localOffset) as int
        : ChapterPositionResolver.pageIndexAtLocalOffset(
            pages,
            localOffset,
          );
    currentChapterIndex = chapterIndex;
  }
}
