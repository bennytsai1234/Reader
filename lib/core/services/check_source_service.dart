import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/exception/app_exception.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/event_bus.dart';

class SourceCheckEntry {
  final String sourceUrl;
  final String sourceName;
  final String stage;
  final String message;
  final SourceRuntimeHealth health;

  const SourceCheckEntry({
    required this.sourceUrl,
    required this.sourceName,
    required this.stage,
    required this.message,
    required this.health,
  });

  bool get isHealthy => health.category == SourceHealthCategory.healthy;
  bool get cleanupCandidate => health.cleanupCandidate;
}

class SourceCheckReport {
  final List<SourceCheckEntry> entries;

  const SourceCheckReport(this.entries);

  static const empty = SourceCheckReport(<SourceCheckEntry>[]);

  int get total => entries.length;
  int get healthyCount => entries.where((entry) => entry.isHealthy).length;
  int get affectedCount => total - healthyCount;
  int get cleanupCandidateCount =>
      entries.where((entry) => entry.cleanupCandidate).length;
  int get quarantinedCount =>
      entries.where((entry) => entry.health.quarantined).length;

  List<SourceCheckEntry> get affectedEntries =>
      entries.where((entry) => !entry.isHealthy).toList();

  List<SourceCheckEntry> get cleanupCandidates =>
      entries.where((entry) => entry.cleanupCandidate).toList();

  List<String> get cleanupCandidateUrls =>
      cleanupCandidates.map((entry) => entry.sourceUrl).toList();

  bool get hasEntries => entries.isNotEmpty;

  String get summary =>
      '可用 $healthyCount / 需處理 $affectedCount / 建議清理 $cleanupCandidateCount';
}

/// CheckSourceService - 書源校驗服務
/// 參考 legado CheckSourceService，以 group/comment 持久化校驗結果，
/// 讓來源管理、搜尋池與執行期策略共用同一套狀態。
class CheckSourceService extends ChangeNotifier {
  final BookSourceService _service;
  final BookSourceDao _sourceDao;
  final AppEventBus _eventBus;

  AppEventBus get eventBus => _eventBus;

  bool _isChecking = false;
  int _totalCount = 0;
  int _currentCount = 0;
  String _statusMsg = '';
  SourceCheckReport _lastReport = SourceCheckReport.empty;

  CheckSourceService({
    BookSourceService? service,
    BookSourceDao? sourceDao,
    AppEventBus? eventBus,
  }) : _service = service ?? BookSourceService(),
       _sourceDao = sourceDao ?? getIt<BookSourceDao>(),
       _eventBus = eventBus ?? AppEventBus();

  bool get isChecking => _isChecking;
  int get totalCount => _totalCount;
  int get currentCount => _currentCount;
  String get statusMsg => _statusMsg;
  SourceCheckReport get lastReport => _lastReport;
  bool get hasLastReport => _lastReport.hasEntries;

  void _postLog(String msg) {
    _eventBus.fire(AppEvent(AppEventBus.checkSource, data: msg));
  }

  Future<SourceCheckReport> check(List<String> urls) async {
    if (_isChecking) return _lastReport;

    _isChecking = true;
    _totalCount = urls.length;
    _currentCount = 0;
    _statusMsg = '準備校驗';
    _lastReport = SourceCheckReport.empty;
    _postLog('開始校驗，共 $_totalCount 個書源');
    notifyListeners();

    const maxConcurrent = 5;
    final tasks = <Future<void>>[];
    final queue = List<String>.from(urls);
    final entries = <SourceCheckEntry>[];

    while (queue.isNotEmpty || tasks.isNotEmpty) {
      if (!_isChecking) break;

      while (queue.isNotEmpty && tasks.length < maxConcurrent) {
        final url = queue.removeAt(0);
        final task = _checkSingleSource(url).then((entry) {
          if (entry != null) {
            entries.add(entry);
          }
          _currentCount++;
          notifyListeners();
        });
        tasks.add(task);
        task.whenComplete(() => tasks.remove(task));
      }
      if (tasks.isNotEmpty) {
        await Future.wait(List<Future<void>>.from(tasks));
      }
    }

    _isChecking = false;
    _lastReport = SourceCheckReport(entries);
    _statusMsg = _lastReport.summary;
    _postLog('校驗完成：${_lastReport.summary}');
    _eventBus.fire(AppEvent(AppEventBus.checkSourceDone, data: _lastReport));
    notifyListeners();
    return _lastReport;
  }

