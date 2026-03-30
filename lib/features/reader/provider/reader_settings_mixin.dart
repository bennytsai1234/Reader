import 'dart:ui' show VoidCallback;
import 'package:legado_reader/core/config/app_config.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reader_provider_base.dart';

/// ReaderProvider 的設置管理擴展
mixin ReaderSettingsMixin on ReaderProviderBase {
  double fontSize = 18.0;
  double lineHeight = 1.5;
  double paragraphSpacing = 1.0;
  double letterSpacing = 0.0;
  int textIndent = 2;
  bool textFullJustify = true;
  int themeIndex = 0;
  double brightness = 1.0;
  int chineseConvert = 0;
  int pageTurnMode = 1; // 預設平移（PageAnim.slide=1）

  /// 設定變更時的回調，由 ReaderProvider 注入
  /// 觸發分頁快取清除 + 重新分頁
  VoidCallback? onSettingsChangedRepaginate;

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    fontSize = p.getDouble(PreferKey.readerFontSize) ?? 18.0;
    lineHeight = p.getDouble(PreferKey.readerLineHeight) ?? 1.5;
    paragraphSpacing = p.getDouble(PreferKey.readerParagraphSpacing) ?? 1.0;
    textIndent = p.getInt(PreferKey.readerTextIndent) ?? 2;
    themeIndex = p.getInt(PreferKey.readerThemeIndex) ?? 0;
    brightness = p.getDouble(PreferKey.readerBrightness) ?? 0.5;
    pageTurnMode = p.getInt(PreferKey.readerPageTurnMode) ?? 1;
    AppConfig.readerPageAnim = pageTurnMode;
    chineseConvert = p.getInt(PreferKey.readerChineseConvert) ?? 0;

    final ttsRate = p.getDouble(PreferKey.readerTtsRate) ?? 0.5;
    final ttsPitch = p.getDouble(PreferKey.readerTtsPitch) ?? 1.0;
    final ttsLang = p.getString(PreferKey.readerTtsLanguage);

    TTSService().setRate(ttsRate);
    TTSService().setPitch(ttsPitch);
    if (ttsLang != null) TTSService().setLanguage(ttsLang);

    final actionsStr = p.getString(PreferKey.readerClickActions) ?? '2,2,1,2,0,1,2,1,1';
    clickActions = actionsStr.split(',').map((e) => int.parse(e)).toList();
    notifyListeners();
  }

  Future<void> saveSetting(String k, dynamic v) async {
    final p = await SharedPreferences.getInstance();
    final fk = 'reader_$k';
    if (v is double) {
      await p.setDouble(fk, v);
    } else if (v is int) {
      await p.setInt(fk, v);
    } else if (v is bool) {
      await p.setBool(fk, v);
    } else if (v is String) {
      await p.setString(fk, v);
    }
  }

  void setFontSize(double s) { fontSize = s; saveSetting('font_size', s); onSettingsChangedRepaginate?.call(); }
  void setLineHeight(double v) { lineHeight = v; saveSetting('line_height', v); onSettingsChangedRepaginate?.call(); }
  void setParagraphSpacing(double v) { paragraphSpacing = v; saveSetting('paragraph_spacing', v); onSettingsChangedRepaginate?.call(); }
  void setLetterSpacing(double v) { letterSpacing = v; saveSetting('letter_spacing', v); onSettingsChangedRepaginate?.call(); }
  void setTextFullJustify(bool v) { textFullJustify = v; saveSetting('text_full_justify', v); onSettingsChangedRepaginate?.call(); }
  void setTextIndent(int v) { textIndent = v; saveSetting('text_indent', v); onSettingsChangedRepaginate?.call(); }
  void setPageTurnMode(int v) { pageTurnMode = v; AppConfig.readerPageAnim = v; saveSetting('page_turn_mode', v); notifyListeners(); }
  void setTheme(int i) { themeIndex = i; saveSetting('theme_index', i); onSettingsChangedRepaginate?.call(); }
  void setBrightness(double v) { brightness = v; saveSetting('brightness', v); notifyListeners(); }
}
