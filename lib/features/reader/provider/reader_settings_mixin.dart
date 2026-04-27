import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/config/app_config.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reader_prefs_repository.dart';
import 'reader_provider_base.dart';

/// ReaderProvider 的設置管理擴展
mixin ReaderSettingsMixin on ReaderProviderBase {
  final ReaderPrefsRepository readerPrefsRepository =
      const ReaderPrefsRepository();
  double fontSize = 18.0;
  double lineHeight = 1.5;
  double paragraphSpacing = 1.0;
  double letterSpacing = 0.0;
  int textIndent = 2;
  bool textFullJustify = true;
  int themeIndex = 0;
  int lastDayThemeIndex = 0;
  int lastNightThemeIndex = 0;
  double brightness = 1.0;
  int chineseConvert = 0;
  int pageTurnMode = 1; // 預設平移（PageAnim.slide=1）
  bool showAddToShelfAlert = true;
  bool showReadTitleAddition = true;
  bool readBarStyleFollowPage = false;
  bool selectText = true;

  /// 設定變更時的回調，由 ReaderProvider 注入
  /// 觸發分頁快取清除 + 重新分頁
  VoidCallback? onSettingsChangedRepaginate;
  VoidCallback? onBeforeRepaginate;

  Future<void> loadSettings() async {
    final snapshot = await readerPrefsRepository.load();
    final p = await SharedPreferences.getInstance();
    fontSize = snapshot.fontSize;
    lineHeight = snapshot.lineHeight;
    paragraphSpacing = snapshot.paragraphSpacing;
    letterSpacing = snapshot.letterSpacing;
    textIndent = snapshot.textIndent;
    textFullJustify = snapshot.textFullJustify;
    themeIndex = snapshot.themeIndex;
    brightness = snapshot.brightness;
    pageTurnMode = snapshot.pageTurnMode;
    AppConfig.readerPageAnim = pageTurnMode;
    chineseConvert = snapshot.chineseConvert;
    showAddToShelfAlert = snapshot.showAddToShelfAlert;
    showReadTitleAddition = snapshot.showReadTitleAddition;
    readBarStyleFollowPage = snapshot.readBarStyleFollowPage;
    selectText = snapshot.selectText;
    clickActions = List<int>.from(snapshot.clickActions);
    lastDayThemeIndex = snapshot.lastDayThemeIndex;
    lastNightThemeIndex = snapshot.lastNightThemeIndex;
    _normalizeDayNightThemeIndexes();

    final ttsRate = p.getDouble(PreferKey.readerTtsRate) ?? 1.0;
    final ttsPitch = p.getDouble(PreferKey.readerTtsPitch) ?? 1.0;
    final ttsLang = p.getString(PreferKey.readerTtsLanguage);

    TTSService().setRate(ttsRate);
    TTSService().setPitch(ttsPitch);
    if (ttsLang != null) TTSService().setLanguage(ttsLang);
    notifyListeners();
  }

  Future<void> saveSetting(String k, dynamic v) async {
    final p = await SharedPreferences.getInstance();
    final key = switch (k) {
      'tts_mode' => 'reader_tts_mode',
      'tts_rate' => PreferKey.readerTtsRate,
      'tts_pitch' => PreferKey.readerTtsPitch,
      'tts_language' => PreferKey.readerTtsLanguage,
      _ => null,
    };
    if (key == null) return;
    if (v is double) {
      await p.setDouble(key, v);
    } else if (v is int) {
      await p.setInt(key, v);
    } else if (v is bool) {
      await p.setBool(key, v);
    } else if (v is String) {
      await p.setString(key, v);
    }
  }

  void setFontSize(double s) {
    fontSize = s;
    unawaited(readerPrefsRepository.saveFontSize(s));
    _triggerRepaginate();
  }

  void setLineHeight(double v) {
    lineHeight = v;
    unawaited(readerPrefsRepository.saveLineHeight(v));
    _triggerRepaginate();
  }

  void setParagraphSpacing(double v) {
    paragraphSpacing = v;
    unawaited(readerPrefsRepository.saveParagraphSpacing(v));
    _triggerRepaginate();
  }

  void setLetterSpacing(double v) {
    letterSpacing = v;
    unawaited(readerPrefsRepository.saveLetterSpacing(v));
    _triggerRepaginate();
  }

  void setTextFullJustify(bool v) {
    textFullJustify = v;
    unawaited(readerPrefsRepository.saveTextFullJustify(v));
    _triggerRepaginate();
  }

  void setTextIndent(int v) {
    textIndent = v;
    unawaited(readerPrefsRepository.saveTextIndent(v));
    _triggerRepaginate();
  }

  void setPageTurnMode(int v) {
    pageTurnMode = v;
    AppConfig.readerPageAnim = v;
    unawaited(readerPrefsRepository.savePageTurnMode(v));
    notifyListeners();
  }

  void setTheme(int i) {
    themeIndex = i;
    unawaited(readerPrefsRepository.saveThemeIndex(i));
    _rememberDayNightThemeIndex(i);
    notifyListeners();
  }

  bool get isCurrentThemeDark => _isThemeDark(themeIndex);

  int get dayNightToggleTargetThemeIndex =>
      isCurrentThemeDark ? lastDayThemeIndex : lastNightThemeIndex;

  bool get willToggleToDarkTheme =>
      _isThemeDark(dayNightToggleTargetThemeIndex);

  String get dayNightToggleLabel => willToggleToDarkTheme ? '夜間' : '日間';

  String get dayNightToggleTooltip =>
      willToggleToDarkTheme ? '切換到夜間主題' : '切換到白天主題';

  IconData get dayNightToggleIcon =>
      willToggleToDarkTheme
          ? Icons.dark_mode_rounded
          : Icons.light_mode_rounded;

  void toggleDayNightTheme() {
    final target = dayNightToggleTargetThemeIndex;
    if (target == themeIndex) {
      final fallback =
          isCurrentThemeDark
              ? _fallbackDayThemeIndex()
              : _fallbackNightThemeIndex();
      if (fallback != themeIndex) {
        setTheme(fallback);
      }
      return;
    }
    setTheme(target);
  }

  void setBrightness(double v) {
    brightness = v;
    unawaited(readerPrefsRepository.saveBrightness(v));
    notifyListeners();
  }

  void setShowReadTitleAddition(bool value) {
    showReadTitleAddition = value;
    unawaited(readerPrefsRepository.saveShowReadTitleAddition(value));
    notifyListeners();
  }

  void setReadBarStyleFollowPage(bool value) {
    readBarStyleFollowPage = value;
    unawaited(readerPrefsRepository.saveReadBarStyleFollowPage(value));
    notifyListeners();
  }

  void setSelectText(bool value) {
    selectText = value;
    unawaited(readerPrefsRepository.saveSelectText(value));
    notifyListeners();
  }

  void _triggerRepaginate() {
    onBeforeRepaginate?.call();
    final callback = onSettingsChangedRepaginate;
    if (callback != null) {
      callback();
    } else {
      notifyListeners();
    }
  }

  void _rememberDayNightThemeIndex(int index) {
    if (_isThemeDark(index)) {
      lastNightThemeIndex = index;
      unawaited(readerPrefsRepository.saveNightThemeIndex(index));
    } else {
      lastDayThemeIndex = index;
      unawaited(readerPrefsRepository.saveDayThemeIndex(index));
    }
  }

  bool _isThemeDark(int index) {
    if (AppTheme.readingThemes.isEmpty) return index != 0;
    final safeIndex = index.clamp(0, AppTheme.readingThemes.length - 1).toInt();
    return AppTheme.readingThemes[safeIndex].backgroundColor
            .computeLuminance() <
        0.5;
  }

  int _fallbackDayThemeIndex() {
    if (AppTheme.readingThemes.isEmpty) return 0;
    for (var i = 0; i < AppTheme.readingThemes.length; i++) {
      if (!_isThemeDark(i)) return i;
    }
    return 0;
  }

  int _fallbackNightThemeIndex() {
    if (AppTheme.readingThemes.isEmpty) return 1;
    for (var i = AppTheme.readingThemes.length - 1; i >= 0; i--) {
      if (_isThemeDark(i)) return i;
    }
    return (AppTheme.readingThemes.length - 1).clamp(0, 1 << 20).toInt();
  }

  void _normalizeDayNightThemeIndexes() {
    if (AppTheme.readingThemes.isEmpty) {
      lastDayThemeIndex = 0;
      lastNightThemeIndex = 1;
      return;
    }
    lastDayThemeIndex =
        lastDayThemeIndex.clamp(0, AppTheme.readingThemes.length - 1).toInt();
    lastNightThemeIndex =
        lastNightThemeIndex.clamp(0, AppTheme.readingThemes.length - 1).toInt();
    _rememberDayNightThemeIndex(themeIndex);
    if (_isThemeDark(lastDayThemeIndex)) {
      lastDayThemeIndex = _fallbackDayThemeIndex();
    }
    if (!_isThemeDark(lastNightThemeIndex)) {
      lastNightThemeIndex = _fallbackNightThemeIndex();
    }
  }
}
