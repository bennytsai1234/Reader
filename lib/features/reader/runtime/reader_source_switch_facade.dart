import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/source_switch_service.dart';

typedef ReaderSourceSwitchApplier =
    Future<void> Function(SourceSwitchResolution resolution);

class ReaderSourceSwitchResult {
  final bool changed;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const ReaderSourceSwitchResult({
    required this.changed,
    required this.message,
    this.error,
    this.stackTrace,
  });
}

class ReaderSourceSwitchFacade {
  final SourceSwitchService _service;

  ReaderSourceSwitchFacade({SourceSwitchService? service})
    : _service = service ?? SourceSwitchService();

  Future<ReaderSourceSwitchResult> autoChangeSourceForCurrentChapter({
    required Book book,
    required int targetChapterIndex,
    required String targetChapterTitle,
    required ReaderSourceSwitchApplier applyResolution,
  }) async {
    try {
      final resolution = await _service.autoResolveSwitch(
        book,
        targetChapterIndex: targetChapterIndex,
        targetChapterTitle: targetChapterTitle,
      );
      if (resolution == null) {
        return const ReaderSourceSwitchResult(
          changed: false,
          message: '找不到可自動切換的可用來源',
        );
      }
      await applyResolution(resolution);
      return ReaderSourceSwitchResult(
        changed: true,
        message: '已切換到 ${resolution.source.bookSourceName}',
      );
    } catch (error, stackTrace) {
      return ReaderSourceSwitchResult(
        changed: false,
        message: '自動換源失敗: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<ReaderSourceSwitchResult> changeBookSource({
    required Book book,
    required SearchBook searchBook,
    required int targetChapterIndex,
    required String targetChapterTitle,
    required ReaderSourceSwitchApplier applyResolution,
  }) async {
    try {
      final resolution = await _service.resolveSwitch(
        book,
        searchBook,
        targetChapterIndex: targetChapterIndex,
        targetChapterTitle: targetChapterTitle,
        validateTargetContent: true,
      );
      await applyResolution(resolution);
      return ReaderSourceSwitchResult(
        changed: true,
        message: '已切換到 ${resolution.source.bookSourceName}',
      );
    } catch (error, stackTrace) {
      return ReaderSourceSwitchResult(
        changed: false,
        message: '換源失敗: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
