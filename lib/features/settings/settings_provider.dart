import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkpage_reader/core/config/app_config.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_source.dart';
import 'provider/settings_base.dart';

export 'provider/settings_base.dart';
export 'provider/settings_sync_backup.dart';

/// SettingsProvider - 設置提供者 (重構後)
/// (原 Android help/config/AppConfig.kt)
class SettingsProvider extends SettingsProviderBase {
  bool appCrash = false;
  bool enableReadRecord = true;
  String localPassword = '';
  int lastBackup = 0;
  int lastVersionCode = 0;
  bool privacyAgreed = false;

  // 封面進階設定
  int coverSearchPriority = 0;
  int coverTimeout = 5000;
  String globalCoverRule = '';

  // --- 主題色彩設定 ---
  bool transparentStatusBar = true;
  bool immNavigationBar = true;
  Color dayPrimaryColor = Colors.brown;
  Color dayAccentColor = Colors.red;
  Color dayBackgroundColor = Colors.grey.shade100;
  Color dayBottomBackgroundColor = Colors.grey.shade200;
  Color nightPrimaryColor = Colors.blueGrey.shade600;
  Color nightAccentColor = Colors.deepOrange.shade800;
  Color nightBackgroundColor = Colors.grey.shade900;
  Color nightBottomBackgroundColor = Colors.grey.shade800;
  String dayBackgroundImage = '';
  String nightBackgroundImage = '';

  // --- 閱讀設定 ---
  bool hideStatusBar = false;
  bool hideNavigationBar = false;
  bool readBodyToLh = true;
  bool paddingDisplayCutouts = false;
  bool useZhLayout = false;
  bool textBottomJustify = true;
  bool mouseWheelPage = true;
  bool keyPageOnLongPress = false;
  bool autoChangeSource = true;
  bool showBrightnessView = true;
  bool noAnimScrollPage = false;
  bool previewImageByClick = false;
  bool optimizeRender = false;
  bool disableReturnKey = false;
  bool expandTextMenu = false;

  // --- 備份設定 ---
  bool onlyLatestBackup = true;
  bool autoCheckNewBackup = true;
  bool autoBackup = false;

  // --- 朗讀設定 ---
  bool ignoreAudioFocusAloud = false;
  bool pauseReadAloudWhilePhoneCalls = false;
  bool readAloudWakeLock = false;
  bool systemMediaControlCompatibilityChange = false;
  bool mediaButtonPerNext = false;
  bool readAloudByPage = false;
  bool streamReadAloudAudio = false;
  double speechRate = 1.0;
  double speechPitch = 1.0;
  double speechVolume = 1.0;
  String ttsSourceKey = ReaderTtsSourcePreference.systemKey;

  // --- 歡迎介面與圖標 ---
  String welcomeImage = '';
  String welcomeImageDark = '';
  bool welcomeShowText = true;
  bool welcomeShowIcon = true;
  String launcherIcon = '';

  // 其他
  bool recordLog = false;

  // --- 缺失屬性補全 ---
  bool autoRefresh = true;
  bool defaultToRead = false;
  int threadCount = 4;
  String userAgent = '';
  bool antiAlias = true;
  bool replaceEnableDefault = true;
  bool enableCronet = false;
  String bookStorageDir = '';
  bool ignoreAudioFocus = false;
  bool autoClearExpired = true;
  bool mediaButtonOnExit = true;
  bool readAloudByMediaButton = false;
  bool showMangaUi = true;

  void setAutoRefresh(bool v) {
    autoRefresh = v;
    save(PreferKey.autoRefresh, v);
    update();
  }

  void setDefaultToRead(bool v) {
    defaultToRead = v;
    save(PreferKey.defaultToRead, v);
    update();
  }

  void setThreadCount(int v) {
    threadCount = v;
    save(PreferKey.threadCount, v);
    update();
  }

  void setUserAgent(String v) {
    userAgent = v;
    save(PreferKey.userAgent, v);
    update();
  }

  void setAntiAlias(bool v) {
    antiAlias = v;
    save(PreferKey.antiAlias, v);
    update();
  }

  void setReplaceEnableDefault(bool v) {
    replaceEnableDefault = v;
    AppConfig.replaceEnableDefault = v;
    save(PreferKey.replaceEnableDefault, v);
    update();
  }

  void setEnableCronet(bool v) {
    enableCronet = v;
    save(PreferKey.cronet, v);
    update();
  }

