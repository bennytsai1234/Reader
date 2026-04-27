import 'package:flutter/widgets.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_host_base.dart'
    show ReaderLifecycle;
import 'package:inkpage_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_lifecycle_runtime.dart';

typedef ReaderBootstrapPrepareTask = Future<void> Function();
typedef ReaderBootstrapBatchUpdate = void Function(VoidCallback fn);
typedef ReaderBootstrapLifecycleSetter =
    void Function(ReaderLifecycle lifecycle);
typedef ReaderBootstrapPhaseSetter = void Function(ReaderSessionPhase phase);
typedef ReaderBootstrapPageTurnModeGetter = int Function();
typedef ReaderBootstrapChapterLoader =
    Future<void> Function(int chapterIndex, int preloadRadius);
typedef ReaderBootstrapRestoreCallback =
    bool Function(int chapterIndex, int charOffset);
typedef ReaderBootstrapIndexCallback = void Function(int index);

class ReaderBootstrapRuntime {
  final ReaderViewportLifecycleRuntime _viewportLifecycle;

  ReaderBootstrapRuntime({ReaderViewportLifecycleRuntime? viewportLifecycle})
    : _viewportLifecycle =
          viewportLifecycle ?? ReaderViewportLifecycleRuntime();

  Future<void> bootstrap({
    required Size? currentViewSize,
    required ReaderBootstrapPageTurnModeGetter pageTurnMode,
    required bool isLocalBook,
    required int currentChapterIndex,
    required int visibleChapterIndex,
    required int initialCharOffset,
    required bool Function() isDisposed,
    required VoidCallback addObserver,
    required ReaderBootstrapLifecycleSetter setLifecycle,
    required ReaderBootstrapPhaseSetter updatePhase,
    required VoidCallback wireCallbacks,
    required List<ReaderBootstrapPrepareTask> prepareTasks,
    required VoidCallback initContentManager,
    required VoidCallback configureRepaginateHooks,
    required ReaderBootstrapBatchUpdate batchUpdate,
    required void Function(Size size) applyViewSize,
    required ReaderBootstrapChapterLoader loadChapterWithPreloadRadius,
    required ReaderBootstrapIndexCallback bootstrapChapterWindow,
    required ReaderBootstrapRestoreCallback restoreInitialCharOffset,
    required VoidCallback clearInitialCharOffset,
    required VoidCallback startBatteryHeartbeat,
    required VoidCallback attachReadAloud,
    required ReaderBootstrapIndexCallback scheduleDeferredWindowWarmup,
    required ReaderBootstrapIndexCallback updateScrollPreloadForVisibleChapter,
    required VoidCallback triggerSilentPreload,
  }) async {
    addObserver();
    setLifecycle(ReaderLifecycle.loading);
    updatePhase(ReaderSessionPhase.bootstrapping);
    wireCallbacks();

    await Future.wait(prepareTasks.map((task) => task()));
    if (isDisposed()) return;

    initContentManager();
    configureRepaginateHooks();

    final size = await _viewportLifecycle.waitForInitialViewSize(
      currentViewSize,
    );
    if (isDisposed()) return;

    batchUpdate(() {
      applyViewSize(size);
    });

    if (_viewportLifecycle.beginInitialSession()) {
      updatePhase(ReaderSessionPhase.contentLoading);
      await loadChapterWithPreloadRadius(
        currentChapterIndex,
        _viewportLifecycle.resolveInitialChapterPreloadRadius(
          pageTurnMode: pageTurnMode(),
          isLocalBook: isLocalBook,
        ),
      );
      if (isDisposed()) return;
    }

    batchUpdate(() {
      var isRestoring = false;
      bootstrapChapterWindow(currentChapterIndex);
      if (initialCharOffset > 0) {
        isRestoring = restoreInitialCharOffset(
          currentChapterIndex,
          initialCharOffset,
        );
        clearInitialCharOffset();
      }
      setLifecycle(ReaderLifecycle.ready);
      updatePhase(
        isRestoring ? ReaderSessionPhase.restoring : ReaderSessionPhase.ready,
      );
    });

    startBatteryHeartbeat();
    attachReadAloud();
    scheduleDeferredWindowWarmup(currentChapterIndex);
    if (pageTurnMode() == PageAnim.scroll) {
      updateScrollPreloadForVisibleChapter(visibleChapterIndex);
      triggerSilentPreload();
    }
  }
}
