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
