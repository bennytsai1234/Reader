import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/engine/explore_url_parser.dart';
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

class SourceCheckLogEntry {
  final DateTime time;
  final String message;

  const SourceCheckLogEntry({required this.time, required this.message});

  String get formattedTime =>
      '[${_twoDigits(time.hour)}:${_twoDigits(time.minute)}:${_twoDigits(time.second)}.${_threeDigits(time.millisecond)}]';
}

class SourceCheckProgress {
  final String sourceName;
  final String message;
  final bool isFinal;
  final bool hasIssue;

  const SourceCheckProgress({
    required this.sourceName,
    required this.message,
    required this.isFinal,
    required this.hasIssue,
  });
}

class SourceCheckConfig {
  final String keyword;
  final int timeoutSeconds;
  final bool checkSearch;
  final bool checkDiscovery;
  final bool checkInfo;
  final bool checkCategory;
  final bool checkContent;

  const SourceCheckConfig({
    required this.keyword,
    required this.timeoutSeconds,
    required this.checkSearch,
    required this.checkDiscovery,
    required this.checkInfo,
    required this.checkCategory,
    required this.checkContent,
  });

  static const SourceCheckConfig defaults = SourceCheckConfig(
    keyword: '我的',
    timeoutSeconds: 15,
    checkSearch: true,
    checkDiscovery: true,
    checkInfo: true,
    checkCategory: true,
    checkContent: true,
  );

  factory SourceCheckConfig.fromPreferences(SharedPreferences prefs) {
    return SourceCheckConfig(
      keyword:
          prefs.getString(PreferKey.checkSourceKeyword) ?? defaults.keyword,
      timeoutSeconds:
          prefs.getInt(PreferKey.checkSourceTimeout) ?? defaults.timeoutSeconds,
      checkSearch:
          prefs.getBool(PreferKey.checkSourceSearch) ?? defaults.checkSearch,
      checkDiscovery:
          prefs.getBool(PreferKey.checkSourceDiscovery) ??
          defaults.checkDiscovery,
      checkInfo: prefs.getBool(PreferKey.checkSourceInfo) ?? defaults.checkInfo,
      checkCategory:
          prefs.getBool(PreferKey.checkSourceCategory) ??
          defaults.checkCategory,
      checkContent:
          prefs.getBool(PreferKey.checkSourceContent) ?? defaults.checkContent,
    ).normalized();
  }

  SourceCheckConfig copyWith({
    String? keyword,
    int? timeoutSeconds,
    bool? checkSearch,
    bool? checkDiscovery,
    bool? checkInfo,
    bool? checkCategory,
    bool? checkContent,
  }) {
    return SourceCheckConfig(
      keyword: keyword ?? this.keyword,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      checkSearch: checkSearch ?? this.checkSearch,
      checkDiscovery: checkDiscovery ?? this.checkDiscovery,
      checkInfo: checkInfo ?? this.checkInfo,
      checkCategory: checkCategory ?? this.checkCategory,
      checkContent: checkContent ?? this.checkContent,
    );
  }

  SourceCheckConfig normalized() {
    var normalizedSearch = checkSearch;
    var normalizedDiscovery = checkDiscovery;
    if (!normalizedSearch && !normalizedDiscovery) {
      normalizedSearch = true;
    }

    var normalizedInfo = checkInfo;
    var normalizedCategory = checkCategory;
    var normalizedContent = checkContent;
    if (!normalizedInfo) {
      normalizedCategory = false;
      normalizedContent = false;
    } else if (!normalizedCategory) {
      normalizedContent = false;
    }

    final trimmedKeyword =
        keyword.trim().isEmpty ? defaults.keyword : keyword.trim();
    final normalizedTimeout = timeoutSeconds < 1 ? 1 : timeoutSeconds;
    return SourceCheckConfig(
      keyword: trimmedKeyword,
      timeoutSeconds: normalizedTimeout,
      checkSearch: normalizedSearch,
      checkDiscovery: normalizedDiscovery,
      checkInfo: normalizedInfo,
      checkCategory: normalizedCategory,
      checkContent: normalizedContent,
    );
  }

  Duration get timeoutDuration => Duration(seconds: timeoutSeconds);

  /// Upper bound for one source check.
  ///
  /// Stage-level checks still use [timeoutDuration]. This budget prevents a
  /// single source from occupying a worker for the full sum of every stage.
  Duration get sourceTimeoutDuration {
    final activeFlows = (checkSearch ? 1 : 0) + (checkDiscovery ? 1 : 0);
    final stageBudget =
        activeFlows +
        (checkInfo ? activeFlows : 0) +
        (checkCategory ? activeFlows : 0) +
        (checkContent ? activeFlows : 0);
    final multiplier = math.max(2, math.min(stageBudget, 6));
    final seconds = math.min(timeoutSeconds * multiplier, 90);
    return Duration(seconds: math.max(timeoutSeconds, seconds));
  }

  String get summary {
    final parts = <String>[
      if (checkSearch) '搜尋',
      if (checkDiscovery) '發現',
      if (checkInfo) '詳情',
      if (checkCategory) '目錄',
      if (checkContent) '正文',
    ];
    return '超時 ${timeoutSeconds}s · ${parts.join('/')}';
  }
}

