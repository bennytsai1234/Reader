import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader_v2/features/tts/reader_v2_tts_highlight.dart';
import 'package:inkpage_reader/features/reader_v2/features/tts/reader_v2_tts_sheet.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_location.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ReaderV2TtsEngine extends ChangeNotifier {
  bool get isPlaying;
  double get rate;
  double get pitch;
  String? get language;
  String get currentSpokenText;
  int get currentWordStart;
  int get currentWordEnd;
  Stream<String> get events;

  Future<void> speak(String text);
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> setRate(double value);
  Future<void> setPitch(double value);
  Future<void> setLanguage(String value);
}

class ReaderV2SystemTtsEngine extends ReaderV2TtsEngine {
  ReaderV2SystemTtsEngine({TTSService? service})
    : _service = service ?? TTSService() {
    _service.addListener(notifyListeners);
  }

  final TTSService _service;

  @override
  bool get isPlaying => _service.isPlaying;

  @override
  double get rate => _service.rate;

  @override
  double get pitch => _service.pitch;

  @override
  String? get language => _service.language;

  @override
  String get currentSpokenText => _service.currentSpokenText;

  @override
  int get currentWordStart => _service.currentWordStart;

  @override
  int get currentWordEnd => _service.currentWordEnd;

  @override
  Stream<String> get events => _service.audioEvents;

  @override
  Future<void> speak(String text) => _service.speak(text);

  @override
  Future<void> stop() => _service.stop();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> resume() => _service.resume();

  @override
  Future<void> setRate(double value) => _service.setRate(value);

  @override
  Future<void> setPitch(double value) => _service.setPitch(value);

  @override
  Future<void> setLanguage(String value) => _service.setLanguage(value);

  @override
  void dispose() {
    _service.removeListener(notifyListeners);
    super.dispose();
  }
}

class ReaderV2TtsController extends ChangeNotifier
    implements ReaderV2TtsSheetController {
  ReaderV2TtsController({required this.runtime, ReaderV2TtsEngine? tts})
    : _tts = tts ?? ReaderV2SystemTtsEngine(),
      _ownsTtsEngine = tts == null {
    _tts.addListener(_handleTtsChanged);
    _eventSubscription = _tts.events.listen(_handleTtsEvent);
  }

  final ReaderV2Runtime runtime;
  final ReaderV2TtsEngine _tts;
  final bool _ownsTtsEngine;
  late final StreamSubscription<String> _eventSubscription;
  ReaderV2Location? _speechStartLocation;
  int _speechGeneration = 0;
  bool _handlingCompletion = false;
  bool _disposed = false;

  @override
  bool get isPlaying => _tts.isPlaying;

  @override
  double get rate => _tts.rate;

  @override
  double get pitch => _tts.pitch;

  String? get language => _tts.language;
  ReaderV2Location? get speechStartLocation => _speechStartLocation;

  ReaderV2TtsHighlight? get currentHighlight {
    final start = _speechStartLocation;
    final wordStart = _tts.currentWordStart;
    final spokenLength = _tts.currentSpokenText.length;
    if (start == null || wordStart < 0 || spokenLength <= 0) return null;
    if (wordStart >= spokenLength) return null;
    final boundedWordStart = wordStart.clamp(0, spokenLength - 1).toInt();
    final wordEnd =
        _tts.currentWordEnd > boundedWordStart
            ? _tts.currentWordEnd
            : boundedWordStart + 1;
    final boundedWordEnd =
        wordEnd.clamp(boundedWordStart + 1, spokenLength).toInt();
    return ReaderV2TtsHighlight(
      chapterIndex: start.chapterIndex,
      highlightStart: start.charOffset + boundedWordStart,
      highlightEnd: start.charOffset + boundedWordEnd,
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
    final generation = ++_speechGeneration;
    final location = runtime.state.visibleLocation.normalized(
      chapterCount: runtime.chapterCount,
    );
    await _startFromLocation(location, generation: generation);
  }

  Future<bool> _startFromLocation(
    ReaderV2Location location, {
    required int generation,
  }) async {
    final content = await runtime.loadContentForTts(location);
    final safeOffset =
        location.charOffset.clamp(0, content.displayText.length).toInt();
    final span = _readableSpan(content.displayText, safeOffset);
    if (!_isActiveGeneration(generation)) return false;
    if (span == null) {
      _speechStartLocation = null;
      notifyListeners();
      return false;
    }
    final text = content.displayText.substring(span.start, span.end);
    _speechStartLocation = ReaderV2Location(
      chapterIndex: location.chapterIndex,
      charOffset: span.start,
    );
    await _tts.speak(text);
    if (!_isActiveGeneration(generation)) return false;
    notifyListeners();
    return true;
  }

  @override
  Future<void> stop() async {
    _speechGeneration += 1;
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

  void _handleTtsEvent(String event) {
    switch (event) {
      case 'onComplete':
        unawaited(_handleSpeechCompleted());
        return;
      case 'onPlay':
        if (!_tts.isPlaying) unawaited(toggle());
        return;
      case 'onPause':
        if (_tts.isPlaying) unawaited(_tts.pause());
        return;
      case 'onStop':
        unawaited(stop());
        return;
    }
  }

  Future<void> _handleSpeechCompleted() async {
    if (_handlingCompletion || _disposed) return;
    final start = _speechStartLocation;
    if (start == null) {
      notifyListeners();
      return;
    }
    final generation = _speechGeneration;
    _handlingCompletion = true;
    try {
      for (
        var chapterIndex = start.chapterIndex + 1;
        _isActiveGeneration(generation) && chapterIndex < runtime.chapterCount;
        chapterIndex += 1
      ) {
        final started = await _startFromLocation(
          ReaderV2Location(chapterIndex: chapterIndex, charOffset: 0),
          generation: generation,
        );
        if (started) return;
      }
      if (_isActiveGeneration(generation)) {
        _speechStartLocation = null;
        notifyListeners();
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'reader_v2_tts_controller',
          context: ErrorDescription('advancing TTS after completion'),
        ),
      );
      if (_isActiveGeneration(generation)) {
        _speechStartLocation = null;
        notifyListeners();
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  bool _isActiveGeneration(int generation) {
    return !_disposed && generation == _speechGeneration;
  }

  ({int start, int end})? _readableSpan(String text, int offset) {
    var start = offset.clamp(0, text.length).toInt();
    var end = text.length;
    while (start < end && _isWhitespace(text.codeUnitAt(start))) {
      start += 1;
    }
    while (end > start && _isWhitespace(text.codeUnitAt(end - 1))) {
      end -= 1;
    }
    if (start >= end) return null;
    return (start: start, end: end);
  }

  bool _isWhitespace(int codeUnit) {
    switch (codeUnit) {
      case 0x09:
      case 0x0A:
      case 0x0B:
      case 0x0C:
      case 0x0D:
      case 0x20:
      case 0x85:
      case 0xA0:
        return true;
    }
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    _speechGeneration += 1;
    unawaited(_eventSubscription.cancel());
    _tts.removeListener(_handleTtsChanged);
    unawaited(_tts.stop());
    if (_ownsTtsEngine) _tts.dispose();
    super.dispose();
  }
}
