import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'http_client.dart';

/// AppUpdateService - 應用程式更新服務
/// (原 Android help/update/AppUpdateGitHub.kt)
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  final Dio _dio = HttpClient().client;

  /// 檢查更新 (對標 AppUpdateGitHub.check)
  Future<UpdateInfo?> checkUpdate({bool isBeta = false}) async {
    try {
      final repoUrl = isBeta
          ? 'https://api.github.com/repos/gedoor/legado/releases/tags/beta'
          : 'https://api.github.com/repos/gedoor/legado/releases/latest';

      final response = await _dio.get(repoUrl);
      if (response.statusCode != 200) return null;

      final data = response.data;
      final tagName = data['tag_name'] as String;
      final body = data['body'] as String;
      final assets = data['assets'] as List<dynamic>;

      // 尋找安裝包 (原 Android Asset.isValid)
      // iOS 端通常無法直接安裝 APK/IPA，此處保留下載連結供跳轉
      final asset = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk') || (a['name'] as String).endsWith('.ipa'),
        orElse: () => assets.isNotEmpty ? assets.first : null,
      );

      final downloadUrl = asset != null ? asset['browser_download_url'] as String : '';
      
      // 版本比對
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(tagName, currentVersion)) {
        return UpdateInfo(
          versionName: tagName,
          updateLog: body,
          downloadUrl: downloadUrl,
        );
      }
    } catch (e) {
      AppLog.e('Check update failed: $e', error: e);
    }
    return null;
  }

  bool _isNewerVersion(String newVer, String oldVer) {
    // 簡單的語義化版本比對 (可根據需要強化)
    return newVer.compareTo(oldVer) > 0;
  }
}

/// UpdateInfo - 更新資訊模型
class UpdateInfo {
  final String versionName;
  final String updateLog;
  final String downloadUrl;

  UpdateInfo({
    required this.versionName,
    required this.updateLog,
    required this.downloadUrl,
  });
}

