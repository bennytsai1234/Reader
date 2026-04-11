import '../js_extensions_base.dart';

/// 注入 rule JS 可見的全域物件：`java` / `cookie` / `cache` / `source`
///
/// 設計上分兩類方法：
///
/// **A. 同步方法** — Dart 端 onMessage handler 必須同步回傳值，JS 端直接拿到
/// 字串/物件結果。例如 `md5Encode` / `base64Encode` / `hexEncode` / `put` 系列等。
///
/// **B. 非同步方法** — 透過 `__asyncCall(channel, payload)` 回傳一個 Promise：
///   - JS 分配 id 並在 `__lr.pendingResolvers[id]` 存放 resolver
///   - `sendMessage(channel, JSON.stringify([id, payload]))` 同步送往 Dart
///   - Dart handler 接到 `[id, payload]`，執行 async 工作後透過
///     `resolveJsPending(id, result)` / `rejectJsPending(id, err)` 重入 JS
///     resolve 該 Promise
///
/// 配合 [AnalyzeRule.evalJSAsync] 將使用者 rule JS 包在 async IIFE 內執行，
/// 並由 [AsyncJsRewriter] 自動在 `java.ajax(...)` 等呼叫前注入 `await`。
///
/// 白名單必須與 `lib/core/engine/js/async_js_rewriter.dart`
/// 的 `asyncMethodsByOwner` 保持同步。
extension JsJavaObject on JsExtensionsBase {
  void injectJavaObjectJs() {
    runtime.evaluate(r'''
      var java = {
        // ─── async: HTTP ─────────────────────────────────────────
        ajax: function(url) { return __asyncCall('ajax', url); },
        ajaxAll: function(urlList) { return __asyncCall('ajaxAll', urlList); },
        connect: function(url) { return __asyncCall('connect', url); },
        get: function(url, headers) {
          return __asyncCall('get', [url, headers || {}]).then(function(res) {
            return {
              body: function() { return res.body; },
              url: function() { return res.url; },
              statusCode: function() { return res.code; },
              headers: function() { return res.headers; }
            };
          });
        },
        post: function(url, body, headers) {
          return __asyncCall('post', [url, body, headers || {}]).then(function(res) {
            return {
              body: function() { return res.body; },
              url: function() { return res.url; },
              statusCode: function() { return res.code; },
              headers: function() { return res.headers; }
            };
          });
        },
        head: function(url, headers) { return this.get(url, headers); },

        // ─── async: WebView / I/O ────────────────────────────────
        webView: function(html, url, js) { return __asyncCall('webView', [html, url, js]); },
        startBrowserAwait: function(url, title) { return __asyncCall('startBrowserAwait', [url, title]); },
        getVerificationCode: function(imageUrl) { return __asyncCall('getVerificationCode', imageUrl); },
        downloadFile: function(url) { return __asyncCall('downloadFile', url); },
        readFile: function(path) { return __asyncCall('readFile', path); },
        readTxtFile: function(path, charset) { return __asyncCall('readTxtFile', [path, charset]); },
        getZipByteArrayContent: function(url, innerPath) { return __asyncCall('getZipByteArrayContent', [url, innerPath]); },
        unArchiveFile: function(zipPath) { return __asyncCall('unArchiveFile', zipPath); },
        getTxtInFolder: function(relPath) { return __asyncCall('getTxtInFolder', relPath); },

        // ─── sync: crypto / encoding ─────────────────────────────
        createSymmetricCrypto: function(transformation, key, iv) {
          return {
            decrypt: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['decrypt', transformation, key, iv, data, 'bytes'])); },
            decryptStr: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['decrypt', transformation, key, iv, data, 'string'])); },
            encrypt: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['encrypt', transformation, key, iv, data, 'bytes'])); },
            encryptBase64: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['encrypt', transformation, key, iv, data, 'base64'])); },
            encryptHex: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['encrypt', transformation, key, iv, data, 'hex'])); }
          };
        },
        md5Encode: function(str) { return sendMessage('_md5Encode', JSON.stringify(str)); },
        md5Encode16: function(str) { return sendMessage('_md5Encode16', JSON.stringify(str)); },
        base64Encode: function(str) { return sendMessage('_base64Encode', JSON.stringify(str)); },
        base64Decode: function(str) { return sendMessage('_base64Decode', JSON.stringify(str)); },
        hexEncodeToString: function(str) { return sendMessage('_hexEncode', JSON.stringify(str)); },
        hexDecodeToString: function(hex) { return sendMessage('_hexDecode', JSON.stringify(hex)); },
        randomUUID: function() { return sendMessage('_randomUUID', ''); },
        timeFormat: function(time) { return sendMessage('_timeFormat', JSON.stringify(time)); },
        timeFormatUTC: function(time, format, sh) { return sendMessage('timeFormatUTC', JSON.stringify([time, format, sh])); },
        t2s: function(text) { return sendMessage('t2s', JSON.stringify(text)); },
        s2t: function(text) { return sendMessage('s2t', JSON.stringify(text)); },
        strToBytes: function(str, charset) { return sendMessage('strToBytes', JSON.stringify([str, charset])); },
        bytesToStr: function(bytes, charset) { return sendMessage('bytesToStr', JSON.stringify([bytes, charset])); },

        // ─── sync: side-effect only (fire-and-forget) ────────────
        log: function(msg) { sendMessage('log', JSON.stringify(msg)); },
        toast: function(msg) { sendMessage('toast', JSON.stringify(msg)); },

        // ─── sync: TTF query/replace (sync helpers) ──────────────
        queryTTF: function(data, useCache) {
          var ttfId = sendMessage('queryTTF', JSON.stringify([data, useCache === undefined ? true : useCache]));
          return ttfId ? { _ttfId: ttfId } : null;
        },
        replaceFont: function(text, errTTF, correctTTF) {
          return sendMessage('replaceFont', JSON.stringify([text, errTTF ? errTTF._ttfId : null, correctTTF ? correctTTF._ttfId : null]));
        }
      };

      // ─── async: java.getCookie → 獨立 channel ─────────────────
      //
      // 提醒：rule JS 裡的 `java.getCookie(tag, key)` 與 `cookie.get(url)`
      // 走不同 Dart handler。前者是站點 Cookie 字串查詢，後者是單一 cookie。
      java.getCookie = function(tag, key) { return __asyncCall('getCookie', [tag, key || null]); };

      // ─── cookie / cache / source 全域物件 ────────────────────
      var cookie = {
        get: function(url) { return __asyncCall('cookieGet', url); },
        set: function(url, value) { sendMessage('setCookie', JSON.stringify([url, value])); },
        remove: function(url) { sendMessage('removeCookie', JSON.stringify(url)); },
        all: function() { return __asyncCall('allCookies', ''); }
      };

      var cache = {
        get: function(key) { return __asyncCall('getCache', key); },
        put: function(key, value, time) { sendMessage('putCache', JSON.stringify([key, value, time || 0])); },
        delete: function(key) { sendMessage('deleteCache', JSON.stringify(key)); }
      };

      var source = source || {};
      source.getLoginInfo = function() { return __asyncCall('sourceGetLoginInfo', ''); };
      source.putLoginInfo = function(info) { sendMessage('sourcePutLoginInfo', JSON.stringify(info)); };
      source.getLoginInfoMap = function() {
        return source.getLoginInfo().then(function(info) {
          try { return JSON.parse(info); } catch(e) { return {}; }
        });
      };
      source.put = function(key, value) { sendMessage('sourcePut', JSON.stringify([key, value])); };
      source.get = function(key) { return __asyncCall('sourceGet', key); };
    ''');
  }
}
