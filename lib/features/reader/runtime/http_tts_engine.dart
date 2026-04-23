import 'dart:async';
import 'dart:typed_data';

import 'package:inkpage_reader/core/engine/analyze_url.dart';
import 'package:inkpage_reader/core/models/http_tts.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine.dart';

typedef HttpTtsBytesFetcher =
    Future<Uint8List> Function(HttpTTS source, String text, {int? speakSpeed});

abstract class ReaderHttpTtsAudioPlayer {
  bool get isPlaying;

  Future<void> playBytes(Uint8List bytes, {String? contentType});
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}

class HttpTtsEngine implements ReaderTtsEngine {
  final HttpTTS source;
  final int? speakSpeed;
  final ReaderHttpTtsAudioPlayer _player;
  final HttpTtsBytesFetcher _fetchBytes;
  final StreamController<ReaderTtsEngineEvent> _events =
      StreamController<ReaderTtsEngineEvent>.broadcast();

  bool _isDisposed = false;
  int _playbackToken = 0;

  HttpTtsEngine({
    required this.source,
    required ReaderHttpTtsAudioPlayer player,
    HttpTtsBytesFetcher? fetchBytes,
    this.speakSpeed,
  }) : _player = player,
       _fetchBytes = fetchBytes ?? _defaultFetchBytes;

  @override
  Stream<ReaderTtsEngineEvent> get events => _events.stream;

  @override
  bool get isPlaying => _player.isPlaying;

  @override
  Future<void> speak(String text) async {
    if (_isDisposed || text.trim().isEmpty) return;
    final token = ++_playbackToken;
    final bytes = await _fetchBytes(source, text, speakSpeed: speakSpeed);
    if (_isDisposed || token != _playbackToken) return;

    _events.add(const ReaderTtsEngineStarted());
    await _player.playBytes(bytes, contentType: source.contentType);

    if (_isDisposed || token != _playbackToken) return;
    _events.add(const ReaderTtsEngineCompleted());
  }

  @override
  Future<void> pause() async {
    _playbackToken += 1;
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _playbackToken += 1;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _playbackToken += 1;
    await _player.dispose();
    await _events.close();
  }

  static Future<Uint8List> _defaultFetchBytes(
    HttpTTS source,
    String text, {
    int? speakSpeed,
  }) async {
    final analyzeUrl = await AnalyzeUrl.create(
      source.url,
      source: source,
      speakText: text,
      speakSpeed: speakSpeed,
    );
    return analyzeUrl.getByteArray();
  }
}
