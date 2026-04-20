import 'package:get_it/get_it.dart';
import 'package:flutter_js/flutter_js.dart';
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

  JavascriptRuntime? runtime;
  try {
    runtime = getJavascriptRuntime();
    _quickJsUnavailableReasonCache = '';
    return null;
  } catch (error) {
    final reason = 'QuickJS runtime unavailable: $error';
    _quickJsUnavailableReasonCache = reason;
    return reason;
  } finally {
    runtime?.dispose();
  }
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
