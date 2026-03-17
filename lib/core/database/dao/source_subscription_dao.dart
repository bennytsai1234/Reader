import 'package:legado_reader/core/models/source_subscription.dart';
import 'drift_compat_dao.dart';
import '../app_database.dart';

/// SourceSubscriptionDao - 書源訂閱操作 (對標 Android SourceSubscriptionDao.kt)
class SourceSubscriptionDao extends DriftCompatDao<SourceSubscription> {
  SourceSubscriptionDao(AppDatabase appDatabase) : super(appDatabase, 'source_subscriptions');

  /// 獲取所有訂閱 (對標 Android: all)
  Future<List<SourceSubscription>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: '`order` ASC',
    );
    return maps.map((m) => SourceSubscription.fromJson(m)).toList();
  }

  /// 插入或更新訂閱 (UPSERT)
  Future<void> upsert(SourceSubscription sub) async {
    await insertOrUpdate(sub.toJson());
  }

  /// 插入別名，兼容舊代碼
  Future<void> insertOrUpdateSub(SourceSubscription sub) => upsert(sub);

  /// 根據 URL 刪除
  Future<void> deleteByUrl(String url) async {
    await deleteRows('url = ?', [url]);
  }

  /// 批量更新排序
  Future<void> updateOrder(List<SourceSubscription> subs) async {
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (int i = 0; i < subs.length; i++) {
        batch.update(
          tableName,
          {'`order`': i},
          where: 'url = ?',
          whereArgs: [subs[i].url],
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
