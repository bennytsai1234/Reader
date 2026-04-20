import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/book_source_part.dart';
import 'package:inkpage_reader/core/storage/app_storage_paths.dart';
import 'package:inkpage_reader/core/services/network_service.dart';
import 'package:inkpage_reader/core/services/check_source_service.dart';
import 'package:share_plus/share_plus.dart';
import 'widgets/import_preview_dialog.dart';

class ParsedSourceImportResult {
  final List<BookSource> importableSources;
  final List<BookSource> excludedNonNovelSources;

  const ParsedSourceImportResult({
    required this.importableSources,
    required this.excludedNonNovelSources,
  });
}

class SourceManagerProvider with ChangeNotifier {
  final BookSourceDao _dao = getIt<BookSourceDao>();
  final CheckSourceService checkService = CheckSourceService();

  List<BookSourcePart> _sources = [];

  String filterGroup = '全部';
  String _searchQuery = '';
  int sortMode = 0;
  bool sortDesc = false;
  bool groupByDomain = false;
  SourceCheckReport get lastCheckReport => checkService.lastReport;
  bool get hasLastCheckReport => checkService.hasLastReport;
  SourceCheckConfig get checkConfig => checkService.config;

  List<BookSourcePart> get sources {
    var list = List<BookSourcePart>.from(_sources);

    // 全文搜尋
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list =
          list
              .where(
                (s) =>
                    s.bookSourceName.toLowerCase().contains(q) ||
                    s.bookSourceUrl.toLowerCase().contains(q) ||
                    (s.bookSourceComment?.toLowerCase().contains(q) ?? false),
              )
              .toList();
    }

    if (filterGroup == '已啟用') {
      list = list.where((s) => s.enabled).toList();
    } else if (filterGroup == '已禁用') {
      list = list.where((s) => !s.enabled).toList();
    } else if (filterGroup == '已啟用發現') {
      list = list.where((s) => s.enabledExplore && s.hasExploreUrl).toList();
    } else if (filterGroup == '已禁用發現') {
      list = list.where((s) => !s.enabledExplore && s.hasExploreUrl).toList();
    } else if (filterGroup == '需登錄') {
      list = list.where((s) => s.hasLoginUrl).toList();
    } else if (filterGroup == '無分組') {
      list =
          list
              .where(
                (s) => s.bookSourceGroup == null || s.bookSourceGroup!.isEmpty,
              )
              .toList();
    } else if (filterGroup != '全部') {
      list =
          list
              .where((s) => s.bookSourceGroup?.contains(filterGroup) ?? false)
              .toList();
    }

    final comparator = _buildComparator();
    if (groupByDomain) {
      list.sort((a, b) {
        final hostCompare = getSourceHost(
          a.bookSourceUrl,
        ).compareTo(getSourceHost(b.bookSourceUrl));
        if (hostCompare != 0) {
          return hostCompare;
        }
        return comparator(a, b);
      });
    } else {
      list.sort(comparator);
    }
    return list;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final Set<String> _selectedUrls = {};
  Set<String> get selectedUrls => _selectedUrls;
  List<String> _allGroups = [];
  List<String> get allGroups => _allGroups;

  SourceManagerProvider() {
    checkService.addListener(_handleCheckServiceChanged);
    loadSources();
    checkService.loadConfig();
  }

