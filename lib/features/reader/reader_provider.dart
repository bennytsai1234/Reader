import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_progress_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_tts_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_auto_page_mixin.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/core/constant/page_anim.dart';

export 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
export 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
export 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';
export 'package:legado_reader/features/reader/provider/reader_progress_mixin.dart';
export 'package:legado_reader/features/reader/provider/reader_tts_mixin.dart';
export 'package:legado_reader/features/reader/provider/reader_auto_page_mixin.dart';

/// ReaderProvider - 閱讀器狀態管理（重構版）
///
/// 職責拆分：
///  - [ReaderProviderBase]   : DAO、基礎狀態
///  - [ReaderSettingsMixin]  : 字體/行距/主題等設定
///  - [ReaderContentMixin]   : 章節加載、分頁、預載
///  - [ReaderProgressMixin]  : 進度儲存/恢復、位置計算  
///  - [ReaderTtsMixin]       : TTS 朗讀、高亮追蹤
///  - [ReaderAutoPageMixin]  : 自動翻頁
///
/// 此檔案僅負責組合所有 Mixin，初始化流程與 dispose 清理。
class ReaderProvider extends ReaderProviderBase
    with ReaderSettingsMixin, ReaderContentMixin, ReaderProgressMixin, ReaderTtsMixin, ReaderAutoPageMixin, WidgetsBindingObserver {

  ReaderProvider({required Book book, int chapterIndex = 0, int chapterPos = 0}) : super(book) {
    currentChapterIndex = chapterIndex;
    initialCharOffset = chapterPos;
    // 初始頁碼設為 0，直到恢復邏輯計算出真正的頁碼
    currentPageIndex = 0;
    _init();
  }

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this);
    await loadSettings();
    await _loadChapters();
    await _loadSource();

    if (isDisposed) return;

    // 標記正在恢復進度
    isRestoring = true;
    pendingRestorePos = initialCharOffset;

    // 注入回調：連接 ReaderContentMixin 與 ReaderProgressMixin
    _wireUpMixins();

    // 關鍵優化：延後 200ms 啟動首章載入，避開 App 啟動時的 CPU 尖峰
    await Future.delayed(const Duration(milliseconds: 200));
    if (isDisposed) return;

    await loadChapter(currentChapterIndex);

    if (isDisposed) return;

    // loadChapter 完成後會自動觸發 applyPendingRestore
    applyPendingRestore();

    listenAudioEvents();
    _startHeartbeat();
    initTtsListener();
  }

  /// 連接各 Mixin 之間的回調
  void _wireUpMixins() {
    // ReaderContentMixin 需要 ReaderProgressMixin 的方法
    getCharOffsetForScrollYFn = getCharOffsetForScrollY;
    jumpToPositionFn = ({int? charOffset, int? pageIndex, bool isRestoringJump = false}) {
      jumpToPosition(charOffset: charOffset, pageIndex: pageIndex, isRestoringJump: isRestoringJump);
    };
    applyPendingRestoreFn = applyPendingRestore;

    // ReaderTtsMixin 的 TTS 啟動回調：停止自動翻頁（互斥）
    onTtsStartCallback = () {
      if (isAutoPaging) stopAutoPage();
    };
  }

  // --- 心跳定時器 (用於電池等資訊) ---
  Timer? _heartbeatTimer;
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      batteryLevelNotifier.value = (batteryLevelNotifier.value - 1).clamp(0, 100);
    });
  }

  Future<void> _loadChapters() async {
    chapters = await chapterDao.getChapters(book.bookUrl);
    notifyListeners();
  }

  Future<void> _loadSource() async {
    source = await sourceDao.getByUrl(book.origin);
  }

  // --- 效能優化：精準更新屬性 ---
  double textPadding = 16.0;

  int get batteryLevel => batteryLevelNotifier.value;
  double get autoPageProgress => autoPageProgressNotifier.value;

  void setViewSize(Size size) {
    if (viewSize == null) {
      viewSize = size;
      if (chapterContentCache.containsKey(currentChapterIndex)) {
        doPaginate().then((_) => applyPendingRestore());
      } else if (pages.isEmpty && !isLoading && chapters.isNotEmpty) {
        loadChapter(currentChapterIndex);
      }
      return;
    }

    // 關鍵修復：如果尺寸變化非常小（例如 < 20 像素），忽略它。
    final double dw = (viewSize!.width - size.width).abs();
    final double dh = (viewSize!.height - size.height).abs();
    if (dw < 10 && dh < 20) return;

    if (viewSize != size) {
      viewSize = size;
      if (chapterContentCache.containsKey(currentChapterIndex)) {
        doPaginate();
      }
    }
  }

  @override
  void onPageChanged(int i) {
    if (currentPageIndex != i) {
      currentPageIndex = i;
      notifyListeners();

      // 進度恢復期間不執行主動儲存
      if (!isRestoring) {
        saveProgress(currentChapterIndex, i);
      }

      // 積極預載入：剩餘 2 頁時即開始加載下一章
      if (i >= pages.length - 2 && !isLoading) {
        final lastPage = pages.lastOrNull;
        if (lastPage != null && lastPage.chapterIndex < chapters.length - 1) {
          unawaited(_preloadChapterSilently(lastPage.chapterIndex + 1));
        }
      }
    }
  }

  /// 靜默預載入章節
  Future<void> _preloadChapterSilently(int chapterIndex) async {
    if (chapterIndex < 0 || chapterIndex >= chapters.length) return;
    if (chapterCache.containsKey(chapterIndex) || silentLoadingChapters.contains(chapterIndex)) return;
    await (this as ReaderContentMixin).loadChapter(chapterIndex);
  }

  @override
  void updateScrollOffset(double scrollY) {
    super.updateScrollOffset(scrollY);
    // 同步給 ReaderContentMixin，供 doPaginate 重新分頁時使用
    lastKnownScrollY = scrollY;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 退出閱讀器時確保當前進度已儲存
    if (isTtsActive) {
      saveTtsProgress();
    } else {
      saveProgress(currentChapterIndex, currentPageIndex);
    }
    scrollSaveTimer?.cancel();
    _heartbeatTimer?.cancel();
    autoPageTimer?.cancel();
    audioEventSub?.cancel();
    TTSService().removeListener(_onTtsProgressUpdateProxy);
    super.dispose();
  }

  // TTS progress update 的代理（用於 removeListener）
  void _onTtsProgressUpdateProxy() {
    // 這個方法由 initTtsListener 中的 TTSService().addListener 使用
    // 但 mhere 已在 ReaderTtsMixin 中處理
  }

  void toggleControls() {
    showControls = !showControls;
    // 菜單彈出時暫停自動翻頁，收起時恢復
    if (showControls) {
      pauseAutoPage();
    } else {
      resumeAutoPage();
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.detached) {
      if (!isDisposed) {
        if (isTtsActive) {
          saveTtsProgress();
        } else {
          saveProgress(currentChapterIndex, currentPageIndex);
        }
      }
    }
  }

  /// 取得下一頁資料，用於分頁模式掃描線效果
  TextPage? get nextPageForAutoPage {
    if (!isAutoPaging || pageTurnMode == PageAnim.scroll) return null;
    final nextIdx = currentPageIndex + 1;
    if (nextIdx < pages.length) return pages[nextIdx];
    return null;
  }

  ReadingTheme get currentTheme => AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];

  String get currentChapterTitle => chapters.isNotEmpty ? chapters[currentChapterIndex].title : '';
  String get currentChapterUrl => chapters.isNotEmpty ? chapters[currentChapterIndex].url : '';

  TTSService get tts => TTSService();

  double backgroundBlur = 0.0;
  void setBackgroundBlur(double v) {
    backgroundBlur = v;
    notifyListeners();
  }

  void setBackgroundImage(String? path) {
    currentTheme.backgroundImage = path;
    notifyListeners();
  }

  BookChapter? get currentChapter => chapters.isNotEmpty && currentChapterIndex < chapters.length ? chapters[currentChapterIndex] : null;
  bool get isBookmarked => false;
  int get ttsMode => 0;
  double get rate => TTSService().rate;

  Stream<int> get jumpPageStream => jumpPageController.stream;

  // --- 進度條拖動邏輯 ---
  bool isScrubbing = false;
  int scrubIndex = 0;

  void onScrubStart() {
    isScrubbing = true;
    scrubIndex = currentChapterIndex;
    notifyListeners();
  }

  void onScrubbing(dynamic value) {
    int targetIndex;
    if (value is double) {
      targetIndex = (value * (chapters.length - 1)).round();
    } else {
      targetIndex = value;
    }
    if (scrubIndex != targetIndex) {
      scrubIndex = targetIndex;
      notifyListeners();
    }
  }

  void onScrubEnd(dynamic value) {
    isScrubbing = false;
    int targetIndex;
    if (value is double) {
      targetIndex = (value * (chapters.length - 1)).round();
    } else {
      targetIndex = value;
    }
    loadChapter(targetIndex);
    notifyListeners();
  }

  void jumpToPage(int index) {
    if (index >= 0 && index < pages.length) {
      onPageChanged(index);
    }
  }

  Future<void> toggleBookmark() async {
    addBookmark();
  }

  void addBookmark({String? content}) {
    final bookmark = Bookmark(
      time: DateTime.now().millisecondsSinceEpoch,
      bookName: book.name,
      bookAuthor: book.author,
      bookUrl: book.bookUrl,
      chapterIndex: currentChapterIndex,
      chapterName: chapters[currentChapterIndex].title,
      chapterPos: currentPageIndex,
      bookText: content ?? '',
    );
    bookmarkDao.upsert(bookmark);
    notifyListeners();
  }

  void replaceChapterSource(int index, BookSource source, String content) {
    if (index >= 0 && index < chapters.length) {
      chapters[index].content = content;
      chapterContentCache[index] = content;
      notifyListeners();
    }
  }

  Future<void> jumpToChapter(int index) async {
    if (index >= 0 && index < chapters.length) {
      await loadChapter(index);
    }
  }

  void setChineseConvert(int val) {
    chineseConvert = val;
    saveSetting('chinese_convert_v2', val);
    clearReaderCache();
    loadChapter(currentChapterIndex);
  }

  void setTtsMode(int val) {
    saveSetting('tts_mode', val);
    notifyListeners();
  }

  void setTtsRate(double val) {
    TTSService().setRate(val);
    saveSetting('tts_rate', val);
    notifyListeners();
  }

  void setTtsPitch(double val) {
    TTSService().setPitch(val);
    saveSetting('tts_pitch', val);
    notifyListeners();
  }

  void setTtsLanguage(String lang) {
    TTSService().setLanguage(lang);
    saveSetting('tts_language', lang);
    notifyListeners();
  }

  void setClickAction(int zone, int action) {
    clickActions[zone] = action;
    saveSetting('click_actions', clickActions.join(','));
    notifyListeners();
  }

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {
    await super.doPaginate(fromEnd: fromEnd);
    // 重新分頁後重置 TTS 高亮快取
    resetTtsHighlightCache();
  }
}
