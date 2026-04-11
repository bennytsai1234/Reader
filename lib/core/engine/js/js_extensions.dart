import 'package:flutter/foundation.dart';
import 'js_extensions_base.dart';
import 'extensions/js_network_extensions.dart';
import 'extensions/js_crypto_extensions.dart';
import 'extensions/js_string_extensions.dart';
import 'extensions/js_file_extensions.dart';
import 'extensions/js_font_extensions.dart';
import 'extensions/js_java_object.dart';
import 'js_encode_utils.dart';
import 'package:legado_reader/core/services/http_client.dart';
import 'package:legado_reader/core/services/cookie_store.dart';

export 'js_extensions_base.dart';
export 'extensions/js_network_extensions.dart';
export 'extensions/js_crypto_extensions.dart';
export 'extensions/js_string_extensions.dart';
export 'extensions/js_file_extensions.dart';
export 'extensions/js_font_extensions.dart';

/// JsExtensions - JS 橋接總控 (重構後)
/// (原 Android help/JsExtensions.kt)
class JsExtensions extends JsExtensionsBase {
  JsExtensions(super.runtime, {super.source});

  /// 注入完整 JS 環境
  ///
  /// 順序重要：`setupPromiseBridge` 必須在任何會用到 `__asyncCall` 的 shim
  /// (`injectJavaObjectJs` / `injectNetworkExtensions` / ...) 之前。
  void inject() {
    setupPromiseBridge();
    _injectCoreHandlers();
    injectNetworkExtensions();
    injectCryptoExtensions();
    injectStringExtensions();
    injectFileExtensions();
    injectFontExtensions();
    injectJavaObjectJs();
  }

  void _injectCoreHandlers() {
    // ─── 純同步 (sharedScope / log / toast) ─────────────────────
    runtime.onMessage('put', (args) {
      if (args is List && args.length >= 2) {
        JsExtensionsBase.sharedScope[args[0].toString()] = args[1];
      }
      return null;
    });
    runtime.onMessage(
      'get',
      (args) => JsExtensionsBase.sharedScope[args.toString()],
    );
    runtime.onMessage('log', (args) {
      debugPrint('JS_LOG: $args');
      return null;
    });
    runtime.onMessage('toast', (args) {
      debugPrint('JS_TOAST: $args');
      return null;
    });

    // ─── Fire-and-forget async (JS 不讀回傳值) ──────────────────
    // 直接啟動 Future，不 block handler；失敗寫 log 但不 reject JS
    runtime.onMessage('setCookie', (args) {
      if (args is List && args.length >= 2) {
        CookieStore().setCookie(args[0].toString(), args[1].toString());
      }
      return null;
    });
    runtime.onMessage('removeCookie', (args) {
      CookieStore().removeCookie(args.toString());
      return null;
    });
    runtime.onMessage('putCache', (args) {
      if (args is List && args.length >= 2) {
        final saveTime = args.length > 2
            ? int.tryParse(args[2].toString()) ?? 0
            : 0;
        cacheManager.put(
          args[0].toString(),
          args[1].toString(),
          saveTimeSeconds: saveTime,
        );
      }
      return null;
    });
    runtime.onMessage('deleteCache', (args) {
      cacheManager.delete(args.toString());
      return null;
    });
    runtime.onMessage('sourcePut', (args) {
      if (args is List && args.length >= 2 && source != null) {
        final key = args[0].toString();
        final value = args[1].toString();
        cacheManager.put('v_${source!.getKey()}_$key', value);
      }
      return null;
    });
    runtime.onMessage('sourcePutLoginInfo', (args) {
      if (source != null) {
        source!.putLoginInfo(args.toString());
      }
      return null;
    });

    // ─── Promise bridge: async with return value ────────────────
    runtime.onMessage('getCache', (args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final key = parsed.payload.toString();
      cacheManager.get(key).then((v) {
        resolveJsPending(parsed.callId, v ?? '');
      }).catchError((e) {
        rejectJsPending(parsed.callId, e);
      });
      return null;
    });

    runtime.onMessage('sourceGet', (args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      if (source == null) {
        resolveJsPending(parsed.callId, '');
        return null;
      }
      final key = parsed.payload.toString();
      cacheManager.get('v_${source!.getKey()}_$key').then((v) {
        resolveJsPending(parsed.callId, v ?? '');
      }).catchError((e) {
        rejectJsPending(parsed.callId, e);
      });
      return null;
    });

    runtime.onMessage('sourceGetLoginInfo', (args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      if (source == null) {
        resolveJsPending(parsed.callId, '');
        return null;
      }
      source!.getLoginInfo().then((v) {
        resolveJsPending(parsed.callId, v ?? '');
      }).catchError((e) {
        rejectJsPending(parsed.callId, e);
      });
      return null;
    });

    runtime.onMessage('cookieGet', (args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final url = parsed.payload.toString();
      CookieStore().getCookie(url).then((v) {
        resolveJsPending(parsed.callId, v);
      }).catchError((e) {
        rejectJsPending(parsed.callId, e);
      });
      return null;
    });

    runtime.onMessage('allCookies', (args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      // CookieStore 目前沒有 allCookies API，回傳空字串維持既有行為
      resolveJsPending(parsed.callId, '');
      return null;
    });

    // cacheFile 供 Dart 端內部使用 (例如 font cache)
    runtime.onMessage('cacheFile', (args) {
      // 歷史上是同步呼叫，但底層是 async HTTP。維持原行為：fire-and-forget
      // 並回傳空字串。若 rule JS 實際需要讀結果，應改用 java.get(...).body()。
      if (args is List && args.isNotEmpty) {
        cacheFile(args[0].toString(), args.length > 1 ? args[1] as int : 0);
      }
      return '';
    });
  }

  /// 下載到快取資料夾並回傳內容；目前僅 Dart 內部呼叫 (非 JS 路徑)
  Future<String> cacheFile(String url, int saveTime) async {
    final key = JsEncodeUtils.md5Encode16(url);
    final cached = await cacheManager.get(key);
    if (cached != null) return cached;
    try {
      final response = await HttpClient().client.get(url);
      final content = response.data.toString();
      if (content.isNotEmpty) await cacheManager.put(key, content);
      return content;
    } catch (_) {
      return '';
    }
  }
}
