import 'package:shared_preferences/shared_preferences.dart';

import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/database/dao/http_tts_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/http_tts.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/runtime/http_tts_engine.dart';
import 'package:inkpage_reader/features/reader/runtime/just_audio_http_tts_player.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_source.dart';
import 'package:inkpage_reader/features/reader/runtime/system_tts_engine.dart';

typedef ReaderHttpTtsSourceLookup = Future<HttpTTS?> Function(int id);
typedef ReaderHttpTtsAudioPlayerBuilder = ReaderHttpTtsAudioPlayer Function();
typedef ReaderSystemTtsEngineBuilder =
    ReaderTtsEngine Function(TTSService ttsService);

class ReaderTtsEngineFactory {
  final HttpTtsDao? _httpTtsDao;
  final ReaderHttpTtsSourceLookup? _lookupHttpSource;
  final ReaderHttpTtsAudioPlayerBuilder _httpAudioPlayerBuilder;
  final ReaderSystemTtsEngineBuilder _buildSystemEngine;
  final TTSService _ttsService;

  ReaderTtsEngineFactory({
    HttpTtsDao? httpTtsDao,
    ReaderHttpTtsSourceLookup? lookupHttpSource,
    ReaderHttpTtsAudioPlayerBuilder? httpAudioPlayerBuilder,
    ReaderSystemTtsEngineBuilder? buildSystemEngine,
    TTSService? ttsService,
  }) : _httpTtsDao = httpTtsDao,
       _lookupHttpSource = lookupHttpSource,
       _httpAudioPlayerBuilder =
           httpAudioPlayerBuilder ?? (() => JustAudioHttpTtsPlayer()),
       _buildSystemEngine =
           buildSystemEngine ?? ((tts) => SystemTtsEngine(tts: tts)),
       _ttsService = ttsService ?? TTSService();

  Future<String> resolveSourceKey({String? overrideSourceKey}) async {
    final normalizedOverride = ReaderTtsSourcePreference.normalize(
      overrideSourceKey,
    );
    if (normalizedOverride != ReaderTtsSourcePreference.systemKey ||
        overrideSourceKey?.trim() == ReaderTtsSourcePreference.systemKey) {
      return normalizedOverride;
    }

    final prefs = await SharedPreferences.getInstance();
    return ReaderTtsSourcePreference.normalize(
      prefs.getString(PreferKey.ttsSource),
    );
  }

  Future<ReaderTtsEngine> create({String? overrideSourceKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final sourceKey = await resolveSourceKey(
      overrideSourceKey: overrideSourceKey,
    );
    final httpSourceId = ReaderTtsSourcePreference.httpIdFromKey(sourceKey);
    if (httpSourceId != null) {
      final source = await _loadHttpSource(httpSourceId);
      if (source != null && source.url.trim().isNotEmpty) {
        final speechRate = prefs.getDouble(PreferKey.ttsSpeechRate) ?? 1.0;
        return HttpTtsEngine(
          source: source,
          player: _httpAudioPlayerBuilder(),
          speakSpeed: deriveHttpSpeakSpeed(speechRate),
        );
      }
      AppLog.e('ReaderTtsEngineFactory: http source not found: $sourceKey');
    }
    return _buildSystemEngine(_ttsService);
  }

  Future<HttpTTS?> _loadHttpSource(int id) {
    final lookup = _lookupHttpSource;
    if (lookup != null) {
      return lookup(id);
    }
    final dao = _httpTtsDao ?? getIt<HttpTtsDao>();
    return dao.getById(id);
  }

  static int deriveHttpSpeakSpeed(double speechRate) {
    final normalized = speechRate.clamp(0.1, 1.0);
    return (normalized * 10).round().clamp(1, 10);
  }
}
