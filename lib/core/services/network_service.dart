import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';
import 'package:legado_reader/core/network/interceptors/app_interceptor.dart';

/// NetworkService - 專業網路伺服 (具備反爬蟲對應能力)
/// 封裝全域 Dio 實例並支持 Cookie 持久化與書源併發控制
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  late Dio _dio;
  late PersistCookieJar _cookieJar;
  final Map<String, Lock> _sourceLocks = {}; // 書源併發鎖
  
  Dio get dio => _dio;
  PersistCookieJar get cookieJar => _cookieJar;

  bool _isInitialized = false;

  /// 獲取書源專屬的鎖 (用於併發控制)
  Lock getSourceLock(String? sourceUrl) {
    if (sourceUrl == null || sourceUrl.isEmpty) return Lock();
    return _sourceLocks.putIfAbsent(sourceUrl, () => Lock());
  }

  Future<void> init() async {
    if (_isInitialized) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = p.join(appDocDir.path, '.cookies');
    final dir = Directory(cookiePath);
    if (!await dir.exists()) await dir.create(recursive: true);

    _cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));
    
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36',
      },
    ));

    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(AppInterceptor());
    
    _isInitialized = true;
  }

  /// 快速 GET 請求
  Future<Response> get(String url, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return await _dio.get(url, queryParameters: queryParameters, options: options);
  }

  /// 快速 POST 請求
  Future<Response> post(String url, {dynamic data, Options? options}) async {
    return await _dio.post(url, data: data, options: options);
  }

  /// 手動保存 Cookie (用於 WebView 同步等場景)
  Future<void> saveCookies(String url, String cookieStr) async {
    final uri = Uri.parse(url);
    await _cookieJar.saveFromResponse(uri, [Cookie.fromSetCookieValue(cookieStr)]);
  }
}

