import 'reader_location.dart';
import 'reader_visual_anchor.dart';

class ReaderProgress {
  const ReaderProgress({required this.location, this.visualAnchor});

  final ReaderLocation location;
  final ReaderVisualAnchor? visualAnchor;
}
