import 'dart:async';
import 'dart:collection';

import 'package:inkpage_reader/features/reader/engine/page_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

enum _PreloadKind { content, layout }

class _PreloadTask {
  const _PreloadTask({
    required this.kind,
    required this.chapterIndex,
    required this.generation,
  });

  final _PreloadKind kind;
  final int chapterIndex;
  final int generation;
}

class ReaderPreloadScheduler {
  ReaderPreloadScheduler({
    required this.resolver,
    int maxConcurrentContentTasks = 1,
    int maxConcurrentLayoutTasks = 1,
  }) : _maxConcurrentContentTasks =
           maxConcurrentContentTasks < 1 ? 1 : maxConcurrentContentTasks,
       _maxConcurrentLayoutTasks =
           maxConcurrentLayoutTasks < 1 ? 1 : maxConcurrentLayoutTasks;

  final PageResolver resolver;
  final int _maxConcurrentContentTasks;
  final int _maxConcurrentLayoutTasks;

  final Queue<_PreloadTask> _contentQueue = Queue<_PreloadTask>();
  final Queue<_PreloadTask> _layoutQueue = Queue<_PreloadTask>();
  final Set<String> _queuedContentKeys = <String>{};
  final Set<String> _queuedLayoutKeys = <String>{};
  final Set<String> _activeContentKeys = <String>{};
  final Set<String> _activeLayoutKeys = <String>{};
  final Map<String, List<Completer<void>>> _waiters =
      <String, List<Completer<void>>>{};

  int _generation = 0;
  bool _disposed = false;

  int get generation => _generation;
  bool get isDisposed => _disposed;

  List<int> get pendingContentChapterIndexes =>
      _contentQueue.map((task) => task.chapterIndex).toList(growable: false);

  List<int> get pendingLayoutChapterIndexes =>
      _layoutQueue.map((task) => task.chapterIndex).toList(growable: false);

  Set<int> get activeContentChapterIndexes =>
      _activeContentKeys.map(_chapterIndexFromKey).toSet();

  Set<int> get activeLayoutChapterIndexes =>
      _activeLayoutKeys.map(_chapterIndexFromKey).toSet();

  int bumpGeneration() {
    _generation += 1;
    _clearQueued(layout: true, content: false);
    _activeLayoutKeys.clear();
    _completeLayoutWaiters();
    return _generation;
  }

  Future<void> scheduleOpen(int centerChapterIndex) {
    return scheduleAround(
      centerChapterIndex,
      contentRadius: 1,
      layoutRadius: 1,
      replaceQueued: true,
    );
  }

  Future<void> scheduleJump(int centerChapterIndex) {
    return scheduleAround(
      centerChapterIndex,
      contentRadius: 1,
      layoutRadius: 1,
      replaceQueued: true,
    );
  }

  Future<void> scheduleScrollSettled(TextPage page) {
    if (page.isPlaceholder) return Future<void>.value();
    if (page.pageIndex >= page.pageSize - 2) {
      return scheduleDirectional(
        fromChapterIndex: page.chapterIndex,
        forward: true,
      );
    }
    if (page.pageIndex <= 1) {
      return scheduleDirectional(
        fromChapterIndex: page.chapterIndex,
        forward: false,
      );
    }
    return scheduleContent(page.chapterIndex);
  }

  Future<void> scheduleSlidePageSettled(TextPage page) {
    return scheduleScrollSettled(page);
  }

  Future<void> scheduleDirectional({
    required int fromChapterIndex,
    required bool forward,
  }) {
    final target = fromChapterIndex + (forward ? 1 : -1);
    return scheduleChapters(
      contentChapterIndexes: <int>[target],
      layoutChapterIndexes: <int>[target],
      priority: true,
    );
  }

