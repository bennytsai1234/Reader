import 'package:inkpage_reader/features/reader/engine/text_page.dart';

import 'models/reader_chapter.dart';

class ReaderPageFactory {
  final ReaderChapter? prevChapter;
  final ReaderChapter? currentChapter;
  final ReaderChapter? nextChapter;
  final int chapterCharOffset;

  const ReaderPageFactory({
    required this.prevChapter,
    required this.currentChapter,
    required this.nextChapter,
    required this.chapterCharOffset,
  });

  int get pageIndex =>
      currentChapter?.getPageIndexByCharIndex(chapterCharOffset) ?? 0;
  List<ReaderChapter> get orderedChapters => [
    if (prevChapter != null) prevChapter!,
    if (currentChapter != null) currentChapter!,
    if (nextChapter != null) nextChapter!,
  ];
  List<TextPage> get windowPages =>
      orderedChapters.expand((chapter) => chapter.pages).toList();
  int get currentGlobalPageIndex =>
      globalPageIndexFor(
        chapterIndex: currentChapter?.index ?? -1,
        localPageIndex: pageIndex,
      ) ??
      0;
  bool get isEmpty => orderedChapters.isEmpty;

  bool hasPrev() {
    final cur = currentChapter;
    if (cur == null) return prevChapter != null;
    return pageIndex > 0 || prevChapter != null;
  }

  bool hasNext() {
    final cur = currentChapter;
    if (cur == null) return nextChapter != null;
    return pageIndex < cur.pageCount - 1 || nextChapter != null;
  }

  int? globalPageIndexFor({
    required int chapterIndex,
    required int localPageIndex,
  }) {
    var offset = 0;
    for (final chapter in orderedChapters) {
      if (chapter.index == chapterIndex) {
        if (localPageIndex < 0 || localPageIndex >= chapter.pageCount) {
          return null;
        }
        return offset + localPageIndex;
      }
      offset += chapter.pageCount;
    }
    return null;
  }
}
