import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

abstract class ReaderViewportCommand {
  final ReaderLocation location;
  final ReaderCommandReason reason;

  const ReaderViewportCommand({required this.location, required this.reason});
}

class ReaderScrollViewportCommand extends ReaderViewportCommand {
  final ReaderScrollTarget target;

  const ReaderScrollViewportCommand({
    required super.location,
    required super.reason,
    required this.target,
  });
}

class ReaderSlideViewportCommand extends ReaderViewportCommand {
  final ReaderSlideTarget target;

  const ReaderSlideViewportCommand({
    required super.location,
    required super.reason,
    required this.target,
  });
}
