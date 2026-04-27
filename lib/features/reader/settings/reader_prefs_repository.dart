import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/features/reader/models/reader_tap_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderPrefsSnapshot {
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double letterSpacing;
  final int textIndent;
  final bool textFullJustify;
  final int themeIndex;
  final int lastDayThemeIndex;
  final int lastNightThemeIndex;
  final double brightness;
  final int pageTurnMode;
  final int chineseConvert;
  final bool showAddToShelfAlert;
  final bool showReadTitleAddition;
  final bool readBarStyleFollowPage;
  final bool selectText;
  final List<int> clickActions;

  const ReaderPrefsSnapshot({
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.letterSpacing,
    required this.textIndent,
    required this.textFullJustify,
    required this.themeIndex,
    required this.lastDayThemeIndex,
    required this.lastNightThemeIndex,
    required this.brightness,
    required this.pageTurnMode,
    required this.chineseConvert,
    required this.showAddToShelfAlert,
    required this.showReadTitleAddition,
    required this.readBarStyleFollowPage,
    required this.selectText,
    required this.clickActions,
  });

  factory ReaderPrefsSnapshot.defaults() {
    return ReaderPrefsSnapshot(
      fontSize: 18.0,
      lineHeight: 1.5,
      paragraphSpacing: 1.0,
      letterSpacing: 0.0,
      textIndent: 2,
      textFullJustify: true,
      themeIndex: 0,
      lastDayThemeIndex: 0,
      lastNightThemeIndex: 1,
      brightness: 1.0,
      pageTurnMode: PageAnim.slide,
      chineseConvert: 0,
      showAddToShelfAlert: true,
      showReadTitleAddition: true,
      readBarStyleFollowPage: false,
      selectText: true,
      clickActions: ReaderTapAction.defaultGrid(),
    );
  }

  ReaderPrefsSnapshot copyWith({
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    double? letterSpacing,
    int? textIndent,
    bool? textFullJustify,
    int? themeIndex,
    int? lastDayThemeIndex,
    int? lastNightThemeIndex,
    double? brightness,
    int? pageTurnMode,
    int? chineseConvert,
    bool? showAddToShelfAlert,
    bool? showReadTitleAddition,
    bool? readBarStyleFollowPage,
    bool? selectText,
    List<int>? clickActions,
  }) {
    return ReaderPrefsSnapshot(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      textIndent: textIndent ?? this.textIndent,
      textFullJustify: textFullJustify ?? this.textFullJustify,
      themeIndex: themeIndex ?? this.themeIndex,
      lastDayThemeIndex: lastDayThemeIndex ?? this.lastDayThemeIndex,
      lastNightThemeIndex: lastNightThemeIndex ?? this.lastNightThemeIndex,
      brightness: brightness ?? this.brightness,
      pageTurnMode: pageTurnMode ?? this.pageTurnMode,
      chineseConvert: chineseConvert ?? this.chineseConvert,
      showAddToShelfAlert: showAddToShelfAlert ?? this.showAddToShelfAlert,
      showReadTitleAddition:
          showReadTitleAddition ?? this.showReadTitleAddition,
      readBarStyleFollowPage:
          readBarStyleFollowPage ?? this.readBarStyleFollowPage,
      selectText: selectText ?? this.selectText,
      clickActions: clickActions ?? List<int>.from(this.clickActions),
    );
  }
}

class ReaderPrefsRepository {
  const ReaderPrefsRepository();