  Future<void> scheduleAround(
    int centerChapterIndex, {
    int contentRadius = 1,
    int layoutRadius = 1,
    bool replaceQueued = false,
  }) {
    if (_disposed) return Future<void>.value();
    final chapterCount = resolver.repository.chapterCount;
    if (chapterCount <= 0) return Future<void>.value();
    if (replaceQueued) {
      _clearQueued(content: true, layout: true);
    }
    final center = centerChapterIndex.clamp(0, chapterCount - 1).toInt();
    final maxRadius =
        contentRadius > layoutRadius ? contentRadius : layoutRadius;
    final order = buildCenteredOrder(
      chapterCount: chapterCount,
      centerChapterIndex: center,
      radius: maxRadius < 0 ? 0 : maxRadius,
    );
    final futures = <Future<void>>[];
    final layoutIndexes = <int>{
      for (final index in order)
        if ((index - center).abs() <= layoutRadius) index,
    };
    for (final index in order) {
      if ((index - center).abs() <= contentRadius &&
          !layoutIndexes.contains(index)) {
        futures.add(scheduleContent(index));
      }
      if (layoutIndexes.contains(index)) {
        futures.add(scheduleLayout(index));
      }
    }
    return Future.wait(futures).then((_) {});
  }

  Future<void> scheduleChapters({
    Iterable<int> contentChapterIndexes = const <int>[],
    Iterable<int> layoutChapterIndexes = const <int>[],
    bool priority = false,
  }) {
    if (_disposed) return Future<void>.value();
    final futures = <Future<void>>[];
    final layoutIndexes = layoutChapterIndexes.toSet();
    for (final index in contentChapterIndexes) {
      if (!layoutIndexes.contains(index)) {
        futures.add(scheduleContent(index, priority: priority));
      }
    }
    for (final index in layoutIndexes) {
      futures.add(scheduleLayout(index, priority: priority));
    }
    return Future.wait(futures).then((_) {});
  }

  Future<void> scheduleContent(int chapterIndex, {bool priority = false}) {
    if (_disposed) return Future<void>.value();
    final safeIndex = _validChapterIndex(chapterIndex);
    if (safeIndex == null) return Future<void>.value();
    if (resolver.repository.cachedContent(safeIndex) != null) {
      return Future<void>.value();
    }
    final key = _taskKey(_PreloadKind.content, safeIndex, 0);
    final future = _registerWaiter(key);
    if (!_queuedContentKeys.contains(key) &&
        !_activeContentKeys.contains(key)) {
      _enqueue(
        _PreloadTask(
          kind: _PreloadKind.content,
          chapterIndex: safeIndex,
          generation: 0,
        ),
        priority: priority,
      );
    }
    _pumpContent();
    return future;
  }

  Future<void> scheduleLayout(int chapterIndex, {bool priority = false}) {
    if (_disposed) return Future<void>.value();
    final safeIndex = _validChapterIndex(chapterIndex);
    if (safeIndex == null) return Future<void>.value();
    if (resolver.cachedLayout(safeIndex) != null) {
      return Future<void>.value();
    }
    final key = _taskKey(_PreloadKind.layout, safeIndex, _generation);
    final future = _registerWaiter(key);
    if (!_queuedLayoutKeys.contains(key) && !_activeLayoutKeys.contains(key)) {
      _enqueue(
        _PreloadTask(
          kind: _PreloadKind.layout,
          chapterIndex: safeIndex,
          generation: _generation,
        ),
        priority: priority,
      );
    }
    _pumpLayout();
    return future;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _clearQueued(content: true, layout: true);
    _completeAllWaiters();
  }

  static List<int> buildCenteredOrder({
    required int chapterCount,
    required int centerChapterIndex,
    required int radius,
  }) {
    if (chapterCount <= 0 || radius < 0) return const <int>[];
    final center = centerChapterIndex.clamp(0, chapterCount - 1).toInt();
    final result = <int>[center];
    for (var distance = 1; distance <= radius; distance++) {
      final next = center + distance;
      if (next < chapterCount) result.add(next);
      final previous = center - distance;
      if (previous >= 0) result.add(previous);
    }
    return result;
  }

  void _enqueue(_PreloadTask task, {required bool priority}) {
    final key = _keyForTask(task);
    switch (task.kind) {
      case _PreloadKind.content:
        if (priority) {
          _contentQueue.addFirst(task);
        } else {
          _contentQueue.add(task);
        }
        _queuedContentKeys.add(key);
        break;
      case _PreloadKind.layout:
        if (priority) {
          _layoutQueue.addFirst(task);
        } else {
          _layoutQueue.add(task);
        }
        _queuedLayoutKeys.add(key);
        break;
    }
  }

