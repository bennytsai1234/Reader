import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_display_coordinator.dart';

class ReaderContentPresentation {
  final ReaderLocation location;
  final ReaderScrollTarget? scrollTarget;
  final int? slidePageIndex;

  const ReaderContentPresentation({
    required this.location,
    this.scrollTarget,
    this.slidePageIndex,
  });
}

class ReaderContentCoordinator {
  final ReaderDisplayCoordinator _displayCoordinator;

  const ReaderContentCoordinator({
    ReaderDisplayCoordinator displayCoordinator =
        const ReaderDisplayCoordinator(),
  }) : _displayCoordinator = displayCoordinator;

  ReaderContentPresentation resolvePresentation(
    ReaderPresentationRequest request,
  ) {
    final instruction = _displayCoordinator.resolveDisplayInstruction(request);
    return ReaderContentPresentation(
      location: instruction.location,
      scrollTarget: instruction.scrollTarget,
      slidePageIndex: instruction.slidePageIndex,
    );
  }

  int resolveSlideTargetIndex(ReaderSlideTargetRequest request) {
    return _displayCoordinator.resolveSlideTargetIndex(request);
  }
}
