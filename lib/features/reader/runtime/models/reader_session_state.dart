import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

enum ReaderSessionPhase {
  bootstrapping,
  contentLoading,
  restoring,
  ready,
  repaginating,
  disposed,
}

class ReaderSessionState {
  ReaderLocation _committedLocation;
  ReaderLocation _visibleLocation;
  ReaderLocation _durableLocation;
  bool _visibleConfirmed;
  int _generation;
  ReaderSessionPhase _phase;

  ReaderSessionState({required ReaderLocation initialLocation})
    : _committedLocation = initialLocation.normalized(),
      _visibleLocation = initialLocation.normalized(),
      _durableLocation = initialLocation.normalized(),
      _visibleConfirmed = false,
      _generation = 0,
      _phase = ReaderSessionPhase.bootstrapping;

  ReaderLocation get committedLocation => _committedLocation;
  ReaderLocation get visibleLocation => _visibleLocation;
  ReaderLocation get durableLocation => _durableLocation;
  bool get visibleConfirmed => _visibleConfirmed;
  int get generation => _generation;
  ReaderSessionPhase get phase => _phase;

  void updateCommittedLocation(ReaderLocation location) {
    _committedLocation = location.normalized();
  }

  void updateVisibleLocation(ReaderLocation location) {
    _visibleLocation = location.normalized();
  }

  void updateDurableLocation(ReaderLocation location) {
    _durableLocation = location.normalized();
  }

  void updateVisibleConfirmed(bool confirmed) {
    _visibleConfirmed = confirmed;
  }

  int bumpGeneration() {
    _generation += 1;
    return _generation;
  }

  void updatePhase(ReaderSessionPhase phase) {
    _phase = phase;
  }
}
