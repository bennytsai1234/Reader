import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/book_source_part.dart';
import 'package:legado_reader/core/services/network_service.dart';
import 'package:legado_reader/core/services/check_source_service.dart';

class SourceManagerProvider with ChangeNotifier {
  final BookSourceDao _dao = getIt<BookSourceDao>();
  final CheckSourceService checkService = CheckSourceService();

  List<BookSourcePart> _sources = [];
  
  String filterGroup = '全部';
  int sortMode = 0; 
  bool sortDesc = false;
  bool groupByDomain = false;

  List<BookSourcePart> get sources {
    var list = List<BookSourcePart>.from(_sources);
    if (filterGroup == '已啟用') {
      list = list.where((s) => s.enabled).toList();
    } else if (filterGroup == '已禁用') {
      list = list.where((s) => !s.enabled).toList();
    } else if (filterGroup == '需登錄') {
      list = list.where((s) => s.hasLoginUrl).toList();
    } else if (filterGroup == '無分組') {
      list = list.where((s) => s.bookSourceGroup == null || s.bookSourceGroup!.isEmpty).toList();
    } else if (filterGroup != '全部') {
      list = list.where((s) => s.bookSourceGroup?.contains(filterGroup) ?? false).toList();
    }

    int multiplier = sortDesc ? -1 : 1;
    switch (sortMode) {
      case 0: list.sort((a, b) => a.customOrder.compareTo(b.customOrder) * multiplier); break;
      case 1: list.sort((a, b) => b.weight.compareTo(a.weight) * multiplier); break;
      case 2: list.sort((a, b) => a.bookSourceName.compareTo(b.bookSourceName) * multiplier); break;
      case 3: list.sort((a, b) => a.bookSourceUrl.compareTo(b.bookSourceUrl) * multiplier); break;
      case 4: list.sort((a, b) => a.lastUpdateTime.compareTo(b.lastUpdateTime) * multiplier); break;
      case 5: list.sort((a, b) => a.respondTime.compareTo(b.respondTime) * multiplier); break;
    }
    return list;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isBatchMode = false;
  bool get isBatchMode => _isBatchMode;
  final Set<String> _selectedUrls = {};
  Set<String> get selectedUrls => _selectedUrls;
  List<String> _allGroups = [];
  List<String> get allGroups => _allGroups;

  SourceManagerProvider() { loadSources(); }

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

  void setFilterGroup(String group) { filterGroup = group; notifyListeners(); }
  void setSortMode(int mode) { sortMode = mode; notifyListeners(); }
  void toggleSortDesc() { sortDesc = !sortDesc; notifyListeners(); }
  void toggleGroupByDomain() { groupByDomain = !groupByDomain; notifyListeners(); }

  void toggleBatchMode() {
    _isBatchMode = !_isBatchMode;
    if (!_isBatchMode) _selectedUrls.clear();
    notifyListeners();
  }

  void toggleSelect(String url) {
    if (_selectedUrls.contains(url)) { _selectedUrls.remove(url); } 
    else { _selectedUrls.add(url); }
    notifyListeners();
  }

  void selectAll() {
    if (_selectedUrls.length == sources.length) { _selectedUrls.clear(); } 
    else { _selectedUrls.addAll(sources.map((s) => s.bookSourceUrl)); }
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

  Future<void> deleteSource(dynamic source) async {
    final String url = source.bookSourceUrl;
    await _dao.deleteByUrl(url);
    await loadSources();
  }

  Future<void> deleteSelected() async {
    for (var url in _selectedUrls) {
      await _dao.deleteByUrl(url);
    }
    _isBatchMode = false;
    _selectedUrls.clear();
    await loadSources();
  }

  /// 通用分享方法：按 URL 集合分享書源 (對標 Android 分享)
  Future<void> shareSourcesByUrls(Set<String> urls, {String fileName = 'sources.legado'}) async {
    if (urls.isEmpty) return;
    
    final selectedFullSources = <BookSource>[];
    for (var url in urls) {
      final full = await _dao.getByUrl(url);
      if (full != null) selectedFullSources.add(full);
    }

    if (selectedFullSources.isEmpty) return;

    final jsonStr = jsonEncode(selectedFullSources.map((s) => s.toJson()).toList());
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, fileName.endsWith('.legado') ? fileName : '$fileName.legado'));
    await file.writeAsString(jsonStr);

    // 使用 SharePlus.instance.share
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: '分享 Legado 書源 ($fileName)',
    ));
  }

  /// 批量分享目前選中的書源
  Future<void> shareSelectedSources() async {
    final fileName = _selectedUrls.length == 1 
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
    final json = jsonEncode(selectedFullSources.map((s) => s.toJson()).toList());
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

  Future<void> checkSelectedSources() async {
    if (_selectedUrls.isEmpty) return;
    await checkService.check(_selectedUrls.toList());
    _isBatchMode = false;
    _selectedUrls.clear();
    await loadSources();
  }

  List<String> get groups => _allGroups;
  String get selectedGroup => filterGroup;
  void selectGroup(String g) => setFilterGroup(g);

  Future<void> selectionAddToGroups(Set<String> urls, String g) async {
    for (var url in urls) {
      final s = await _dao.getByUrl(url);
      if (s != null) {
        final groups = (s.bookSourceGroup ?? '').split(RegExp(r'[,，\s]+')).where((e) => e.isNotEmpty).toSet();
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
        final groups = (s.bookSourceGroup ?? '').split(RegExp(r'[,，\s]+')).where((e) => e.isNotEmpty).toSet();
        groups.remove(g);
        s.bookSourceGroup = groups.join(',');
        await _dao.upsert(s);
      }
    }
    await loadSources();
  }

  Future<void> clearInvalidSources() async {
    // 實作清理無效書源邏輯
  }

  Future<void> checkAllSources() async {
    final urls = sources.map((s) => s.bookSourceUrl).toList();
    await checkService.check(urls);
    await loadSources();
  }

  Future<int> importFromJson(String jsonStr) async {
    _isLoading = true; notifyListeners();
    try {
      final List<dynamic> list = jsonDecode(jsonStr) is List ? jsonDecode(jsonStr) : [jsonDecode(jsonStr)];
      final sources = list.map((e) => BookSource.fromJson(e)).toList();
      await _dao.insertOrUpdateAll(sources);
      await loadSources();
      return sources.length;
    } catch (_) {
      return 0;
    } finally { _isLoading = false; notifyListeners(); }
  }

  Future<int> importFromUrl(String url) async {
    _isLoading = true; notifyListeners();
    try {
      final response = await getIt<NetworkService>().dio.get(url);
      if (response.statusCode == 200) {
        return await importFromJson(jsonEncode(response.data));
      }
    } catch (_) {}
    finally { _isLoading = false; notifyListeners(); }
    return 0;
  }

  Future<int> importFromText(String text) async {
    return await importFromJson(text);
  }
}
