import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/models/read_record.dart';
import 'package:legado_reader/core/database/dao/read_record_dao.dart';
import 'package:legado_reader/core/di/injection.dart';

class ReadRecordProvider extends ChangeNotifier {
  final ReadRecordDao _dao = getIt<ReadRecordDao>();

  List<ReadRecord> _records = [];
  List<ReadRecord> get records => _records;

  int _totalTime = 0;
  int get totalTime => _totalTime;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchKey = '';

  ReadRecordProvider() {
    loadRecords();
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allRecords = await _dao.getAllTime();
      _totalTime = allRecords.fold<int>(0, (sum, item) => sum + item.readTime);
      if (_searchKey.isEmpty) {
        _records = await _dao.getAllShow();
      } else {
        _records = await _dao.search(_searchKey);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String key) {
    _searchKey = key;
    loadRecords();
  }

  Future<void> deleteRecord(String bookName) async {
    await _dao.deleteByName(bookName);
    await loadRecords();
  }

  Future<void> clearAll() async {
    await _dao.clearAll();
    await loadRecords();
  }

  String formatDuration(int minutes) {
    if (minutes < 60) return '$minutes 分鐘';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours 小時 $mins 分鐘';
  }
}

