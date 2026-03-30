import 'dart:io';

import 'package:legado_reader/core/services/app_log_service.dart';

class StorageMetrics {
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static Future<int> directorySize(Directory dir) async {
    var totalSize = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (error) {
      AppLog.e('Error calculating dir size for ${dir.path}: $error', error: error);
    }
    return totalSize;
  }

  static Future<void> clearDirectoryContents(Directory dir) async {
    try {
      if (!await dir.exists()) return;
      await for (final entity in dir.list(followLinks: false)) {
        await entity.delete(recursive: true);
      }
    } catch (error) {
      AppLog.e('Error clearing directory ${dir.path}: $error', error: error);
    }
  }
}