  Future<SourceCheckEntry?> _checkSingleSource(String url) async {
    final source = await _sourceDao.getByUrl(url);
    if (source == null) return null;

    _statusMsg = '正在校驗: ${source.bookSourceName}';
    _postLog('⇒ 正在校驗 [${source.bookSourceName}] ...');
    notifyListeners();

    source.removeInvalidGroups();
    source.removeErrorComment();
    source.respondTime = 0;
    source.lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

    final preflight = _resolvePreflightStatus(source);
    if (preflight != null) {
      await _persistStatus(source, preflight.health, preflight.message);
      return preflight;
    }

    var stage = 'search';
    try {
      final searchWord = source.getCheckKeyword('我的');
      _postLog('  ◇ 測試搜尋: $searchWord');
      final searchResults = await _service
          .searchBooks(source, searchWord)
          .timeout(const Duration(seconds: 15));

      if (searchResults.isEmpty) {
        return await _markAndPersist(
          source,
          stage: stage,
          health: const SourceRuntimeHealth(
            category: SourceHealthCategory.searchBroken,
            label: searchBrokenSourceGroupTag,
            description: '搜尋沒有結果',
            allowsSearch: false,
            allowsReading: true,
            cleanupCandidate: false,
            quarantined: false,
          ),
          message: '搜尋結果為空 ($searchWord)',
        );
      }

      var book = searchResults.first.toBook().copyWith(
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
        originOrder: source.customOrder,
      );

      stage = 'detail';
      _postLog('  ◇ 測試詳情: ${book.name}');
      book = await _service
          .getBookInfo(source, book)
          .timeout(const Duration(seconds: 10));
      if (book.name.trim().isEmpty || book.bookUrl.trim().isEmpty) {
        return await _markAndPersist(
          source,
          stage: stage,
          health: const SourceRuntimeHealth(
            category: SourceHealthCategory.detailBroken,
            label: detailBrokenSourceGroupTag,
            description: '詳情頁無法正常解析',
            allowsSearch: false,
            allowsReading: false,
            cleanupCandidate: false,
            quarantined: true,
          ),
          message: '詳情頁返回空資料',
        );
      }

      stage = 'toc';
      _postLog('  ◇ 測試目錄: ${book.name}');
      final chapters = await _service
          .getChapterList(source, book)
          .timeout(const Duration(seconds: 10));
      final readableChapters =
          chapters.where((chapter) => !chapter.isVolume).toList();
      if (readableChapters.isEmpty) {
        final health =
            looksLikeDownloadOnlySource(book, readableChapters)
                ? const SourceRuntimeHealth(
                  category: SourceHealthCategory.downloadOnly,
                  label: downloadOnlySourceGroupTag,
                  description: '來源只提供下載，不提供線上正文閱讀',
                  allowsSearch: false,
                  allowsReading: false,
                  cleanupCandidate: true,
                  quarantined: false,
                )
                : const SourceRuntimeHealth(
                  category: SourceHealthCategory.tocBroken,
                  label: tocBrokenSourceGroupTag,
                  description: '目錄抓取失敗或沒有可閱讀章節',
                  allowsSearch: false,
                  allowsReading: false,
                  cleanupCandidate: false,
                  quarantined: true,
                );
        final message =
            health.category == SourceHealthCategory.downloadOnly
                ? '來源為下載站，不提供線上目錄'
                : '目錄抓取失敗或沒有可閱讀章節';
        return await _markAndPersist(
          source,
          stage: stage,
          health: health,
          message: message,
        );
      }

      if (looksLikeDownloadOnlySource(book, readableChapters)) {
        return await _markAndPersist(
          source,
          stage: stage,
          health: const SourceRuntimeHealth(
            category: SourceHealthCategory.downloadOnly,
            label: downloadOnlySourceGroupTag,
            description: '來源只提供下載，不提供線上正文閱讀',
            allowsSearch: false,
            allowsReading: false,
            cleanupCandidate: true,
            quarantined: false,
          ),
          message: '來源為下載站，不提供線上正文',
        );
      }

      final firstChapter = readableChapters.first;
      final nextChapterUrl = _nextReadableChapterUrl(
        readableChapters,
        firstChapter,
      );

      stage = 'content';
      _postLog('  ◇ 測試正文: ${firstChapter.title}');
      final content = await _service
          .getContent(
            source,
            book,
            firstChapter,
            nextChapterUrl: nextChapterUrl,
          )
          .timeout(const Duration(seconds: 10));

      if (looksLikeLoginRequiredContent(content)) {
        return await _markAndPersist(
          source,
          stage: stage,
          health: const SourceRuntimeHealth(
            category: SourceHealthCategory.loginRequired,
            label: loginRequiredSourceGroupTag,
            description: '來源需要登入後才能閱讀',
            allowsSearch: false,
            allowsReading: false,
            cleanupCandidate: true,
            quarantined: false,
          ),
          message: '正文需要登入後閱讀',
        );
      }

      if (!looksReadable(content)) {
        return await _markAndPersist(
          source,
          stage: stage,
          health: const SourceRuntimeHealth(
            category: SourceHealthCategory.contentBroken,
            label: contentBrokenSourceGroupTag,
            description: '正文內容過短或為空',
            allowsSearch: false,
            allowsReading: false,
            cleanupCandidate: false,
            quarantined: true,
          ),
          message: '正文內容過短或為空',
        );
      }

      await _persistStatus(source, SourceRuntimeHealth.healthy, '');
      _postLog('  ✓ [${source.bookSourceName}] 校驗成功');
      return SourceCheckEntry(
        sourceUrl: source.bookSourceUrl,
        sourceName: source.bookSourceName,
        stage: 'done',
        message: '校驗成功',
        health: SourceRuntimeHealth.healthy,
      );
    } on LoginCheckException catch (error) {
      return _markFromException(
        source,
        stage: stage,
        error: error,
        fallbackMessage: error.message,
      );
    } on TimeoutException catch (error) {
      return _markFromException(
        source,
        stage: stage,
        error: error,
        fallbackMessage: '校驗超時',
      );
    } catch (error) {
      return _markFromException(
        source,
        stage: stage,
        error: error,
        fallbackMessage: error.toString(),
      );
    }
  }

