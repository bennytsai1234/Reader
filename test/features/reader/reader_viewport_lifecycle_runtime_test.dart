import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_lifecycle_runtime.dart';

void main() {
  group('ReaderViewportLifecycleRuntime', () {
    test('首次 view size 會完成 bootstrap completer 並不觸發 repaginate', () async {
      final runtime = ReaderViewportLifecycleRuntime();
      final waitFuture = runtime.waitForInitialViewSize(null);

      final update = runtime.handleViewSizeChange(
        size: const Size(320, 640),
        currentViewSize: null,
        hasContentManager: false,
        hasCachedCurrentChapterContent: false,
        hasCurrentChapterPages: false,
        isPaginatingContent: false,
      );

      expect(update.completedBootstrapSize, isTrue);
      expect(update.shouldRepaginate, isFalse);
      expect(await waitFuture, const Size(320, 640));
    });

    test('初始 session preload radius 會依 scroll/slide 與本地書決定', () {
      final runtime = ReaderViewportLifecycleRuntime();

      expect(
        runtime.resolveInitialChapterPreloadRadius(
          pageTurnMode: PageAnim.scroll,
          isLocalBook: true,
        ),
        1,
      );
      expect(
        runtime.resolveInitialChapterPreloadRadius(
          pageTurnMode: PageAnim.scroll,
          isLocalBook: false,
        ),
        0,
      );
      expect(
        runtime.resolveInitialChapterPreloadRadius(
          pageTurnMode: PageAnim.slide,
          isLocalBook: false,
        ),
        2,
      );
    });

    test(
      'viewSize 尚未寫入但已有 cached content 時會要求 refresh config 與 repaginate',
      () {
        final runtime = ReaderViewportLifecycleRuntime();
        runtime.handleViewSizeChange(
          size: const Size(320, 640),
          currentViewSize: null,
          hasContentManager: false,
          hasCachedCurrentChapterContent: false,
          hasCurrentChapterPages: false,
          isPaginatingContent: false,
        );

        final update = runtime.handleViewSizeChange(
          size: const Size(360, 720),
          currentViewSize: null,
          hasContentManager: true,
          hasCachedCurrentChapterContent: true,
          hasCurrentChapterPages: false,
          isPaginatingContent: false,
        );

        expect(update.shouldApplySize, isTrue);
        expect(update.shouldRefreshPaginationConfig, isTrue);
        expect(update.shouldRepaginate, isTrue);
      },
    );

    test('guard 期間的 transient viewport 變化會被忽略', () {
      final runtime = ReaderViewportLifecycleRuntime();
      runtime.handleViewSizeChange(
        size: const Size(320, 640),
        currentViewSize: null,
        hasContentManager: false,
        hasCachedCurrentChapterContent: false,
        hasCurrentChapterPages: false,
        isPaginatingContent: false,
      );
      runtime.guardTransientViewportChanges(
        now: DateTime(2026, 4, 21, 10, 0, 0),
      );

      final update = runtime.handleViewSizeChange(
        size: const Size(360, 760),
        currentViewSize: const Size(320, 640),
        hasContentManager: true,
        hasCachedCurrentChapterContent: true,
        hasCurrentChapterPages: true,
        isPaginatingContent: false,
        now: DateTime(2026, 4, 21, 10, 0, 0, 200),
      );

      expect(update.shouldApplySize, isFalse);
      expect(update.shouldRepaginate, isFalse);
    });

    test('正在 repaginate 時新的 viewport 變化會排隊到下一輪', () {
      final runtime = ReaderViewportLifecycleRuntime();
      runtime.handleViewSizeChange(
        size: const Size(320, 640),
        currentViewSize: null,
        hasContentManager: false,
        hasCachedCurrentChapterContent: false,
        hasCurrentChapterPages: false,
        isPaginatingContent: false,
      );

      final update = runtime.handleViewSizeChange(
        size: const Size(480, 800),
        currentViewSize: const Size(320, 640),
        hasContentManager: true,
        hasCachedCurrentChapterContent: true,
        hasCurrentChapterPages: true,
        isPaginatingContent: true,
      );

      expect(update.shouldApplySize, isTrue);
      expect(update.queuedRepaginate, isTrue);
      expect(runtime.hasPendingRepaginateForLatestViewport, isTrue);

      runtime.beginRepaginateIteration();
      expect(runtime.hasPendingRepaginateForLatestViewport, isFalse);
    });

    test('beginInitialSession 只會在第一次回傳 true', () {
      final runtime = ReaderViewportLifecycleRuntime();

      expect(runtime.beginInitialSession(), isTrue);
      expect(runtime.beginInitialSession(), isFalse);
    });
  });
}
