import 'package:inkpage_reader/core/services/cookie_store.dart';
import 'package:inkpage_reader/core/services/network_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewDataService {
  WebViewDataService({
    CookieStore? cookieStore,
    NetworkService? networkService,
    WebViewCookieManager? webViewCookieManager,
  }) : _cookieStore = cookieStore ?? CookieStore(),
       _networkService = networkService ?? NetworkService(),
       _webViewCookieManager = webViewCookieManager ?? WebViewCookieManager();

  final CookieStore _cookieStore;
  final NetworkService _networkService;
  final WebViewCookieManager _webViewCookieManager;

  Future<bool> clearAllCookies() async {
    await _cookieStore.clearAll();
    await _networkService.cookieJar.deleteAll();
    return _webViewCookieManager.clearCookies();
  }

  Future<void> clearSourceCookies(String source) async {
    final uri = _normalizeSourceUri(source);
    await _cookieStore.removeCookie(uri.toString());
    await _networkService.cookieJar.delete(uri, true);
  }

  Future<void> clearWebViewLocalStorage() async {
    final controller = WebViewController();
    await controller.clearLocalStorage();
  }

  Future<void> clearWebViewCache() async {
    final controller = WebViewController();
    await controller.clearCache();
  }

  Uri _normalizeSourceUri(String source) {
    final value = source.trim();
    if (value.isEmpty) {
      throw ArgumentError('請輸入書源網址或網域');
    }
    final rawUri = Uri.tryParse(value);
    if (rawUri != null && rawUri.hasScheme && rawUri.host.isNotEmpty) {
      return rawUri;
    }
    final withScheme = Uri.tryParse('https://$value');
    if (withScheme != null && withScheme.host.isNotEmpty) {
      return withScheme;
    }
    throw ArgumentError('書源網址或網域格式不正確');
  }
}