  void _handleCheckServiceChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    checkService.removeListener(_handleCheckServiceChanged);
    checkService.dispose();
    super.dispose();
  }

  Future<void> loadSources() async {
    _isLoading = true;
    notifyListeners();
    _sources = await _dao.getAllPart();
    _updateGroups();
    _isLoading = false;
    notifyListeners();
  }

  /// 獲取完整書源 (用於編輯或調試)
  Future<BookSource?> getFullSource(String url) => _dao.getByUrl(url);

  void _updateGroups() {
    final groupSet = <String>{};
    for (var s in _sources) {
      if (s.bookSourceGroup != null && s.bookSourceGroup!.isNotEmpty) {
        groupSet.addAll(s.bookSourceGroup!.split(RegExp(r'[,，\s]+')));
      }
    }
    _allGroups = groupSet.toList()..sort();
  }

  void setFilterGroup(String group) {
    filterGroup = group;
    notifyListeners();
  }

  void setSortMode(int mode) {
    sortMode = mode;
    notifyListeners();
  }

  void toggleSortDesc() {
    sortDesc = !sortDesc;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleGroupByDomain() {
    groupByDomain = !groupByDomain;
    notifyListeners();
  }

  String getSourceHost(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.trim();
      return host.isEmpty ? '其他' : host;
    } catch (_) {
      return '其他';
    }
  }

  bool shouldShowHostHeaderAt(int index) {
    if (!groupByDomain || index < 0 || index >= sources.length) {
      return false;
    }
    if (index == 0) {
      return true;
    }
    return getSourceHost(sources[index - 1].bookSourceUrl) !=
        getSourceHost(sources[index].bookSourceUrl);
  }

  void toggleSelect(String url) {
    if (_selectedUrls.contains(url)) {
      _selectedUrls.remove(url);
    } else {
      _selectedUrls.add(url);
    }
    notifyListeners();
  }

  void selectAll() {
    if (_selectedUrls.length == sources.length) {
      _selectedUrls.clear();
    } else {
      _selectedUrls.addAll(sources.map((s) => s.bookSourceUrl));
    }
    notifyListeners();
  }

  /// 反選 (對標 legado revertSelection)
  void revertSelection() {
    final allUrls = sources.map((s) => s.bookSourceUrl).toSet();
    final newSelection = allUrls.difference(_selectedUrls);
    _selectedUrls.clear();
    _selectedUrls.addAll(newSelection);
    notifyListeners();
  }

  Future<void> toggleEnabled(dynamic source) async {
    final String url = source.bookSourceUrl;
    final fullSource = await _dao.getByUrl(url);
    if (fullSource != null) {
      fullSource.enabled = !fullSource.enabled;
      await _dao.upsert(fullSource);
      await loadSources(); // 刷新局部列表
    }
  }

  Future<void> toggleEnabledExplore(dynamic source) async {
    final String url = source.bookSourceUrl;
    final fullSource = await _dao.getByUrl(url);
    if (fullSource != null) {
      fullSource.enabledExplore = !fullSource.enabledExplore;
      await _dao.upsert(fullSource);
      await loadSources();
    }
  }

  Future<void> deleteSource(dynamic source) async {
    final String url = source.bookSourceUrl;
    await _dao.deleteByUrl(url);
    await loadSources();
  }

  Future<void> deleteSelected() async {
    if (_selectedUrls.isNotEmpty) {
      await _dao.deleteByUrls(_selectedUrls.toList());
    }
    _selectedUrls.clear();
    await loadSources();
  }

  Future<void> batchSetEnabled(bool enabled) async {
    for (final url in _selectedUrls) {
      final s = await _dao.getByUrl(url);
      if (s != null) {
        s.enabled = enabled;
        await _dao.upsert(s);
      }
    }
    await loadSources();
  }

  Future<void> batchSetEnabledExplore(bool enabled) async {
    for (final url in _selectedUrls) {
      final s = await _dao.getByUrl(url);
      if (s != null) {
        s.enabledExplore = enabled;
        await _dao.upsert(s);
      }
    }
    await loadSources();
  }

  void checkSelectedInterval() {
    if (_selectedUrls.length < 2) return;
    final visibleSources = sources;
    final selectedIndices =
        visibleSources
            .asMap()
            .entries
            .where((entry) => _selectedUrls.contains(entry.value.bookSourceUrl))
            .map((entry) => entry.key)
            .toList()
          ..sort();
    if (selectedIndices.length < 2) return;
    final start = selectedIndices.first;
    final end = selectedIndices.last;
    for (var index = start; index <= end; index++) {
      _selectedUrls.add(visibleSources[index].bookSourceUrl);
    }
    notifyListeners();
  }

  Future<void> moveSelectedToTop() async {
    if (_selectedUrls.isEmpty) return;
    final all = await _dao.getAll();
    all.sort((a, b) => a.customOrder.compareTo(b.customOrder));
    final selected =
        all.where((s) => _selectedUrls.contains(s.bookSourceUrl)).toList();
    final rest =
        all.where((s) => !_selectedUrls.contains(s.bookSourceUrl)).toList();
    final reordered = [...selected, ...rest];
    await _dao.updateCustomOrder(reordered);
    await loadSources();
  }

  Future<void> moveSelectedToBottom() async {
    if (_selectedUrls.isEmpty) return;
    final all = await _dao.getAll();
    all.sort((a, b) => a.customOrder.compareTo(b.customOrder));
    final selected =
        all.where((s) => _selectedUrls.contains(s.bookSourceUrl)).toList();
    final rest =
        all.where((s) => !_selectedUrls.contains(s.bookSourceUrl)).toList();
    final reordered = [...rest, ...selected];
    await _dao.updateCustomOrder(reordered);
    await loadSources();
  }

  Future<void> moveToTop(String url) async {
    final all = await _dao.getAll();
    all.sort((a, b) => a.customOrder.compareTo(b.customOrder));
    final idx = all.indexWhere((s) => s.bookSourceUrl == url);
    if (idx <= 0) return;
    final item = all.removeAt(idx);
    all.insert(0, item);
    await _dao.updateCustomOrder(all);
    await loadSources();
  }

  Future<void> moveToBottom(String url) async {
    final all = await _dao.getAll();
    all.sort((a, b) => a.customOrder.compareTo(b.customOrder));
    final idx = all.indexWhere((s) => s.bookSourceUrl == url);
    if (idx < 0 || idx == all.length - 1) return;
    final item = all.removeAt(idx);
    all.add(item);
    await _dao.updateCustomOrder(all);
    await loadSources();
  }

  /// 通用分享方法：按 URL 集合分享書源 (對標 Android 分享)
  Future<void> shareSourcesByUrls(
    Set<String> urls, {
    String fileName = 'sources.legado',
  }) async {
    if (urls.isEmpty) return;

    final selectedFullSources = <BookSource>[];
    for (var url in urls) {
      final full = await _dao.getByUrl(url);
      if (full != null) selectedFullSources.add(full);
    }

    if (selectedFullSources.isEmpty) return;

    final jsonStr = jsonEncode(
      selectedFullSources.map((s) => s.toJson()).toList(),
    );
    final file = await AppStoragePaths.shareExportFile(
      fileName.endsWith('.legado') ? fileName : '$fileName.legado',
    );
    await file.writeAsString(jsonStr);

    // 使用 SharePlus.instance.share
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: '分享 Legado 書源 ($fileName)'),
    );
  }

  /// 批量分享目前選中的書源
  Future<void> shareSelectedSources() async {
    final fileName =
        _selectedUrls.length == 1
            ? '${sources.firstWhere((s) => s.bookSourceUrl == _selectedUrls.first).bookSourceName}.legado'
            : 'export_${_selectedUrls.length}_sources.legado';
    await shareSourcesByUrls(_selectedUrls, fileName: fileName);
  }

  Future<void> exportSelected() async {
    final selectedFullSources = <BookSource>[];
    for (var url in _selectedUrls) {
      final full = await _dao.getByUrl(url);
      if (full != null) selectedFullSources.add(full);
    }
    final json = jsonEncode(
      selectedFullSources.map((s) => s.toJson()).toList(),
    );
    await Clipboard.setData(ClipboardData(text: json));
  }

  Future<void> reorderSource(int oldIndex, int newIndex) async {
    if (sortMode != 0 || groupByDomain) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final list = sources;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await _dao.updateCustomOrder(list);
    await loadSources();
  }

  Future<void> addGroup(String name) async {
    if (name.isEmpty || _allGroups.contains(name)) return;
    // 這裡只需要更新本地緩存並刷新即可
    _allGroups.add(name);
    _allGroups.sort();
    notifyListeners();
  }

  Future<void> renameGroup(String oldName, String newName) async {
    if (newName.isEmpty || oldName == newName) return;
    await _dao.renameGroup(oldName, newName);
    await loadSources();
  }

  Future<void> deleteGroup(String name) async {
    await _dao.removeGroupLabel(name);
    if (filterGroup == name) filterGroup = '全部';
    await loadSources();
  }

  Future<void> checkSelectedSources({SourceCheckConfig? config}) async {
    if (_selectedUrls.isEmpty) return;
    if (config != null) {
      await checkService.updateConfig(config);
    }
    await checkService.check(_selectedUrls.toList());
    await loadSources();
  }

  List<String> get groups => _allGroups;
  String get selectedGroup => filterGroup;
  void selectGroup(String g) => setFilterGroup(g);

  Future<void> selectionAddToGroups(Set<String> urls, String g) async {
    for (var url in urls) {
      final s = await _dao.getByUrl(url);
      if (s != null) {
        final groups =
            (s.bookSourceGroup ?? '')
                .split(RegExp(r'[,，\s]+'))
                .where((e) => e.isNotEmpty)
                .toSet();
        groups.add(g);
        s.bookSourceGroup = groups.join(',');
        await _dao.upsert(s);
      }
    }
    await loadSources();
  }

  Future<void> selectionRemoveFromGroups(Set<String> urls, String g) async {
    for (var url in urls) {
      final s = await _dao.getByUrl(url);
      if (s != null) {
        final groups =
            (s.bookSourceGroup ?? '')
                .split(RegExp(r'[,，\s]+'))
                .where((e) => e.isNotEmpty)
                .toSet();
        groups.remove(g);
        s.bookSourceGroup = groups.join(',');
        await _dao.upsert(s);
      }
    }
    await loadSources();
  }

  Future<void> clearInvalidSources() async {
    final all = await _dao.getAll();
    final urlsToDelete = <String>[];
    for (final s in all) {
      if (s.isCleanupCandidate) {
        urlsToDelete.add(s.bookSourceUrl);
      }
    }
    if (urlsToDelete.isNotEmpty) {
      await _dao.deleteByUrls(urlsToDelete);
      await loadSources();
    }
  }

  Future<int> deleteNonNovelSources() async {
    final all = await _dao.getAll();
    final urlsToDelete = <String>[];
    for (final source in all) {
      if (source.isNovelTextSource) continue;
      urlsToDelete.add(source.bookSourceUrl);
    }
    if (urlsToDelete.isNotEmpty) {
      await _dao.deleteByUrls(urlsToDelete);
      await loadSources();
    }
    return urlsToDelete.length;
  }

  Future<void> checkAllSources({SourceCheckConfig? config}) async {
    final urls = sources.map((s) => s.bookSourceUrl).toList();
    if (config != null) {
      await checkService.updateConfig(config);
    }
    await checkService.check(urls);
    await loadSources();
  }

  Future<void> deleteSourcesByUrls(Iterable<String> urls) async {
    final normalized = urls.toSet().toList();
    if (normalized.isEmpty) return;
    await _dao.deleteByUrls(normalized);
    _selectedUrls.removeAll(normalized);
    await loadSources();
  }

  /// 解析 JSON 字串為書源列表 (不匯入)
  List<BookSource> parseSources(String jsonStr) {
    return parseSourcesDetailed(jsonStr).importableSources;
  }

  ParsedSourceImportResult parseSourcesDetailed(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    final List<dynamic> list = decoded is List ? decoded : [decoded];
    final result = <BookSource>[];
    final excluded = <BookSource>[];
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final source = BookSource.fromJson(e);
      if (source.bookSourceUrl.isEmpty || source.bookSourceName.isEmpty) {
        continue;
      }
      if (!source.isNovelTextSource) {
        source.enabled = false;
        source.enabledExplore = false;
        source.addGroup(nonNovelSourceGroupTag);
        excluded.add(source);
        continue;
      }
      result.add(source);
    }
    return ParsedSourceImportResult(
      importableSources: result,
      excludedNonNovelSources: excluded,
    );
  }

  /// 預覽匯入：分類為新增、更新、無變化
  Future<ImportPreviewResult> previewImport(
    List<BookSource> incoming, {
    List<BookSource> excludedSources = const <BookSource>[],
  }) async {
    final newSources = <BookSource>[];
    final updatedSources = <BookSource>[];
    final unchangedSources = <BookSource>[];

    for (final s in incoming) {
      final existing = await _dao.getByUrl(s.bookSourceUrl);
      if (existing == null) {
        newSources.add(s);
      } else if (existing.lastUpdateTime != s.lastUpdateTime) {
        updatedSources.add(s);
      } else {
        unchangedSources.add(s);
      }
    }

    return ImportPreviewResult(
      newSources: newSources,
      updatedSources: updatedSources,
      unchangedSources: unchangedSources,
      excludedSources: excludedSources,
    );
  }

  /// 直接匯入書源列表（跳過預覽）
  Future<int> importSources(List<BookSource> sources) async {
    if (sources.isEmpty) return 0;
    _isLoading = true;
    notifyListeners();
    try {
      await _dao.insertOrUpdateAll(sources);
      await loadSources();
      return sources.length;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> importFromJson(String jsonStr) async {
    _isLoading = true;
    notifyListeners();
    try {
      final parsed = parseSourcesDetailed(jsonStr);
      if (parsed.importableSources.isEmpty) return 0;
      await _dao.insertOrUpdateAll(parsed.importableSources);
      await loadSources();
      return parsed.importableSources.length;
    } catch (_) {
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> importFromUrl(String url) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await getIt<NetworkService>().dio.get(url);
      if (response.statusCode == 200) {
        return await importFromJson(jsonEncode(response.data));
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return 0;
  }

  Future<int> importFromText(String text) async {
    return await importFromJson(text);
  }

  int Function(BookSourcePart a, BookSourcePart b) _buildComparator() {
    final multiplier = sortDesc ? -1 : 1;
    switch (sortMode) {
      case 0:
        return (a, b) => a.customOrder.compareTo(b.customOrder) * multiplier;
      case 1:
        return (a, b) => b.weight.compareTo(a.weight) * multiplier;
      case 2:
        return (a, b) =>
            a.bookSourceName.compareTo(b.bookSourceName) * multiplier;
      case 3:
        return (a, b) =>
            a.bookSourceUrl.compareTo(b.bookSourceUrl) * multiplier;
      case 4:
        return (a, b) =>
            a.lastUpdateTime.compareTo(b.lastUpdateTime) * multiplier;
      default:
        return (a, b) => a.customOrder.compareTo(b.customOrder) * multiplier;
    }
  }
}
