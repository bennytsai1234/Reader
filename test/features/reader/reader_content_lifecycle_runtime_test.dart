import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_content_lifecycle_runtime.dart';

TextPage _page(int chapterIndex) => TextPage(
  index: 0,
  lines: const <TextLine>[],
  title: 'chapter-$chapterIndex',
  chapterIndex: chapterIndex,
);

void main() {
  group('ReaderContentLifecycleRuntime', () {
    test('dispose 會清空 cache 並重設 presentation state', () {
      final runtime = ReaderContentLifecycleRuntime();
      final chapterPagesCache = <int, List<TextPage>>{
        1: <TextPage>[_page(1)],
      };
      var slidePages = <TextPage>[_page(1)];
      var resetCalls = 0;

      runtime.dispose(
        chapterPagesCache: chapterPagesCache,
        setSlidePages: (pages) => slidePages = pages,
        resetPresentationState: () => resetCalls += 1,
      );

      expect(chapterPagesCache, isEmpty);
      expect(slidePages, isEmpty);
      expect(resetCalls, 1);
      expect(runtime.hasContentManager, isFalse);
    });

    test('effectivePreloadRadius 會限制 local scroll 的 preload 半徑', () {
      final runtime = ReaderContentLifecycleRuntime();

      expect(
        runtime.effectivePreloadRadius(
          requestedRadius: 4,
          isScrollMode: true,
          isLocalBook: true,
        ),
        1,
      );
      expect(
        runtime.effectivePreloadRadius(
          requestedRadius: 4,
          isScrollMode: false,
          isLocalBook: true,
        ),
        4,
      );
    });

    test('computeLocalAdjacentPreloadOrder 會在 local scroll 補兩側鄰章', () {
      final runtime = ReaderContentLifecycleRuntime();

      expect(
        runtime.computeLocalAdjacentPreloadOrder(
          centerIndex: 2,
          totalChapters: 6,
        ),
        <int>[3, 1],
      );
      expect(
        runtime.computeLocalAdjacentPreloadOrder(
          centerIndex: 4,
          totalChapters: 7,
          previousCenterIndex: 2,
        ),
        <int>[5, 3, 6, 2],
      );
      expect(
        runtime.computeLocalAdjacentPreloadOrder(
          centerIndex: 2,
          totalChapters: 7,
          previousCenterIndex: 4,
        ),
        <int>[1, 3, 0, 4],
      );
    });
  });
}
