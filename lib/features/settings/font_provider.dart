import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:legado_reader/core/storage/app_storage_paths.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider with ChangeNotifier {
  static const String _fontKey = 'selected_font_family';

  List<String> _customFonts = [];
  List<String> get customFonts => _customFonts;

  String? _selectedFont;
  String? get selectedFont => _selectedFont;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _downloadProgress = 0;
  double get downloadProgress => _downloadProgress;

  FontProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _selectedFont = prefs.getString(_fontKey);

    await loadCustomFonts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCustomFonts() async {
    try {
      final dir = await getFontDir();
      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>().toList();
        final loadedFonts = <String>[];

        for (var file in files) {
          final ext = p.extension(file.path).toLowerCase();
          if (ext == '.ttf' || ext == '.otf') {
            final name = p.basenameWithoutExtension(file.path);
            try {
              final fontData = await file.readAsBytes();
              final fontLoader = FontLoader(name);
              fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
              await fontLoader.load();
              loadedFonts.add(name);
            } catch (e) {
              AppLog.e('Failed to load font $name: $e', error: e);
            }
          }
        }
        _customFonts = loadedFonts;
      }
    } catch (e) {
      AppLog.e('loadCustomFonts error: $e', error: e);
    }
  }

  Future<Directory> getFontDir() async {
    return AppStoragePaths.fontsDir(ensureExists: true);
  }

  Future<void> setSelectedFont(String? font) async {
    _selectedFont = font;
    final prefs = await SharedPreferences.getInstance();
    if (font == null) {
      await prefs.remove(_fontKey);
    } else {
      await prefs.setString(_fontKey, font);
    }
    notifyListeners();
  }

  Future<bool> downloadFont(String url, String name) async {
    _downloadProgress = 0;
    _isLoading = true;
    notifyListeners();

    try {
      final fontDir = await getFontDir();
      // 簡單判斷副檔名
      var ext = '.ttf';
      if (url.toLowerCase().contains('.otf')) ext = '.otf';

      final savePath = '${fontDir.path}/$name$ext';

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            _downloadProgress = count / total;
            notifyListeners();
          }
        },
      );

      // 動態加載
      final fontData = await File(savePath).readAsBytes();
      final fontLoader = FontLoader(name);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();

      if (!_customFonts.contains(name)) {
        _customFonts.add(name);
      }
      return true;
    } catch (e) {
      AppLog.e('Download font failed: $e', error: e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFont(String name) async {
    final fontDir = await getFontDir();
    final files = fontDir.listSync().whereType<File>();
    for (var file in files) {
      if (p.basenameWithoutExtension(file.path) == name) {
        await file.delete();
        _customFonts.remove(name);
        if (_selectedFont == name) {
          setSelectedFont(null);
        }
        notifyListeners();
        break;
      }
    }
  }

  Future<void> addLocalFont(String path) async {
    final name = p.basenameWithoutExtension(path);
    final ext = p.extension(path);
    final fontDir = await getFontDir();
    final newPath = '${fontDir.path}/$name$ext';

    await File(path).copy(newPath);

    final fontData = await File(newPath).readAsBytes();
    final fontLoader = FontLoader(name);
    fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
    await fontLoader.load();

    if (!_customFonts.contains(name)) {
      _customFonts.add(name);
    }
    notifyListeners();
  }
}
