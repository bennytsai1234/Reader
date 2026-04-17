import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_auto_page_coordinator.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'reader_content_mixin.dart';

/// ReaderProvider 的自動翻頁擴展
/// 對標 Android AutoPager：定時器驅動的自動翻頁 + 掃描線效果
mixin ReaderAutoPageMixin
    on ReaderProviderBase, ReaderSettingsMixin, ReaderContentMixin {
  // --- 自動翻頁穩定版 (對標 Android AutoPager) ---
  final ReaderAutoPageCoordinator _autoPageCoordinator =
      ReaderAutoPageCoordinator();

  bool get isAutoPaging => _autoPageCoordinator.isActive;
  double get autoPageSpeed => _autoPageCoordinator.speed; // 單位：秒/頁
  bool get isAutoPagePaused => _autoPageCoordinator.isPaused;

  double scrollDeltaPerFrame(Size viewSize, double dtSeconds) {
    return (viewSize.height / autoPageSpeed.clamp(1.0, 600.0)) * dtSeconds;
  }

  void attachAutoPageTicker(Ticker Function(TickerCallback) createTicker) {
    _autoPageCoordinator.attachTicker(
      createTicker,
      shouldTick: () => !TTSService().isPlaying,
      onTick: _onAutoPageTick,
    );
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
      final delta = dtSeconds / autoPageSpeed.clamp(1.0, 600.0);
      autoPageProgressNotifier.value += delta;
      if (autoPageProgressNotifier.value >= 1.0) {
        autoPageProgressNotifier.value = 0.0;
        nextPage(reason: ReaderCommandReason.autoPage);
      }
      return;
    }

    final viewSize = this.viewSize;
    if (viewSize == null) return;

    final step = contentCallbacksRef.evaluateScrollAutoPageStep?.call(
      dtSeconds,
    );
    if (step != null) {
      if (!step.advanceChapter &&
          step.chapterIndex != null &&
          step.localOffset != null) {
        contentCallbacksRef.jumpToChapterLocalOffset?.call(
          chapterIndex: step.chapterIndex!,
          localOffset: step.localOffset!,
          alignment: 0.0,
          reason: ReaderCommandReason.autoPage,
        );
      } else if (step.advanceChapter) {
        nextChapter(reason: ReaderCommandReason.autoPage);
      }
    }

    final deltaPixels = scrollDeltaPerFrame(viewSize, dtSeconds);
    final pageBasis = viewSize.height <= 0 ? 1.0 : viewSize.height;
    autoPageProgressNotifier.value =
        ((autoPageProgressNotifier.value * pageBasis) + deltaPixels) %
        pageBasis /
        pageBasis;
  }

  void setAutoPageSpeed(double speed) {
    _autoPageCoordinator.speed = speed;
    notifyListeners();
  }

  void stopAutoPage() {
    _autoPageCoordinator.stop();
    autoPageProgressNotifier.value = 0.0;
    notifyListeners();
  }

  void disposeAutoPageCoordinator() {
    _autoPageCoordinator.dispose();
    autoPageProgressNotifier.value = 0.0;
  }
}
