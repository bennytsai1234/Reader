import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';
import 'package:legado_reader/core/services/webdav_service.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/services/tts_service.dart';

export 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
export 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
export 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';

/// ReaderProvider - 閱讀器狀態管理 (效能優化版)
class ReaderProvider extends ReaderProviderBase with ReaderSettingsMixin, ReaderContentMixin {
  ReaderProvider({required Book book, int chapterIndex = 0, int chapterPos = 0}) : super(book) {
    currentChapterIndex = chapterIndex;
    currentPageIndex = chapterPos;
    _init();
  }

  Future<void> _init() async {
    await loadSettings();
    await _loadChapters();
    await _loadSource();
    
    // 背景同步 WebDAV (不阻塞主 UI)
    unawaited(WebDavService().isConfigured().then((configured) {
      if (configured) WebDavService().syncAllBookProgress();
    }));

    await loadChapter(currentChapterIndex);
    _listenAudioEvents();
    _startHeartbeat();
  }

  // --- 效能優化：精準更新屬性 ---
  bool isAutoPaging = false;
  double autoPageSpeed = 1.0;
  double textPadding = 16.0;
  
  int get batteryLevel => batteryLevelNotifier.value;
  double get autoPageProgress => autoPageProgressNotifier.value;

  Timer? _heartbeatTimer;
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // 這裡可以透過插件獲取真實電量，目前先模擬
      batteryLevelNotifier.value = (batteryLevelNotifier.value - 1).clamp(0, 100);
    });
  }

  StreamSubscription? _audioEventSub;
  void _listenAudioEvents() {
    _audioEventSub?.cancel();
    _audioEventSub = TTSService().audioEvents.listen((event) {
      switch (event) {
        case 'onPlay': if (!TTSService().isPlaying) toggleTts(); break;
        case 'onPause': if (TTSService().isPlaying) toggleTts(); break;
        case 'onSkipToNext': nextChapter().then((_) => _startTts()); break;
        case 'onSkipToPrevious': prevChapter().then((_) => _startTts()); break;
        case 'onComplete': 
          if (currentPageIndex < pages.length - 1) {
            onPageChanged(currentPageIndex + 1);
            _startTts();
          } else {
            nextChapter().then((_) => _startTts());
          }
          break;
      }
    });
  }

  Future<void> _loadChapters() async {
    chapters = await chapterDao.getChapters(book.bookUrl);
    notifyListeners();
  }

  Future<void> _loadSource() async {
    source = await sourceDao.getByUrl(book.origin);
  }

  void setViewSize(Size size) {
    if (viewSize != size) {
      viewSize = size;
      if (content.isNotEmpty) {
        doPaginate();
      }
    }
  }

  void onPageChanged(int i) {


    if (currentPageIndex != i) {
      currentPageIndex = i;
      notifyListeners();
      // 非同步更新進度到資料庫
      final title = chapters.isNotEmpty ? chapters[currentChapterIndex].title : '';
      unawaited(bookDao.updateProgress(book.bookUrl, currentChapterIndex, title, i));
    }
  }

  void toggleControls() {
    showControls = !showControls;
    notifyListeners();
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
  bool get isBookmarked => false; // 這裡可以進一步實作查詢
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
    // Simple toggle: check if bookmark exists at current chapter and pos
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
    doPaginate();
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

  Future<void> syncWebDAV() async {
    final configured = await WebDavService().isConfigured();
    if (configured) {
      await WebDavService().syncAllBookProgress();
    }
  }

  // --- TTS 功能 ---
  void toggleTts() {
    if (TTSService().isPlaying) {
      TTSService().stop();
    } else {
      _startTts();
    }
    notifyListeners();
  }

  void _startTts() async {
    if (pages.isEmpty) return;
    final currentPage = pages[currentPageIndex];
    final textToSpeak = currentPage.lines.map((l) => l.text).join('\n');
    await TTSService().speak(textToSpeak);
  }

  // --- 自動翻頁優化 ---
  Timer? _autoPageTimer;
  void toggleAutoPage() {
    isAutoPaging = !isAutoPaging;
    if (isAutoPaging) {
      _startAutoPage();
    } else {
      _autoPageTimer?.cancel();
      autoPageProgressNotifier.value = 0.0;
    }
    notifyListeners();
  }

  void _startAutoPage() {
    _autoPageTimer?.cancel();
    _autoPageTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      autoPageProgressNotifier.value += 0.005 * autoPageSpeed;
      if (autoPageProgressNotifier.value >= 1.0) {
        autoPageProgressNotifier.value = 0.0;
        nextPage();
      }
    });
  }

  void setAutoPageSpeed(double speed) {
    autoPageSpeed = speed;
    notifyListeners();
  }

  void stopAutoPage() {
    isAutoPaging = false;
    _autoPageTimer?.cancel();
    notifyListeners();
  }

  void setClickAction(int zone, int action) {
    saveSetting('click_action_$zone', action);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _autoPageTimer?.cancel();
    _audioEventSub?.cancel();
    super.dispose();
  }
}

