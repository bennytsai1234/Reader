import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_execution_bridge.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  group('ReaderViewportExecutionBridge', () {
    const bridge = ReaderViewportExecutionBridge();

    test('layout update 會在同尺寸且 insets 改變時要求 repaginate', () {
      final update = bridge.resolveLayoutUpdate(
        size: const Size(320, 640),
        contentInsetsChanged: true,
        scrollInsetsChanged: false,
        currentViewSize: const Size(320, 640),
        isReady: true,
      );

      expect(update.shouldRepaginate, isTrue);
      expect(update.nextViewSize, isNull);
    });

    test('layout update 會在尺寸改變時回傳新的 view size', () {
      final update = bridge.resolveLayoutUpdate(
        size: const Size(360, 640),
        contentInsetsChanged: false,
        scrollInsetsChanged: false,
        currentViewSize: const Size(320, 640),
        isReady: true,
      );

      expect(update.shouldRepaginate, isFalse);
      expect(update.nextViewSize, const Size(360, 640));
    });

    test('visible scroll update 會取第一個可見章節並換算 local offset', () {
      final update = bridge.resolveVisibleScrollUpdate(
        positions: const <ItemPosition>[
          ItemPosition(index: 1, itemLeadingEdge: -0.25, itemTrailingEdge: 0.6),
          ItemPosition(index: 2, itemLeadingEdge: 0.6, itemTrailingEdge: 1.3),
        ],
        viewportHeight: 400,
        chapterHeightFor: (chapterIndex) => chapterIndex == 1 ? 180 : 220,
      );

      expect(update, isNotNull);
      expect(update!.chapterIndex, 1);
      expect(update.localOffset, 100);
      expect(update.alignment, 0.0);
      expect(update.visibleChapterIndexes, [1, 2]);
    });

    test('無可見 item 時回傳 null', () {
      final update = bridge.resolveVisibleScrollUpdate(
        positions: const <ItemPosition>[
          ItemPosition(index: 3, itemLeadingEdge: 1.2, itemTrailingEdge: 1.8),
        ],
        viewportHeight: 400,
        chapterHeightFor: (_) => 0,
      );

      expect(update, isNull);
    });
  });
}