  void setBookStorageDir(String v) {
    bookStorageDir = v;
    save(PreferKey.bookStorageDir, v);
    update();
  }

  void setIgnoreAudioFocus(bool v) {
    ignoreAudioFocus = v;
    save(PreferKey.ignoreAudioFocus, v);
    update();
  }

  void setAutoClearExpired(bool v) {
    autoClearExpired = v;
    save(PreferKey.autoClearExpired, v);
    update();
  }

  void setMediaButtonOnExit(bool v) {
    mediaButtonOnExit = v;
    save(PreferKey.mediaButtonOnExit, v);
    update();
  }

  void setReadAloudByMediaButton(bool v) {
    readAloudByMediaButton = v;
    save(PreferKey.readAloudByMediaButton, v);
    update();
  }

  void setShowMangaUi(bool v) {
    showMangaUi = v;
    save(PreferKey.showMangaUi, v);
    update();
  }

  // --- 主題與備份 Setter 補全 ---
  void setTransparentStatusBar(bool v) {
    transparentStatusBar = v;
    save(PreferKey.transparentStatusBar, v);
    update();
  }

  void setImmNavigationBar(bool v) {
    immNavigationBar = v;
    save(PreferKey.immNavigationBar, v);
    update();
  }

  void setDayAccentColor(Color c) {
    dayAccentColor = c;
    save(PreferKey.cAccent, c.toARGB32());
    update();
  }

  void setDayBackgroundColor(Color c) {
    dayBackgroundColor = c;
    save(PreferKey.cBackground, c.toARGB32());
    update();
  }

  void setDayBottomBackgroundColor(Color c) {
    dayBottomBackgroundColor = c;
    save(PreferKey.cBBackground, c.toARGB32());
    update();
  }

  void setNightAccentColor(Color c) {
    nightAccentColor = c;
    save(PreferKey.cNAccent, c.toARGB32());
    update();
  }

  void setNightBackgroundColor(Color c) {
    nightBackgroundColor = c;
    save(PreferKey.cNBackground, c.toARGB32());
    update();
  }

  void setNightBottomBackgroundColor(Color c) {
    nightBottomBackgroundColor = c;
    save(PreferKey.cNBBackground, c.toARGB32());
    update();
  }

  void setOnlyLatestBackup(bool v) {
    onlyLatestBackup = v;
    save(PreferKey.onlyLatestBackup, v);
    update();
  }

  void setAutoCheckNewBackup(bool v) {
    autoCheckNewBackup = v;
    save(PreferKey.autoCheckNewBackup, v);
    update();
  }

  void setAutoBackup(bool v) {
    autoBackup = v;
    save(PreferKey.autoBackup, v);
    update();
  }

  void setReadBodyToLh(bool v) {
    readBodyToLh = v;
    save(PreferKey.readBodyToLh, v);
    update();
  }

  void setPaddingDisplayCutouts(bool v) {
    paddingDisplayCutouts = v;
    save(PreferKey.paddingDisplayCutouts, v);
    update();
  }

  void setUseZhLayout(bool v) {
    useZhLayout = v;
    save(PreferKey.useZhLayout, v);
    update();
  }

  void setTextBottomJustify(bool v) {
    textBottomJustify = v;
    save(PreferKey.textBottomJustify, v);
    update();
  }

  void setMouseWheelPage(bool v) {
    mouseWheelPage = v;
    save(PreferKey.mouseWheelPage, v);
    update();
  }

  void setKeyPageOnLongPress(bool v) {
    keyPageOnLongPress = v;
    save(PreferKey.keyPageOnLongPress, v);
    update();
  }

  void setShowBrightnessView(bool v) {
    showBrightnessView = v;
    save(PreferKey.showBrightnessView, v);
    update();
  }

  void setNoAnimScrollPage(bool v) {
    noAnimScrollPage = v;
    save(PreferKey.noAnimScrollPage, v);
    update();
  }

  void setPreviewImageByClick(bool v) {
    previewImageByClick = v;
    save(PreferKey.previewImageByClick, v);
    update();
  }

  void setDisableReturnKey(bool v) {
    disableReturnKey = v;
    save(PreferKey.disableReturnKey, v);
    update();
  }

  void setExpandTextMenu(bool v) {
    expandTextMenu = v;
    save(PreferKey.expandTextMenu, v);
    update();
  }

  void setWelcomeShowIcon(bool v) {
    welcomeShowIcon = v;
    save(PreferKey.welcomeShowIcon, v);
    update();
  }

