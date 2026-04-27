import 'package:inkpage_reader/features/reader/runtime/reader_host_base.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

abstract class ReaderViewportCommand {
  final ReaderAnchor anchor;
  final ReaderCommandReason reason;

  const ReaderViewportCommand({required this.anchor, required this.reason});

  ReaderLocation get location => anchor.location;
}

class ReaderScrollViewportCommand extends ReaderViewportCommand {
  final ReaderScrollTarget target;

  const ReaderScrollViewportCommand({
    required super.anchor,
    required super.reason,
    required this.target,
  });
}

class ReaderSlideViewportCommand extends ReaderViewportCommand {
  final ReaderSlideTarget target;

  const ReaderSlideViewportCommand({
    required super.anchor,
    required super.reason,
    required this.target,
  });
}
