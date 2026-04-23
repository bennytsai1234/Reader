// ignore_for_file: experimental_member_use

import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'package:inkpage_reader/features/reader/runtime/http_tts_engine.dart';

class JustAudioHttpTtsPlayer implements ReaderHttpTtsAudioPlayer {
  final AudioPlayer _player;

  JustAudioHttpTtsPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  @override
  bool get isPlaying => _player.playing;

  @override
  Future<void> playBytes(Uint8List bytes, {String? contentType}) async {
    final source = _BytesAudioSource(bytes, contentType: contentType);
    await _player.stop();
    await _player.setAudioSource(source);
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  final String? _contentType;

  _BytesAudioSource(this._bytes, {String? contentType})
    : _contentType = contentType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final safeStart = (start ?? 0).clamp(0, _bytes.length);
    final safeEnd = (end ?? _bytes.length).clamp(safeStart, _bytes.length);
    final range = _bytes.sublist(safeStart, safeEnd);
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: range.length,
      offset: safeStart,
      stream: Stream<List<int>>.value(range),
      contentType: _contentType ?? 'application/octet-stream',
    );
  }
}
