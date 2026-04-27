import 'package:inkpage_reader/features/reader/runtime/reader_host_base.dart';

class ReaderCommandGuard {
  ReaderCommandReason? _activeReason;

  ReaderCommandReason? get activeReason => _activeReason;

  bool canDispatch(ReaderCommandReason reason) {
    final active = _activeReason;
    if (active == null) return true;
    if (active == reason) return true;
    return _priorityOf(reason) >= _priorityOf(active);
  }

  bool begin(ReaderCommandReason reason) {
    if (!canDispatch(reason)) return false;
    _activeReason = reason;
    return true;
  }

  void clear([ReaderCommandReason? reason]) {
    if (reason == null || _activeReason == reason) {
      _activeReason = null;
    }
  }

  int _priorityOf(ReaderCommandReason reason) {
    switch (reason) {
      case ReaderCommandReason.user:
      case ReaderCommandReason.userScroll:
        return 5;
      case ReaderCommandReason.restore:
        return 4;
      case ReaderCommandReason.settingsRepaginate:
        return 3;
      case ReaderCommandReason.tts:
        return 2;
      case ReaderCommandReason.autoPage:
        return 1;
      case ReaderCommandReason.chapterChange:
      case ReaderCommandReason.system:
        return 0;
    }
  }
}
