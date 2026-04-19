import 'package:dio/dio.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';

/// AppInterceptor - 全域網路攔截器 (對標 Android HttpHelper.kt 內建攔截器)
class AppInterceptor extends Interceptor {
  static const String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
  static const String _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 1. 自動補全 Referer (對標 Android: 預設使用 Host 作為 Referer)
    if (!_hasHeader(options.headers, 'referer')) {
      options.headers['Referer'] = options.uri.origin;
    }

    // 2. 確保 User-Agent 存在
    if (!_hasHeader(options.headers, 'user-agent')) {
      options.headers['User-Agent'] = _defaultUserAgentFor(options.uri);
    }

    // 3. 語言修復 (對標 Android: 支援中文環境)
    if (!_hasHeader(options.headers, 'accept-language')) {
      options.headers['Accept-Language'] = 'zh-CN,zh;q=0.9,en;q=0.8';
    }

    AppLog.i('Network Request: [${options.method}] ${options.uri}');
    super.onRequest(options, handler);
  }

  String _defaultUserAgentFor(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host.startsWith('m.')) {
      return _mobileUserAgent;
    }
    return _desktopUserAgent;
  }

  bool _hasHeader(Map<String, dynamic> headers, String name) {
    final target = name.toLowerCase();
    return headers.keys.any((key) => key.toString().toLowerCase() == target);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 這裡可以處理特殊的內容編碼或自動修正
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLog.e(
      'Network Error: ${err.message}',
      error: err.error,
      stackTrace: err.stackTrace,
    );
    super.onError(err, handler);
  }
}
