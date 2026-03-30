import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/database/dao/read_record_dao.dart';
import 'package:legado_reader/core/database/dao/txt_toc_rule_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/services/app_log_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const String _appVersion = '0.1.6';
  static const int _schemaVersion = 8;

  /// 執行全量備份並返回 ZIP 檔案路徑
  Future<File?> createBackupZip() async {
    final tempDir = await getTemporaryDirectory();
    final backupFolder = Directory(p.join(tempDir.path, 'legado_backup'));
    if (await backupFolder.exists()) await backupFolder.delete(recursive: true);
    await backupFolder.create();

    try {
      // 0. 寫入備份 manifest（版本資訊，供還原時驗證）
      final manifest = {
        'appVersion': _appVersion,
        'schemaVersion': _schemaVersion,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await File(
        p.join(backupFolder.path, 'manifest.json'),
      ).writeAsString(jsonEncode(manifest));

      // 1. 導出資料庫表為 JSON (對標 Android Backup.kt)
      await _writeJson(
        backupFolder,
        'bookshelf.json',
        await getIt<BookDao>().getAll(),
      );
      await _writeJson(
        backupFolder,
        'bookSource.json',
        await getIt<BookSourceDao>().getAllFull(),
      );
      await _writeJson(
        backupFolder,
        'replaceRule.json',
        await getIt<ReplaceRuleDao>().getAll(),
      );
      await _writeJson(
        backupFolder,
        'bookmark.json',
        await getIt<BookmarkDao>().getAll(),
      );
      await _writeJson(
        backupFolder,
        'readRecord.json',
        await getIt<ReadRecordDao>().getAll(),
      );
      await _writeJson(
        backupFolder,
        'txtTocRule.json',
        await getIt<TxtTocRuleDao>().getAll(),
      );

      // 2. 導出偏好設定 (對標 config.xml)
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> config = {};
      for (var key in prefs.getKeys()) {
        config[key] = prefs.get(key);
      }
      await File(
        p.join(backupFolder.path, 'config.json'),
      ).writeAsString(jsonEncode(config));

      // 3. 打包為 ZIP（先寫暫存檔，再原子重新命名）
      final encoder = ZipFileEncoder();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final zipPath = p.join(tempDir.path, 'backup-$dateStr.zip');
      final tmpZipPath = '$zipPath.tmp';

      encoder.create(tmpZipPath);
      await for (var entity in backupFolder.list(recursive: true)) {
        if (entity is File) {
          encoder.addFile(entity);
        }
      }
      encoder.close();

      // 原子重新命名：確保不會寫到一半產生殘缺 ZIP
      final tmpFile = File(tmpZipPath);
      await tmpFile.rename(zipPath);

      return File(zipPath);
    } catch (e, stack) {
      AppLog.e('建立備份 ZIP 失敗: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> _writeJson(
    Directory folder,
    String name,
    List<dynamic> data,
  ) async {
    final file = File(p.join(folder.path, name));
    final jsonList =
        data.map((e) {
          try {
            return (e as dynamic).toJson();
          } catch (err) {
            AppLog.w('Backup: toJson failed for item in $name: $err');
            return e;
          }
        }).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }
}
