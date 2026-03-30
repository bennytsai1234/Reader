import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/search_history_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/services/rule_big_data_service.dart';
import 'package:legado_reader/core/storage/app_storage_paths.dart';
import 'package:legado_reader/core/storage/storage_metrics.dart';

class StorageEntry {
  const StorageEntry({
    required this.icon,
    required this.title,
    required this.description,
    required this.sizeInBytes,
    required this.displayValue,
    required this.onClear,
  });

  final IconData icon;
  final String title;
  final String description;
  final int sizeInBytes;
  final String displayValue;
  final Future<void> Function() onClear;
}

class StorageManagementProvider extends ChangeNotifier {
  final ChapterDao _chapterDao = getIt<ChapterDao>();
  final SearchHistoryDao _searchHistoryDao = getIt<SearchHistoryDao>();

  bool _isLoading = false;
  List<StorageEntry> _entries = const [];

  bool get isLoading => _isLoading;
  List<StorageEntry> get entries => _entries;
  int get totalTrackedBytes =>
      _entries.fold(0, (sum, item) => sum + item.sizeInBytes);

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    final chapterSize = await _chapterDao.getTotalContentSize();
    final imageCacheDir = await AppStoragePaths.imageCacheDir();
    final imageCacheSize = await StorageMetrics.directorySize(imageCacheDir);
    final exportTempDir = await AppStoragePaths.shareExportDir();
    final exportTempSize = await StorageMetrics.directorySize(exportTempDir);
    final searchHistoryCount = await _searchHistoryDao.countAll();
    final ruleDataDir = await AppStoragePaths.ruleDataDir();
    final ruleDataSize = await StorageMetrics.directorySize(ruleDataDir);
    final fontDir = await AppStoragePaths.fontsDir();
    final fontSize = await StorageMetrics.directorySize(fontDir);

    _entries = [
      StorageEntry(
        icon: Icons.article_outlined,
        title: '書籍正文快取',
        description: '已下載章節與閱讀中寫入資料庫的正文內容',
        sizeInBytes: chapterSize,
        displayValue: StorageMetrics.formatBytes(chapterSize),
        onClear: _chapterDao.clearAllContent,
      ),
      StorageEntry(
        icon: Icons.image_outlined,
        title: '封面與圖片快取',
        description: '封面圖與閱讀中載入的圖片快取',
        sizeInBytes: imageCacheSize,
        displayValue: StorageMetrics.formatBytes(imageCacheSize),
        onClear: _clearImageCache,
      ),
      StorageEntry(
        icon: Icons.ios_share_outlined,
        title: '分享與匯出暫存',
        description: '匯出 TXT、分享書源時產生的暫存檔',
        sizeInBytes: exportTempSize,
        displayValue: StorageMetrics.formatBytes(exportTempSize),
        onClear: _clearExportTemp,
      ),
      StorageEntry(
        icon: Icons.history,
        title: '搜尋歷史紀錄',
        description: '搜尋關鍵字與搜尋時間紀錄',
        sizeInBytes: 0,
        displayValue: '$searchHistoryCount 筆',
        onClear: _searchHistoryDao.clearAll,
      ),
      StorageEntry(
        icon: Icons.storage_outlined,
        title: '規則緩存數據',
        description: 'AnalyzeRule 執行時寫入的大型變數資料',
        sizeInBytes: ruleDataSize,
        displayValue: StorageMetrics.formatBytes(ruleDataSize),
        onClear: () => RuleBigDataService().clear(),
      ),
      StorageEntry(
        icon: Icons.font_download_outlined,
        title: '自訂字體檔案',
        description: '使用者額外匯入或下載的字體',
        sizeInBytes: fontSize,
        displayValue: StorageMetrics.formatBytes(fontSize),
        onClear: _clearFonts,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearEntry(StorageEntry entry) async {
    await entry.onClear();
    await load();
  }

  Future<void> clearAll() async {
    await _chapterDao.clearAllContent();
    await _clearImageCache();
    await _clearExportTemp();
    await _searchHistoryDao.clearAll();
    await RuleBigDataService().clear();
    await _clearFonts();
    await load();
  }

  Future<void> _clearImageCache() async {
    await DefaultCacheManager().emptyCache();
    final imageCacheDir = await AppStoragePaths.imageCacheDir();
    await StorageMetrics.clearDirectoryContents(imageCacheDir);
  }

  Future<void> _clearExportTemp() async {
    final exportDir = await AppStoragePaths.shareExportDir();
    await StorageMetrics.clearDirectoryContents(exportDir);
  }

  Future<void> _clearFonts() async {
    final fontDir = await AppStoragePaths.fontsDir();
    await StorageMetrics.clearDirectoryContents(fontDir);
    if (!await fontDir.exists()) {
      await fontDir.create(recursive: true);
    }
  }
}
