import '../js_extensions_base.dart';

/// JsExtensions 的 JS 端封裝物件注入
extension JsJavaObject on JsExtensionsBase {
  void injectJavaObjectJs() {
    runtime.evaluate('''
      var java = {
        ajax: function(url) { return sendMessage('ajax', JSON.stringify(url)); },
        ajaxAll: function(urlList) { return sendMessage('ajaxAll', JSON.stringify(urlList)); },
        connect: function(url) { return sendMessage('connect', JSON.stringify(url)); },
        get: function(url, headers) { 
          var res = sendMessage('get', JSON.stringify([url, headers]));
          return { body: function() { return res.body; }, url: function() { return res.url; }, statusCode: function() { return res.code; }, headers: function() { return res.headers; } };
        },
        post: function(url, body, headers) {
          var res = sendMessage('post', JSON.stringify([url, body, headers]));
          return { body: function() { return res.body; }, url: function() { return res.url; }, statusCode: function() { return res.code; }, headers: function() { return res.headers; } };
        },
        head: function(url, headers) { return this.get(url, headers); },
        getCookie: function(tag, key) { return sendMessage('getCookie', JSON.stringify([tag, key])); },
        createSymmetricCrypto: function(transformation, key, iv) {
          return {
            decrypt: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['decrypt', transformation, key, iv, data, 'bytes'])); },
            decryptStr: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['decrypt', transformation, key, iv, data, 'string'])); },
            encrypt: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['encrypt', transformation, key, iv, data, 'bytes'])); },
            encryptBase64: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['encrypt', transformation, key, iv, data, 'base64'])); },
            encryptHex: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['encrypt', transformation, key, iv, data, 'hex'])); }
          };
        },
        log: function(msg) { sendMessage('log', JSON.stringify(msg)); },
        toast: function(msg) { sendMessage('toast', JSON.stringify(msg)); },
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
        readFile: function(path) { return sendMessage('readFile', JSON.stringify(path)); },
        readTxtFile: function(path, charset) { return sendMessage('readTxtFile', JSON.stringify([path, charset])); },
        downloadFile: function(url) { return sendMessage('downloadFile', JSON.stringify(url)); },
        queryTTF: function(data, useCache) {
          var ttfId = sendMessage('queryTTF', JSON.stringify([data, useCache === undefined ? true : useCache]));
          return ttfId ? { _ttfId: ttfId } : null;
        },
        replaceFont: function(text, errTTF, correctTTF) {
          return sendMessage('replaceFont', JSON.stringify([text, errTTF ? errTTF._ttfId : null, correctTTF ? correctTTF._ttfId : null]));
        },
        webView: function(html, url, js) { return sendMessage('webView', JSON.stringify([html, url, js])); }
      };

      var cookie = {
        get: function(url) { return sendMessage('getCookie', JSON.stringify(url)); },
        set: function(url, value) { return sendMessage('setCookie', JSON.stringify([url, value])); },
        remove: function(url) { return sendMessage('removeCookie', JSON.stringify(url)); },
        all: function() { return sendMessage('allCookies', ''); }
      };

      var cache = {
        get: function(key) { return sendMessage('getCache', JSON.stringify(key)); },
        put: function(key, value, time) { return sendMessage('putCache', JSON.stringify([key, value, time || 0])); },
        delete: function(key) { return sendMessage('deleteCache', JSON.stringify(key)); }
      };

      var source = source || {};
      source.getLoginInfo = function() { return sendMessage('sourceGetLoginInfo', ''); };
      source.putLoginInfo = function(info) { return sendMessage('sourcePutLoginInfo', JSON.stringify(info)); };
      source.getLoginInfoMap = function() {
        var info = sendMessage('sourceGetLoginInfo', '');
        try { return JSON.parse(info); } catch(e) { return {}; }
      };
      source.put = function(key, value) { return sendMessage('sourcePut', JSON.stringify([key, value])); };
      source.get = function(key) { return sendMessage('sourceGet', JSON.stringify(key)); };
    ''');
  }
}
