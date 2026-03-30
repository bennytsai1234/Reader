import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';

enum AudioPlayMode { listLoop, singleLoop, shuffle, listEndStop }

/// AudioPlayService - 音頻播放服務 (補足定時器、播放模式與背景控制)
class AudioPlayService extends ChangeNotifier {
  static final AudioPlayService _instance = AudioPlayService._internal();
  factory AudioPlayService() => _instance;
  AudioPlayService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;
  Timer? _sleepTimer;
  Duration? _remainingSleepTime;
  AudioPlayMode _playMode = AudioPlayMode.listLoop;

  AudioPlayer get player => _player;
  Duration? get remainingSleepTime => _remainingSleepTime;
  AudioPlayMode get playMode => _playMode;

  Future<void> _init() async {
    if (_isInitialized) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _isInitialized = true;
  }

  void setPlayMode(AudioPlayMode mode) {
    _playMode = mode;
    switch (mode) {
      case AudioPlayMode.singleLoop:
        _player.setLoopMode(LoopMode.one);
        _player.setShuffleModeEnabled(false);
        break;
      case AudioPlayMode.listLoop:
        _player.setLoopMode(LoopMode.all);
        _player.setShuffleModeEnabled(false);
        break;
      case AudioPlayMode.shuffle:
        _player.setLoopMode(LoopMode.all);
        _player.setShuffleModeEnabled(true);
        break;
      case AudioPlayMode.listEndStop:
        _player.setLoopMode(LoopMode.off);
        _player.setShuffleModeEnabled(false);
        break;
    }
    notifyListeners();
  }

  void nextPlayMode() {
    final nextIdx = (_playMode.index + 1) % AudioPlayMode.values.length;
    setPlayMode(AudioPlayMode.values[nextIdx]);
  }

  Future<void> playUrl(String url, {String? title, String? artist, String? album, String? artUri}) async {
    try {
      await _init();
      final mediaItem = MediaItem(
        id: url,
        album: album ?? '保安專用閱讀器',
        title: title ?? 'Unknown Chapter',
        artist: artist ?? 'Unknown Author',
        artUri: artUri != null ? Uri.parse(artUri) : null,
      );
      
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: mediaItem,
        ),
      );
      _player.play();
    } catch (e) {
      AppLog.e('AudioPlayService play error: $e', error: e);
    }
  }

  /// 設定定時睡眠 (原 Android TimerSliderPopup)
  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes <= 0) {
      _remainingSleepTime = null;
      notifyListeners();
      return;
    }

    _remainingSleepTime = Duration(minutes: minutes);
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSleepTime == null) {
        timer.cancel();
        return;
      }
      
      final newTime = _remainingSleepTime! - const Duration(seconds: 1);
      if (newTime.inSeconds <= 0) {
        _remainingSleepTime = null;
        _player.pause();
        timer.cancel();
      } else {
        _remainingSleepTime = newTime;
      }
      notifyListeners();
    });
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() {
    _sleepTimer?.cancel();
    _remainingSleepTime = null;
    return _player.stop();
  }
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}

