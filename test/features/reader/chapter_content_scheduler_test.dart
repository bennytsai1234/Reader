import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/chapter_content_preparation_pipeline.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_content_scheduler.dart';

List<BookChapter> _chapters(int count) {
  return List<BookChapter>.generate(
    count,
    (index) => BookChapter(
      title: 'c$index',
      index: index,
      url: 'chapter-$index',
      bookUrl: 'book',
    ),
  );
}

void main() {
  group('ChapterContentScheduler', () {
    test('buildCenteredWholeBookOrder 依目前章、下一章、上一章、往後、往前排序', () {
      expect(
        ChapterContentScheduler.buildCenteredWholeBookOrder(
          chapterCount: 5,
          centerChapterIndex: 2,
        ),
        <int>[2, 3, 1, 4, 0],
      );
    });

    test('start 會依補全順序逐章讀取 storage', () async {
      final order = <int>[];
      final completers = <int, Completer<ChapterContentPreparationResult>>{};
      final scheduler = ChapterContentScheduler(
        chapters: _chapters(5),
        readContent: (index, chapter) {
          order.add(index);
          return (completers[index] ??=
                  Completer<ChapterContentPreparationResult>())
              .future;
        },
      );

      scheduler.start(centerChapterIndex: 2);
      expect(order, <int>[2]);

      completers[2]!.complete(ChapterContentPreparationResult.ready('c2'));
      await Future<void>.delayed(Duration.zero);
      expect(order, <int>[2, 3]);

      completers[3]!.complete(ChapterContentPreparationResult.ready('c3'));
      await Future<void>.delayed(Duration.zero);
      expect(order, <int>[2, 3, 1]);

      completers[1]!.complete(ChapterContentPreparationResult.ready('c1'));
      await Future<void>.delayed(Duration.zero);
      expect(order, <int>[2, 3, 1, 4]);

      completers[4]!.complete(ChapterContentPreparationResult.ready('c4'));
      await Future<void>.delayed(Duration.zero);
      expect(order, <int>[2, 3, 1, 4, 0]);

      scheduler.dispose();
    });

    test('中心章改變時會重排未開始任務，但不取消進行中任務', () async {
      final order = <int>[];
      final completers = <int, Completer<ChapterContentPreparationResult>>{};
      final scheduler = ChapterContentScheduler(
        chapters: _chapters(6),
        readContent: (index, chapter) {
          order.add(index);
          return (completers[index] ??=
                  Completer<ChapterContentPreparationResult>())
              .future;
        },
      );

      scheduler.start(centerChapterIndex: 1);
      expect(order, <int>[1]);

      scheduler.start(centerChapterIndex: 4);
      expect(scheduler.pendingChapterIndexes, <int>[4, 5, 3, 2, 0]);

      completers[1]!.complete(ChapterContentPreparationResult.ready('c1'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(order, <int>[1, 4]);

      scheduler.dispose();
    });
  });
}
