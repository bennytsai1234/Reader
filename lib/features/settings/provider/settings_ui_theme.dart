import 'package:flutter/services.dart';
import 'dart:io';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'settings_base.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';

/// SettingsProvider 的 UI 與主題配置擴展
extension SettingsUiTheme on SettingsProviderBase {
  // 基礎 UI 屬性 (由 SettingsProvider 子類實例化，這裡定義 setter)
  Future<void> setDayPrimaryColor(Color c) async { (this as dynamic).dayPrimaryColor = c; update(); }
  Future<void> setNightPrimaryColor(Color c) async { (this as dynamic).nightPrimaryColor = c; update(); }

  Future<void> setDayBackgroundImage(String v) async {
    (this as dynamic).dayBackgroundImage = v;
    await save(PreferKey.bgImage, v);
    update();
  }

  Future<void> setNightBackgroundImage(String v) async {
    (this as dynamic).nightBackgroundImage = v;
    await save(PreferKey.bgImageN, v);
    update();
  }

  // 歡迎介面設定
  Future<void> setWelcomeImage(String v) async { (this as dynamic).welcomeImage = v; await save(PreferKey.welcomeImage, v); update(); }
  Future<void> setWelcomeShowText(bool v) async { (this as dynamic).welcomeShowText = v; await save(PreferKey.welcomeShowText, v); update(); }

  // 啟動圖標設定
  Future<void> setLauncherIcon(String v) async {
    (this as dynamic).launcherIcon = v;
    await save(PreferKey.launcherIcon, v);
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.legado.reader/launcher_icon');
        await platform.invokeMethod('changeIcon', {'iconName': v});
      } catch (e) { AppLog.e('變更啟動圖標失敗: $e', error: e); }
    }
    update();
  }
}

