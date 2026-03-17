import 'drift_compat_dao.dart';
import '../app_database.dart';

/// SearchHistory - 搜尋歷史模型 (對標 Android SearchKeyword)
class SearchHistory {
  final int? id;
  final String keyword;
  final int searchTime;

  SearchHistory({this.id, required this.keyword, required this.searchTime});

  Map<String, dynamic> toJson() => {
    'id': id,
    'keyword': keyword,
    'searchTime': searchTime,
  };

  factory SearchHistory.fromJson(Map<String, dynamic> json) => SearchHistory(
    id: json['id'],
    keyword: json['keyword'],
    searchTime: json['searchTime'],
  );
}

/// SearchHistoryDao - SQLite 實作 (對標 Android SearchKeywordDao.kt)
class SearchHistoryDao extends DriftCompatDao<SearchHistory> {
  SearchHistoryDao(AppDatabase appDatabase) : super(appDatabase, 'search_history');

  /// 獲取所有搜尋紀錄 (對標 Android: getRecent)
  Future<List<SearchHistory>> getRecent() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'searchTime DESC',
      limit: 20, // 限制獲取最近的 20 條
    );
    return maps.map((m) => SearchHistory.fromJson(m)).toList();
  }

  /// 獲取所有紀錄別名
  Future<List<SearchHistory>> getAll() => getRecent();

  /// 插入搜尋紀錄 (對標 Android: add)
  Future<void> add(String keyword) async {
    final history = SearchHistory(
      keyword: keyword,
      searchTime: DateTime.now().millisecondsSinceEpoch,
    );
    await insertOrUpdate(history.toJson());
  }

  /// 插入別名，兼容舊代碼
  Future<void> addKeyword(String keyword) => add(keyword);

  /// 刪除指定紀錄
  Future<void> deleteKeyword(String keyword) async {
    await deleteRows('keyword = ?', [keyword]);
  }

  /// 清空所有紀錄 (對標 Android: deleteAll)
  Future<void> deleteAll() async {
    await clearAll();
  }

  /// 刪除過期紀錄 (對標 Android: deleteOld)
  Future<void> clearOld(int timeLimit) async {
    await deleteRows('searchTime < ?', [timeLimit]);
  }

  /// 清空別名
  Future<int> clearAll() => super.clearAll();
}
