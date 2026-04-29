import 'package:inkpage_reader/features/reader/engine/reader_location.dart';

class ReaderAnchor {
  final ReaderLocation location;
  final String? contentHash;
  final String? layoutSignature;
  final int? pageIndexSnapshot;
  final double? localOffsetSnapshot;

  const ReaderAnchor({
    required this.location,
    this.contentHash,
    this.layoutSignature,
    this.pageIndexSnapshot,
    this.localOffsetSnapshot,
  });

  factory ReaderAnchor.location(
    ReaderLocation location, {
    String? contentHash,
    String? layoutSignature,
    int? pageIndexSnapshot,
    double? localOffsetSnapshot,
  }) {
    return ReaderAnchor(
      location: location,
      contentHash: contentHash,
      layoutSignature: layoutSignature,
      pageIndexSnapshot: pageIndexSnapshot,
      localOffsetSnapshot: localOffsetSnapshot,
    );
  }

  factory ReaderAnchor.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double? asDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final hasPageIndex = json.containsKey('pageIndexSnapshot');
    return ReaderAnchor(
      location:
          ReaderLocation(
            chapterIndex: asInt(json['chapterIndex']),
            charOffset: asInt(json['charOffset']),
            visualOffsetPx: asDouble(json['visualOffsetPx']) ?? 0.0,
          ).normalized(),
      contentHash: json['contentHash'] as String?,
      layoutSignature: json['layoutSignature'] as String?,
      pageIndexSnapshot: hasPageIndex ? asInt(json['pageIndexSnapshot']) : null,
      localOffsetSnapshot: asDouble(json['localOffsetSnapshot']),
    );
  }

  ReaderAnchor normalized() {
    return ReaderAnchor(
      location: location.normalized(),
      contentHash: contentHash,
      layoutSignature: layoutSignature,
      pageIndexSnapshot: pageIndexSnapshot,
      localOffsetSnapshot: localOffsetSnapshot,
    );
  }

  ReaderAnchor copyWith({
    ReaderLocation? location,
    String? contentHash,
    String? layoutSignature,
    int? pageIndexSnapshot,
    double? localOffsetSnapshot,
  }) {
    return ReaderAnchor(
      location: location ?? this.location,
      contentHash: contentHash ?? this.contentHash,
      layoutSignature: layoutSignature ?? this.layoutSignature,
      pageIndexSnapshot: pageIndexSnapshot ?? this.pageIndexSnapshot,
      localOffsetSnapshot: localOffsetSnapshot ?? this.localOffsetSnapshot,
    );
  }

  ReaderAnchor withLocalOffsetSnapshot(double? localOffsetSnapshot) {
    return ReaderAnchor(
      location: location,
      contentHash: contentHash,
      layoutSignature: layoutSignature,
      pageIndexSnapshot: pageIndexSnapshot,
      localOffsetSnapshot: localOffsetSnapshot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterIndex': location.chapterIndex,
      'charOffset': location.charOffset,
      'visualOffsetPx': location.visualOffsetPx,
      if (contentHash != null) 'contentHash': contentHash,
      if (layoutSignature != null) 'layoutSignature': layoutSignature,
      if (pageIndexSnapshot != null) 'pageIndexSnapshot': pageIndexSnapshot,
      if (localOffsetSnapshot != null)
        'localOffsetSnapshot': localOffsetSnapshot,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderAnchor &&
        other.location == location &&
        other.contentHash == contentHash &&
        other.layoutSignature == layoutSignature &&
        other.pageIndexSnapshot == pageIndexSnapshot &&
        other.localOffsetSnapshot == localOffsetSnapshot;
  }

  @override
  int get hashCode => Object.hash(
    location,
    contentHash,
    layoutSignature,
    pageIndexSnapshot,
    localOffsetSnapshot,
  );
}
