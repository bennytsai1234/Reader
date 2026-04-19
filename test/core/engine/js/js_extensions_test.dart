import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/js/async_js_rewriter.dart';
import 'package:inkpage_reader/core/engine/js/js_extensions.dart';
import 'package:inkpage_reader/core/engine/js/js_rule_async_wrapper.dart';
import 'package:inkpage_reader/core/models/book_source.dart';

import '../../../test_helper.dart';

void main() {
  setupTestDI();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsExtensions bridge completeness', () {
    JavascriptRuntime? runtime;
    Object? runtimeError;

    setUp(() {
      runtimeError = null;
      try {
        runtime = getJavascriptRuntime();
      } catch (error) {
        runtime = null;
        runtimeError = error;
      }
    });

    tearDown(() {
      runtime?.dispose();
    });

    test('java bridge exposes missing helper methods', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      expect(
        runtime!.evaluate('typeof java.base64Decode').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.md5Encode16').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.hexEncodeToString').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.hexDecodeToString').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.randomUUID').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.timeFormat').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.timeFormatUTC').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.toNumChapter').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.cacheFile').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.importScript').stringResult,
        'function',
      );
      expect(runtime!.evaluate('typeof java.head').stringResult, 'function');
      expect(
        runtime!.evaluate('typeof java.webViewGetSource').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.webViewGetOverrideUrl').stringResult,
        'function',
      );
    });

    test('java.log returns the original value like Legado', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        var logged = java.log("bridge-value");
        logged;
      ''');

      expect(result.stringResult, 'bridge-value');
    });

    test('cookie and cache bridges are exposed', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      expect(runtime!.evaluate('typeof cookie.set').stringResult, 'function');
      expect(
        runtime!.evaluate('typeof cookie.remove').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof cookie.getCookie').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof cookie.setCookie').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof cookie.removeCookie').stringResult,
        'function',
      );
      expect(runtime!.evaluate('typeof cache.get').stringResult, 'function');
      expect(
        runtime!.evaluate('typeof cache.getFile').stringResult,
        'function',
      );
      expect(runtime!.evaluate('typeof cache.put').stringResult, 'function');
      expect(
        runtime!.evaluate('typeof cache.putFile').stringResult,
        'function',
      );
    });

    test('source bridge is exposed when source exists', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(
        runtime!,
        source: BookSource(
          bookSourceUrl: 'https://example.com',
          bookSourceName: 'Example',
        ),
      );
      ext.inject();

      expect(
        runtime!.evaluate('typeof source.getLoginInfo').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof source.getKey').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof source.getVariable').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof source.setVariable').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof source.getHeaderMap').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof source.putLoginInfo').stringResult,
        'function',
      );
      expect(runtime!.evaluate('typeof source.put').stringResult, 'function');
      expect(runtime!.evaluate('typeof source.get').stringResult, 'function');
    });

    test('Jsoup shim supports importClass and select text helpers', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        importClass(org.jsoup.Jsoup);
        var doc = Jsoup.parse('<div class="introduce">简介</div><div class="text-row">标签1</div><div class="text-row">标签2</div>');
        doc.select('.introduce').text() + '|' + doc.select('.text-row:eq(0)').text();
      ''');

      expect(result.stringResult, '简介|标签1');
    });

    test('Jsoup shim supports select().first().attr()', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        importClass(org.jsoup.Jsoup);
        var doc = Jsoup.parse('<div><a href="/chapter/1">第一章</a><a href="/chapter/2">第二章</a></div>');
        doc.select('a').first().attr('href');
      ''');

      expect(result.stringResult, '/chapter/1');
    });

    test('Jsoup shim supports data() and remove() mutations', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        importClass(org.jsoup.Jsoup);
        var doc = Jsoup.parse('<style>.hide:nth-last-child(2){display:none}</style><div class="hide">X</div><div class="show">Y</div>');
        var selector = String(doc.select("style").first().data()).replace(/{display:none}/g, ",").slice(0, -1);
        doc.select(selector).remove();
        doc.html();
      ''');

      expect(result.stringResult.contains('>X<'), isFalse);
      expect(result.stringResult.contains('>Y<'), isTrue);
    });

    test('Jsoup shim preserves middle nodes for nth-child removals', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        importClass(org.jsoup.Jsoup);
        var doc = Jsoup.parse('<style>.list>li:nth-child(1){display:none}.list>li:nth-last-child(1){display:none}</style><ul class="list"><li>A</li><li>B</li><li>C</li></ul>');
        var selector = String(doc.select("style").first().data()).replace(/{display:none}/g, ",").slice(0, -1);
        doc.select(selector).remove();
        doc.html();
      ''');

      expect(result.stringResult.contains('>A<'), isFalse);
      expect(result.stringResult.contains('>B<'), isTrue);
      expect(result.stringResult.contains('>C<'), isFalse);
    });

    test('JavaImporter shim supports Base64 and GZIP decode loops', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();
      final payload = base64Encode(gzip.encode(utf8.encode('解压成功')));

      final result = runtime!.evaluate('''
        var payload = "$payload";
        var javaImport = new JavaImporter();
        javaImport.importPackage(
          Packages.java.lang,
          Packages.java.io,
          Packages.java.util,
          Packages.java.util.zip
        );
        with(javaImport) {
          function decode(content) {
            var decoded = Base64.getDecoder().decode(String(content));
            var output = new ByteArrayOutputStream();
            var input = new ByteArrayInputStream(decoded);
            var gzipInput = new GZIPInputStream(input);
            var buffer = String(" ").getBytes();
            while (true) {
              var read = gzipInput.read(buffer);
              if (read > 0) {
                output.write(buffer, 0, read);
              } else {
                return output.toString();
              }
            }
          }
          decode(payload);
        }
      ''');

      expect(result.stringResult, '解压成功');
    });

    test('Java String getBytes returns a writable buffer', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        var javaImport = new JavaImporter();
        javaImport.importPackage(Packages.java.lang);
        with(javaImport) {
          String(" ").getBytes().length;
        }
      ''');

      expect(result.stringResult, '1');
    });

    test(
      'java.gzipToString accepts byte arrays from base64DecodeToByteArray',
      () {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }
        final ext = JsExtensions(runtime!);
        ext.inject();
        final payload = base64Encode(gzip.encode(utf8.encode('解压成功')));

        final result = runtime!.evaluate('''
        var payload = "$payload";
        java.gzipToString(java.base64DecodeToByteArray(payload), "UTF-8");
      ''');

        expect(result.stringResult, '解压成功');
      },
    );

    test('java.base64Encode supports byte arrays', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        var javaImport = new JavaImporter();
        javaImport.importPackage(Packages.java.lang);
        with(javaImport) {
          java.base64Encode(String("hello").getBytes());
        }
      ''');

      expect(result.stringResult, 'aGVsbG8=');
    });

    test('String.replaceAll follows Legado Java regex semantics', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        var javaImport = new JavaImporter();
        javaImport.importPackage(Packages.java.lang);
        with(javaImport) {
          "abc123".replaceAll("[a-z]+", "") + "|" +
          String("第12章").replaceAll("\\d+", "#");
        }
      ''');

      expect(result.stringResult, '123|第#章');
    });

    test('global unpack helper decodes packed source tokens', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        unpack('0("1 2");', 3, 3, ['alert', 'hello', 'world']);
      ''');

      expect(result.stringResult, 'alert("hello world");');
    });

    test(
      'java.aesBase64DecodeToString helper matches symmetric crypto output',
      () {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }
        final ext = JsExtensions(runtime!);
        ext.inject();

        final result = runtime!.evaluate(r'''
        var key = "1234567890123456";
        var iv = "6543210987654321";
        var crypto = java.createSymmetricCrypto("AES/CBC/PKCS5Padding", key, iv);
        var encoded = crypto.encryptBase64("hello");
        java.aesBase64DecodeToString(encoded, key, "AES/CBC/PKCS5Padding", iv);
      ''');

        expect(result.stringResult, 'hello');
      },
    );

    test(
      'JavaImporter shim supports javax crypto, Arrays.copyOfRange, and digestHex',
      () {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }
        final ext = JsExtensions(runtime!);
        ext.inject();

        final result = runtime!.evaluate(r'''
        var javaImport = new JavaImporter();
        javaImport.importPackage(
          Packages.java.lang,
          Packages.java.util,
          Packages.javax.crypto.spec,
          Packages.javax.crypto
        );
        with(javaImport) {
          var keyBytes = String("1234567890123456").getBytes();
          var ivBytes = String("6543210987654321").getBytes();
          var prefix = String(Arrays.copyOfRange(keyBytes, 0, 3)).toString();
          var parsed = Integer.parseInt("ff", 16);
          var digest = java.digestHex("hello", "sha-256");

          var encrypted = java.base64DecodeToByteArray(
            java.createSymmetricCrypto("AES/CBC/PKCS5Padding", "1234567890123456", "6543210987654321")
              .encryptBase64("hello")
          );
          var decryptCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
          decryptCipher.init(2, SecretKeySpec(keyBytes, "AES"), IvParameterSpec(ivBytes));
          var plain = String(decryptCipher.doFinal(encrypted)).toString();

          prefix + "|" + parsed + "|" + digest.length() + "|" + plain;
        }
      ''');

        expect(result.stringResult, '123|255|64|hello');
      },
    );

    test(
      'Cipher.doFinal decrypts large byte arrays without corrupting payloads',
      () {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }
        final ext = JsExtensions(runtime!);
        ext.inject();

        final result = runtime!.evaluate(r'''
        var javaImport = new JavaImporter();
        javaImport.importPackage(
          Packages.java.lang,
          Packages.java.util,
          Packages.javax.crypto.spec,
          Packages.javax.crypto
        );
        with(javaImport) {
          var prefix = '{"book":[';
          var suffix = '],"ok":true}';
          var filler = "章节内容".repeat(20000);
          var plainText = prefix + JSON.stringify({ title: "深空彼岸", body: filler }) + suffix;
          var keyBytes = String("12345678901234561234567890123456").getBytes();
          var ivBytes = String("6543210987654321").getBytes();

          var encrypted = java.base64DecodeToByteArray(
            java.createSymmetricCrypto(
              "AES/CBC/PKCS5Padding",
              keyBytes,
              ivBytes
            ).encryptBase64(plainText)
          );

          var decryptCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
          decryptCipher.init(2, SecretKeySpec(keyBytes, "AES"), IvParameterSpec(ivBytes));
          var decoded = String(decryptCipher.doFinal(encrypted)).toString();

          decoded.length + "|" + decoded.substring(0, 8) + "|" + decoded.substring(decoded.length - 11);
        }
      ''');

        final parts = result.stringResult.split('|');
        expect(parts.length, 3);
        expect(int.tryParse(parts[0]), isNotNull);
        expect(parts[1], '{"book":');
        expect(parts[2], ',"ok":true}');
      },
    );

    test(
      'Cipher.doFinal matches createSymmetricCrypto for signed byte key material',
      () {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }
        final ext = JsExtensions(runtime!);
        ext.inject();

        final result = runtime!.evaluate(r'''
        function intToByte(i) {
          var b = i & 0xFF;
          if (b >= 128) {
            return -1 * (128 - (b % 128));
          }
          return b;
        }

        var javaImport = new JavaImporter();
        javaImport.importPackage(
          Packages.java.lang,
          Packages.java.util,
          Packages.javax.crypto.spec,
          Packages.javax.crypto
        );
        with(javaImport) {
          var prefix = "T2CP9CY7FAQIBEZW";
          var suffix = "PE3PHV5A4NVHZ73W";
          var sha = java.digestHex(prefix, "sha-256").toString();
          var md5 = java.md5Encode(suffix).toString();
          var keyBytes = [];
          for (var i = 0; i < sha.length; i += 2) {
            keyBytes.push(intToByte(Integer.parseInt(sha.substring(i, i + 2), 16)));
          }
          var suffixBytes = String(suffix).getBytes();
          var md5Bytes = String(md5).getBytes();
          var ivBytes = [];
          for (var j = 0; j < 16; j++) {
            ivBytes[j] = (md5Bytes[j] ^ suffixBytes[j]) ^ (-1);
          }

          var plain = '{"book":[{"title":"深空彼岸"}],"ok":true}';
          var encrypted = java.base64DecodeToByteArray(
            java.createSymmetricCrypto("AES/CBC/PKCS5Padding", keyBytes, ivBytes)
              .encryptBase64(plain)
          );

          var decryptCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
          decryptCipher.init(2, SecretKeySpec(keyBytes, "AES"), IvParameterSpec(ivBytes));
          String(decryptCipher.doFinal(encrypted)).toString();
        }
      ''');

        expect(result.stringResult, '{"book":[{"title":"深空彼岸"}],"ok":true}');
      },
    );

    test('java.toNumChapter matches Legado chapter numbering helper', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        java.toNumChapter("第十二章 归来");
      ''');

      expect(result.stringResult, '第12章 归来');
    });

    test(
      'async java.ajax results support chained Java-style replaceAll rules',
      () async {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }
        final ext = JsExtensions(runtime!);
        ext.inject();
        runtime!.evaluate(
          'java.ajax = function() { '
          '  return Promise.resolve(\'<style>gone</style><p>正文</p>\'); '
          '}; '
          'var baseUrl = "https://fqbook.cc/read-61918.html"; '
          'var result = \'<script>var url="_getcontent.php?id=61918&v=test-token"</script>\';',
        );

        final rewritten = AsyncJsRewriter.rewrite(r'''
java.ajax(baseUrl.replace('read-', '_getcontent.php?id=').replace('.html','&v=' + result.match(/&v=(.*?)"/)[1])).replaceAll('<style.*style>','').replaceAll('<([^<]*?)class(.*?)</(.*?)>','')
''');
        final (callId, future) = ext.registerRuleCall();
        final wrapped = JsRuleAsyncWrapper.wrap(rewritten, callId);

        final evalResult = runtime!.evaluate(wrapped);
        expect(evalResult.isError, isFalse, reason: evalResult.stringResult);
        runtime!.executePendingJob();

        final resolved = await future;
        expect(resolved, '<p>正文</p>');
      },
    );

    test('java.connect wraps responses with raw request url parity', () async {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();
      runtime!.evaluate(r'''
        __asyncCall = function(channel, payload) {
          if (channel !== 'connect') {
            return Promise.reject(new Error('unexpected channel: ' + channel));
          }
          return Promise.resolve({
            body: 'OK',
            url: 'https://canonical.example/e/search/result/index.php?searchid=42',
            requestUrl: 'http://m.666biquge.com',
            code: 200,
            message: 'OK',
            headers: {},
            redirects: ['https://canonical.example/e/search/result/index.php?searchid=42']
          });
        };
      ''');

      final rewritten = AsyncJsRewriter.rewrite(r'''
        var res = java.connect("http://m.666biquge.com");
        [
          res.raw().request().url(),
          res.url(),
          String(res.code()),
          String(res.statusCode()),
          String(res.isSuccessful())
        ].join("|")
      ''');
      final (callId, future) = ext.registerRuleCall();
      final wrapped = JsRuleAsyncWrapper.wrap(rewritten, callId);

      final evalResult = runtime!.evaluate(wrapped);
      expect(evalResult.isError, isFalse, reason: evalResult.stringResult);
      runtime!.executePendingJob();

      final resolved = await future;
      expect(
        resolved,
        'https://canonical.example/e/search/result/index.php?searchid=42|'
        'https://canonical.example/e/search/result/index.php?searchid=42|'
        '200|200|true',
      );
    });

    test('java.connect normalizes bare-origin raw request urls with slash', () async {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();
      runtime!.evaluate(r'''
        __asyncCall = function(channel, payload) {
          if (channel !== 'connect') {
            return Promise.reject(new Error('unexpected channel: ' + channel));
          }
          return Promise.resolve({
            body: '',
            url: 'http://m.666biquge.com',
            requestUrl: 'http://m.666biquge.com',
            code: 200,
            message: 'OK',
            headers: {},
            redirects: []
          });
        };
      ''');

      final rewritten = AsyncJsRewriter.rewrite(r'''
        java.connect("http://m.666biquge.com").raw().request().url() + "modules/article/waps.php"
      ''');
      final (callId, future) = ext.registerRuleCall();
      final wrapped = JsRuleAsyncWrapper.wrap(rewritten, callId);

      final evalResult = runtime!.evaluate(wrapped);
      expect(evalResult.isError, isFalse, reason: evalResult.stringResult);
      runtime!.executePendingJob();

      final resolved = await future;
      expect(resolved, 'http://m.666biquge.com/modules/article/waps.php');
    });
  });
}