class _SourceCheckIssue {
  final String stage;
  final String message;
  final SourceRuntimeHealth health;

  const _SourceCheckIssue({
    required this.stage,
    required this.message,
    required this.health,
  });
}

enum _SourceCheckMode { search, discovery }

extension on _SourceCheckMode {
  String get label => this == _SourceCheckMode.search ? '搜尋' : '發現';
}

/// CheckSourceService - 書源校驗服務
/// 參考 legado CheckSourceService，以 group/comment 持久化校驗結果，
/// 讓來源管理、搜尋池與執行期策略共用同一套狀態。
class CheckSourceService extends ChangeNotifier {
  static const int _validationPageConcurrency = 1;
  static const int _sourceCheckConcurrency = 6;
  static const Duration _notifyThrottleInterval = Duration(milliseconds: 120);
  final BookSourceService _service;
  final BookSourceDao _sourceDao;
  final AppEventBus _eventBus;

  AppEventBus get eventBus => _eventBus;

  bool _isChecking = false;
  int _totalCount = 0;
  int _currentCount = 0;
  String _statusMsg = '';
  SourceCheckReport _lastReport = SourceCheckReport.empty;
  SourceCheckConfig _config = SourceCheckConfig.defaults;
  final List<SourceCheckLogEntry> _logs = <SourceCheckLogEntry>[];
  final Map<String, SourceCheckProgress> _sourceProgress =
      <String, SourceCheckProgress>{};
  final Set<String> _timedOutSourceUrls = <String>{};
  Timer? _notifyTimer;
  bool _isDisposed = false;

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
  SourceCheckConfig get config => _config;
  UnmodifiableListView<SourceCheckLogEntry> get logs =>
      UnmodifiableListView<SourceCheckLogEntry>(_logs);
  UnmodifiableMapView<String, SourceCheckProgress> get sourceProgress =>
      UnmodifiableMapView<String, SourceCheckProgress>(_sourceProgress);

  SourceCheckProgress? progressOf(String sourceUrl) =>
      _sourceProgress[sourceUrl];

  Future<void> loadConfig() async {
    final prefs = await _safeGetPreferences();
    if (prefs == null) return;
    _config = SourceCheckConfig.fromPreferences(prefs);
    _notifyIfAlive();
  }

  Future<void> updateConfig(SourceCheckConfig next) async {
    final normalized = next.normalized();
    _config = normalized;
    final prefs = await _safeGetPreferences();
    if (prefs != null) {
      await prefs.setString(PreferKey.checkSourceKeyword, normalized.keyword);
      await prefs.setInt(
        PreferKey.checkSourceTimeout,
        normalized.timeoutSeconds,
      );
      await prefs.setBool(PreferKey.checkSourceSearch, normalized.checkSearch);
      await prefs.setBool(
        PreferKey.checkSourceDiscovery,
        normalized.checkDiscovery,
      );
      await prefs.setBool(PreferKey.checkSourceInfo, normalized.checkInfo);
      await prefs.setBool(
        PreferKey.checkSourceCategory,
        normalized.checkCategory,
      );
      await prefs.setBool(
        PreferKey.checkSourceContent,
        normalized.checkContent,
      );
      await prefs.setString(PreferKey.checkSource, normalized.summary);
    }
    _notifyIfAlive();
  }

  Future<SourceCheckReport> check(List<String> urls) async {
    if (_isChecking) return _lastReport;

    final normalizedUrls = LinkedHashSet<String>.from(
      urls.map((url) => url.trim()).where((url) => url.isNotEmpty),
    ).toList(growable: false);
    final config = _config.normalized();
    _isChecking = true;
    _totalCount = normalizedUrls.length;
    _currentCount = 0;
    _statusMsg = '準備校驗';
    _lastReport = SourceCheckReport.empty;
    _logs.clear();
    _sourceProgress.clear();
    _timedOutSourceUrls.clear();
    _appendLog('開始校驗，共 $_totalCount 個書源 (${config.summary})');
    _notifyIfAlive();

    final entries = <SourceCheckEntry>[];
    var nextIndex = 0;
    final workerCount = math.min(
      _sourceCheckConcurrency,
      math.max(1, normalizedUrls.length),
    );

    Future<void> worker() async {
      while (_isChecking) {
        final cursor = nextIndex;
        if (cursor >= normalizedUrls.length) break;
        nextIndex = cursor + 1;
        final url = normalizedUrls[cursor];

        try {
          final entry = await _checkSingleSourceWithBudget(url, config);
          if (entry != null) {
            entries.add(entry);
          }
        } catch (error, stack) {
          AppLog.e('書源校驗任務失敗: $url', error: error, stackTrace: stack);
          final entry = await _recordUnexpectedSourceFailure(url, error);
          if (entry != null) {
            entries.add(entry);
          }
        } finally {
          _currentCount++;
          _notifyIfAlive();
        }
      }
    }

    await Future.wait(List.generate(workerCount, (_) => worker()));

    if (!_isChecking) {
      _appendLog('校驗已取消，已完成 $_currentCount / $_totalCount');
    }

    _isChecking = false;
    _lastReport = SourceCheckReport(entries);
    _statusMsg = _lastReport.summary;
    _appendLog('校驗完成：${_lastReport.summary}');
    _eventBus.fire(AppEvent(AppEventBus.checkSourceDone, data: _lastReport));
    _notifyIfAlive();
    return _lastReport;
  }

