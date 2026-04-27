import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'page_window.dart';

enum ReaderMode { scroll, slide }

enum ReaderPhase { cold, loading, layingOut, ready, switchingMode, error }

class ReaderScrollState {
  const ReaderScrollState({
    required this.pageWindow,
    required this.pageOffset,
    required this.visibleLocation,
    this.isDragging = false,
    this.isAnimating = false,
  });

  final PageWindow pageWindow;
  final double pageOffset;
  final ReaderLocation visibleLocation;
  final bool isDragging;
  final bool isAnimating;
}

class ReaderState {
  const ReaderState({
    required this.mode,
    required this.phase,
    required this.committedLocation,
    required this.visibleLocation,
    required this.layoutSpec,
    required this.layoutGeneration,
    this.pageWindow,
    this.currentSlidePage,
    this.errorMessage,
  });

  final ReaderMode mode;
  final ReaderPhase phase;
  final ReaderLocation committedLocation;
  final ReaderLocation visibleLocation;
  final LayoutSpec layoutSpec;
  final int layoutGeneration;
  final PageWindow? pageWindow;
  final TextPage? currentSlidePage;
  final String? errorMessage;

  ReaderState copyWith({
    ReaderMode? mode,
    ReaderPhase? phase,
    ReaderLocation? committedLocation,
    ReaderLocation? visibleLocation,
    LayoutSpec? layoutSpec,
    int? layoutGeneration,
    PageWindow? pageWindow,
    bool clearPageWindow = false,
    TextPage? currentSlidePage,
    bool clearCurrentSlidePage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReaderState(
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      committedLocation: committedLocation ?? this.committedLocation,
      visibleLocation: visibleLocation ?? this.visibleLocation,
      layoutSpec: layoutSpec ?? this.layoutSpec,
      layoutGeneration: layoutGeneration ?? this.layoutGeneration,
      pageWindow: clearPageWindow ? null : (pageWindow ?? this.pageWindow),
      currentSlidePage:
          clearCurrentSlidePage
              ? null
              : (currentSlidePage ?? this.currentSlidePage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
