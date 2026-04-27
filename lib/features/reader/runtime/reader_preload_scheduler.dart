import 'dart:async';

import 'package:inkpage_reader/features/reader/engine/page_resolver.dart';

class ReaderPreloadScheduler {
  ReaderPreloadScheduler({required this.resolver});

  final PageResolver resolver;
  int _generation = 0;

  int bumpGeneration() {
    _generation += 1;
    return _generation;
  }

  int get generation => _generation;

  void preloadAround(int chapterIndex, {int radius = 1}) {
    final generation = _generation;
    for (
      var index = chapterIndex - radius;
      index <= chapterIndex + radius;
      index++
    ) {
      if (index < 0 || index >= resolver.repository.chapterCount) continue;
      unawaited(_preload(index, generation));
    }
  }

  Future<void> _preload(int chapterIndex, int generation) async {
    try {
      final layout = await resolver.ensureLayout(chapterIndex);
      if (generation != _generation) return;
      // The resolver owns the cache; touching the layout here only makes the
      // generation check explicit and keeps stale work harmless.
      layout.pages.length;
    } catch (_) {
      // Preload is opportunistic. Foreground navigation will surface errors.
    }
  }
}
