import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';

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

  ReaderPresentationAnchor toPresentationAnchor({bool fromEnd = false}) {
    return ReaderPresentationAnchor(
      location: location,
      fromEnd: fromEnd,
    ).normalized();
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