  void _pumpContent() {
    if (_disposed) return;
    while (_activeContentKeys.length < _maxConcurrentContentTasks &&
        _contentQueue.isNotEmpty) {
      final task = _contentQueue.removeFirst();
      final key = _keyForTask(task);
      _queuedContentKeys.remove(key);
      if (resolver.repository.cachedContent(task.chapterIndex) != null) {
        _completeWaiters(key);
        continue;
      }
      _activeContentKeys.add(key);
      unawaited(_runContentTask(task, key));
    }
  }

  void _pumpLayout() {
    if (_disposed) return;
    while (_activeLayoutKeys.length < _maxConcurrentLayoutTasks &&
        _layoutQueue.isNotEmpty) {
      final task = _layoutQueue.removeFirst();
      final key = _keyForTask(task);
      _queuedLayoutKeys.remove(key);
      if (task.generation != _generation ||
          resolver.cachedLayout(task.chapterIndex) != null) {
        _completeWaiters(key);
        continue;
      }
      _activeLayoutKeys.add(key);
      unawaited(_runLayoutTask(task, key));
    }
  }

  Future<void> _runContentTask(_PreloadTask task, String key) async {
    try {
      await resolver.repository.preloadContent(task.chapterIndex);
    } catch (_) {
      // Background content preload is opportunistic. Foreground navigation
      // still surfaces loading errors through PageResolver placeholders.
    } finally {
      _activeContentKeys.remove(key);
      _completeWaiters(key);
      _pumpContent();
    }
  }

  Future<void> _runLayoutTask(_PreloadTask task, String key) async {
    try {
      if (task.generation == _generation) {
        await resolver.ensureLayout(task.chapterIndex);
      }
    } catch (_) {
      // Layout preload records resolver errors for placeholders, but does not
      // notify UI directly.
    } finally {
      _activeLayoutKeys.remove(key);
      _completeWaiters(key);
      _pumpLayout();
    }
  }

  Future<void> _registerWaiter(String key) {
    final completer = Completer<void>();
    _waiters.putIfAbsent(key, () => <Completer<void>>[]).add(completer);
    return completer.future;
  }

  void _completeWaiters(String key) {
    final waiters = _waiters.remove(key);
    if (waiters == null) return;
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  void _completeLayoutWaiters() {
    final layoutKeys =
        _waiters.keys
            .where((key) => key.startsWith('${_PreloadKind.layout.name}|'))
            .toList();
    for (final key in layoutKeys) {
      _completeWaiters(key);
    }
  }

  void _completeAllWaiters() {
    for (final key in _waiters.keys.toList()) {
      _completeWaiters(key);
    }
  }

  void _clearQueued({required bool content, required bool layout}) {
    if (content) {
      for (final task in _contentQueue) {
        _completeWaiters(_keyForTask(task));
      }
      _contentQueue.clear();
      _queuedContentKeys.clear();
    }
    if (layout) {
      for (final task in _layoutQueue) {
        _completeWaiters(_keyForTask(task));
      }
      _layoutQueue.clear();
      _queuedLayoutKeys.clear();
    }
  }

  int? _validChapterIndex(int chapterIndex) {
    final count = resolver.repository.chapterCount;
    if (count <= 0 || chapterIndex < 0 || chapterIndex >= count) return null;
    return chapterIndex;
  }

  String _keyForTask(_PreloadTask task) {
    return _taskKey(task.kind, task.chapterIndex, task.generation);
  }

  String _taskKey(_PreloadKind kind, int chapterIndex, int generation) {
    if (kind == _PreloadKind.content) {
      return '${kind.name}|$chapterIndex';
    }
    return '${kind.name}|$chapterIndex|$generation';
  }

  static int _chapterIndexFromKey(String key) {
    final parts = key.split('|');
    return int.tryParse(parts.length > 1 ? parts[1] : '') ?? -1;
  }
}