  Future<SourceCheckEntry?> _checkSingleSourceWithBudget(
    String url,
    SourceCheckConfig config,
  ) {
    return _checkSingleSource(url, config).timeout(
      config.sourceTimeoutDuration,
      onTimeout: () => _recordSourceTimeout(url, config),
    );
  }

  Future<SourceCheckEntry?> _recordSourceTimeout(
    String url,
    SourceCheckConfig config,
  ) async {
    if (_isDisposed || !_isChecking) return null;
    _timedOutSourceUrls.add(url);
    final source = await _sourceDao.getByUrl(url);
    if (source == null) return null;

    final message =
        '整體校驗超時 (${config.sourceTimeoutDuration.inSeconds}s)，已停止此書源後續步驟';
    const health = SourceRuntimeHealth(
      category: SourceHealthCategory.upstreamUnstable,
      label: timeoutSourceGroupTag,
      description: '來源響應過慢或上游阻擋，先隔離避免拖慢批次校驗',
      allowsSearch: false,
      allowsReading: false,
      cleanupCandidate: false,
      quarantined: true,
    );

    await _persistStatus(source, health, message, force: true);
    _appendLog(
      '  ✕ [${source.bookSourceName}] $message',
      sourceUrl: url,
      force: true,
    );
    _setSourceProgress(
      source,
      message,
      isFinal: true,
      hasIssue: true,
      force: true,
    );
    return SourceCheckEntry(
      sourceUrl: source.bookSourceUrl,
      sourceName: source.bookSourceName,
      stage: 'timeout',
      message: message,
      health: source.runtimeHealth,
    );
  }

  Future<SourceCheckEntry?> _recordUnexpectedSourceFailure(
    String url,
    Object error,
  ) async {
    if (_shouldIgnoreSourceUpdate(url)) return null;
    final source = await _sourceDao.getByUrl(url);
    if (source == null || _shouldIgnoreSourceUpdate(url)) return null;

    final message = _compactMessage(
      error.toString().trim().isEmpty ? '校驗失敗' : error.toString(),
    );
    const health = SourceRuntimeHealth(
      category: SourceHealthCategory.upstreamUnstable,
      label: quarantineSourceGroupTag,
      description: '校驗流程異常，先隔離避免影響其他書源',
      allowsSearch: false,
      allowsReading: false,
      cleanupCandidate: false,
      quarantined: true,
    );

    await _persistStatus(source, health, message);
    _appendLog('  ✕ [${source.bookSourceName}] $message', sourceUrl: url);
    _setSourceProgress(source, message, isFinal: true, hasIssue: true);
    return SourceCheckEntry(
      sourceUrl: source.bookSourceUrl,
      sourceName: source.bookSourceName,
      stage: 'error',
      message: message,
      health: source.runtimeHealth,
    );
  }

  Future<SourceCheckEntry?> _checkSingleSource(
    String url,
    SourceCheckConfig config,
  ) async {
    final source = await _sourceDao.getByUrl(url);
    if (source == null || _shouldIgnoreSourceUpdate(url)) return null;

    _statusMsg = '正在校驗: ${source.bookSourceName}';
    _appendLog('⇒ 正在校驗 [${source.bookSourceName}] ...', sourceUrl: url);
    _setSourceProgress(source, '等待校驗', isFinal: false, hasIssue: false);
    _notifyIfAlive();

    source.removeInvalidGroups();
    source.removeErrorComment();
    source.respondTime = 0;
    source.lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

    final preflight = _resolvePreflightStatus(source);
    if (_shouldIgnoreSourceUpdate(url)) return null;
    if (preflight != null) {
      await _persistStatus(source, preflight.health, preflight.message);
      _appendLog(
        '  ✕ [${source.bookSourceName}] ${preflight.message}',
        sourceUrl: url,
      );
      _setSourceProgress(
        source,
        preflight.message,
        isFinal: true,
        hasIssue: true,
      );
      return preflight;
    }

    final issues = <_SourceCheckIssue>[];

    if (config.checkSearch) {
      await _runSearchCheck(source, config, issues);
      if (_shouldIgnoreSourceUpdate(url)) return null;
    } else {
      _appendLog('  ≡ 跳過搜尋檢查', sourceUrl: url);
    }

    if (config.checkDiscovery) {
      await _runDiscoveryCheck(source, config, issues);
      if (_shouldIgnoreSourceUpdate(url)) return null;
    } else {
      _appendLog('  ≡ 跳過發現檢查', sourceUrl: url);
    }

    if (_shouldIgnoreSourceUpdate(url)) return null;
    if (issues.isEmpty) {
      await _persistStatus(source, SourceRuntimeHealth.healthy, '');
      _appendLog('  ✓ [${source.bookSourceName}] 校驗成功', sourceUrl: url);
      _setSourceProgress(source, '校驗成功', isFinal: true, hasIssue: false);
      return SourceCheckEntry(
        sourceUrl: source.bookSourceUrl,
        sourceName: source.bookSourceName,
        stage: 'done',
        message: '校驗成功',
        health: SourceRuntimeHealth.healthy,
      );
    }

    final primary = _pickPrimaryIssue(issues);
    final mergedMessage = _composeIssueMessage(issues);
    await _persistStatus(
      source,
      primary.health,
      mergedMessage,
      extraHealths: issues
          .where((issue) => !identical(issue, primary))
          .map((issue) => issue.health),
    );
    _appendLog(
      '  ✕ [${source.bookSourceName}] ${source.runtimeHealth.label}: $mergedMessage',
      sourceUrl: url,
    );
    _setSourceProgress(
      source,
      '${source.runtimeHealth.label}: $mergedMessage',
      isFinal: true,
      hasIssue: true,
    );
    return SourceCheckEntry(
      sourceUrl: source.bookSourceUrl,
      sourceName: source.bookSourceName,
      stage: primary.stage,
      message: mergedMessage,
      health: source.runtimeHealth,
    );
  }

