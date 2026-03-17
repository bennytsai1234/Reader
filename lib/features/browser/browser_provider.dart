import 'package:legado_reader/core/base/base_provider.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/services/cookie_store.dart';
import 'browser_params.dart';
import 'package:legado_reader/core/di/injection.dart';

class BrowserProvider extends BaseProvider {
  final BrowserParams params;
  
  String? _baseUrl;
  Map<String, String> _headerMap = {};
  String? _html;
  bool _isInitialized = false;
  
  String? get baseUrl => _baseUrl;
  Map<String, String> get headerMap => _headerMap;
  String? get html => _html;
  bool get isInitialized => _isInitialized;

  BrowserProvider(this.params);

  Future<void> init() async {
    if (_isInitialized) return;
    
    await runTask(() async {
      final source = params.sourceOrigin != null 
          ? await getIt<BookSourceDao>().getByUrl(params.sourceOrigin!) 
          : null;
      
      final analyzeUrl = AnalyzeUrl(
        params.url,
        source: source,
      );
      
      _baseUrl = analyzeUrl.url;
      _headerMap = analyzeUrl.headerMap.cast<String, String>();
      
      // 同步 Cookie 到 WebView (如果有的話)
      final domain = CookieStore().getSubDomain(_baseUrl!);
      final cookie = await CookieStore().getCookie(domain);
      if (cookie.isNotEmpty) {
        _headerMap['Cookie'] = cookie;
      }

      if (analyzeUrl.method == 'POST') {
        _html = await analyzeUrl.getResponseBody();
      }
      
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> saveVerificationResult(String currentHtml) async {
    if (!params.sourceVerificationEnable) return;
    
    await runTask(() async {
      if (params.refetchAfterSuccess) {
        final source = await getIt<BookSourceDao>().getByUrl(params.sourceOrigin!);
        final analyzeUrl = AnalyzeUrl(
          params.url,
          source: source,
        );
        await analyzeUrl.getResponseBody();
      }
      
      // 注意：這裡應呼叫 SourceVerificationService.sendResult
      // 但因為 Provider 不持有 Request 對象，這部分邏輯通常在 Page 層處理
    });
  }

  Future<void> disableSource() async {
    if (params.sourceOrigin == null) return;
    await runTask(() async {
      final source = await getIt<BookSourceDao>().getByUrl(params.sourceOrigin!);
      if (source != null) {
        source.enabled = false;
        await getIt<BookSourceDao>().upsert(source);
      }
    });
  }

  Future<void> deleteSource() async {
    if (params.sourceOrigin == null) return;
    await runTask(() async {
      await getIt<BookSourceDao>().deleteByUrl(params.sourceOrigin!);
    });
  }
}


