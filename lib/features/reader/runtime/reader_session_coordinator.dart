import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';

class ReaderSessionCoordinator {
  final ReaderSessionState _state;
  final ReaderProgressStore _store;
  final Book Function() _book;
  final List<BookChapter> Function() _chapters;
  final Future<void> Function(
    int chapterIndex,
    String title,
    int charOffset,
    String? readerAnchorJson,
  )
  _writeProgress;

  ReaderSessionCoordinator({
    required ReaderSessionState state,
    required ReaderProgressStore store,
    required Book Function() book,
    required List<BookChapter> Function() chapters,
    required Future<void> Function(
      int chapterIndex,
      String title,
      int charOffset,
      String? readerAnchorJson,
    )
    writeProgress,
  }) : _state = state,
       _store = store,
       _book = book,
       _chapters = chapters,
       _writeProgress = writeProgress;

  ReaderLocation get committedLocation => _state.committedLocation;
  ReaderLocation get visibleLocation => _state.visibleLocation;
  ReaderLocation get durableLocation => _state.durableLocation;
  bool get visibleConfirmed => _state.visibleConfirmed;
  int get generation => _state.generation;
  ReaderSessionPhase get phase => _state.phase;

  void updateCommittedLocation(ReaderLocation location) {
    _state.updateCommittedLocation(location);
  }

  void updateVisibleLocation(ReaderLocation location) {
    _state.updateVisibleLocation(location);
  }

  void updateDurableLocation(ReaderLocation location) {
    _state.updateDurableLocation(location);
  }

  void updateVisibleConfirmed(bool confirmed) {
    _state.updateVisibleConfirmed(confirmed);
  }

  int bumpGeneration() {
    return _state.bumpGeneration();
  }

  void updatePhase(ReaderSessionPhase phase) {
    _state.updatePhase(phase);
  }

  Future<void> persistLocation(ReaderLocation location) async {
    await persistAnchor(ReaderAnchor.location(location));
  }

  Future<void> persistAnchor(ReaderAnchor anchor) async {
    final normalized = anchor.normalized();
    updateCommittedLocation(normalized.location);
    updateDurableLocation(normalized.location);
    await _store.persistCharOffset(
      write: _writeProgress,
      book: _book(),
      chapters: _chapters(),
      chapterIndex: normalized.location.chapterIndex,
      charOffset: normalized.location.charOffset,
      anchor: normalized,
    );
  }
}
