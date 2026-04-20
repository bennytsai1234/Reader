import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

enum ReaderLifecycle { loading, ready, disposed }

enum ReaderCommandReason {
  restore,
  user,
  userScroll,
  tts,
  autoPage,
  chapterChange,
  settingsRepaginate,
  system,
}

abstract class ReaderProviderBase extends ChangeNotifier {
  final BookDao bookDao = getIt<BookDao>();
  final ChapterDao chapterDao = getIt<ChapterDao>();
  final ReplaceRuleDao replaceDao = getIt<ReplaceRuleDao>();
  final BookSourceDao sourceDao = getIt<BookSourceDao>();
  final BookSourceService service = BookSourceService();
  final BookmarkDao bookmarkDao = getIt<BookmarkDao>();

  final Book book;
  BookSource? source;
  List<BookChapter> chapters = [];

  int currentChapterIndex = 0;
  int currentPageIndex = 0;
  int visibleChapterIndex = 0;
  double visibleChapterAlignment = 0.0;
  double visibleChapterLocalOffset = 0.0;
  Size? viewSize;
  double contentTopInset = 0.0;
  double contentBottomInset = 0.0;

  final Map<int, List<TextPage>> _chapterPagesCache = {};
  Map<int, List<TextPage>> get chapterPagesCache => _chapterPagesCache;

  List<TextPage> slidePages = [];
  final Set<int> loadingChapters = {};
  bool get isLoading => loadingChapters.isNotEmpty;

  int? _pendingJumpTarget;
  int? _pendingJumpChapterIndex;
  double? _pendingJumpAlignment;
  double? _pendingJumpLocalOffset;
  int? _pendingSlidePageIndex;
  int? _pendingControllerReset;
  ReaderCommandReason _pendingChapterJumpReason = ReaderCommandReason.system;

  bool showControls = false;
  int scrubbingChapterIndex = -1;
  ReaderLifecycle lifecycle = ReaderLifecycle.loading;
  bool get isReady => lifecycle == ReaderLifecycle.ready;

  List<int> clickActions = [2, 1, 1, 2, 0, 1, 2, 1, 1];
  List<Bookmark> bookmarks = [];
  final ValueNotifier<int> batteryLevelNotifier = ValueNotifier<int>(100);
  final ValueNotifier<double> autoPageProgressNotifier = ValueNotifier<double>(0.0);

  // ── Batch update support ──────────────────────────────────────────
  bool _isBatching = false;
  bool _batchDirty = false;

  /// Run [fn] while suppressing intermediate notifyListeners calls.
  /// A single notifyListeners fires after [fn] completes if any state changed.
  void batchUpdate(VoidCallback fn) {
    _isBatching = true;
    _batchDirty = false;
    try {
      fn();
    } finally {
      _isBatching = false;
      if (_batchDirty) {
        notifyListeners();
      }
    }
  }

  @override
  void notifyListeners() {
    if (_isBatching) {
      _batchDirty = true;
      return;
    }
    if (_isDisposed) return;
    super.notifyListeners();
  }

  ReaderProviderBase(this.book);

  bool updateContentInsets({
    required double top,
    required double bottom,
  }) {
    final normalizedTop = top < 0 ? 0.0 : top;
    final normalizedBottom = bottom < 0 ? 0.0 : bottom;
    if ((contentTopInset - normalizedTop).abs() < 0.5 &&
        (contentBottomInset - normalizedBottom).abs() < 0.5) {
      return false;
    }
    contentTopInset = normalizedTop;
    contentBottomInset = normalizedBottom;
    return true;
  }

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void requestJumpToPage(
    int pageIndex, {
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    _pendingJumpTarget = pageIndex;
    _pendingSlidePageIndex = pageIndex;
  }

  int? consumePendingJump() {
    final value = _pendingJumpTarget;
    _pendingJumpTarget = null;
    return value;
  }

  void requestJumpToChapter({
    required int chapterIndex,
    double alignment = 0.0,
    double localOffset = 0.0,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    _pendingJumpChapterIndex = chapterIndex;
    _pendingJumpAlignment = alignment;
    _pendingJumpLocalOffset = localOffset;
    _pendingChapterJumpReason = reason;
  }

  ({
    int chapterIndex,
    double alignment,
    double localOffset,
    ReaderCommandReason reason,
  })? consumePendingChapterJump() {
    final chapterIndex = _pendingJumpChapterIndex;
    if (chapterIndex == null) return null;
    final alignment = _pendingJumpAlignment ?? 0.0;
    final localOffset = _pendingJumpLocalOffset ?? 0.0;
    final reason = _pendingChapterJumpReason;
    _pendingJumpChapterIndex = null;
    _pendingJumpAlignment = null;
    _pendingJumpLocalOffset = null;
    _pendingChapterJumpReason = ReaderCommandReason.system;
    return (
      chapterIndex: chapterIndex,
      alignment: alignment,
      localOffset: localOffset,
      reason: reason,
    );
  }

  int? consumePendingSlidePageIndex() {
    final value = _pendingSlidePageIndex;
    _pendingSlidePageIndex = null;
    return value;
  }

  /// Request PageController recreation at [pageIndex] to avoid
  /// the one-frame glitch during slide window recentering.
  void requestControllerReset(int pageIndex) {
    _pendingControllerReset = pageIndex;
  }

  /// Consume the pending controller reset target.
  /// Returns null if no reset is pending.
  int? consumeControllerReset() {
    final value = _pendingControllerReset;
    _pendingControllerReset = null;
    return value;
  }
  @override
  void dispose() {
    _isDisposed = true;
    lifecycle = ReaderLifecycle.disposed;
    batteryLevelNotifier.dispose();
    autoPageProgressNotifier.dispose();
    super.dispose();
  }
}