  Future<SourceCheckEntry> _markFromException(
    BookSource source, {
    required String stage,
    required Object error,
    required String fallbackMessage,
  }) async {
    final normalized = error.toString().toLowerCase();
    final message = _compactMessage(fallbackMessage);
    AppLog.e(
      'CheckSource Error [${source.bookSourceName}] stage=$stage: $error',
      error: error,
    );

    if (error is LoginCheckException ||
        normalized.contains('需要登入後閱讀') ||
        normalized.contains('需要登录后阅读') ||
        normalized.contains('loginrequired') ||
        normalized.contains('permissionlimit')) {
      return _markAndPersist(
        source,
        stage: stage,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.loginRequired,
          label: loginRequiredSourceGroupTag,
          description: '來源需要登入後才能閱讀',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: true,
          quarantined: false,
        ),
        message: message,
      );
    }

    if (_looksLikeTimeout(normalized)) {
      return _markAndPersist(
        source,
        stage: stage,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.upstreamUnstable,
          label: quarantineSourceGroupTag,
          description: '上游暫時不可用，來源先隔離但不視為永久失效',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: false,
          quarantined: true,
        ),
        message: '校驗超時或來源響應過慢',
      );
    }

    if (_looksLikeBlockedUpstream(normalized)) {
      return _markAndPersist(
        source,
        stage: stage,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.upstreamUnstable,
          label: quarantineSourceGroupTag,
          description: '上游暫時不可用，來源先隔離但不視為永久失效',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: false,
          quarantined: true,
        ),
        message: message,
      );
    }

    if (stage == 'search') {
      return _markAndPersist(
        source,
        stage: stage,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.searchBroken,
          label: searchBrokenSourceGroupTag,
          description: '搜尋規則已失效',
          allowsSearch: false,
          allowsReading: true,
          cleanupCandidate: false,
          quarantined: false,
        ),
        message: message,
      );
    }

    if (stage == 'detail') {
      return _markAndPersist(
        source,
        stage: stage,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.detailBroken,
          label: detailBrokenSourceGroupTag,
          description: '詳情頁無法正常解析',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: false,
          quarantined: true,
        ),
        message: message,
      );
    }

    if (stage == 'toc') {
      return _markAndPersist(
        source,
        stage: stage,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.tocBroken,
          label: tocBrokenSourceGroupTag,
          description: '目錄抓取失敗或沒有可閱讀章節',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: false,
          quarantined: true,
        ),
        message: message,
      );
    }

    return _markAndPersist(
      source,
      stage: stage,
      health: const SourceRuntimeHealth(
        category: SourceHealthCategory.contentBroken,
        label: contentBrokenSourceGroupTag,
        description: '正文抓取失敗或無法閱讀',
        allowsSearch: false,
        allowsReading: false,
        cleanupCandidate: false,
        quarantined: true,
      ),
      message: message,
    );
  }

  Future<SourceCheckEntry> _markAndPersist(
    BookSource source, {
    required String stage,
    required SourceRuntimeHealth health,
    required String message,
  }) async {
    await _persistStatus(source, health, message);
    _postLog('  ✕ [${source.bookSourceName}] ${health.label}: $message');
    return SourceCheckEntry(
      sourceUrl: source.bookSourceUrl,
      sourceName: source.bookSourceName,
      stage: stage,
      message: message,
      health: source.runtimeHealth,
    );
  }

  Future<void> _persistStatus(
    BookSource source,
    SourceRuntimeHealth health,
    String message,
  ) async {
    source.removeInvalidGroups();
    source.removeErrorComment();
    source.respondTime = 0;
    source.lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

    switch (health.category) {
      case SourceHealthCategory.healthy:
        break;
      case SourceHealthCategory.nonNovel:
        source.addGroup(nonNovelSourceGroupTag);
        break;
      case SourceHealthCategory.loginRequired:
        source.addGroup(loginRequiredSourceGroupTag);
        break;
      case SourceHealthCategory.downloadOnly:
        source.addGroup(downloadOnlySourceGroupTag);
        break;
      case SourceHealthCategory.searchBroken:
        source.addGroup(searchBrokenSourceGroupTag);
        break;
      case SourceHealthCategory.detailBroken:
        source.addGroup(
          '$detailBrokenSourceGroupTag,$quarantineSourceGroupTag',
        );
        break;
      case SourceHealthCategory.tocBroken:
        source.addGroup('$tocBrokenSourceGroupTag,$quarantineSourceGroupTag');
        break;
      case SourceHealthCategory.contentBroken:
        source.addGroup(
          '$contentBrokenSourceGroupTag,$quarantineSourceGroupTag',
        );
        break;
      case SourceHealthCategory.upstreamUnstable:
        source.addGroup(
          '$upstreamBlockedSourceGroupTag,$timeoutSourceGroupTag,$quarantineSourceGroupTag',
        );
        break;
    }

    if (message.trim().isNotEmpty) {
      source.addErrorComment(message.trim());
    }
    await _sourceDao.upsert(source);
  }

  SourceCheckEntry? _resolvePreflightStatus(BookSource source) {
    if (!source.isNovelTextSource) {
      return SourceCheckEntry(
        sourceUrl: source.bookSourceUrl,
        sourceName: source.bookSourceName,
        stage: 'filter',
        message: '來源不是純文字小說書源',
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.nonNovel,
          label: nonNovelSourceGroupTag,
          description: '來源不是純文字小說書源',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: true,
          quarantined: false,
        ),
      );
    }

    if (source.bookSourceType != 0) {
      return SourceCheckEntry(
        sourceUrl: source.bookSourceUrl,
        sourceName: source.bookSourceName,
        stage: 'filter',
        message: '來源不提供純文字正文',
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.downloadOnly,
          label: downloadOnlySourceGroupTag,
          description: '來源不提供純文字正文',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: true,
          quarantined: false,
        ),
      );
    }

    return null;
  }

  void cancel() {
    _isChecking = false;
    notifyListeners();
  }

  String? _nextReadableChapterUrl(
    List<BookChapter> chapters,
    BookChapter currentChapter,
  ) {
    final startIndex = chapters.indexOf(currentChapter);
    if (startIndex < 0) return null;

    for (var i = startIndex + 1; i < chapters.length; i++) {
      final chapter = chapters[i];
      if (!chapter.isVolume && chapter.url.isNotEmpty) {
        return chapter.url;
      }
    }
    return null;
  }
}

