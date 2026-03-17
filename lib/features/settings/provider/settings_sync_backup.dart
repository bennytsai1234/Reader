import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';

mixin SettingsSyncBackupMixin on ChangeNotifier {
  late SharedPreferences prefs;
  
  bool onlyLatestBackup = true;
  bool autoCheckNewBackup = true;
  bool autoBackup = false;

  void loadSyncBackup(SharedPreferences p) {
    prefs = p;
    onlyLatestBackup = prefs.getBool(PreferKey.onlyLatestBackup) ?? true;
    autoCheckNewBackup = prefs.getBool(PreferKey.autoCheckNewBackup) ?? true;
    autoBackup = prefs.getBool('auto_backup') ?? false;
  }

  void setOnlyLatestBackup(bool v) {
    onlyLatestBackup = v;
    prefs.setBool(PreferKey.onlyLatestBackup, v);
    notifyListeners();
  }

  void setAutoCheckNewBackup(bool v) {
    autoCheckNewBackup = v;
    prefs.setBool(PreferKey.autoCheckNewBackup, v);
    notifyListeners();
  }

  void setAutoBackup(bool v) {
    autoBackup = v;
    prefs.setBool('auto_backup', v);
    notifyListeners();
  }
}
