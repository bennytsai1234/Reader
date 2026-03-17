import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/txt_toc_rule_dao.dart';
import 'package:legado_reader/core/database/dao/http_tts_dao.dart';
import 'package:legado_reader/core/database/dao/dict_rule_dao.dart';
import 'package:legado_reader/core/database/dao/search_history_dao.dart';
import 'package:legado_reader/core/database/dao/cache_dao.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/txt_toc_rule.dart';
import 'package:legado_reader/core/models/http_tts.dart';
import 'package:legado_reader/core/models/dict_rule.dart';
import 'chinese_utils.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:legado_reader/core/di/injection.dart';

/// DefaultData - 預設資料初始化
/// (原 Android help/DefaultData.kt)
class DefaultData {
  DefaultData._();
  static final _initLock = Lock();

  static Future<void> init() async {
    await _initLock.synchronized(() async {
      await AppTheme.init();
      await _init();
    });
  }

  static Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    // 原 Android versionCode 判斷
    const currentDataVersion = 101;
    final savedDataVersion = prefs.getInt('default_data_version') ?? 0;

    if (savedDataVersion < currentDataVersion) {
      await _loadDefaultTocRules();
      await _loadDefaultHttpTts();
      await _loadDefaultSources();
      await _loadDefaultDictRules();
      await prefs.setInt('default_data_version', currentDataVersion);
    }

    // 2. 啟動時維護與清理 (原 Android App.onCreate 中的各式 Clear 與 adjustSortNumber)
    await _maintenance();

    // 3. 預熱與同步 (原 Android ChineseUtils.preLoad 與 AppWebDav 同步)
    _startBackgroundTasks(prefs);
  }

  static Future<void> _maintenance() async {
    try {
      // 校正書源排序 (原 Android SourceHelp.adjustSortNumber)
      await getIt<BookSourceDao>().adjustSortNumbers();

      // 維護與清理
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 清理超過 7 天的搜尋歷史 (對標 Android SearchKeywordDao.deleteOld)
      final sevenDaysAgo = now - 7 * 24 * 60 * 60 * 1000;
      await getIt<SearchHistoryDao>().clearOld(sevenDaysAgo);
      
      // 清理過期快取 (對標 Android CacheDao.clearDeadline)
      await getIt<CacheDao>().clearDeadline(now);

    } catch (e) {
      debugPrint('Maintenance error: $e');
    }
  }

  static void _startBackgroundTasks(SharedPreferences prefs) {
    // A. 預熱簡繁轉換 (原 Android ChineseUtils.preLoad)
    ChineseUtils.s2t('');
  }

  /// 載入預設目錄規則 (對標 importDefaultTocRules)
  static Future<void> _loadDefaultTocRules() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/txtTocRule.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      final rules = list.map((e) => TxtTocRule.fromJson(e)).toList();
      await getIt<TxtTocRuleDao>().insertOrUpdateAll(rules);
    } catch (e) {
      debugPrint('Error loading default TOC rules: $e. Falling back to hardcoded rules.');
      // 如果 Asset 缺失，回退到基礎硬編碼規則 (原 Android 應急邏輯)
      final defaultRules = [
        TxtTocRule(id: 0, name: '標準章節', rule: r'第[一二三四五六七八九十百千萬零\d]+[章回節卷集幕計].*', enable: true),
        TxtTocRule(id: 0, name: '數字章節', rule: r'^\s*\d+.*', enable: true),
      ];
      try {
        await getIt<TxtTocRuleDao>().insertOrUpdateAll(defaultRules);
      } catch (dbError) {
        debugPrint('Failed to insert hardcoded TOC rules: $dbError');
      }
    }
  }

  /// 載入預設 HTTP TTS (對標 importDefaultHttpTTS)
  static Future<void> _loadDefaultHttpTts() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/httpTTS.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      final engines = list.map((e) => HttpTTS.fromJson(e)).toList();
      await getIt<HttpTtsDao>().insertOrUpdateAll(engines);
    } catch (e) {
      debugPrint('Default HttpTTS Asset Not Found');
    }
  }

  /// 載入預設書源
  static Future<void> _loadDefaultSources() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/sources.json');
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final sources = jsonList.map((j) => BookSource.fromJson(jsonAt(j))).toList();     
      await getIt<BookSourceDao>().insertOrUpdateAll(sources);
    } catch (e) {
      debugPrint('Error loading default sources: $e');
    }
  }

  /// 載入預設字典規則 (對標 importDefaultDictRules)
  static Future<void> _loadDefaultDictRules() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/dictRules.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      final rules = list.map((e) => DictRule.fromJson(e)).toList();
      await getIt<DictRuleDao>().insertOrUpdateAll(rules);
    } catch (e) {
      debugPrint('Default DictRules Asset Not Found');
    }
  }

  static Map<String, dynamic> jsonAt(dynamic j) => Map<String, dynamic>.from(j);
}


