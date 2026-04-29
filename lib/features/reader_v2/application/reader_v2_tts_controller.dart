import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_highlight.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_controller_sheets.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_location.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderV2TtsController extends ChangeNotifier
    implements ReaderTtsSheetController {
  ReaderV2TtsController({required this.runtime, TTSService? tts})
    : _tts = tts ?? TTSService() {
    _tts.addListener(_handleTtsChanged);
  }

  final ReaderV2Runtime runtime;
  final TTSService _tts;
  ReaderV2Location? _speechStartLocation;

  @override
  bool get isPlaying => _tts.isPlaying;

  @override
  double get rate => _tts.rate;

  @override
  double get pitch => _tts.pitch;

  String? get language => _tts.language;
  ReaderV2Location? get speechStartLocation => _speechStartLocation;

  ReaderTtsHighlight? get currentHighlight {
    final start = _speechStartLocation;
    final wordStart = _tts.currentWordStart;
    if (start == null || wordStart < 0) return null;
    final wordEnd =
        _tts.currentWordEnd > wordStart ? _tts.currentWordEnd : wordStart + 1;
    return ReaderTtsHighlight(
      chapterIndex: start.chapterIndex,
      highlightStart: start.charOffset + wordStart,
      highlightEnd: start.charOffset + wordEnd,
    );
  }

  ReaderV2Location? get highlightLocation {
    final highlight = currentHighlight;
    if (highlight == null) return null;
    return ReaderV2Location(
      chapterIndex: highlight.chapterIndex,
      charOffset: highlight.highlightStart,
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

  @override
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
        location.charOffset.clamp(0, content.displayText.length).toInt();
    final text = content.displayText.substring(safeOffset).trim();
    if (text.isEmpty) return;
    _speechStartLocation = ReaderV2Location(
      chapterIndex: location.chapterIndex,
      charOffset: safeOffset,
    );
    await _tts.speak(text);
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    _speechStartLocation = null;
    await _tts.stop();
    notifyListeners();
  }

  @override
  Future<void> setRate(double value) async {
    await _tts.setRate(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PreferKey.readerTtsRate, value);
    notifyListeners();
  }

  @override
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
