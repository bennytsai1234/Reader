import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Centralizes app-owned filesystem locations so features don't hardcode paths.
class AppStoragePaths {
  static Future<Directory> documentsDir() => getApplicationDocumentsDirectory();

  static Future<Directory> temporaryDir() => getTemporaryDirectory();

  static Future<Directory> fontsDir({bool ensureExists = false}) async {
    return _subdirectory(
      await documentsDir(),
      'fonts',
      ensureExists: ensureExists,
    );
  }

  static Future<Directory> ruleDataDir({bool ensureExists = false}) async {
    return _subdirectory(
      await documentsDir(),
      'ruleData',
      ensureExists: ensureExists,
    );
  }

  static Future<Directory> imageCacheDir({bool ensureExists = false}) async {
    return _subdirectory(
      await temporaryDir(),
      'libCachedImageData',
      ensureExists: ensureExists,
    );
  }

  static Future<Directory> shareExportDir({bool ensureExists = false}) async {
    return _subdirectory(
      await temporaryDir(),
      'exports',
      ensureExists: ensureExists,
    );
  }

  static Future<File> shareExportFile(String fileName) async {
    final dir = await shareExportDir(ensureExists: true);
    return File(p.join(dir.path, fileName));
  }

  static Future<Directory> backupTempDir({bool ensureExists = false}) async {
    return _subdirectory(
      await temporaryDir(),
      'legado_backup_zip',
      ensureExists: ensureExists,
    );
  }

  static Future<Directory> jsCacheDir({bool ensureExists = false}) async {
    return _subdirectory(
      await temporaryDir(),
      'js_cache',
      ensureExists: ensureExists,
    );
  }

  static Future<Directory> _subdirectory(
    Directory root,
    String name, {
    required bool ensureExists,
  }) async {
    final dir = Directory(p.join(root.path, name));
    if (ensureExists && !await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
