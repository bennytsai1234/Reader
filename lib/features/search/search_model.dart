import 'dart:async';
import 'package:dio/dio.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/engine/web_book/web_book_service.dart';
import 'package:inkpage_reader/core/database/dao/search_book_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:pool/pool.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/search_scope.dart';

/// SearchModel - 多書源並行搜尋引擎
/// (對標 Legado model/webBook/SearchModel.kt)
///
/// 純邏輯層，不依賴 Flutter UI。
/// 透過 [SearchModelCallback] 回報搜尋進度與結果。
class SearchModel {
  final SearchModelCallback callback;

  List<SearchBook> _searchBooks = [];
  CancelToken? _cancelToken;
  bool _isCancelled = false;
  int _failedCount = 0;
  int _completedCount = 0;
  int _totalCount = 0;
  String _currentSourceName = '';

  SearchModel({required this.callback});

  int get failedCount => _failedCount;
  int get completedCount => _completedCount;
  int get totalCount => _totalCount;
  String get currentSourceName => _currentSourceName;
  double get progress =>
      _totalCount == 0 ? 0 : (_completedCount / _totalCount).clamp(0.0, 1.0);

  /// 執行搜尋
  Future<void> search({
    required String key,
    required SearchScope scope,
    required bool precisionSearch,
  }) async {
    // 取消先前搜尋
    cancelSearch();

    _isCancelled = false;
    _searchBooks = [];
    _failedCount = 0;
    _completedCount = 0;
    _cancelToken = CancelToken();

    callback.onSearchStart();

    // 取得搜尋範圍內的書源
    final sources = await scope.getBookSources();
    _totalCount = sources.length;

    if (sources.isEmpty) {
      callback.onSearchFinish(isEmpty: true);
      return;
    }

    // 取得並行數
    final threadCount = await SharedPreferences.getInstance().then(
      (p) => p.getInt('thread_count') ?? 8,
    );
    final searchPool = Pool(threadCount);

    final tasks = <Future<void>>[];
    for (final source in sources) {
      if (_isCancelled) break;
      tasks.add(
        searchPool.withResource(() async {
          if (_isCancelled) return;
          await _searchSingleSource(source, key, precisionSearch);
        }),
      );
    }

    await Future.wait(tasks);

    if (!_isCancelled) {
      callback.onSearchFinish(isEmpty: _searchBooks.isEmpty);
    }
  }

  Future<void> _searchSingleSource(
    BookSource source,
    String key,
    bool precisionSearch,
  ) async {
    if (_isCancelled) return;

    _currentSourceName = source.bookSourceName;
    callback.onSearchProgress(
      currentSource: _currentSourceName,
      completed: _completedCount,
      total: _totalCount,
      failed: _failedCount,
    );

    try {
      if (_isCancelled) return;

      final books = await WebBook.searchBookAwait(
        source,
        key,
        cancelToken: _cancelToken,
      ).timeout(const Duration(seconds: 30));

      if (_isCancelled) return;

      // 精準搜尋過濾
      final filteredBooks =
          precisionSearch
              ? books.where((b) => b.name == key || b.author == key).toList()
              : books;

      if (filteredBooks.isNotEmpty) {
        // 持久化到搜尋快取
        await getIt<SearchBookDao>().insertList(filteredBooks);
        // 合併結果
        _mergeItems(filteredBooks, key, precisionSearch);
        callback.onSearchSuccess(List.from(_searchBooks));
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      _failedCount++;
      AppLog.e('搜尋失敗 [${source.bookSourceName}]: $e', error: e);
    } catch (e) {
      _failedCount++;
      AppLog.e('搜尋失敗 [${source.bookSourceName}]: $e', error: e);
    } finally {
      _completedCount++;
      callback.onSearchProgress(
        currentSource: _currentSourceName,
        completed: _completedCount,
        total: _totalCount,
        failed: _failedCount,
      );
    }
  }

  /// 合併搜尋結果 — 三級排序 (對標 Legado SearchModel.mergeItems)
  ///
  /// 排序優先級：
  /// 1. 完全匹配（書名或作者 == 搜尋關鍵字）
  /// 2. 包含匹配（書名或作者包含搜尋關鍵字）
  /// 3. 其他結果（非精準搜尋時才保留）
  ///
  /// 每級內部按來源數量降序排列。
  void _mergeItems(
    List<SearchBook> newBooks,
    String searchKey,
    bool precision,
  ) {
    // 分類現有結果
    final equalData = <SearchBook>[];
    final containsData = <SearchBook>[];
    final otherData = <SearchBook>[];

    for (final book in _searchBooks) {
      if (book.name == searchKey || book.author == searchKey) {
        equalData.add(book);
      } else if ((book.name.contains(searchKey)) ||
          (book.author?.contains(searchKey) ?? false)) {
        containsData.add(book);
      } else {
        otherData.add(book);
      }
    }

    // 合併新結果
    for (final newBook in newBooks) {
      final isEqual = newBook.name == searchKey || newBook.author == searchKey;
      final isContains =
          !isEqual &&
          ((newBook.name.contains(searchKey)) ||
              (newBook.author?.contains(searchKey) ?? false));

      if (isEqual) {
        _mergeIntoList(equalData, newBook);
      } else if (isContains) {
        _mergeIntoList(containsData, newBook);
      } else if (!precision) {
        _mergeIntoList(otherData, newBook);
      }
    }

    // 排序並合併
    equalData.sort((a, b) => b.origins.length.compareTo(a.origins.length));
    containsData.sort((a, b) => b.origins.length.compareTo(a.origins.length));

    final result = <SearchBook>[];
    result.addAll(equalData);
    result.addAll(containsData);
    if (!precision) {
      result.addAll(otherData);
    }

    _searchBooks = result;
  }

  /// 將新書合併到指定列表中（相同名+作者則合併來源，否則新增）
  void _mergeIntoList(List<SearchBook> list, SearchBook newBook) {
    final index = list.indexWhere(
      (b) => b.name == newBook.name && b.author == newBook.author,
    );
    if (index != -1) {
      list[index].addOrigin(newBook.origin, name: newBook.originName);
    } else {
      list.add(newBook);
    }
  }

  /// 取消搜尋
  void cancelSearch() {
    _isCancelled = true;
    _cancelToken?.cancel('搜尋取消');
    _cancelToken = null;
  }

  void dispose() {
    cancelSearch();
  }
}

/// 搜尋引擎回調介面
abstract class SearchModelCallback {
  void onSearchStart();
  void onSearchSuccess(List<SearchBook> searchBooks);
  void onSearchFinish({required bool isEmpty});
  void onSearchProgress({
    required String currentSource,
    required int completed,
    required int total,
    required int failed,
  });
}
