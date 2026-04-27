class ReaderVisualAnchor {
  const ReaderVisualAnchor({
    required this.contentHash,
    required this.layoutSignature,
    required this.anchorOffset,
  });

  final String contentHash;
  final String layoutSignature;
  final double anchorOffset;

  bool matches({required String contentHash, required String layoutSignature}) {
    return this.contentHash == contentHash &&
        this.layoutSignature == layoutSignature;
  }
}
