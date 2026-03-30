import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/source/book_source_logic.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'book_source_service.dart';
import 'event_bus.dart';
import 'package:legado_reader/core/di/injection.dart';

/// CheckSourceService - 書源校驗服務
/// (原 Android service/CheckSourceService.kt)
class CheckSourceService extends ChangeNotifier {
  static final CheckSourceService _instance = CheckSourceService._internal();
  factory CheckSourceService() => _instance;

  final BookSourceService _service = BookSourceService();
  final BookSourceDao _sourceDao = getIt<BookSourceDao>();
  final AppEventBus _eventBus = AppEventBus();

  AppEventBus get eventBus => _eventBus;

  bool _isChecking = false;
  int _totalCount = 0;
  int _currentCount = 0;
  String _statusMsg = '';

  CheckSourceService._internal();

  bool get isChecking => _isChecking;
  int get totalCount => _totalCount;
  int get currentCount => _currentCount;
  String get statusMsg => _statusMsg;

  /// 發送詳細日誌 (原 Android postLog)
  void _postLog(String msg) {
    _eventBus.fire(AppEvent(AppEventBus.checkSource, data: msg));
  }

  /// 開始校驗選中的書源 (原 Android check 邏輯)
  Future<void> check(List<String> urls) async {
    if (_isChecking) return;
    
    _isChecking = true;
    _totalCount = urls.length;
    _currentCount = 0;
    _postLog('開始校驗，共 $_totalCount 個書源');
    notifyListeners();

    // 實作併發控制 (預設 5 個併發)
    const maxConcurrent = 5;
    final tasks = <Future>[];
    final queue = List<String>.from(urls);

    while (queue.isNotEmpty || tasks.isNotEmpty) {
      if (!_isChecking) break; // 支援取消

      while (queue.isNotEmpty && tasks.length < maxConcurrent) {
        final url = queue.removeAt(0);
        final task = _checkSingleSource(url).then((_) {
          _currentCount++;
          notifyListeners();
        });
        tasks.add(task);
        // 移除已完成的 task
        task.then((_) => tasks.remove(task));
      }
      if (tasks.isNotEmpty) {
        await Future.wait(List.from(tasks));
      }
    }

    _isChecking = false;
    _statusMsg = '校驗完成';
    _postLog('所有校驗任務已結束');
    _eventBus.fire(AppEvent(AppEventBus.checkSourceDone));
    notifyListeners();
  }

  /// 單個書源深度校驗 (原 Android checkSource)
  Future<void> _checkSingleSource(String url) async {
    final source = await _sourceDao.getByUrl(url);
    if (source == null) return;

    _statusMsg = '正在校驗: ${source.bookSourceName}';
    _postLog('⇒ 正在校驗 [${source.bookSourceName}] ...');
    notifyListeners();

    try {
      // 1. 移除舊的錯誤標記與註釋
      source.removeGroup('搜尋失效');
      source.removeGroup('目錄失效');
      source.removeGroup('正文失效');
      source.removeGroup('校驗超時');
      source.removeGroup('網站失效');
      source.removeErrorComment();

      final stopwatch = Stopwatch()..start();

      // 2. 測試搜尋 (Search Check)
      final searchWord = source.getCheckKeyword('我的');
      _postLog('  ◇ 正在測試搜尋: $searchWord');
      final searchResults = await _service.searchBooks(source, searchWord).timeout(const Duration(seconds: 15));
      
      if (searchResults.isEmpty) {
        _postLog('  └ 搜尋結果為空');
        source.addGroup('搜尋失效');
        source.addErrorComment('搜尋結果為空 ($searchWord)');
      } else {
        _postLog('  └ 搜尋成功，找到 ${searchResults.length} 本書');
        // 3. 測試詳情與目錄 (Info & TOC Check)
        final firstBook = searchResults.first;
        _postLog('  ◇ 正在測試獲取詳情與目錄: ${firstBook.name}');
        
        final book = Book(
          bookUrl: firstBook.bookUrl,
          origin: source.bookSourceUrl,
          name: firstBook.name,
        );
        
        final chapters = await _service.getChapterList(source, book).timeout(const Duration(seconds: 10));
        
        if (chapters.isEmpty) {
          _postLog('  └ 目錄抓取失敗或為空');
          source.addGroup('目錄失效');
          source.addErrorComment('目錄抓取失敗或為空');
        } else {
          _postLog('  └ 目錄抓取成功，共 ${chapters.length} 章');
          // 4. 測試正文 (Content Check)
          final firstChapter = chapters.firstWhere((c) => (c.title.length > 1), orElse: () => chapters.first);
          _postLog('  ◇ 正在測試獲取正文: ${firstChapter.title}');
          
          final content = await _service.getContent(source, book, firstChapter).timeout(const Duration(seconds: 10));
          
          if (content.isEmpty || content.length < 10) {
            _postLog('  └ 正文內容過短或為空');
            source.addGroup('正文失效');
            source.addErrorComment('正文內容過短或為空');
          } else {
            _postLog('  └ 正文抓取成功 (長度: ${content.length})');
          }
        }
      }

      stopwatch.stop();
      source.respondTime = stopwatch.elapsedMilliseconds;
      source.lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
      _postLog('  ✓ [${source.bookSourceName}] 校驗成功 (耗時: ${source.respondTime}ms)');
      
      // 更新書源狀態
      await _sourceDao.upsert(source);
    } on TimeoutException {
      _postLog('  ✕ [${source.bookSourceName}] 校驗超時');
      source.addGroup('校驗超時');
      source.addErrorComment('校驗超時');
      await _sourceDao.upsert(source);
    } catch (e) {
      _postLog('  ✕ [${source.bookSourceName}] 發生錯誤: $e');
      AppLog.e('CheckSource Error [${source.bookSourceName}]: $e', error: e);
      source.addGroup('網站失效');
      source.addErrorComment('網路發生錯誤: $e');
      await _sourceDao.upsert(source);
    }
  }

  void cancel() {
    _isChecking = false;
    notifyListeners();
  }
}


