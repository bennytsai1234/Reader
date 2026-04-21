import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_auto_page_coordinator.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'reader_content_facade_mixin.dart';

/// ReaderProvider 的自動翻頁擴展
/// 對標 Android AutoPager：定時器驅動的自動翻頁 + 掃描線效果
mixin ReaderAutoPageMixin
    on ReaderProviderBase, ReaderSettingsMixin, ReaderContentFacadeMixin {
  // --- 自動翻頁穩定版 (對標 Android AutoPager) ---
  final ReaderAutoPageCoordinator _autoPageCoordinator =
      ReaderAutoPageCoordinator();
  bool Function(double deltaPixels)? _scrollAutoPageDriver;

  bool get isAutoPaging => _autoPageCoordinator.isActive;
  double get autoPageSpeed => _autoPageCoordinator.speed; // 單位：秒/頁
  bool get isAutoPagePaused => _autoPageCoordinator.isPaused;

  Future<void> loadAutoPageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final speed = (prefs.getInt(PreferKey.autoReadSpeed) ?? 10).clamp(1, 120);
    _autoPageCoordinator.speed = speed.toDouble();
  }

  double scrollDeltaPerFrame(Size viewSize, double dtSeconds) {
    return (viewSize.height / autoPageSpeed.clamp(1.0, 120.0)) * dtSeconds;
  }

  void attachAutoPageTicker(Ticker Function(TickerCallback) createTicker) {
    _autoPageCoordinator.attachTicker(
      createTicker,
      shouldTick: () => !TTSService().isPlaying,
      onTick: _onAutoPageTick,
    );
  }

  void attachScrollAutoPageDriver(bool Function(double deltaPixels) driver) {
    _scrollAutoPageDriver = driver;
  }

  void detachScrollAutoPageDriver() {
    _scrollAutoPageDriver = null;
  }

  void detachAutoPageTicker() {
    _autoPageCoordinator.detachTicker();
  }

  void toggleAutoPage() {
    _autoPageCoordinator.isActive = !_autoPageCoordinator.isActive;
    if (isAutoPaging) {
      // 自動翻頁與 TTS 互斥
      if (TTSService().isPlaying) TTSService().stop();
      _autoPageCoordinator.isPaused = false;
      restartAutoPageCycle();
    } else {
      stopAutoPage();
    }
    _autoPageCoordinator.syncTickerState();
    notifyListeners();
  }

  /// 手動操作時暫停 (對標 Android onMenuShow/onTouch)
  void pauseAutoPage() {
    if (isAutoPaging && !isAutoPagePaused) {
      _autoPageCoordinator.isPaused = true;
      _autoPageCoordinator.syncTickerState();
      notifyListeners();
    }
  }

  /// 手動操作結束後恢復
  void resumeAutoPage() {
    if (isAutoPaging && isAutoPagePaused) {
      _autoPageCoordinator.isPaused = false;
      _autoPageCoordinator.syncTickerState();
      notifyListeners();
    }
  }

  void _onAutoPageTick(double dtSeconds) {
    if (pageTurnMode != PageAnim.scroll) {
      _tickSlideAutoPage(dtSeconds);
      return;
    }
    _tickScrollAutoPage(dtSeconds);
  }

  void _tickSlideAutoPage(double dtSeconds) {
    final delta = dtSeconds / autoPageSpeed.clamp(1.0, 120.0);
    autoPageProgressNotifier.value += delta;
    if (autoPageProgressNotifier.value < 1.0) {
      return;
    }
    autoPageProgressNotifier.value = 0.0;
    final atBookEnd =
        currentChapterIndex >= chapters.length - 1 &&
        currentPageIndex >= slidePages.length - 1;
    if (atBookEnd) {
      stopAutoPage();
      return;
    }
    nextPage(reason: ReaderCommandReason.autoPage);
  }

  void _tickScrollAutoPage(double dtSeconds) {
    final viewSize = this.viewSize;
    if (viewSize == null) return;
    final deltaPixels = scrollDeltaPerFrame(viewSize, dtSeconds);
    final moved = _scrollAutoPageDriver?.call(deltaPixels) ?? false;
    final pageBasis = viewSize.height <= 0 ? 1.0 : viewSize.height;
    if (!moved) {
      autoPageProgressNotifier.value = 1.0;
      stopAutoPage();
      return;
    }
    autoPageProgressNotifier.value =
        ((autoPageProgressNotifier.value * pageBasis) + deltaPixels) %
        pageBasis /
        pageBasis;
  }

  void setAutoPageSpeed(double speed) {
    final normalized = speed.clamp(1.0, 120.0).roundToDouble();
    _autoPageCoordinator.speed = normalized;
    restartAutoPageCycle();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt(PreferKey.autoReadSpeed, normalized.round()),
    );
    notifyListeners();
  }

  void restartAutoPageCycle() {
    _autoPageCoordinator.restartCycle();
    autoPageProgressNotifier.value = 0.0;
  }

  void stopAutoPage() {
    _autoPageCoordinator.stop();
    autoPageProgressNotifier.value = 0.0;
    notifyListeners();
  }

  void disposeAutoPageCoordinator() {
    _autoPageCoordinator.dispose();
    _scrollAutoPageDriver = null;
    autoPageProgressNotifier.value = 0.0;
  }
}
