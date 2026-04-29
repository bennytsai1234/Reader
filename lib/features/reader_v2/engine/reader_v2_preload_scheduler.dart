import 'dart:async';
import 'dart:collection';

import 'package:inkpage_reader/features/reader/engine/text_page.dart';

import 'reader_v2_resolver.dart';

enum _ReaderV2PreloadKind { content, layout }

class _ReaderV2PreloadTask {
  const _ReaderV2PreloadTask({
    required this.kind,
    required this.chapterIndex,
    required this.generation,
  });

  final _ReaderV2PreloadKind kind;
  final int chapterIndex;
  final int generation;
}

class ReaderV2PreloadScheduler {
  ReaderV2PreloadScheduler({
    required this.resolver,
    int maxConcurrentContentTasks = 1,
    int maxConcurrentLayoutTasks = 1,
  }) : _maxConcurrentContentTasks =
           maxConcurrentContentTasks < 1 ? 1 : maxConcurrentContentTasks,
       _maxConcurrentLayoutTasks =
           maxConcurrentLayoutTasks < 1 ? 1 : maxConcurrentLayoutTasks;

  final ReaderV2Resolver resolver;
  final int _maxConcurrentContentTasks;
  final int _maxConcurrentLayoutTasks;

  final Queue<_ReaderV2PreloadTask> _contentQueue =
      Queue<_ReaderV2PreloadTask>();
  final Queue<_ReaderV2PreloadTask> _layoutQueue =
      Queue<_ReaderV2PreloadTask>();
  final Set<String> _queuedContentKeys = <String>{};
  final Set<String> _queuedLayoutKeys = <String>{};
  final Set<String> _activeContentKeys = <String>{};
  final Set<String> _activeLayoutKeys = <String>{};
  final Map<String, List<Completer<void>>> _waiters =
      <String, List<Completer<void>>>{};

  int _generation = 0;
  bool _disposed = false;

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
    return scheduleOpen(centerChapterIndex);
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
    if (layoutRadius >= 0) {
      resolver.retainLayoutsFor(layoutIndexes);
    }
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
    final key = _taskKey(_ReaderV2PreloadKind.content, safeIndex, 0);
    final future = _registerWaiter(key);
    if (!_queuedContentKeys.contains(key) &&
        !_activeContentKeys.contains(key)) {
      _enqueue(
        _ReaderV2PreloadTask(
          kind: _ReaderV2PreloadKind.content,
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
    final key = _taskKey(_ReaderV2PreloadKind.layout, safeIndex, _generation);
    final future = _registerWaiter(key);
    if (!_queuedLayoutKeys.contains(key) && !_activeLayoutKeys.contains(key)) {
      _enqueue(
        _ReaderV2PreloadTask(
          kind: _ReaderV2PreloadKind.layout,
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
    final order = <int>[center];
    for (var delta = 1; delta <= radius; delta++) {
      final left = center - delta;
      if (left >= 0) order.add(left);
      final right = center + delta;
      if (right < chapterCount) order.add(right);
    }
    return order;
  }

  void _enqueue(_ReaderV2PreloadTask task, {required bool priority}) {
    final queue =
        task.kind == _ReaderV2PreloadKind.content ? _contentQueue : _layoutQueue;
    final queuedKeys =
        task.kind == _ReaderV2PreloadKind.content
            ? _queuedContentKeys
            : _queuedLayoutKeys;
    final key = _taskKey(task.kind, task.chapterIndex, task.generation);
    queuedKeys.add(key);
    if (priority) {
      queue.addFirst(task);
    } else {
      queue.addLast(task);
    }
  }

  void _pumpContent() {
    while (_activeContentKeys.length < _maxConcurrentContentTasks &&
        _contentQueue.isNotEmpty) {
      final task = _contentQueue.removeFirst();
      final key = _taskKey(task.kind, task.chapterIndex, task.generation);
      _queuedContentKeys.remove(key);
      _activeContentKeys.add(key);
      resolver.repository
          .preloadContent(task.chapterIndex)
          .then((_) => _completeWaiters(key))
          .catchError((_) => _completeWaiters(key))
          .whenComplete(() {
            _activeContentKeys.remove(key);
            _pumpContent();
          });
    }
  }

  void _pumpLayout() {
    while (_activeLayoutKeys.length < _maxConcurrentLayoutTasks &&
        _layoutQueue.isNotEmpty) {
      final task = _layoutQueue.removeFirst();
      final key = _taskKey(task.kind, task.chapterIndex, task.generation);
      _queuedLayoutKeys.remove(key);
      _activeLayoutKeys.add(key);
      resolver
          .ensureLayout(task.chapterIndex, retryOnStale: false)
          .then((_) => _completeWaiters(key))
          .catchError((_) => _completeWaiters(key))
          .whenComplete(() {
            _activeLayoutKeys.remove(key);
            _pumpLayout();
          });
    }
  }

  Future<void> _registerWaiter(String key) {
    final completer = Completer<void>();
    (_waiters[key] ??= <Completer<void>>[]).add(completer);
    return completer.future;
  }

  String _taskKey(_ReaderV2PreloadKind kind, int chapterIndex, int generation) {
    return '${kind.name}|$chapterIndex|$generation';
  }

  int? _validChapterIndex(int chapterIndex) {
    final count = resolver.repository.chapterCount;
    if (count <= 0 || chapterIndex < 0 || chapterIndex >= count) return null;
    return chapterIndex;
  }

  void _completeWaiters(String key) {
    final waiters = _waiters.remove(key);
    if (waiters == null) return;
    for (final completer in waiters) {
      if (!completer.isCompleted) completer.complete();
    }
  }

  void _completeAllWaiters() {
    final keys = _waiters.keys.toList(growable: false);
    for (final key in keys) {
      _completeWaiters(key);
    }
  }

  void _completeLayoutWaiters() {
    final keys =
        _waiters.keys
            .where((key) => key.startsWith('${_ReaderV2PreloadKind.layout.name}|'))
            .toList(growable: false);
    for (final key in keys) {
      _completeWaiters(key);
    }
  }

  void _clearQueued({required bool content, required bool layout}) {
    if (content) {
      _contentQueue.clear();
      _queuedContentKeys.clear();
    }
    if (layout) {
      _layoutQueue.clear();
      _queuedLayoutKeys.clear();
    }
  }
}