  Future<void> _runSearchCheck(
    BookSource source,
    SourceCheckConfig config,
    List<_SourceCheckIssue> issues,
  ) async {
    final searchWord = source.getCheckKeyword(config.keyword);
    final searchUrl = source.searchUrl?.trim() ?? '';
    if (searchUrl.isEmpty) {
      _recordIssue(
        source,
        issues,
        const _SourceCheckIssue(
          stage: 'search',
          message: '搜尋連結規則為空',
          health: SourceRuntimeHealth(
            category: SourceHealthCategory.searchBroken,
            label: searchBrokenSourceGroupTag,
            description: '搜尋規則已失效',
            allowsSearch: false,
            allowsReading: true,
            cleanupCandidate: false,
            quarantined: false,
          ),
        ),
      );
      return;
    }

    _setSourceProgress(
      source,
      '搜尋: $searchWord',
      isFinal: false,
      hasIssue: false,
    );
    _appendLog('  ◇ 測試搜尋: $searchWord', sourceUrl: source.bookSourceUrl);
    try {
      final searchResults = await _service
          .searchBooks(source, searchWord)
          .timeout(config.timeoutDuration);
      if (_shouldIgnoreSourceUpdate(source.bookSourceUrl)) return;
      if (searchResults.isEmpty) {
        _recordIssue(
          source,
          issues,
          _SourceCheckIssue(
            stage: 'search',
            message: '搜尋結果為空 ($searchWord)',
            health: const SourceRuntimeHealth(
              category: SourceHealthCategory.searchBroken,
              label: searchBrokenSourceGroupTag,
              description: '搜尋沒有結果',
              allowsSearch: false,
              allowsReading: true,
              cleanupCandidate: false,
              quarantined: false,
            ),
          ),
        );
        return;
      }

      final seedBook = searchResults.first.toBook().copyWith(
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
        originOrder: source.customOrder,
      );
      await _checkBookFlow(
        source,
        seedBook,
        config: config,
        issues: issues,
        mode: _SourceCheckMode.search,
      );
    } on TimeoutException catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: 'search',
          error: error,
          fallbackMessage: '搜尋超時',
          mode: _SourceCheckMode.search,
        ),
      );
    } catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: 'search',
          error: error,
          fallbackMessage: error.toString(),
          mode: _SourceCheckMode.search,
        ),
      );
    }
  }

  Future<void> _runDiscoveryCheck(
    BookSource source,
    SourceCheckConfig config,
    List<_SourceCheckIssue> issues,
  ) async {
    final exploreUrl = source.exploreUrl?.trim() ?? '';
    if (exploreUrl.isEmpty) {
      _appendLog('  ≡ 跳過發現檢查: 未配置發現網址', sourceUrl: source.bookSourceUrl);
      return;
    }

    _setSourceProgress(source, '發現: 解析入口', isFinal: false, hasIssue: false);
    _appendLog('  ◇ 解析發現規則', sourceUrl: source.bookSourceUrl);
    try {
      final kinds = await ExploreUrlParser.parseAsync(
        exploreUrl,
        source: source,
        jsTimeout: config.timeoutDuration,
      ).timeout(config.timeoutDuration);
      if (_shouldIgnoreSourceUpdate(source.bookSourceUrl)) return;

      String? targetUrl;
      for (final kind in kinds) {
        final candidate = kind.url?.trim();
        if (candidate == null || candidate.isEmpty) {
          continue;
        }
        if (kind.title.startsWith('ERROR:')) {
          continue;
        }
        targetUrl = candidate;
        break;
      }

      if (targetUrl == null || targetUrl.isEmpty) {
        _recordIssue(
          source,
          issues,
          const _SourceCheckIssue(
            stage: 'discovery',
            message: '發現規則為空或沒有可用入口',
            health: SourceRuntimeHealth(
              category: SourceHealthCategory.discoveryBroken,
              label: discoveryBrokenSourceGroupTag,
              description: '發現規則已失效',
              allowsSearch: true,
              allowsReading: true,
              cleanupCandidate: false,
              quarantined: false,
            ),
          ),
        );
        return;
      }

      _setSourceProgress(
        source,
        '發現: $targetUrl',
        isFinal: false,
        hasIssue: false,
      );
      _appendLog('  ◇ 測試發現: $targetUrl', sourceUrl: source.bookSourceUrl);
      final books = await _service
          .exploreBooks(source, targetUrl)
          .timeout(config.timeoutDuration);
      if (_shouldIgnoreSourceUpdate(source.bookSourceUrl)) return;
      if (books.isEmpty) {
        _recordIssue(
          source,
          issues,
          const _SourceCheckIssue(
            stage: 'discovery',
            message: '發現頁沒有結果',
            health: SourceRuntimeHealth(
              category: SourceHealthCategory.discoveryBroken,
              label: discoveryBrokenSourceGroupTag,
              description: '發現規則已失效',
              allowsSearch: true,
              allowsReading: true,
              cleanupCandidate: false,
              quarantined: false,
            ),
          ),
        );
        return;
      }

      final seedBook = books.first.toBook().copyWith(
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
        originOrder: source.customOrder,
      );
      await _checkBookFlow(
        source,
        seedBook,
        config: config,
        issues: issues,
        mode: _SourceCheckMode.discovery,
      );
    } on TimeoutException catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: 'discovery',
          error: error,
          fallbackMessage: '發現檢查超時',
          mode: _SourceCheckMode.discovery,
        ),
      );
    } catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: 'discovery',
          error: error,
          fallbackMessage: error.toString(),
          mode: _SourceCheckMode.discovery,
        ),
      );
    }
  }

  Future<void> _checkBookFlow(
    BookSource source,
    Book seedBook, {
    required SourceCheckConfig config,
    required List<_SourceCheckIssue> issues,
    required _SourceCheckMode mode,
  }) async {
    if (!config.checkInfo) {
      return;
    }

    Book book = seedBook;
    try {
      _setSourceProgress(
        source,
        '${mode.label}詳情: ${book.name}',
        isFinal: false,
        hasIssue: false,
      );
      _appendLog(
        '  ◇ 測試${mode.label}詳情: ${book.name}',
        sourceUrl: source.bookSourceUrl,
      );
      book = await _service
          .getBookInfo(source, book)
          .timeout(config.timeoutDuration);
      if (_shouldIgnoreSourceUpdate(source.bookSourceUrl)) return;
      if (book.name.trim().isEmpty || book.bookUrl.trim().isEmpty) {
        _recordIssue(
          source,
          issues,
          _SourceCheckIssue(
            stage: _stageFor(mode, 'detail'),
            message:
                mode == _SourceCheckMode.search ? '詳情頁返回空資料' : '發現詳情頁返回空資料',
            health: _detailHealthFor(mode),
          ),
        );
        return;
      }
    } on TimeoutException catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: _stageFor(mode, 'detail'),
          error: error,
          fallbackMessage: '${mode.label}詳情檢查超時',
          mode: mode,
        ),
      );
      return;
    } catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: _stageFor(mode, 'detail'),
          error: error,
          fallbackMessage: error.toString(),
          mode: mode,
        ),
      );
      return;
    }

    if (!config.checkCategory) {
      return;
    }

    List<BookChapter> readableChapters;
    try {
      _setSourceProgress(
        source,
        '${mode.label}目錄: ${book.name}',
        isFinal: false,
        hasIssue: false,
      );
      _appendLog(
        '  ◇ 測試${mode.label}目錄: ${book.name}',
        sourceUrl: source.bookSourceUrl,
      );
      final chapters = await _service
          .getChapterList(
            source,
            book,
            pageConcurrency: _validationPageConcurrency,
          )
          .timeout(config.timeoutDuration);
      if (_shouldIgnoreSourceUpdate(source.bookSourceUrl)) return;
      readableChapters =
          chapters.where((chapter) => !chapter.isVolume).toList();
    } on TimeoutException catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: _stageFor(mode, 'toc'),
          error: error,
          fallbackMessage: '${mode.label}目錄檢查超時',
          mode: mode,
        ),
      );
      return;
    } catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: _stageFor(mode, 'toc'),
          error: error,
          fallbackMessage: error.toString(),
          mode: mode,
        ),
      );
      return;
    }

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
              : _tocHealthFor(mode);
      final message =
          health.category == SourceHealthCategory.downloadOnly
              ? '來源為下載站，不提供線上目錄'
              : mode == _SourceCheckMode.search
              ? '目錄抓取失敗或沒有可閱讀章節'
              : '發現書籍目錄抓取失敗或沒有可閱讀章節';
      _recordIssue(
        source,
        issues,
        _SourceCheckIssue(
          stage: _stageFor(mode, 'toc'),
          message: message,
          health: health,
        ),
      );
      return;
    }

    if (looksLikeDownloadOnlySource(book, readableChapters)) {
      _recordIssue(
        source,
        issues,
        _SourceCheckIssue(
          stage: _stageFor(mode, 'toc'),
          message: '來源為下載站，不提供線上正文',
          health: const SourceRuntimeHealth(
            category: SourceHealthCategory.downloadOnly,
            label: downloadOnlySourceGroupTag,
            description: '來源只提供下載，不提供線上正文閱讀',
            allowsSearch: false,
            allowsReading: false,
            cleanupCandidate: true,
            quarantined: false,
          ),
        ),
      );
      return;
    }

    if (!config.checkContent) {
      return;
    }

    final firstChapter = readableChapters.first;
    final nextChapterUrl = _nextReadableChapterUrl(
      readableChapters,
      firstChapter,
    );

    try {
      _setSourceProgress(
        source,
        '${mode.label}正文: ${firstChapter.title}',
        isFinal: false,
        hasIssue: false,
      );
      _appendLog(
        '  ◇ 測試${mode.label}正文: ${firstChapter.title}',
        sourceUrl: source.bookSourceUrl,
      );
      final content = await _service
          .getContent(
            source,
            book,
            firstChapter,
            nextChapterUrl: nextChapterUrl,
            pageConcurrency: _validationPageConcurrency,
          )
          .timeout(config.timeoutDuration);
      if (_shouldIgnoreSourceUpdate(source.bookSourceUrl)) return;

      if (looksLikeLoginRequiredContent(content)) {
        _recordIssue(
          source,
          issues,
          const _SourceCheckIssue(
            stage: 'content',
            message: '正文需要登入後閱讀',
            health: SourceRuntimeHealth(
              category: SourceHealthCategory.loginRequired,
              label: loginRequiredSourceGroupTag,
              description: '來源需要登入後才能閱讀',
              allowsSearch: false,
              allowsReading: false,
              cleanupCandidate: true,
              quarantined: false,
            ),
          ),
        );
        return;
      }

      if (!looksReadable(content)) {
        _recordIssue(
          source,
          issues,
          _SourceCheckIssue(
            stage: _stageFor(mode, 'content'),
            message:
                mode == _SourceCheckMode.search ? '正文內容過短或為空' : '發現書籍正文內容過短或為空',
            health: _contentHealthFor(mode),
          ),
        );
      }
    } on TimeoutException catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: _stageFor(mode, 'content'),
          error: error,
          fallbackMessage: '${mode.label}正文檢查超時',
          mode: mode,
        ),
      );
    } catch (error) {
      _recordIssue(
        source,
        issues,
        _issueFromException(
          stage: _stageFor(mode, 'content'),
          error: error,
          fallbackMessage: error.toString(),
          mode: mode,
        ),
      );
    }
  }

  _SourceCheckIssue _issueFromException({
    required String stage,
    required Object error,
    required String fallbackMessage,
    required _SourceCheckMode mode,
  }) {
    final normalized = error.toString().toLowerCase();
    final message = _compactMessage(fallbackMessage);
    AppLog.e(
      'CheckSource Error stage=$stage mode=${mode.name}: $error',
      error: error,
    );

    if (error is LoginCheckException ||
        normalized.contains('需要登入後閱讀') ||
        normalized.contains('需要登录后阅读') ||
        normalized.contains('loginrequired') ||
        normalized.contains('permissionlimit')) {
      return const _SourceCheckIssue(
        stage: 'content',
        message: '正文需要登入後閱讀',
        health: SourceRuntimeHealth(
          category: SourceHealthCategory.loginRequired,
          label: loginRequiredSourceGroupTag,
          description: '來源需要登入後才能閱讀',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: true,
          quarantined: false,
        ),
      );
    }

    if (_looksLikeTimeout(normalized)) {
      return const _SourceCheckIssue(
        stage: 'timeout',
        message: '校驗超時或來源響應過慢',
        health: SourceRuntimeHealth(
          category: SourceHealthCategory.upstreamUnstable,
          label: quarantineSourceGroupTag,
          description: '上游暫時不可用，來源先隔離但不視為永久失效',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: false,
          quarantined: true,
        ),
      );
    }

    if (_looksLikeBlockedUpstream(normalized)) {
      return _SourceCheckIssue(
        stage: 'upstream',
        message: message,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.upstreamUnstable,
          label: quarantineSourceGroupTag,
          description: '上游暫時不可用，來源先隔離但不視為永久失效',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: false,
          quarantined: true,
        ),
      );
    }

    if (mode == _SourceCheckMode.discovery) {
      if (stage.endsWith('detail')) {
        return _SourceCheckIssue(
          stage: stage,
          message: message,
          health: const SourceRuntimeHealth(
            category: SourceHealthCategory.discoveryDetailBroken,
            label: discoveryDetailBrokenSourceGroupTag,
            description: '發現書籍詳情失效',
            allowsSearch: true,
            allowsReading: true,
            cleanupCandidate: false,
            quarantined: false,
          ),
        );
      }

      if (stage.endsWith('toc')) {
        return _SourceCheckIssue(
          stage: stage,
          message: message,
          health: const SourceRuntimeHealth(
            category: SourceHealthCategory.discoveryTocBroken,
            label: discoveryTocBrokenSourceGroupTag,
            description: '發現書籍目錄失效',
            allowsSearch: true,
            allowsReading: true,
            cleanupCandidate: false,
            quarantined: false,
          ),
        );
      }

      if (stage.endsWith('content')) {
        return _SourceCheckIssue(
          stage: stage,
          message: message,
          health: const SourceRuntimeHealth(
            category: SourceHealthCategory.discoveryContentBroken,
            label: discoveryContentBrokenSourceGroupTag,
            description: '發現書籍正文失效',
            allowsSearch: true,
            allowsReading: true,
            cleanupCandidate: false,
            quarantined: false,
          ),
        );
      }

      return _SourceCheckIssue(
        stage: stage,
        message: message,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.discoveryBroken,
          label: discoveryBrokenSourceGroupTag,
          description: '發現規則已失效',
          allowsSearch: true,
          allowsReading: true,
          cleanupCandidate: false,
          quarantined: false,
        ),
      );
    }

    if (stage == 'search') {
      return _SourceCheckIssue(
        stage: stage,
        message: message,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.searchBroken,
          label: searchBrokenSourceGroupTag,
          description: '搜尋規則已失效',
          allowsSearch: false,
          allowsReading: true,
          cleanupCandidate: false,
          quarantined: false,
        ),
      );
    }

    if (stage.endsWith('detail')) {
      return _SourceCheckIssue(
        stage: stage,
        message: message,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.detailBroken,
          label: detailBrokenSourceGroupTag,
          description: '詳情頁無法正常解析',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: false,
          quarantined: true,
        ),
      );
    }

    if (stage.endsWith('toc')) {
      return _SourceCheckIssue(
        stage: stage,
        message: message,
        health: const SourceRuntimeHealth(
          category: SourceHealthCategory.tocBroken,
          label: tocBrokenSourceGroupTag,
          description: '目錄抓取失敗或沒有可閱讀章節',
          allowsSearch: false,
          allowsReading: false,
          cleanupCandidate: false,
          quarantined: true,
        ),
      );
    }

    return _SourceCheckIssue(
      stage: stage,
      message: message,
      health: const SourceRuntimeHealth(
        category: SourceHealthCategory.contentBroken,
        label: contentBrokenSourceGroupTag,
        description: '正文抓取失敗或無法閱讀',
        allowsSearch: false,
        allowsReading: false,
        cleanupCandidate: false,
        quarantined: true,
      ),
    );
  }

  Future<void> _persistStatus(
    BookSource source,
    SourceRuntimeHealth health,
    String message, {
    Iterable<SourceRuntimeHealth> extraHealths = const <SourceRuntimeHealth>[],
    bool force = false,
  }) async {
    if (!force && _shouldIgnoreSourceUpdate(source.bookSourceUrl)) return;
    source.removeInvalidGroups();
    source.removeErrorComment();
    source.respondTime = 0;
    source.lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

    final seenCategories = <SourceHealthCategory>{};
    for (final nextHealth in <SourceRuntimeHealth>[health, ...extraHealths]) {
      if (!seenCategories.add(nextHealth.category)) {
        continue;
      }
      _applyHealthGroup(source, nextHealth);
    }

    if (message.trim().isNotEmpty) {
      source.addErrorComment(message.trim());
    }
    await _sourceDao.upsert(source);
  }

  void _applyHealthGroup(BookSource source, SourceRuntimeHealth health) {
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
      case SourceHealthCategory.discoveryBroken:
        source.addGroup(discoveryBrokenSourceGroupTag);
        break;
      case SourceHealthCategory.discoveryDetailBroken:
        source.addGroup(discoveryDetailBrokenSourceGroupTag);
        break;
      case SourceHealthCategory.discoveryTocBroken:
        source.addGroup(discoveryTocBrokenSourceGroupTag);
        break;
      case SourceHealthCategory.discoveryContentBroken:
        source.addGroup(discoveryContentBrokenSourceGroupTag);
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
  }

  void _recordIssue(
    BookSource source,
    List<_SourceCheckIssue> issues,
    _SourceCheckIssue issue,
  ) {
    if (_shouldIgnoreSourceUpdate(source.bookSourceUrl)) return;
    issues.add(issue);
    _setSourceProgress(
      source,
      '${_stageLabel(issue.stage)}: ${issue.message}',
      isFinal: false,
      hasIssue: true,
    );
    _appendLog(
      '  ! [${source.bookSourceName}] ${_stageLabel(issue.stage)}: ${issue.message}',
      sourceUrl: source.bookSourceUrl,
    );
  }

  _SourceCheckIssue _pickPrimaryIssue(List<_SourceCheckIssue> issues) {
    _SourceCheckIssue primary = issues.first;
    for (final issue in issues.skip(1)) {
      if (_issuePriority(issue.health.category) >
          _issuePriority(primary.health.category)) {
        primary = issue;
      }
    }
    return primary;
  }

  String _composeIssueMessage(List<_SourceCheckIssue> issues) {
    final seen = <String>{};
    final parts = <String>[];
    for (final issue in issues) {
      final part = '${_stageLabel(issue.stage)}: ${issue.message}';
      if (seen.add(part)) {
        parts.add(part);
      }
    }
    return _compactMessage(parts.join('；'));
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
    if (!_isChecking) return;
    _isChecking = false;
    _appendLog('收到取消指令，停止派發新校驗任務');
    _notifyIfAlive(immediate: true);
  }

  Future<SharedPreferences?> _safeGetPreferences() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  bool _shouldIgnoreSourceUpdate(String sourceUrl) =>
      _isDisposed || !_isChecking || _timedOutSourceUrls.contains(sourceUrl);

  void _appendLog(String msg, {String? sourceUrl, bool force = false}) {
    if (_isDisposed) return;
    if (!force && sourceUrl != null && _shouldIgnoreSourceUpdate(sourceUrl)) {
      return;
    }
    _logs.add(SourceCheckLogEntry(time: DateTime.now(), message: msg));
    if (_logs.length > 400) {
      _logs.removeAt(0);
    }
    _eventBus.fire(AppEvent(AppEventBus.checkSource, data: msg));
    _notifyIfAlive();
  }

  void _setSourceProgress(
    BookSource source,
    String message, {
    required bool isFinal,
    required bool hasIssue,
    bool force = false,
  }) {
    if (_isDisposed) return;
    if (!force && _shouldIgnoreSourceUpdate(source.bookSourceUrl)) return;
    _sourceProgress[source.bookSourceUrl] = SourceCheckProgress(
      sourceName: source.bookSourceName,
      message: message,
      isFinal: isFinal,
      hasIssue: hasIssue,
    );
  }

  void _notifyIfAlive({bool immediate = false}) {
    if (_isDisposed) return;
    if (immediate || !_isChecking) {
      _notifyTimer?.cancel();
      _notifyTimer = null;
      notifyListeners();
      return;
    }
    if (_notifyTimer?.isActive ?? false) return;
    _notifyTimer = Timer(_notifyThrottleInterval, () {
      if (_isDisposed) return;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isChecking = false;
    _notifyTimer?.cancel();
    _notifyTimer = null;
    super.dispose();
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

String _stageFor(_SourceCheckMode mode, String detailStage) {
  if (mode == _SourceCheckMode.search) {
    return detailStage;
  }
  return 'discovery:$detailStage';
}

SourceRuntimeHealth _detailHealthFor(_SourceCheckMode mode) {
  if (mode == _SourceCheckMode.search) {
    return const SourceRuntimeHealth(
      category: SourceHealthCategory.detailBroken,
      label: detailBrokenSourceGroupTag,
      description: '詳情頁無法正常解析',
      allowsSearch: false,
      allowsReading: false,
      cleanupCandidate: false,
      quarantined: true,
    );
  }
  return const SourceRuntimeHealth(
    category: SourceHealthCategory.discoveryDetailBroken,
    label: discoveryDetailBrokenSourceGroupTag,
    description: '發現書籍詳情失效',
    allowsSearch: true,
    allowsReading: true,
    cleanupCandidate: false,
    quarantined: false,
  );
}

SourceRuntimeHealth _tocHealthFor(_SourceCheckMode mode) {
  if (mode == _SourceCheckMode.search) {
    return const SourceRuntimeHealth(
      category: SourceHealthCategory.tocBroken,
      label: tocBrokenSourceGroupTag,
      description: '目錄抓取失敗或沒有可閱讀章節',
      allowsSearch: false,
      allowsReading: false,
      cleanupCandidate: false,
      quarantined: true,
    );
  }
  return const SourceRuntimeHealth(
    category: SourceHealthCategory.discoveryTocBroken,
    label: discoveryTocBrokenSourceGroupTag,
    description: '發現書籍目錄失效',
    allowsSearch: true,
    allowsReading: true,
    cleanupCandidate: false,
    quarantined: false,
  );
}

SourceRuntimeHealth _contentHealthFor(_SourceCheckMode mode) {
  if (mode == _SourceCheckMode.search) {
    return const SourceRuntimeHealth(
      category: SourceHealthCategory.contentBroken,
      label: contentBrokenSourceGroupTag,
      description: '正文內容過短或為空',
      allowsSearch: false,
      allowsReading: false,
      cleanupCandidate: false,
      quarantined: true,
    );
  }
  return const SourceRuntimeHealth(
    category: SourceHealthCategory.discoveryContentBroken,
    label: discoveryContentBrokenSourceGroupTag,
    description: '發現書籍正文失效',
    allowsSearch: true,
    allowsReading: true,
    cleanupCandidate: false,
    quarantined: false,
  );
}

int _issuePriority(SourceHealthCategory category) {
  switch (category) {
    case SourceHealthCategory.nonNovel:
      return 100;
    case SourceHealthCategory.loginRequired:
      return 95;
    case SourceHealthCategory.downloadOnly:
      return 90;
    case SourceHealthCategory.contentBroken:
      return 80;
    case SourceHealthCategory.tocBroken:
      return 70;
    case SourceHealthCategory.detailBroken:
      return 60;
    case SourceHealthCategory.searchBroken:
      return 50;
    case SourceHealthCategory.upstreamUnstable:
      return 40;
    case SourceHealthCategory.discoveryDetailBroken:
      return 29;
    case SourceHealthCategory.discoveryTocBroken:
      return 28;
    case SourceHealthCategory.discoveryContentBroken:
      return 27;
    case SourceHealthCategory.discoveryBroken:
      return 26;
    case SourceHealthCategory.healthy:
      return 0;
  }
}

String _stageLabel(String stage) {
  switch (stage) {
    case 'search':
      return '搜尋';
    case 'discovery':
      return '發現';
    case 'detail':
      return '詳情';
    case 'toc':
      return '目錄';
    case 'content':
      return '正文';
    case 'discovery:detail':
      return '發現詳情';
    case 'discovery:toc':
      return '發現目錄';
    case 'discovery:content':
      return '發現正文';
    case 'filter':
      return '預檢';
    case 'timeout':
      return '超時';
    case 'upstream':
      return '上游';
    default:
      return stage;
  }
}

String _compactMessage(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return '未知錯誤';
  }
  final firstLine = trimmed.split('\n').first.trim();
  return firstLine.length > 220
      ? '${firstLine.substring(0, 220)}...'
      : firstLine;
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

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _threeDigits(int value) => value.toString().padLeft(3, '0');
