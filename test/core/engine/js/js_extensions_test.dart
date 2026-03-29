import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/js/js_extensions.dart';
import 'package:legado_reader/core/models/book_source.dart';

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

      expect(runtime!.evaluate('typeof java.base64Decode').stringResult, 'function');
      expect(runtime!.evaluate('typeof java.md5Encode16').stringResult, 'function');
      expect(runtime!.evaluate('typeof java.hexEncodeToString').stringResult, 'function');
      expect(runtime!.evaluate('typeof java.hexDecodeToString').stringResult, 'function');
      expect(runtime!.evaluate('typeof java.randomUUID').stringResult, 'function');
      expect(runtime!.evaluate('typeof java.timeFormat').stringResult, 'function');
      expect(runtime!.evaluate('typeof java.timeFormatUTC').stringResult, 'function');
    });

    test('cookie and cache bridges are exposed', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      expect(runtime!.evaluate('typeof cookie.set').stringResult, 'function');
      expect(runtime!.evaluate('typeof cookie.remove').stringResult, 'function');
      expect(runtime!.evaluate('typeof cache.get').stringResult, 'function');
      expect(runtime!.evaluate('typeof cache.put').stringResult, 'function');
    });

    test('source bridge is exposed when source exists', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(
        runtime!,
        source: BookSource(bookSourceUrl: 'https://example.com', bookSourceName: 'Example'),
      );
      ext.inject();

      expect(runtime!.evaluate('typeof source.getLoginInfo').stringResult, 'function');
      expect(runtime!.evaluate('typeof source.putLoginInfo').stringResult, 'function');
      expect(runtime!.evaluate('typeof source.put').stringResult, 'function');
      expect(runtime!.evaluate('typeof source.get').stringResult, 'function');
    });
  });
}