  void setWelcomeImageDark(String v) {
    welcomeImageDark = v;
    save(PreferKey.welcomeImageDark, v);
    update();
  }

  void setWelcomeShowTextDark(bool v) {
    welcomeShowTextDark = v;
    save(PreferKey.welcomeShowTextDark, v);
    update();
  }

  void setWelcomeShowIconDark(bool v) {
    welcomeShowIconDark = v;
    save(PreferKey.welcomeShowIconDark, v);
    update();
  }

  bool welcomeShowTextDark = true;
  bool welcomeShowIconDark = true;

  void setLastVersionCode(int v) {
    lastVersionCode = v;
    save(PreferKey.lastVersionCode, v);
    update();
  }

  // --- 朗讀 Setter 補全 ---
  void setIgnoreAudioFocusAloud(bool v) {
    ignoreAudioFocusAloud = v;
    save(PreferKey.ignoreAudioFocusAloud, v);
    update();
  }

  void setPauseReadAloudWhilePhoneCalls(bool v) {
    pauseReadAloudWhilePhoneCalls = v;
    save(PreferKey.pauseReadAloudWhilePhoneCalls, v);
    update();
  }

  void setReadAloudWakeLock(bool v) {
    readAloudWakeLock = v;
    save(PreferKey.readAloudWakeLock, v);
    update();
  }

  void setSystemMediaControlCompatibilityChange(bool v) {
    systemMediaControlCompatibilityChange = v;
    save(PreferKey.systemMediaControlCompat, v);
    update();
  }

  void setMediaButtonPerNext(bool v) {
    mediaButtonPerNext = v;
    save(PreferKey.mediaButtonPerNext, v);
    update();
  }

  void setReadAloudByPage(bool v) {
    readAloudByPage = v;
    save(PreferKey.readAloudByPage, v);
    update();
  }

  void setStreamReadAloudAudio(bool v) {
    streamReadAloudAudio = v;
    save(PreferKey.streamReadAloudAudio, v);
    update();
  }

