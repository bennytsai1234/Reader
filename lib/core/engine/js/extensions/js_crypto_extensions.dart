import 'dart:io' show gzip;
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:uuid/uuid.dart';
import '../js_extensions.dart';
import '../js_encode_utils.dart';

extension JsCryptoExtensions on JsExtensions {
  void injectCryptoExtensions() {
    // 實作 java.createSymmetricCrypto
    runtime.onMessage('symmetricCrypto', (dynamic args) {
      final action = args[0].toString();
      final transformation = args[1].toString();
      final key = args[2];
      final iv = args[3];
      final data = args[4];
      final outputFormat = args[5].toString();

      return JsEncodeUtils.symmetricCrypto(
        action,
        transformation,
        key,
        iv,
        data,
        outputFormat: outputFormat,
      );
    });

    // 注入輔助函式
    runtime.onMessage(
      '_md5Encode',
      (dynamic args) => JsEncodeUtils.md5Encode(args.toString()),
    );
    runtime.onMessage(
      '_md5Encode16',
      (dynamic args) => JsEncodeUtils.md5Encode16(args.toString()),
    );
    runtime.onMessage(
      '_base64Encode',
      (dynamic args) => JsEncodeUtils.base64Encode(args.toString()),
    );
    runtime.onMessage('_base64Decode', (dynamic args) {
      final str = args is List ? args[0].toString() : args.toString();
      final charset =
          args is List && args.length > 1 ? args[1].toString() : 'UTF-8';
      return JsEncodeUtils.base64Decode(str, charset: charset);
    });
    runtime.onMessage('_base64DecodeToBytes', (dynamic args) {
      final payload = _decodeArgs(args);
      final str =
          payload is List ? payload.first.toString() : payload.toString();
      return jsonEncode(JsEncodeUtils.base64DecodeToBytes(str).toList());
    });
    runtime.onMessage(
      '_hexEncode',
      (dynamic args) => hex.encode(utf8.encode(args.toString())),
    );
    runtime.onMessage(
      '_hexDecode',
      (dynamic args) => utf8.decode(hex.decode(args.toString())),
    );
    runtime.onMessage('_randomUUID', (dynamic args) => const Uuid().v4());
    runtime.onMessage('_gunzipBytes', (dynamic args) {
      final payload = _decodeArgs(args);
      final bytesSource =
          payload is List && payload.every((item) => item is num)
              ? payload
              : (payload is List ? payload.first : payload);
      final bytes = List<int>.from(bytesSource as List);
      return jsonEncode(gzip.decode(bytes));
    });
  }

  dynamic _decodeArgs(dynamic args) {
    if (args is String) {
      try {
        return jsonDecode(args);
      } catch (_) {
        return args;
      }
    }
    return args;
  }
}