  Future<ReaderPrefsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = ReaderPrefsSnapshot.defaults();
    return ReaderPrefsSnapshot(
      fontSize: prefs.getDouble(PreferKey.readerFontSize) ?? defaults.fontSize,
      lineHeight:
          prefs.getDouble(PreferKey.readerLineHeight) ?? defaults.lineHeight,
      paragraphSpacing:
          prefs.getDouble(PreferKey.readerParagraphSpacing) ??
          defaults.paragraphSpacing,
      letterSpacing:
          prefs.getDouble(PreferKey.readerLetterSpacing) ??
          defaults.letterSpacing,
      textIndent:
          prefs.getInt(PreferKey.readerTextIndent) ?? defaults.textIndent,
      textFullJustify:
          prefs.getBool(PreferKey.readerTextFullJustify) ??
          prefs.getBool(PreferKey.textFullJustify) ??
          defaults.textFullJustify,
      themeIndex:
          prefs.getInt(PreferKey.readerThemeIndex) ?? defaults.themeIndex,
      lastDayThemeIndex:
          prefs.getInt(PreferKey.readerDayThemeIndex) ??
          defaults.lastDayThemeIndex,
      lastNightThemeIndex:
          prefs.getInt(PreferKey.readerNightThemeIndex) ??
          defaults.lastNightThemeIndex,
      brightness:
          prefs.getDouble(PreferKey.readerBrightness) ?? defaults.brightness,
      pageTurnMode:
          prefs.getInt(PreferKey.readerPageTurnMode) ?? defaults.pageTurnMode,
      chineseConvert:
          prefs.getInt(PreferKey.readerChineseConvert) ??
          defaults.chineseConvert,
      showAddToShelfAlert:
          prefs.getBool(PreferKey.showAddToShelfAlert) ??
          defaults.showAddToShelfAlert,
      showReadTitleAddition:
          prefs.getBool(PreferKey.showReadTitleAddition) ??
          defaults.showReadTitleAddition,
      readBarStyleFollowPage:
          prefs.getBool(PreferKey.readBarStyleFollowPage) ??
          defaults.readBarStyleFollowPage,
      selectText:
          prefs.getBool(PreferKey.textSelectAble) ?? defaults.selectText,
      clickActions: _parseClickActions(
        prefs.getString(PreferKey.readerClickActions),
      ),
    );
  }

  Future<void> saveFontSize(double value) {
    return _setDouble(PreferKey.readerFontSize, value);
  }

  Future<void> saveLineHeight(double value) {
    return _setDouble(PreferKey.readerLineHeight, value);
  }

  Future<void> saveParagraphSpacing(double value) {
    return _setDouble(PreferKey.readerParagraphSpacing, value);
  }

  Future<void> saveLetterSpacing(double value) {
    return _setDouble(PreferKey.readerLetterSpacing, value);
  }

  Future<void> saveTextIndent(int value) {
    return _setInt(PreferKey.readerTextIndent, value);
  }

  Future<void> saveTextFullJustify(bool value) {
    return _setBool(PreferKey.readerTextFullJustify, value);
  }

  Future<void> saveThemeIndex(int value) {
    return _setInt(PreferKey.readerThemeIndex, value);
  }

  Future<void> saveDayThemeIndex(int value) {
    return _setInt(PreferKey.readerDayThemeIndex, value);
  }

  Future<void> saveNightThemeIndex(int value) {
    return _setInt(PreferKey.readerNightThemeIndex, value);
  }

  Future<void> saveBrightness(double value) {
    return _setDouble(PreferKey.readerBrightness, value);
  }

  Future<void> savePageTurnMode(int value) {
    return _setInt(PreferKey.readerPageTurnMode, value);
  }

  Future<void> saveChineseConvert(int value) {
    return _setInt(PreferKey.readerChineseConvert, value);
  }

  Future<void> saveShowAddToShelfAlert(bool value) {
    return _setBool(PreferKey.showAddToShelfAlert, value);
  }

  Future<void> saveShowReadTitleAddition(bool value) {
    return _setBool(PreferKey.showReadTitleAddition, value);
  }

  Future<void> saveReadBarStyleFollowPage(bool value) {
    return _setBool(PreferKey.readBarStyleFollowPage, value);
  }

  Future<void> saveSelectText(bool value) {
    return _setBool(PreferKey.textSelectAble, value);
  }

  Future<void> saveClickActions(List<int> actions) {
    final normalized = _normalizeClickActions(actions);
    return _setString(PreferKey.readerClickActions, normalized.join(','));
  }

  List<int> parseClickActions(String? stored) {
    return _parseClickActions(stored);
  }

  List<int> normalizeClickActions(List<int> actions) {
    return _normalizeClickActions(actions);
  }

  Future<void> _setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<void> _setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  List<int> _parseClickActions(String? stored) {
    final normalized =
        stored
            ?.split(',')
            .map((value) => int.tryParse(value.trim()))
            .whereType<int>()
            .toList();
    return _normalizeClickActions(normalized);
  }

  List<int> _normalizeClickActions(List<int>? actions) {
    if (actions == null || actions.length != 9) {
      return ReaderTapAction.defaultGrid();
    }
    return List<int>.from(actions);
  }
}
