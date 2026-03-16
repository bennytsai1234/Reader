import 'package:dio/dio.dart';
import 'package:legado_reader/core/services/network_service.dart';

/// HttpHelper - 網路請求門面 (對標 Android HttpHelper.kt)
class HttpHelper {
  HttpHelper._();

  /// 獲取全域 Dio 實例
  static Dio get client => NetworkService().dio;

  /// 同步 Cookie 到特定書源 (對標 Android: CookieManager.setCookie)
  static Future<void> setCookie(String url, String cookie) async {
    await NetworkService().saveCookies(url, cookie);
  }

  /// 移除特定書源的 Cookie
  static Future<void> removeCookie(String url) async {
    final uri = Uri.parse(url);
    await NetworkService().cookieJar.delete(uri);
  }
}
