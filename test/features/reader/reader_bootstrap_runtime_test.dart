import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_host_base.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_bootstrap_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_lifecycle_runtime.dart';

void main() {
  group('ReaderBootstrapRuntime', () {
    test('slide bootstrap 會依序完成 prepare/render/restore/warmup', () async {
      final lifecycle = ReaderViewportLifecycleRuntime();
      final runtime = ReaderBootstrapRuntime(viewportLifecycle: lifecycle);
      final logs = <String>[];
      final phases = <ReaderSessionPhase>[];
      Size? appliedSize;
      ReaderLifecycle? currentLifecycle;
      ({int chapterIndex, int preloadRadius})? loadRequest;
      ({int chapterIndex, int charOffset})? restoreRequest;
      var clearedInitialCharOffset = false;

      await runtime.bootstrap(
        currentViewSize: const Size(360, 720),
        pageTurnMode: () => PageAnim.slide,
        isLocalBook: false,
        currentChapterIndex: 2,
        visibleChapterIndex: 2,
        initialCharOffset: 48,
        isDisposed: () => false,
        addObserver: () => logs.add('addObserver'),
        setLifecycle: (value) {
          currentLifecycle = value;
          logs.add('lifecycle:$value');
        },
        updatePhase: (value) {
          phases.add(value);
          logs.add('phase:$value');
        },
        wireCallbacks: () => logs.add('wireCallbacks'),
        prepareTasks: <ReaderBootstrapPrepareTask>[
          () async => logs.add('prepare:settings'),
          () async => logs.add('prepare:autoPage'),
          () async => logs.add('prepare:tts'),
          () async => logs.add('prepare:chapters'),
          () async => logs.add('prepare:source'),
        ],
        initContentManager: () => logs.add('initContentManager'),
        configureRepaginateHooks: () => logs.add('configureRepaginateHooks'),
        batchUpdate: (fn) {
          logs.add('batch:start');
          fn();
          logs.add('batch:end');
        },
        applyViewSize: (size) {
          appliedSize = size;
          logs.add('applyViewSize:$size');
        },
        loadChapterWithPreloadRadius: (chapterIndex, preloadRadius) async {
          loadRequest = (
            chapterIndex: chapterIndex,
            preloadRadius: preloadRadius,
          );
          logs.add('loadChapter:$chapterIndex:$preloadRadius');
        },
        bootstrapChapterWindow: (index) => logs.add('bootstrapWindow:$index'),
        restoreInitialCharOffset: (chapterIndex, charOffset) {
          restoreRequest = (chapterIndex: chapterIndex, charOffset: charOffset);
          logs.add('restore:$chapterIndex:$charOffset');
          return false;
        },
        clearInitialCharOffset: () {
          clearedInitialCharOffset = true;
          logs.add('clearInitialCharOffset');
        },
        startBatteryHeartbeat: () => logs.add('startBatteryHeartbeat'),
        attachReadAloud: () => logs.add('attachReadAloud'),
        scheduleDeferredWindowWarmup:
            (index) => logs.add('scheduleWarmup:$index'),
        updateScrollPreloadForVisibleChapter:
            (index) => logs.add('scrollPreload:$index'),
        triggerSilentPreload: () => logs.add('triggerSilentPreload'),
      );

      expect(appliedSize, const Size(360, 720));
      expect(currentLifecycle, ReaderLifecycle.ready);
      expect(phases, <ReaderSessionPhase>[
        ReaderSessionPhase.bootstrapping,
        ReaderSessionPhase.contentLoading,
        ReaderSessionPhase.ready,
      ]);
      expect(loadRequest, (chapterIndex: 2, preloadRadius: 2));
      expect(restoreRequest, (chapterIndex: 2, charOffset: 48));
      expect(clearedInitialCharOffset, isTrue);
      expect(logs, <String>[
        'addObserver',
        'lifecycle:ReaderLifecycle.loading',
        'phase:ReaderSessionPhase.bootstrapping',
        'wireCallbacks',
        'prepare:settings',
        'prepare:autoPage',
        'prepare:tts',
        'prepare:chapters',
        'prepare:source',
        'initContentManager',
        'configureRepaginateHooks',
        'batch:start',
        'applyViewSize:Size(360.0, 720.0)',
        'batch:end',
        'phase:ReaderSessionPhase.contentLoading',
        'loadChapter:2:2',
        'batch:start',
        'bootstrapWindow:2',
        'restore:2:48',
        'clearInitialCharOffset',
        'lifecycle:ReaderLifecycle.ready',
        'phase:ReaderSessionPhase.ready',
        'batch:end',
        'startBatteryHeartbeat',
        'attachReadAloud',
        'scheduleWarmup:2',
      ]);
    });

    test('scroll bootstrap 會在 warmup 階段啟動 preload', () async {
      final lifecycle = ReaderViewportLifecycleRuntime();
      final runtime = ReaderBootstrapRuntime(viewportLifecycle: lifecycle);
      final logs = <String>[];
      ({int chapterIndex, int preloadRadius})? loadRequest;

      await runtime.bootstrap(
        currentViewSize: const Size(320, 640),
        pageTurnMode: () => PageAnim.scroll,
        isLocalBook: true,
        currentChapterIndex: 1,
        visibleChapterIndex: 3,
        initialCharOffset: 0,
        isDisposed: () => false,
        addObserver: () {},
        setLifecycle: (_) {},
        updatePhase: (_) {},
        wireCallbacks: () {},
        prepareTasks: const <ReaderBootstrapPrepareTask>[],
        initContentManager: () {},
        configureRepaginateHooks: () {},
        batchUpdate: (fn) => fn(),
        applyViewSize: (_) {},
        loadChapterWithPreloadRadius: (chapterIndex, preloadRadius) async {
          loadRequest = (
            chapterIndex: chapterIndex,
            preloadRadius: preloadRadius,
          );
        },
        bootstrapChapterWindow: (_) {},
        restoreInitialCharOffset: (_, __) {
          logs.add('restore');
          return false;
        },
        clearInitialCharOffset: () => logs.add('clear'),
        startBatteryHeartbeat: () => logs.add('battery'),
        attachReadAloud: () => logs.add('aloud'),
        scheduleDeferredWindowWarmup: (index) => logs.add('warmup:$index'),
        updateScrollPreloadForVisibleChapter:
            (index) => logs.add('scrollPreload:$index'),
        triggerSilentPreload: () => logs.add('silentPreload'),
      );

      expect(loadRequest, (chapterIndex: 1, preloadRadius: 1));
      expect(logs, <String>[
        'battery',
        'aloud',
        'warmup:1',
        'scrollPreload:3',
        'silentPreload',
      ]);
    });

    test('bootstrap 會讀取 prepare 後更新的 pageTurnMode', () async {
      final runtime = ReaderBootstrapRuntime();
      var mode = PageAnim.slide;
      ({int chapterIndex, int preloadRadius})? loadRequest;
      final logs = <String>[];

      await runtime.bootstrap(
        currentViewSize: const Size(320, 640),
        pageTurnMode: () => mode,
        isLocalBook: true,
        currentChapterIndex: 1,
        visibleChapterIndex: 2,
        initialCharOffset: 0,
        isDisposed: () => false,
        addObserver: () {},
        setLifecycle: (_) {},
        updatePhase: (_) {},
        wireCallbacks: () {},
        prepareTasks: <ReaderBootstrapPrepareTask>[
          () async => mode = PageAnim.scroll,
        ],
        initContentManager: () {},
        configureRepaginateHooks: () {},
        batchUpdate: (fn) => fn(),
        applyViewSize: (_) {},
        loadChapterWithPreloadRadius: (chapterIndex, preloadRadius) async {
          loadRequest = (
            chapterIndex: chapterIndex,
            preloadRadius: preloadRadius,
          );
        },
        bootstrapChapterWindow: (_) {},
        restoreInitialCharOffset: (_, __) => false,
        clearInitialCharOffset: () {},
        startBatteryHeartbeat: () => logs.add('battery'),
        attachReadAloud: () => logs.add('aloud'),
        scheduleDeferredWindowWarmup: (index) => logs.add('warmup:$index'),
        updateScrollPreloadForVisibleChapter:
            (index) => logs.add('scrollPreload:$index'),
        triggerSilentPreload: () => logs.add('silentPreload'),
      );

      expect(loadRequest, (chapterIndex: 1, preloadRadius: 1));
      expect(logs, <String>[
        'battery',
        'aloud',
        'warmup:1',
        'scrollPreload:2',
        'silentPreload',
      ]);
    });

    test('scroll restore bootstrap 會把 phase 標為 restoring', () async {
      final runtime = ReaderBootstrapRuntime();
      final phases = <ReaderSessionPhase>[];

      await runtime.bootstrap(
        currentViewSize: const Size(320, 640),
        pageTurnMode: () => PageAnim.scroll,
        isLocalBook: false,
        currentChapterIndex: 1,
        visibleChapterIndex: 1,
        initialCharOffset: 96,
        isDisposed: () => false,
        addObserver: () {},
        setLifecycle: (_) {},
        updatePhase: phases.add,
        wireCallbacks: () {},
        prepareTasks: const <ReaderBootstrapPrepareTask>[],
        initContentManager: () {},
        configureRepaginateHooks: () {},
        batchUpdate: (fn) => fn(),
        applyViewSize: (_) {},
        loadChapterWithPreloadRadius: (_, __) async {},
        bootstrapChapterWindow: (_) {},
        restoreInitialCharOffset: (_, __) => true,
        clearInitialCharOffset: () {},
        startBatteryHeartbeat: () {},
        attachReadAloud: () {},
        scheduleDeferredWindowWarmup: (_) {},
        updateScrollPreloadForVisibleChapter: (_) {},
        triggerSilentPreload: () {},
      );

      expect(phases, <ReaderSessionPhase>[
        ReaderSessionPhase.bootstrapping,
        ReaderSessionPhase.contentLoading,
        ReaderSessionPhase.restoring,
      ]);
    });

    test('prepare 後若已 disposed 會中止後續 bootstrap', () async {
      final runtime = ReaderBootstrapRuntime();
      final logs = <String>[];
      var disposed = false;

      await runtime.bootstrap(
        currentViewSize: const Size(320, 640),
        pageTurnMode: () => PageAnim.slide,
        isLocalBook: false,
        currentChapterIndex: 0,
        visibleChapterIndex: 0,
        initialCharOffset: 12,
        isDisposed: () => disposed,
        addObserver: () => logs.add('addObserver'),
        setLifecycle: (_) => logs.add('setLifecycle'),
        updatePhase: (_) => logs.add('updatePhase'),
        wireCallbacks: () => logs.add('wireCallbacks'),
        prepareTasks: <ReaderBootstrapPrepareTask>[
          () async {
            disposed = true;
            logs.add('prepare');
          },
        ],
        initContentManager: () => logs.add('initContentManager'),
        configureRepaginateHooks: () => logs.add('configureHooks'),
        batchUpdate: (fn) => fn(),
        applyViewSize: (_) => logs.add('applyViewSize'),
        loadChapterWithPreloadRadius: (_, __) async => logs.add('loadChapter'),
        bootstrapChapterWindow: (_) => logs.add('bootstrapWindow'),
        restoreInitialCharOffset: (_, __) {
          logs.add('restore');
          return false;
        },
        clearInitialCharOffset: () => logs.add('clear'),
        startBatteryHeartbeat: () => logs.add('battery'),
        attachReadAloud: () => logs.add('aloud'),
        scheduleDeferredWindowWarmup: (_) => logs.add('warmup'),
        updateScrollPreloadForVisibleChapter: (_) => logs.add('scrollPreload'),
        triggerSilentPreload: () => logs.add('silentPreload'),
      );

      expect(logs, <String>[
        'addObserver',
        'setLifecycle',
        'updatePhase',
        'wireCallbacks',
        'prepare',
      ]);
    });
  });
}
