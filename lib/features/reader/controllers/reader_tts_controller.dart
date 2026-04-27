import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderTtsController extends ChangeNotifier {
  ReaderTtsController({required this.runtime, TTSService? tts})
    : _tts = tts ?? TTSService() {
    _tts.addListener(_handleTtsChanged);
  }

  final ReaderRuntime runtime;
  final TTSService _tts;
  ReaderLocation? _speechStartLocation;

  bool get isPlaying => _tts.isPlaying;
  double get rate => _tts.rate;
  double get pitch => _tts.pitch;
  String? get language => _tts.language;
  ReaderLocation? get speechStartLocation => _speechStartLocation;

  ReaderLocation? get highlightLocation {
    final start = _speechStartLocation;
    if (start == null || _tts.currentWordStart < 0) return null;
    return ReaderLocation(
      chapterIndex: start.chapterIndex,
      charOffset: start.charOffset + _tts.currentWordStart,
    );
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRate = prefs.getDouble(PreferKey.readerTtsRate);
    final savedPitch = prefs.getDouble(PreferKey.readerTtsPitch);
    final savedLanguage = prefs.getString(PreferKey.readerTtsLanguage);
    if (savedRate != null) await _tts.setRate(savedRate);
    if (savedPitch != null) await _tts.setPitch(savedPitch);
    if (savedLanguage != null && savedLanguage.isNotEmpty) {
      await _tts.setLanguage(savedLanguage);
    }
    notifyListeners();
  }

  Future<void> toggle() async {
    if (_tts.isPlaying) {
      await _tts.pause();
      return;
    }
    if (_tts.currentSpokenText.isNotEmpty) {
      await _tts.resume();
      return;
    }
    await startFromVisibleLocation();
  }

  Future<void> startFromVisibleLocation() async {
    final location = runtime.state.visibleLocation.normalized(
      chapterCount: runtime.chapterCount,
    );
    final content = await runtime.loadContentForTts(location);
    final safeOffset =
        location.charOffset.clamp(0, content.plainText.length).toInt();
    final text = await runtime.textFromVisibleLocation();
    if (text.isEmpty) return;
    _speechStartLocation = ReaderLocation(
      chapterIndex: location.chapterIndex,
      charOffset: safeOffset,
    );
    await _tts.speak(text);
    notifyListeners();
  }

  Future<void> stop() async {
    _speechStartLocation = null;
    await _tts.stop();
    notifyListeners();
  }

  Future<void> setRate(double value) async {
    await _tts.setRate(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PreferKey.readerTtsRate, value);
    notifyListeners();
  }

  Future<void> setPitch(double value) async {
    await _tts.setPitch(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PreferKey.readerTtsPitch, value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    await _tts.setLanguage(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferKey.readerTtsLanguage, value);
    notifyListeners();
  }

  void _handleTtsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.removeListener(_handleTtsChanged);
    unawaited(_tts.stop());
    super.dispose();
  }
}
