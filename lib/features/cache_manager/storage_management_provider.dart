import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/database/dao/search_history_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/services/book_cover_storage_service.dart';
import 'package:inkpage_reader/core/services/rule_big_data_service.dart';
import 'package:inkpage_reader/core/storage/app_storage_paths.dart';
import 'package:inkpage_reader/core/storage/storage_metrics.dart';

class StorageEntry {
  const StorageEntry({
    required this.icon,
    required this.title,
    required this.description,
    required this.sizeInBytes,
    required this.displayValue,
    this.onClear,
    this.clearLabel = '清理',
  });

  final IconData icon;
  final String title;
  final String description;
  final int sizeInBytes;
  final String displayValue;
  final Future<void> Function()? onClear;
  final String clearLabel;

  bool get canClear => onClear != null;
}

class StorageManagementProvider extends ChangeNotifier {
  final ReaderChapterContentDao _chapterContentDao =
      getIt<ReaderChapterContentDao>();
  final SearchHistoryDao _searchHistoryDao = getIt<SearchHistoryDao>();
  final BookCoverStorageService _coverStorage = BookCoverStorageService();

  bool _isLoading = false;
  List<StorageEntry> _entries = const [];

  bool get isLoading => _isLoading;
  List<StorageEntry> get entries => _entries;
  int get totalTrackedBytes =>
      _entries.fold(0, (sum, item) => sum + item.sizeInBytes);

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    final chapterSize = await _chapterContentDao.getTotalContentSize();
    final coverAssetSize = await _coverStorage.getTotalCoverAssetSize();
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
        title: '書籍正文儲存',
        description: '已建立本地 storage 的章節正文，刪書時才會一併移除',
        sizeInBytes: chapterSize,
        displayValue: StorageMetrics.formatBytes(chapterSize),
      ),
      StorageEntry(
        icon: Icons.photo_library_outlined,
        title: '書籍封面儲存',
        description: '書架與詳情頁使用的本地封面檔案，避免打開 app 時等待網路圖片',
        sizeInBytes: coverAssetSize,
        displayValue: StorageMetrics.formatBytes(coverAssetSize),
      ),
      StorageEntry(
        icon: Icons.image_outlined,
        title: '臨時圖片快取',
        description: '搜尋、詳情和其他臨時畫面載入的圖片，可重新下載',
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
    final onClear = entry.onClear;
    if (onClear == null) return;
    await onClear();
    await load();
  }

  Future<void> clearAll() async {
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
