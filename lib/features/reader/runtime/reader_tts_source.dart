enum ReaderTtsSourceType { system, http }

class ReaderTtsSourcePreference {
  ReaderTtsSourcePreference._();

  static const String systemKey = 'system';
  static const String httpPrefix = 'httpTts:';

  static ReaderTtsSourceType typeOf(String? sourceKey) {
    if (httpIdFromKey(sourceKey) != null) {
      return ReaderTtsSourceType.http;
    }
    return ReaderTtsSourceType.system;
  }

  static int? httpIdFromKey(String? sourceKey) {
    final normalized = sourceKey?.trim() ?? '';
    if (!normalized.startsWith(httpPrefix)) return null;
    final rawId = normalized.substring(httpPrefix.length).trim();
    return int.tryParse(rawId);
  }

  static String httpKeyForId(int id) => '$httpPrefix$id';

  static String normalize(String? sourceKey) {
    final normalized = sourceKey?.trim() ?? '';
    if (normalized.isEmpty) return systemKey;
    if (normalized == systemKey) return systemKey;
    final httpId = httpIdFromKey(normalized);
    if (httpId != null && httpId > 0) {
      return httpKeyForId(httpId);
    }
    return systemKey;
  }
}
