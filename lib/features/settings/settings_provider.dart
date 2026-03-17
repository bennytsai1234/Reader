import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/config/app_config.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';
import 'provider/settings_base.dart';

export 'provider/settings_base.dart';
export 'provider/settings_ui_theme.dart';
export 'provider/settings_reading.dart';
export 'provider/settings_sync_backup.dart';
export 'provider/settings_advanced.dart';

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
  bool textFullJustify = true;
  bool textBottomJustify = true;
  bool mouseWheelPage = true;
  bool volumeKeyPage = true;
  bool volumeKeyPageOnPlay = false;
  bool keyPageOnLongPress = false;
  bool autoChangeSource = true;
  bool selectText = true;
  bool showBrightnessView = true;
  bool noAnimScrollPage = false;
  bool previewImageByClick = false;
  bool optimizeRender = false;
  bool disableReturnKey = false;
  bool expandTextMenu = false;
  bool showReadTitleAddition = true;
  bool readBarStyleFollowPage = false;

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
  double speechRate = 0.5;
  double speechPitch = 1.0;
  double speechVolume = 1.0;

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
  bool showDiscovery = true;
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
  bool showAddToShelfAlert = true;
  bool showMangaUi = true;

  void setAutoRefresh(bool v) { autoRefresh = v; save(PreferKey.autoRefresh, v); update(); }
  void setDefaultToRead(bool v) { defaultToRead = v; save(PreferKey.defaultToRead, v); update(); }
  void setShowDiscovery(bool v) { showDiscovery = v; save(PreferKey.showDiscovery, v); update(); }
  void setThreadCount(int v) { threadCount = v; save(PreferKey.threadCount, v); update(); }
  void setUserAgent(String v) { userAgent = v; save(PreferKey.userAgent, v); update(); }
  void setAntiAlias(bool v) { antiAlias = v; save(PreferKey.antiAlias, v); update(); }
  void setReplaceEnableDefault(bool v) { replaceEnableDefault = v; AppConfig.replaceEnableDefault = v; save(PreferKey.replaceEnableDefault, v); update(); }
  void setEnableCronet(bool v) { enableCronet = v; save(PreferKey.cronet, v); update(); }
  void setBookStorageDir(String v) { bookStorageDir = v; save('book_storage_dir', v); update(); }
  void setIgnoreAudioFocus(bool v) { ignoreAudioFocus = v; save(PreferKey.ignoreAudioFocus, v); update(); }
  void setAutoClearExpired(bool v) { autoClearExpired = v; save(PreferKey.autoClearExpired, v); update(); }
  void setMediaButtonOnExit(bool v) { mediaButtonOnExit = v; save('media_button_on_exit', v); update(); }
  void setReadAloudByMediaButton(bool v) { readAloudByMediaButton = v; save(PreferKey.readAloudByMediaButton, v); update(); }
  void setShowAddToShelfAlert(bool v) { showAddToShelfAlert = v; save(PreferKey.showAddToShelfAlert, v); update(); }
  void setShowMangaUi(bool v) { showMangaUi = v; save(PreferKey.showMangaUi, v); update(); }

  // --- 主題與備份 Setter 補全 ---
  void setTransparentStatusBar(bool v) { transparentStatusBar = v; save(PreferKey.transparentStatusBar, v); update(); }
  void setImmNavigationBar(bool v) { immNavigationBar = v; save(PreferKey.immNavigationBar, v); update(); }
  void setDayAccentColor(Color c) { dayAccentColor = c; save(PreferKey.cAccent, c.toARGB32()); update(); }
  void setDayBackgroundColor(Color c) { dayBackgroundColor = c; save(PreferKey.cBackground, c.toARGB32()); update(); }
  void setDayBottomBackgroundColor(Color c) { dayBottomBackgroundColor = c; save(PreferKey.cBBackground, c.toARGB32()); update(); }
  void setNightAccentColor(Color c) { nightAccentColor = c; save(PreferKey.cNAccent, c.toARGB32()); update(); }
  void setNightBackgroundColor(Color c) { nightBackgroundColor = c; save(PreferKey.cNBackground, c.toARGB32()); update(); }
  void setNightBottomBackgroundColor(Color c) { nightBottomBackgroundColor = c; save(PreferKey.cNBBackground, c.toARGB32()); update(); }

  void setOnlyLatestBackup(bool v) { onlyLatestBackup = v; save(PreferKey.onlyLatestBackup, v); update(); }
  void setAutoCheckNewBackup(bool v) { autoCheckNewBackup = v; save(PreferKey.autoCheckNewBackup, v); update(); }
  void setAutoBackup(bool v) { autoBackup = v; save('auto_backup', v); update(); }

  void setReadBodyToLh(bool v) { readBodyToLh = v; save(PreferKey.readBodyToLh, v); update(); }
  void setPaddingDisplayCutouts(bool v) { paddingDisplayCutouts = v; save(PreferKey.paddingDisplayCutouts, v); update(); }
  void setUseZhLayout(bool v) { useZhLayout = v; save(PreferKey.useZhLayout, v); update(); }
  void setTextFullJustify(bool v) { textFullJustify = v; save(PreferKey.textFullJustify, v); update(); }
  void setTextBottomJustify(bool v) { textBottomJustify = v; save(PreferKey.textBottomJustify, v); update(); }
  void setMouseWheelPage(bool v) { mouseWheelPage = v; save(PreferKey.mouseWheelPage, v); update(); }
  void setVolumeKeyPageOnPlay(bool v) { volumeKeyPageOnPlay = v; save(PreferKey.volumeKeyPageOnPlay, v); update(); }
  void setKeyPageOnLongPress(bool v) { keyPageOnLongPress = v; save(PreferKey.keyPageOnLongPress, v); update(); }
  void setSelectText(bool v) { selectText = v; save(PreferKey.textSelectAble, v); update(); }
  void setShowBrightnessView(bool v) { showBrightnessView = v; save(PreferKey.showBrightnessView, v); update(); }
  void setNoAnimScrollPage(bool v) { noAnimScrollPage = v; save(PreferKey.noAnimScrollPage, v); update(); }
  void setPreviewImageByClick(bool v) { previewImageByClick = v; save(PreferKey.previewImageByClick, v); update(); }
  void setDisableReturnKey(bool v) { disableReturnKey = v; save('disable_return_key', v); update(); }
  void setExpandTextMenu(bool v) { expandTextMenu = v; save(PreferKey.expandTextMenu, v); update(); }
  void setShowReadTitleAddition(bool v) { showReadTitleAddition = v; save(PreferKey.showReadTitleAddition, v); update(); }
  void setReadBarStyleFollowPage(bool v) { readBarStyleFollowPage = v; save(PreferKey.readBarStyleFollowPage, v); update(); }

  void setWelcomeShowIcon(bool v) { welcomeShowIcon = v; save(PreferKey.welcomeShowIcon, v); update(); }
  void setWelcomeImageDark(String v) { welcomeImageDark = v; save(PreferKey.welcomeImageDark, v); update(); }
  void setWelcomeShowTextDark(bool v) { welcomeShowTextDark = v; save(PreferKey.welcomeShowTextDark, v); update(); }
  void setWelcomeShowIconDark(bool v) { welcomeShowIconDark = v; save(PreferKey.welcomeShowIconDark, v); update(); }
  bool welcomeShowTextDark = true;
  bool welcomeShowIconDark = true;

  void setLastVersionCode(int v) { lastVersionCode = v; save(PreferKey.lastVersionCode, v); update(); }

  // --- 朗讀 Setter 補全 ---
  void setIgnoreAudioFocusAloud(bool v) { ignoreAudioFocusAloud = v; save('ignore_audio_focus_aloud', v); update(); }
  void setPauseReadAloudWhilePhoneCalls(bool v) { pauseReadAloudWhilePhoneCalls = v; save(PreferKey.pauseReadAloudWhilePhoneCalls, v); update(); }
  void setReadAloudWakeLock(bool v) { readAloudWakeLock = v; save(PreferKey.readAloudWakeLock, v); update(); }
  void setSystemMediaControlCompatibilityChange(bool v) { systemMediaControlCompatibilityChange = v; save('system_media_control_compat', v); update(); }
  void setMediaButtonPerNext(bool v) { mediaButtonPerNext = v; save('media_button_per_next', v); update(); }
  void setReadAloudByPage(bool v) { readAloudByPage = v; save(PreferKey.readAloudByPage, v); update(); }
  void setStreamReadAloudAudio(bool v) { streamReadAloudAudio = v; save(PreferKey.streamReadAloudAudio, v); update(); }
  void setLastBackup(int v) { lastBackup = v; save('last_backup', v); update(); }

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
    privacyAgreed = prefs.getBool('privacy_agreed') ?? false;

    // --- 歡迎與介面 ---
    welcomeImage = prefs.getString(PreferKey.welcomeImage) ?? '';
    welcomeImageDark = prefs.getString(PreferKey.welcomeImageDark) ?? '';
    welcomeShowText = prefs.getBool(PreferKey.welcomeShowText) ?? true;
    welcomeShowTextDark = prefs.getBool(PreferKey.welcomeShowTextDark) ?? true;
    welcomeShowIcon = prefs.getBool(PreferKey.welcomeShowIcon) ?? true;
    welcomeShowIconDark = prefs.getBool(PreferKey.welcomeShowIconDark) ?? true;
    launcherIcon = prefs.getString(PreferKey.launcherIcon) ?? '';
    showDiscovery = prefs.getBool(PreferKey.showDiscovery) ?? true;
    showAddToShelfAlert = prefs.getBool(PreferKey.showAddToShelfAlert) ?? true;

    lastBackup = prefs.getInt('last_backup') ?? 0;

    // --- 主題與顯示 ---
    transparentStatusBar = prefs.getBool(PreferKey.transparentStatusBar) ?? true;
    immNavigationBar = prefs.getBool(PreferKey.immNavigationBar) ?? true;
    dayBackgroundImage = prefs.getString(PreferKey.bgImage) ?? '';
    nightBackgroundImage = prefs.getString(PreferKey.bgImageN) ?? '';
    
    dayPrimaryColor = Color(prefs.getInt(PreferKey.cPrimary) ?? Colors.brown.toARGB32());
    dayAccentColor = Color(prefs.getInt(PreferKey.cAccent) ?? Colors.red.toARGB32());
    dayBackgroundColor = Color(prefs.getInt(PreferKey.cBackground) ?? Colors.grey.shade100.toARGB32());
    dayBottomBackgroundColor = Color(prefs.getInt(PreferKey.cBBackground) ?? Colors.grey.shade200.toARGB32());
    nightPrimaryColor = Color(prefs.getInt(PreferKey.cNPrimary) ?? Colors.blueGrey.shade600.toARGB32());
    nightAccentColor = Color(prefs.getInt(PreferKey.cNAccent) ?? Colors.deepOrange.shade800.toARGB32());
    nightBackgroundColor = Color(prefs.getInt(PreferKey.cNBackground) ?? Colors.grey.shade900.toARGB32());
    nightBottomBackgroundColor = Color(prefs.getInt(PreferKey.cNBBackground) ?? Colors.grey.shade800.toARGB32());

    // --- 閱讀設定 ---
    hideStatusBar = prefs.getBool(PreferKey.hideStatusBar) ?? false;
    hideNavigationBar = prefs.getBool(PreferKey.hideNavigationBar) ?? false;
    readBodyToLh = prefs.getBool(PreferKey.readBodyToLh) ?? true;
    paddingDisplayCutouts = prefs.getBool(PreferKey.paddingDisplayCutouts) ?? false;
    useZhLayout = prefs.getBool(PreferKey.useZhLayout) ?? false;
    textFullJustify = prefs.getBool(PreferKey.textFullJustify) ?? true;
    textBottomJustify = prefs.getBool(PreferKey.textBottomJustify) ?? true;
    mouseWheelPage = prefs.getBool(PreferKey.mouseWheelPage) ?? true;
    volumeKeyPage = prefs.getBool(PreferKey.volumeKeyPage) ?? true;
    volumeKeyPageOnPlay = prefs.getBool(PreferKey.volumeKeyPageOnPlay) ?? false;
    keyPageOnLongPress = prefs.getBool(PreferKey.keyPageOnLongPress) ?? false;
    autoChangeSource = prefs.getBool(PreferKey.autoChangeSource) ?? true;
    selectText = prefs.getBool(PreferKey.textSelectAble) ?? true;
    showBrightnessView = prefs.getBool(PreferKey.showBrightnessView) ?? true;
    noAnimScrollPage = prefs.getBool(PreferKey.noAnimScrollPage) ?? false;
    previewImageByClick = prefs.getBool(PreferKey.previewImageByClick) ?? false;
    optimizeRender = prefs.getBool(PreferKey.optimizeRender) ?? false;
    expandTextMenu = prefs.getBool(PreferKey.expandTextMenu) ?? false;
    showReadTitleAddition = prefs.getBool(PreferKey.showReadTitleAddition) ?? true;
    readBarStyleFollowPage = prefs.getBool(PreferKey.readBarStyleFollowPage) ?? false;
    autoRefresh = prefs.getBool(PreferKey.autoRefresh) ?? true;
    defaultToRead = prefs.getBool(PreferKey.defaultToRead) ?? false;
    replaceEnableDefault = prefs.getBool(PreferKey.replaceEnableDefault) ?? true;
    AppConfig.replaceEnableDefault = replaceEnableDefault; // 同步至 AppConfig
    autoClearExpired = prefs.getBool(PreferKey.autoClearExpired) ?? true;
    showMangaUi = prefs.getBool(PreferKey.showMangaUi) ?? true;
    antiAlias = prefs.getBool(PreferKey.antiAlias) ?? true;

    // --- 備份與同步 ---
    onlyLatestBackup = prefs.getBool(PreferKey.onlyLatestBackup) ?? true;
    autoCheckNewBackup = prefs.getBool(PreferKey.autoCheckNewBackup) ?? true;
    autoBackup = prefs.getBool('auto_backup') ?? false;

    // --- 朗讀設定 ---
    ignoreAudioFocus = prefs.getBool(PreferKey.ignoreAudioFocus) ?? false;
    ignoreAudioFocusAloud = prefs.getBool('ignore_audio_focus_aloud') ?? false;
    pauseReadAloudWhilePhoneCalls = prefs.getBool(PreferKey.pauseReadAloudWhilePhoneCalls) ?? false;
    readAloudWakeLock = prefs.getBool(PreferKey.readAloudWakeLock) ?? false;
    readAloudByPage = prefs.getBool(PreferKey.readAloudByPage) ?? false;
    streamReadAloudAudio = prefs.getBool(PreferKey.streamReadAloudAudio) ?? false;
    readAloudByMediaButton = prefs.getBool(PreferKey.readAloudByMediaButton) ?? false;
    speechRate = prefs.getDouble(PreferKey.ttsSpeechRate) ?? 0.5;
    speechPitch = prefs.getDouble('speech_pitch') ?? 1.0;
    speechVolume = prefs.getDouble('speech_volume') ?? 1.0;

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
}


