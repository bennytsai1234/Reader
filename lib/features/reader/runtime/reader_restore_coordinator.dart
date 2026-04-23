import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

class ReaderRestoreCoordinator {
  int _pendingScrollRestoreToken = 0;
  ReaderAnchor? _pendingScrollRestoreAnchor;
  bool _pendingScrollRestoreDispatched = false;

  int registerPendingScrollRestore({
    ReaderAnchor? anchor,
    int? chapterIndex,
    int charOffset = 0,
    double? localOffset,
  }) {
    final resolvedLocalOffset =
        localOffset ?? anchor?.localOffsetSnapshot ?? 0.0;
    final resolvedAnchor = (anchor ??
            ReaderAnchor.location(
              ReaderLocation(
                chapterIndex: chapterIndex ?? 0,
                charOffset: charOffset,
              ),
            ))
        .normalized()
        .copyWith(localOffsetSnapshot: resolvedLocalOffset);
    _pendingScrollRestoreToken++;
    _pendingScrollRestoreAnchor = resolvedAnchor;
    _pendingScrollRestoreDispatched = false;
    return _pendingScrollRestoreToken;
  }

  int get pendingScrollRestoreToken => _pendingScrollRestoreToken;
  ReaderAnchor? get pendingScrollRestoreAnchor => _pendingScrollRestoreAnchor;
  int? get pendingScrollRestoreChapterIndex =>
      _pendingScrollRestoreAnchor?.location.chapterIndex;
  double? get pendingScrollRestoreLocalOffset =>
      _pendingScrollRestoreAnchor?.localOffsetSnapshot;
  bool get hasPendingScrollRestore => _pendingScrollRestoreAnchor != null;
  bool get hasQueuedScrollRestore =>
      hasPendingScrollRestore && !_pendingScrollRestoreDispatched;

  bool matchesPendingScrollRestore(int token) =>
      hasPendingScrollRestore && token == _pendingScrollRestoreToken;

  ({int token, ReaderAnchor anchor, int chapterIndex, double localOffset})?
  dispatchPendingScrollRestore() {
    final anchor = _pendingScrollRestoreAnchor;
    final localOffset = anchor?.localOffsetSnapshot;
    if (anchor == null ||
        localOffset == null ||
        _pendingScrollRestoreDispatched) {
      return null;
    }
    _pendingScrollRestoreDispatched = true;
    return (
      token: _pendingScrollRestoreToken,
      anchor: anchor,
      chapterIndex: anchor.location.chapterIndex,
      localOffset: localOffset,
    );
  }

  void deferPendingScrollRestore(int token) {
    if (!matchesPendingScrollRestore(token)) return;
    _pendingScrollRestoreDispatched = false;
  }

  bool completePendingScrollRestore(int token) {
    if (!matchesPendingScrollRestore(token)) return false;
    clear();
    return true;
  }

  void clear() {
    _pendingScrollRestoreAnchor = null;
    _pendingScrollRestoreDispatched = false;
  }
}
