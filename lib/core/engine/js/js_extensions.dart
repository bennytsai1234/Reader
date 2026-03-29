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

  void inject() {
    _injectCoreHandlers();
    injectNetworkExtensions();
    injectCryptoExtensions();
    injectStringExtensions();
    injectFileExtensions();
    injectFontExtensions();
    injectJavaObjectJs();
  }

  void _injectCoreHandlers() {
    runtime.onMessage('put', (args) { if (args is List && args.length >= 2) JsExtensionsBase.sharedScope[args[0].toString()] = args[1]; });
    runtime.onMessage('get', (args) => JsExtensionsBase.sharedScope[args.toString()]);
    runtime.onMessage('log', (args) => debugPrint('JS_LOG: $args'));
    runtime.onMessage('toast', (args) => debugPrint('JS_TOAST: $args'));
    runtime.onMessage('cacheFile', (args) => cacheFile(args[0].toString(), args.length > 1 ? args[1] as int : 0));
    runtime.onMessage('setCookie', (args) async {
      if (args is List && args.length >= 2) {
        await CookieStore().setCookie(args[0].toString(), args[1].toString());
      }
    });
    runtime.onMessage('removeCookie', (args) async {
      await CookieStore().removeCookie(args.toString());
    });
    runtime.onMessage('allCookies', (args) async => '');
    runtime.onMessage('getCache', (args) async => await cacheManager.get(args.toString()) ?? '');
    runtime.onMessage('putCache', (args) async {
      if (args is List && args.length >= 2) {
        final saveTime = args.length > 2 ? int.tryParse(args[2].toString()) ?? 0 : 0;
        await cacheManager.put(args[0].toString(), args[1].toString(), saveTimeSeconds: saveTime);
      }
    });
    runtime.onMessage('deleteCache', (args) async {
      await cacheManager.delete(args.toString());
    });
    runtime.onMessage('sourcePut', (args) async {
      if (args is List && args.length >= 2 && source != null) {
        final key = args[0].toString();
        final value = args[1].toString();
        await cacheManager.put('v_${source!.getKey()}_$key', value);
        return value;
      }
      return '';
    });
    runtime.onMessage('sourceGet', (args) async {
      if (source == null) {
        return '';
      }
      return await cacheManager.get('v_${source!.getKey()}_${args.toString()}') ?? '';
    });
    runtime.onMessage('sourceGetLoginInfo', (args) async {
      if (source == null) {
        return '';
      }
      return await source!.getLoginInfo() ?? '';
    });
    runtime.onMessage('sourcePutLoginInfo', (args) async {
      if (source != null) {
        await source!.putLoginInfo(args.toString());
      }
    });
  }

  Future<String> cacheFile(String url, int saveTime) async {
    final key = JsEncodeUtils.md5Encode16(url);
    final cached = await cacheManager.get(key);
    if (cached != null) return cached;
    try {
      final response = await HttpClient().client.get(url);
      final content = response.data.toString();
      if (content.isNotEmpty) await cacheManager.put(key, content);
      return content;
    } catch (_) { return ''; }
  }
}
