import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';

class ReaderViewSizeUpdate {
  final bool completedBootstrapSize;
  final bool shouldApplySize;
  final bool shouldRefreshPaginationConfig;
  final bool shouldRepaginate;
  final bool queuedRepaginate;

  const ReaderViewSizeUpdate({
    this.completedBootstrapSize = false,
    this.shouldApplySize = false,
    this.shouldRefreshPaginationConfig = false,
    this.shouldRepaginate = false,
    this.queuedRepaginate = false,
  });
}

class ReaderViewportLifecycleRuntime {
  final Completer<Size> _initialViewSize = Completer<Size>();
  bool _initialSessionPrimed = false;
  bool _pendingRepaginateForLatestViewport = false;
  DateTime? _ignoreViewportChangesUntil;

  Future<Size> waitForInitialViewSize(Size? currentViewSize) {
    if (currentViewSize != null) {
      return Future<Size>.value(currentViewSize);
    }
    return _initialViewSize.future;
  }

  bool beginInitialSession() {
    if (_initialSessionPrimed) return false;
    _initialSessionPrimed = true;
    return true;
  }

  int resolveInitialChapterPreloadRadius({
    required int pageTurnMode,
    required bool isLocalBook,
  }) {
    if (pageTurnMode == PageAnim.scroll) {
      return isLocalBook ? 1 : 0;
    }
    return 2;
  }

  ReaderViewSizeUpdate handleViewSizeChange({
    required Size size,
    required Size? currentViewSize,
    required bool hasContentManager,
    required bool hasCachedCurrentChapterContent,
    required bool hasCurrentChapterPages,
    required bool isPaginatingContent,
    DateTime? now,
  }) {
    if (!_initialViewSize.isCompleted) {
      _initialViewSize.complete(size);
      return const ReaderViewSizeUpdate(completedBootstrapSize: true);
    }

    if (currentViewSize == null) {
      return ReaderViewSizeUpdate(
        shouldApplySize: true,
        shouldRefreshPaginationConfig: hasContentManager,
        shouldRepaginate:
            hasContentManager &&
            hasCachedCurrentChapterContent &&
            !hasCurrentChapterPages,
      );
    }

    if (_shouldIgnoreViewSizeChange(currentViewSize, size, now: now)) {
      return const ReaderViewSizeUpdate();
    }

    if (!hasContentManager || !hasCachedCurrentChapterContent) {
      return const ReaderViewSizeUpdate(shouldApplySize: true);
    }

    if (isPaginatingContent) {
      _pendingRepaginateForLatestViewport = true;
      return const ReaderViewSizeUpdate(
        shouldApplySize: true,
        queuedRepaginate: true,
      );
    }

    return const ReaderViewSizeUpdate(
      shouldApplySize: true,
      shouldRepaginate: true,
    );
  }

  void beginRepaginateIteration() {
    _pendingRepaginateForLatestViewport = false;
  }

  bool get hasPendingRepaginateForLatestViewport =>
      _pendingRepaginateForLatestViewport;

  void guardTransientViewportChanges({DateTime? now}) {
    _ignoreViewportChangesUntil = (now ?? DateTime.now()).add(
      const Duration(milliseconds: 500),
    );
  }

  bool _shouldIgnoreViewSizeChange(
    Size currentSize,
    Size nextSize, {
    DateTime? now,
  }) {
    final dw = (currentSize.width - nextSize.width).abs();
    final dh = (currentSize.height - nextSize.height).abs();
    if (dw < 12 && dh < 24) return true;
    if (dw < 1 && dh < 96) return true;
    final guardUntil = _ignoreViewportChangesUntil;
    if (guardUntil != null && (now ?? DateTime.now()).isBefore(guardUntil)) {
      return dw < 64 && dh < 180;
    }
    return false;
  }
}
