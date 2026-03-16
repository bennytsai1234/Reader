import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/search_history_dao.dart';
import 'package:legado_reader/core/services/rule_big_data_service.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class GlobalCachePage extends StatefulWidget {
  const GlobalCachePage({super.key});

  @override
  State<GlobalCachePage> createState() => _GlobalCachePageState();
}

class _GlobalCachePageState extends State<GlobalCachePage> {
  String _chapterCacheSize = '0.00 MB';
  String _imageCacheSize = '0.00 MB';
  String _historyCount = '0 條';
  String _bigDataSize = '0.00 MB';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    // 1. 統計正文快取 (目前估算，資料難以精確算磁碟)
    // 這裡對位 Android：主要清理資料庫紀錄與 Text 緩存檔案
    _chapterCacheSize = '計算中...';

    // 2. 統計圖片快取
    final tempDir = await getTemporaryDirectory();
    final imageCacheDir = Directory('${tempDir.path}/libCachedImageData');
    double imageSize = 0;
    if (await imageCacheDir.exists()) {
      await for (var file in imageCacheDir.list(recursive: true)) {
        if (file is File) imageSize += await file.length();
      }
    }
    _imageCacheSize = '${(imageSize / 1024 / 1024).toStringAsFixed(2)} MB';

    // 3. 統計歷史紀錄
    final history = await getIt<SearchHistoryDao>().getRecent();
    _historyCount = '${history.length} 條';

    // 4. 統計大數據規則快取
    final bigDataPath = await RuleBigDataService().getStorageDir();
    final bigDataDir = Directory(bigDataPath);
    double bigDataSize = 0;
    if (await bigDataDir.exists()) {
      await for (var file in bigDataDir.list()) {
        if (file is File) bigDataSize += await file.length();
      }
    }
    _bigDataSize = '${(bigDataSize / 1024 / 1024).toStringAsFixed(2)} MB';

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('清理快取')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [
              _buildCacheItem(
                icon: Icons.article_outlined,
                title: '書籍正文快取',
                subtitle: '包含所有離線下載與閱讀過的章節內容',
                value: _chapterCacheSize,
                onClear: () async {
                  await getIt<ChapterDao>().clearAllContent();
                  _loadStats();
                },
              ),
              _buildCacheItem(
                icon: Icons.image_outlined,
                title: '封面與圖片快取',
                subtitle: '書籍封面與正文插圖快取',
                value: _imageCacheSize,
                onClear: () async {
                  await DefaultCacheManager().emptyCache();
                  _loadStats();
                },
              ),
              _buildCacheItem(
                icon: Icons.history,
                title: '搜尋歷史紀錄',
                subtitle: '清理所有搜尋過的核心關鍵字',
                value: _historyCount,
                onClear: () async {
                  await getIt<SearchHistoryDao>().clearAll();
                  _loadStats();
                },
              ),
              _buildCacheItem(
                icon: Icons.storage_outlined,
                title: '規則緩存數據',
                subtitle: 'AnalyzeRule 產生的規則執行快取',
                value: _bigDataSize,
                onClear: () async {
                  await RuleBigDataService().clear();
                  _loadStats();
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: _clearAll,
                  child: const Text('一鍵清理所有快取'),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildCacheItem({required IconData icon, required String title, required String subtitle, required String value, required VoidCallback onClear}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 4),
          InkWell(onTap: onClear, child: const Text('清理', style: TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    );
  }

  void _clearAll() async {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('全部清理'),
      content: const Text('確定要清理所有快取嗎？這不會影響您的書架與書源。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          await getIt<ChapterDao>().clearAllContent();
          await DefaultCacheManager().emptyCache();
          await getIt<SearchHistoryDao>().clearAll();
          await RuleBigDataService().clear();
          _loadStats();
        }, child: const Text('確定清理')),
      ],
    ));
  }
}
