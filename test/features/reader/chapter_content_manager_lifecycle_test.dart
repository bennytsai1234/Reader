import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/engine/chapter_content_manager.dart';

void main() {
  ChapterContentManager buildManager({
    required List<BookChapter> chapters,
    required String content,
    List<int>? fetchedIndexes,
  }) {
    final manager = ChapterContentManager(
      fetchFn: (index) async {
        fetchedIndexes?.add(index);
        return FetchResult(content: content);
      },
      chapters: chapters,
    );
    manager.updateConfig(
      const PaginationConfig(
        viewSize: Size(360, 640),
        titleStyle: TextStyle(fontSize: 20),
        contentStyle: TextStyle(fontSize: 16, height: 1.5),
      ),
    );
    return manager;
  }

  List<BookChapter> buildChapters(int count) {
    return List.generate(
      count,
      (index) => BookChapter(
        title: 'Chapter $index',
        index: index,
        url: 'chapter-$index',
        bookUrl: 'book',
      ),
    );
  }

  group('ChapterContentManager lifecycle API', () {
    test('ensureChapterReady 會沿用主載入快取', () async {
      final fetched = <int>[];
      final manager = buildManager(
        chapters: buildChapters(3),
        content: 'A\nB\nC\nD',
        fetchedIndexes: fetched,
      );

      final first = await manager.ensureChapterReady(1);
      final second = await manager.ensureChapterReady(1);

      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
      expect(fetched, [1]);
    });

    test('prioritize 與 warmChaptersAround 會建立鄰近中心的預載視窗', () async {
      final manager = buildManager(
        chapters: buildChapters(6),
        content: 'A\nB\nC\nD',
      );

      manager.updateWindow(3, preloadRadius: 1, preload: false);
      manager.prioritize([2, 3, 4], centerIndex: 3);
      manager.warmChaptersAround(3, radius: 1);

      expect(manager.targetWindow, {2, 3, 4});
    });

    test('evictOutside 會驅逐保留集合之外的快取', () async {
      final manager = buildManager(
        chapters: buildChapters(5),
        content: 'A\nB\nC\nD',
      );

      await manager.ensureChapterReady(1);
      await manager.ensureChapterReady(2);
      await manager.ensureChapterReady(3);

      final evicted = manager.evictOutside({2});

      expect(evicted, {1, 3});
      expect(manager.getCachedPages(1), isNull);
      expect(manager.getCachedPages(2), isNotNull);
      expect(manager.getCachedPages(3), isNull);
    });
  });
}
