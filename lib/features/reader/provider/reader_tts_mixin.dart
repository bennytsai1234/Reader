import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/runtime/read_aloud_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_follow_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'reader_content_mixin.dart';
import 'reader_auto_page_mixin.dart';

mixin ReaderTtsMixin
    on
        ReaderProviderBase,
        ReaderSettingsMixin,
        ReaderContentMixin,
        ReaderAutoPageMixin {
  late final ReadAloudController readAloudController;
  final ReaderTtsFollowCoordinator _ttsFollow =
      const ReaderTtsFollowCoordinator();
  int _ttsMode = 0;
  int get ttsMode => _ttsMode;

  void initTts(ReadAloudController controller) {
    readAloudController = controller;
  }

  Future<void> loadTtsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ttsMode = prefs.getInt('reader_tts_mode') ?? 0;
    notifyListeners();
  }

  int get ttsStart => readAloudController.ttsStart;
  int get ttsEnd => readAloudController.ttsEnd;
  int get ttsWordStart => readAloudController.ttsWordStart;
  int get ttsWordEnd => readAloudController.ttsWordEnd;
  int get ttsChapterIndex => readAloudController.ttsChapterIndex;
  bool get isTtsActive => readAloudController.isActive;
  bool get isTtsPlaying => readAloudController.isPlaying;
  bool get stopAfterChapter => readAloudController.stopAfterChapter;
  TTSService get tts => TTSService();

  void toggleTts() {
    if (isAutoPaging) stopAutoPage();
    readAloudController.toggle();
  }

  void startTtsFromLine(int lineIndex) {
    if (isAutoPaging) stopAutoPage();
    readAloudController.startFromLine(lineIndex);
  }

  void stopTts() {
    readAloudController.stop();
    contentCallbacksRef.clearNavigationReason?.call(ReaderCommandReason.tts);
  }

  Future<void> nextPageOrChapter() {
    return readAloudController.nextPageOrChapter();
  }

  Future<void> prevPageOrChapter() {
    return readAloudController.prevPageOrChapter();
  }

  Future<void> handleTtsNextPage() async {
    if (contentCallbacksRef.canMoveToNextSlidePage?.call() ?? true) {
      nextPage(reason: ReaderCommandReason.tts);
    }
  }

  Future<void> handleTtsPrevPage() async {
    if (contentCallbacksRef.canMoveToPrevSlidePage?.call() ?? true) {
      prevPage(reason: ReaderCommandReason.tts);
    }
  }

  void handleTtsPageJump(int pageIndex) {
    final chapterIndex =
        ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex;
    final globalIndex = contentCallbacksRef.globalPageIndexFor?.call(
      chapterIndex: chapterIndex,
      localPageIndex: pageIndex,
    );
    if (globalIndex != null && globalIndex >= 0) {
      contentCallbacksRef.jumpToSlidePage?.call(
        globalIndex,
        reason: ReaderCommandReason.tts,
      );
    }
  }

  void handleTtsChapterJump({
    required int chapterIndex,
    required double alignment,
    required double localOffset,
  }) {
    contentCallbacksRef.jumpToChapterLocalOffset?.call(
      chapterIndex: chapterIndex,
      alignment: alignment,
      localOffset: localOffset,
      reason: ReaderCommandReason.tts,
    );
  }

  void updateTtsMediaInfo(String title, String author) {
    TTSService().updateMediaInfo(
      title: title.isEmpty ? book.name : title,
      author: author.isEmpty ? book.author : author,
    );
  }

  void notifyIfActive() {
    if (!isDisposed) notifyListeners();
  }

  void setTtsMode(int val) {
    _ttsMode = val;
    saveSetting('tts_mode', val);
    notifyListeners();
  }

  void setStopAfterChapter(bool val) {
    readAloudController.setStopAfterChapter(val);
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

  ReaderTtsFollowTarget? evaluateTtsFollowTarget({
    required double viewportHeight,
  }) {
    final chapterIndex =
        ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex;
    final runtimeChapter =
        contentCallbacksRef.chapterAt?.call(chapterIndex) as ReaderChapter?;
    final pages =
        contentCallbacksRef.pagesForChapter?.call(chapterIndex) ??
        chapterPagesCache[chapterIndex] ??
        [];

    if (((runtimeChapter == null && pages.isEmpty) ||
            (runtimeChapter != null && runtimeChapter.isEmpty)) ||
        ttsStart < 0) {
      return null;
    }

    final rawLocalOffset =
        runtimeChapter != null
            ? runtimeChapter.resolveScrollAnchor(ttsStart).localOffset
            : ChapterPositionResolver.charOffsetToLocalOffset(
              pages.cast(),
              ttsStart,
            );

    final chapterHeight =
        runtimeChapter?.chapterHeight ??
        ChapterPositionResolver.chapterHeight(pages.cast());
    final targetLocalOffset =
        chapterHeight > 0
            ? rawLocalOffset.clamp(0.0, chapterHeight)
            : rawLocalOffset;

    return _ttsFollow.evaluate(
      chapterIndex: chapterIndex,
      visibleChapterIndex: visibleChapterIndex,
      targetLocalOffset: targetLocalOffset,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
      viewportHeight: viewportHeight,
    );
  }

  void saveTtsProgress() {
    readAloudController.saveProgress(
      persist: (chapterIndex, charOffset) {
        contentCallbacksRef.updateSessionLocation?.call(
          ReaderLocation(chapterIndex: chapterIndex, charOffset: charOffset),
        );
        contentCallbacksRef.persistCurrentProgress?.call(
          chapterIndex: chapterIndex,
          reason: ReaderCommandReason.tts,
        );
      },
    );
  }
}