String _compactMessage(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return '未知錯誤';
  }
  final firstLine = trimmed.split('\n').first.trim();
  return firstLine.length > 160 ? firstLine.substring(0, 160) : firstLine;
}

bool _looksLikeTimeout(String normalized) {
  return normalized.contains('timeout') ||
      normalized.contains('timed out') ||
      normalized.contains('socketexception') ||
      normalized.contains('handshakeexception') ||
      normalized.contains('ssl') ||
      normalized.contains('receivetimeout') ||
      normalized.contains('future not completed');
}

bool _looksLikeBlockedUpstream(String normalized) {
  return normalized.contains(' 401') ||
      normalized.contains(' 403') ||
      normalized.contains(' 404') ||
      normalized.contains(' 429') ||
      normalized.contains(' 502') ||
      normalized.contains(' 503') ||
      normalized.contains('forbidden') ||
      normalized.contains('cloudflare') ||
      normalized.contains('certificate_verify_failed');
}

bool looksReadable(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('加載章節失敗')) return false;
  if (trimmed.startsWith('章節內容為空')) return false;
  return trimmed.runes.length >= 20;
}

bool looksLikeLoginRequiredContent(String content) {
  final normalized = content.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.contains('permissionlimit') ||
      normalized.contains('loginrequired') ||
      normalized.contains('需要登入') ||
      normalized.contains('需要登录') ||
      normalized.contains('登入後閱讀') ||
      normalized.contains('登录后阅读') ||
      normalized.contains('請先登錄') ||
      normalized.contains('请先登录');
}

bool looksLikeDownloadOnlySource(
  Book book,
  List<BookChapter> readableChapters,
) {
  if (book.origin.isEmpty) return false;
  final urls = <String>[
    book.bookUrl.trim().toLowerCase(),
    book.tocUrl.trim().toLowerCase(),
    if (readableChapters.isNotEmpty)
      readableChapters.first.url.trim().toLowerCase(),
  ];
  const downloadUrlMarkers = <String>[
    'downbook.php',
    '/download/',
    'downajax',
    '.zip',
    '.rar',
    '.epub',
    '.txt',
  ];
  return urls.any(
    (url) => downloadUrlMarkers.any((marker) => url.contains(marker)),
  );
}