  void setLastBackup(int v) {
    lastBackup = v;
    save(PreferKey.lastBackup, v);
    update();
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // --- 核心設定 ---
    final mode = prefs.getString(PreferKey.themeMode) ?? 'system';
    themeMode = parseThemeMode(mode);

    final lang = prefs.getString(PreferKey.language) ?? 'system';
    locale = parseLocale(lang);

    userAgent = prefs.getString(PreferKey.userAgent) ?? '';
    threadCount = prefs.getInt(PreferKey.threadCount) ?? 4;
    recordLog = prefs.getBool(PreferKey.recordLog) ?? false;
    appCrash = prefs.getBool(PreferKey.appCrash) ?? false;
    lastVersionCode = prefs.getInt(PreferKey.lastVersionCode) ?? 0;
    privacyAgreed = prefs.getBool(PreferKey.privacyAgreed) ?? false;

    // --- 封面進階設定 ---
    coverSearchPriority = prefs.getInt(PreferKey.coverSearchPriority) ?? 0;
    coverTimeout = prefs.getInt(PreferKey.coverTimeout) ?? 5000;
    globalCoverRule = prefs.getString(PreferKey.globalCoverRule) ?? '';

    // --- 歡迎與介面 ---
    welcomeImage = prefs.getString(PreferKey.welcomeImage) ?? '';
    welcomeImageDark = prefs.getString(PreferKey.welcomeImageDark) ?? '';
    welcomeShowText = prefs.getBool(PreferKey.welcomeShowText) ?? true;
    welcomeShowTextDark = prefs.getBool(PreferKey.welcomeShowTextDark) ?? true;
    welcomeShowIcon = prefs.getBool(PreferKey.welcomeShowIcon) ?? true;
    welcomeShowIconDark = prefs.getBool(PreferKey.welcomeShowIconDark) ?? true;
    launcherIcon = prefs.getString(PreferKey.launcherIcon) ?? '';

    lastBackup = prefs.getInt(PreferKey.lastBackup) ?? 0;

    // --- 主題與顯示 ---
    transparentStatusBar =
        prefs.getBool(PreferKey.transparentStatusBar) ?? true;
    immNavigationBar = prefs.getBool(PreferKey.immNavigationBar) ?? true;
    dayBackgroundImage = prefs.getString(PreferKey.bgImage) ?? '';
    nightBackgroundImage = prefs.getString(PreferKey.bgImageN) ?? '';

    dayPrimaryColor = Color(
      prefs.getInt(PreferKey.cPrimary) ?? Colors.brown.toARGB32(),
    );
    dayAccentColor = Color(
      prefs.getInt(PreferKey.cAccent) ?? Colors.red.toARGB32(),
    );
    dayBackgroundColor = Color(
      prefs.getInt(PreferKey.cBackground) ?? Colors.grey.shade100.toARGB32(),
    );
    dayBottomBackgroundColor = Color(
      prefs.getInt(PreferKey.cBBackground) ?? Colors.grey.shade200.toARGB32(),
    );
    nightPrimaryColor = Color(
      prefs.getInt(PreferKey.cNPrimary) ?? Colors.blueGrey.shade600.toARGB32(),
    );
    nightAccentColor = Color(
      prefs.getInt(PreferKey.cNAccent) ?? Colors.deepOrange.shade800.toARGB32(),
    );
    nightBackgroundColor = Color(
      prefs.getInt(PreferKey.cNBackground) ?? Colors.grey.shade900.toARGB32(),
    );
    nightBottomBackgroundColor = Color(
      prefs.getInt(PreferKey.cNBBackground) ?? Colors.grey.shade800.toARGB32(),
    );

    // --- 閱讀設定 ---
    hideStatusBar = prefs.getBool(PreferKey.hideStatusBar) ?? false;
    hideNavigationBar = prefs.getBool(PreferKey.hideNavigationBar) ?? false;
    readBodyToLh = prefs.getBool(PreferKey.readBodyToLh) ?? true;
    paddingDisplayCutouts =
        prefs.getBool(PreferKey.paddingDisplayCutouts) ?? false;
    useZhLayout = prefs.getBool(PreferKey.useZhLayout) ?? false;
    textBottomJustify = prefs.getBool(PreferKey.textBottomJustify) ?? true;
    mouseWheelPage = prefs.getBool(PreferKey.mouseWheelPage) ?? true;
    keyPageOnLongPress = prefs.getBool(PreferKey.keyPageOnLongPress) ?? false;
    autoChangeSource = prefs.getBool(PreferKey.autoChangeSource) ?? true;
    showBrightnessView = prefs.getBool(PreferKey.showBrightnessView) ?? true;
    noAnimScrollPage = prefs.getBool(PreferKey.noAnimScrollPage) ?? false;
    previewImageByClick = prefs.getBool(PreferKey.previewImageByClick) ?? false;
    optimizeRender = prefs.getBool(PreferKey.optimizeRender) ?? false;
    expandTextMenu = prefs.getBool(PreferKey.expandTextMenu) ?? false;
    autoRefresh = prefs.getBool(PreferKey.autoRefresh) ?? true;
    defaultToRead = prefs.getBool(PreferKey.defaultToRead) ?? false;
    replaceEnableDefault =
        prefs.getBool(PreferKey.replaceEnableDefault) ?? true;
    AppConfig.replaceEnableDefault = replaceEnableDefault; // 同步至 AppConfig
    autoClearExpired = prefs.getBool(PreferKey.autoClearExpired) ?? true;
    showMangaUi = prefs.getBool(PreferKey.showMangaUi) ?? true;
    antiAlias = prefs.getBool(PreferKey.antiAlias) ?? true;

    // --- 備份與同步 ---
    onlyLatestBackup = prefs.getBool(PreferKey.onlyLatestBackup) ?? true;
    autoCheckNewBackup = prefs.getBool(PreferKey.autoCheckNewBackup) ?? true;
    autoBackup = prefs.getBool(PreferKey.autoBackup) ?? false;

    // --- 朗讀設定 ---
    ignoreAudioFocus = prefs.getBool(PreferKey.ignoreAudioFocus) ?? false;
    ignoreAudioFocusAloud =
        prefs.getBool(PreferKey.ignoreAudioFocusAloud) ?? false;
    pauseReadAloudWhilePhoneCalls =
        prefs.getBool(PreferKey.pauseReadAloudWhilePhoneCalls) ?? false;
    readAloudWakeLock = prefs.getBool(PreferKey.readAloudWakeLock) ?? false;
    readAloudByPage = prefs.getBool(PreferKey.readAloudByPage) ?? false;
    streamReadAloudAudio =
        prefs.getBool(PreferKey.streamReadAloudAudio) ?? false;
    readAloudByMediaButton =
        prefs.getBool(PreferKey.readAloudByMediaButton) ?? false;
    speechRate = prefs.getDouble(PreferKey.ttsSpeechRate) ?? 1.0;
    speechPitch = prefs.getDouble(PreferKey.speechPitch) ?? 1.0;
    speechVolume = prefs.getDouble(PreferKey.speechVolume) ?? 1.0;
    final savedTtsSource = prefs.getString(PreferKey.ttsSource);
    ttsSourceKey = ReaderTtsSourcePreference.systemKey;
    if (savedTtsSource != null &&
        savedTtsSource != ReaderTtsSourcePreference.systemKey) {
      await prefs.setString(
        PreferKey.ttsSource,
        ReaderTtsSourcePreference.systemKey,
      );
    }
    TTSService().setRate(speechRate);
    TTSService().setPitch(speechPitch);
    TTSService().setVolume(speechVolume);

    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    locale = parseLocale(lang);
    await save(PreferKey.language, lang);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await save(PreferKey.themeMode, mode.toString().split('.').last);
    notifyListeners();
  }

