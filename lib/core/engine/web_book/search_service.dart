import 'dart:async';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/engine/web_book/web_book_service.dart';
import 'package:legado_reader/core/database/dao/search_book_dao.dart';
import 'package:legado_reader/core/di/injection.dart';

/// SearchService - 多書源並行搜尋服務 (原 Android model/webBook/SearchModel.kt)
class SearchService {
  final List<SearchBook> _searchBooks = [];
  StreamController<List<SearchBook>>? _controller;
  
  bool _isSearching = false;
  String _searchKey = '';

  Stream<List<SearchBook>> get searchStream => _controller?.stream ?? const Stream.empty();

  Future<void> search(List<BookSource> sources, String key, {int page = 1}) async {
    if (_isSearching && page == 1) {
      await stopSearch();
    }

    _searchKey = key;
    _isSearching = true;

    if (page == 1) {
      _searchBooks.clear();
      _controller?.close();
      _controller = StreamController<List<SearchBook>>.broadcast();
    }

    final tasks = <Future>[];
    for (final source in sources) {
      tasks.add(_searchSingleSource(source, key, page));
    }

    Future.wait(tasks).then((_) {
      _isSearching = false;
    });
  }

  Future<void> _searchSingleSource(BookSource source, String key, int page) async {
    try {
      final results = await WebBook.searchBookAwait(
        source, 
        key, 
        page: page,
      );

      if (results.isNotEmpty) {
        _mergeResults(results);
        _controller?.add(List.from(_searchBooks));
        
        await getIt<SearchBookDao>().insertList(results);
      }
    } catch (e) {
      AppLog.e('Search failed for ${source.bookSourceName}: $e', error: e);
    }
  }

  void _mergeResults(List<SearchBook> newResults) {
    for (var newBook in newResults) {
      final index = _searchBooks.indexWhere((b) => b.name == newBook.name && b.author == newBook.author);
      if (index != -1) {
        _searchBooks[index].addOrigin(newBook.origin);
      } else {
        _searchBooks.add(newBook);
      }
    }
    
    _searchBooks.sort((a, b) {
      final aEqual = a.name == _searchKey || a.author == _searchKey;
      final bEqual = b.name == _searchKey || b.author == _searchKey;
      if (aEqual && !bEqual) return -1;
      if (!aEqual && bEqual) return 1;
      
      return b.origins.length.compareTo(a.origins.length);
    });
  }

  Future<void> stopSearch() async {
    _isSearching = false;
  }

  void dispose() {
    _controller?.close();
  }
}
