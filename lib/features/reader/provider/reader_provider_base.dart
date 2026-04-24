import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_temp_chapter_cache_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_mailbox.dart';

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
  final ReaderTempChapterCacheDao? readerTempChapterCacheDao =
      getIt.isRegistered<ReaderTempChapterCacheDao>()
          ? getIt<ReaderTempChapterCacheDao>()
          : null;
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
  double scrollViewportTopInset = 0.0;
  double scrollViewportBottomInset = 0.0;

  final Map<int, List<TextPage>> _chapterPagesCache = {};
  Map<int, List<TextPage>> get chapterPagesCache => _chapterPagesCache;

  List<TextPage> slidePages = [];
  final Set<int> loadingChapters = {};
  bool get isLoading => loadingChapters.isNotEmpty;

  final ReaderViewportMailbox<ReaderCommandReason> _viewportMailbox =
      ReaderViewportMailbox<ReaderCommandReason>(
        systemReason: ReaderCommandReason.system,
      );

  bool showControls = false;
  int scrubbingChapterIndex = -1;
  ReaderLifecycle lifecycle = ReaderLifecycle.loading;
  bool get isReady => lifecycle == ReaderLifecycle.ready;

  List<int> clickActions = [0, 0, 0, 0, 0, 0, 0, 0, 0];
  List<Bookmark> bookmarks = [];
  final ValueNotifier<int> batteryLevelNotifier = ValueNotifier<int>(100);
  final ValueNotifier<double> autoPageProgressNotifier = ValueNotifier<double>(
    0.0,
  );

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

  bool updateContentInsets({required double top, required double bottom}) {
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

  bool updateScrollViewportInsets({
    required double top,
    required double bottom,
  }) {
    final normalizedTop = top < 0 ? 0.0 : top;
    final normalizedBottom = bottom < 0 ? 0.0 : bottom;
    if ((scrollViewportTopInset - normalizedTop).abs() < 0.5 &&
        (scrollViewportBottomInset - normalizedBottom).abs() < 0.5) {
      return false;
    }
    scrollViewportTopInset = normalizedTop;
    scrollViewportBottomInset = normalizedBottom;
    return true;
  }

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void requestJumpToPage(
    int pageIndex, {
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    _viewportMailbox.requestJumpToPage(pageIndex);
  }

  int? consumePendingJump() {
    return _viewportMailbox.consumePendingJump();
  }

  void requestJumpToChapter({
    required int chapterIndex,
    double alignment = 0.0,
    double localOffset = 0.0,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    _viewportMailbox.requestJumpToChapter(
      chapterIndex: chapterIndex,
      alignment: alignment,
      localOffset: localOffset,
      reason: reason,
    );
  }

  ({
    int chapterIndex,
    double alignment,
    double localOffset,
    ReaderCommandReason reason,
  })?
  consumePendingChapterJump() {
    final jump = _viewportMailbox.consumePendingChapterJump();
    if (jump == null) return null;
    return (
      chapterIndex: jump.chapterIndex,
      alignment: jump.alignment,
      localOffset: jump.localOffset,
      reason: jump.reason,
    );
  }

  int? consumePendingSlidePageIndex() {
    return _viewportMailbox.consumePendingSlidePageIndex();
  }

  /// Request PageController recreation at [pageIndex] to avoid
  /// the one-frame glitch during slide window recentering.
  void requestControllerReset(int pageIndex) {
    _viewportMailbox.requestControllerReset(pageIndex);
  }

  /// Consume the pending controller reset target.
  /// Returns null if no reset is pending.
  int? consumeControllerReset() {
    return _viewportMailbox.consumeControllerReset();
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