  // --- 封面進階 ---
  void setCoverSearchPriority(int v) {
    coverSearchPriority = v;
    save(PreferKey.coverSearchPriority, v);
    update();
  }

  void setCoverTimeout(int v) {
    coverTimeout = v;
    save(PreferKey.coverTimeout, v);
    update();
  }

  void setGlobalCoverRule(String v) {
    globalCoverRule = v;
    save(PreferKey.globalCoverRule, v);
    update();
  }

  void setPrivacyAgreed(bool v) {
    privacyAgreed = v;
    save(PreferKey.privacyAgreed, v);
    update();
  }

  void setRecordLog(bool v) {
    recordLog = v;
    save(PreferKey.recordLog, v);
    update();
  }

  // --- 主題色彩 ---
  void setDayPrimaryColor(Color c) {
    dayPrimaryColor = c;
    save(PreferKey.cPrimary, c.toARGB32());
    update();
  }

  void setNightPrimaryColor(Color c) {
    nightPrimaryColor = c;
    save(PreferKey.cNPrimary, c.toARGB32());
    update();
  }

  Future<void> setDayBackgroundImage(String v) async {
    dayBackgroundImage = v;
    await save(PreferKey.bgImage, v);
    update();
  }

  Future<void> setNightBackgroundImage(String v) async {
    nightBackgroundImage = v;
    await save(PreferKey.bgImageN, v);
    update();
  }

  // --- 歡迎介面 ---
  Future<void> setWelcomeImage(String v) async {
    welcomeImage = v;
    await save(PreferKey.welcomeImage, v);
    update();
  }

  Future<void> setWelcomeShowText(bool v) async {
    welcomeShowText = v;
    await save(PreferKey.welcomeShowText, v);
    update();
  }

  // --- 啟動圖標 ---
  Future<void> setLauncherIcon(String v) async {
    launcherIcon = v;
    await save(PreferKey.launcherIcon, v);
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.legado.reader/launcher_icon');
        await platform.invokeMethod('changeIcon', {'iconName': v});
      } catch (e) {
        AppLog.e('變更啟動圖標失敗: $e', error: e);
      }
    }
    update();
  }

  // --- 朗讀速率 ---
  void setSpeechRate(double v) {
    speechRate = v;
    TTSService().setRate(v);
    save(PreferKey.ttsSpeechRate, v);
    update();
  }

  void setSpeechPitch(double v) {
    speechPitch = v;
    TTSService().setPitch(v);
    save(PreferKey.speechPitch, v);
    update();
  }

  void setSpeechVolume(double v) {
    speechVolume = v;
    TTSService().setVolume(v);
    save(PreferKey.speechVolume, v);
    update();
  }

  void setTtsSourceKey(String _) {
    ttsSourceKey = ReaderTtsSourcePreference.systemKey;
    save(PreferKey.ttsSource, ttsSourceKey);
    update();
  }

  // --- 閱讀顯示 ---
  void setHideStatusBar(bool v) {
    hideStatusBar = v;
    save(PreferKey.hideStatusBar, v);
    update();
  }

  void setHideNavigationBar(bool v) {
    hideNavigationBar = v;
    save(PreferKey.hideNavigationBar, v);
    update();
  }

  void setAutoChangeSource(bool v) {
    autoChangeSource = v;
    save(PreferKey.autoChangeSource, v);
    update();
  }

  void setOptimizeRender(bool v) {
    optimizeRender = v;
    save(PreferKey.optimizeRender, v);
    update();
  }
}
