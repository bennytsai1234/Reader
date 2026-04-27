class ReaderTrace {
  const ReaderTrace({this.enabled = false});

  final bool enabled;

  void log(String message) {
    if (!enabled) return;
    // ignore: avoid_print
    print('[reader-engine] $message');
  }
}
