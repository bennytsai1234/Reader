import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:inkpage_reader/core/database/dao/cookie_dao.dart';
import 'package:inkpage_reader/core/database/dao/cache_dao.dart';
import 'package:inkpage_reader/core/models/cookie.dart';
import 'package:inkpage_reader/core/models/cache.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCookieDao extends Fake implements CookieDao {
  @override
  Future<Cookie?> getByUrl(String url) async => null;

  @override
  Future<void> upsert(Cookie cookie) async {}

  @override
  Future<void> deleteByUrl(String url) async {}
}

class FakeCacheDao extends Fake implements CacheDao {
  @override
  Future<Cache?> get(String key) async => null;

  @override
  Future<void> upsert(Cache cache) async {}

  @override
  Future<void> deleteByKey(String key) async {}
}

String? _quickJsUnavailableReasonCache;

String? quickJsUnavailableReason() {
  final cached = _quickJsUnavailableReasonCache;
  if (cached != null) {
    return cached.isEmpty ? null : cached;
  }

  final explicitPath = Platform.environment['LIBQUICKJSC_TEST_PATH']?.trim();
  if (explicitPath != null && explicitPath.isNotEmpty) {
    if (File(explicitPath).existsSync()) {
      _quickJsUnavailableReasonCache = '';
      return null;
    }
    final reason =
        'QuickJS runtime unavailable: LIBQUICKJSC_TEST_PATH does not exist ($explicitPath)';
    _quickJsUnavailableReasonCache = reason;
    return reason;
  }

  final ldLibraryPath = Platform.environment['LD_LIBRARY_PATH']?.trim();
  if (ldLibraryPath != null && ldLibraryPath.isNotEmpty) {
    final libFound = ldLibraryPath
        .split(':')
        .where((part) => part.isNotEmpty)
        .any((dir) {
          return File('$dir/libquickjs_c_bridge_plugin.so').existsSync();
        });
    if (libFound) {
      _quickJsUnavailableReasonCache = '';
      return null;
    }
  }

  if (!Platform.isLinux) {
    _quickJsUnavailableReasonCache = '';
    return null;
  }

  final reason =
      'QuickJS runtime unavailable: set LIBQUICKJSC_TEST_PATH or use tool/flutter_test_with_quickjs.sh';
  _quickJsUnavailableReasonCache = reason;
  return reason;
}

void setupTestDI() {
  final getIt = GetIt.instance;
  if (!getIt.isRegistered<CookieDao>()) {
    getIt.registerLazySingleton<CookieDao>(() => FakeCookieDao());
  }
  if (!getIt.isRegistered<CacheDao>()) {
    getIt.registerLazySingleton<CacheDao>(() => FakeCacheDao());
  }
}
