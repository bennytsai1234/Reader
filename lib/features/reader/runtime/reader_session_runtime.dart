import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_command.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime_controller.dart';

class ReaderSessionRuntimeContext {
  final bool isScrollMode;
  final int currentChapterIndex;
  final int visibleChapterIndex;
  final double visibleChapterLocalOffset;
  final int currentPageIndex;

  const ReaderSessionRuntimeContext({
    required this.isScrollMode,
    required this.currentChapterIndex,
    required this.visibleChapterIndex,
    required this.visibleChapterLocalOffset,
    required this.currentPageIndex,
  });
}

class ReaderPreparedSessionAnchor {
  final ReaderLocation location;
  final double localOffset;

  const ReaderPreparedSessionAnchor({
    required this.location,
    required this.localOffset,
  });
}

class ReaderSessionRuntime {
  final ReaderRuntimeController _runtimeController;
  final ReaderLocation Function() _committedLocation;
  final void Function(ReaderLocation) _updateCommittedLocation;
  final void Function(ReaderLocation) _updateVisibleLocation;
  final Future<void> Function(ReaderLocation) _persistLocation;
  final void Function(ReaderViewportCommand) _dispatchViewportCommand;

  ReaderSessionRuntime({
    required ReaderRuntimeController runtimeController,
    required ReaderLocation Function() committedLocation,
    required void Function(ReaderLocation) updateCommittedLocation,
    required void Function(ReaderLocation) updateVisibleLocation,
    required Future<void> Function(ReaderLocation) persistLocation,
    required void Function(ReaderViewportCommand) dispatchViewportCommand,
  }) : _runtimeController = runtimeController,
       _committedLocation = committedLocation,
       _updateCommittedLocation = updateCommittedLocation,
       _updateVisibleLocation = updateVisibleLocation,
       _persistLocation = persistLocation,
       _dispatchViewportCommand = dispatchViewportCommand;

  ReaderPresentationAnchor captureReadingAnchor(
    ReaderSessionRuntimeContext context, {
    bool fromEnd = false,
  }) {
    return _runtimeController.capturePresentationAnchor(
      isScrollMode: context.isScrollMode,
      currentChapterIndex: context.currentChapterIndex,
      visibleChapterIndex: context.visibleChapterIndex,
      visibleChapterLocalOffset: context.visibleChapterLocalOffset,
      currentPageIndex: context.currentPageIndex,
      fallbackLocation: _committedLocation(),
      fromEnd: fromEnd,
    );
  }

  ReaderLocation resolveModeSwitchLocation(
    ReaderSessionRuntimeContext context,
  ) {
    return captureReadingAnchor(context).location;
  }

  ReaderLocation resolveExitLocation(ReaderSessionRuntimeContext context) {
    if (!context.isScrollMode) {
      return resolveModeSwitchLocation(context).normalized();
    }
    final location = _runtimeController.resolveVisibleScrollLocation(
      chapterIndex: context.visibleChapterIndex,
      localOffset: context.visibleChapterLocalOffset,
    );
    _updateVisibleLocation(location);
    return location.normalized();
  }

  ReaderPreparedSessionAnchor prepareSettingsRepaginateAnchor(
    ReaderSessionRuntimeContext context,
  ) {
    final location = captureReadingAnchor(context).location;
    _updateCommittedLocation(location);
    _updateVisibleLocation(location);
    return ReaderPreparedSessionAnchor(
      location: location,
      localOffset: _runtimeController.localOffsetForLocation(location),
    );
  }

  int resolveCurrentCharOffset(ReaderSessionRuntimeContext context) {
    return captureReadingAnchor(context).location.charOffset;
  }

  int resolveVisibleCharOffset({
    required int visibleChapterIndex,
    required double visibleChapterLocalOffset,
  }) {
    final location = _runtimeController.resolveVisibleScrollLocation(
      chapterIndex: visibleChapterIndex,
      localOffset: visibleChapterLocalOffset,
    );
    _updateVisibleLocation(location);
    return location.charOffset;
  }

  void jumpToPosition({
    required bool isScrollMode,
    required int currentChapterIndex,
    int? chapterIndex,
    int? charOffset,
    int? pageIndex,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    final targetChapter = chapterIndex ?? currentChapterIndex;
    final command = _runtimeController.resolveViewportCommand(
      isScrollMode: isScrollMode,
      anchor: ReaderPresentationAnchor(
        location: ReaderLocation(
          chapterIndex: targetChapter,
          charOffset: charOffset ?? 0,
        ),
      ),
      globalPageIndex: pageIndex,
      reason: reason,
    );
    _dispatchViewportCommand(command);
  }

  Future<void> persistExitProgress(ReaderSessionRuntimeContext context) {
    return _persistLocation(resolveExitLocation(context));
  }
}
