import 'dart:async';
import 'package:legado_reader/core/models/cookie.dart';
import '../app_database.dart';

/// CookieDao - SQLite 實作 (對標 Android CookieDao.kt)
class CookieDao extends BaseDao<Cookie> {
  CookieDao(AppDatabase appDatabase) : super(appDatabase, 'cookies');

  /// 根據 URL 獲取 Cookie (對標 Android: getCookie)
  Future<Cookie?> getByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Cookie.fromJson(maps.first);
  }

  /// 獲取所有包含 '|' 的 OkHttp Cookies
  Future<List<Cookie>> getOkHttpCookies() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: "url LIKE '%|%'",
    );
    return maps.map((m) => Cookie.fromJson(m)).toList();
  }

  /// 插入或更新 Cookie (UPSERT)
  Future<void> upsert(Cookie cookie) async {
    await insertOrUpdate(cookie.toJson());
  }

  /// 插入或更新別名，兼容舊代碼
  Future<void> insertOrUpdateCookie(Cookie cookie) => upsert(cookie);

  /// 根據 URL 刪除 Cookie
  Future<void> deleteByUrl(String url) async {
    await delete('url = ?', [url]);
  }

  /// 刪除所有包含 '|' 的 OkHttp Cookies
  Future<void> deleteOkHttp() async {
    await delete("url LIKE '%|%'");
  }

  /// 清空所有 Cookie
  Future<void> deleteAll() async {
    await clear();
  }
}
