import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_source_switch_facade.dart';

class ReaderSourceSwitchRuntime {
  final ReaderSourceSwitchFacade _facade;

  ReaderSourceSwitchRuntime({ReaderSourceSwitchFacade? facade})
    : _facade = facade ?? ReaderSourceSwitchFacade();

  bool _isSwitching = false;
  String? _message;

  bool get isSwitching => _isSwitching;
  String? get message => _message;

  Future<ReaderSourceSwitchResult?> autoChangeSourceForCurrentChapter({
    required Book book,
    required int targetChapterIndex,
    required String targetChapterTitle,
    required ReaderSourceSwitchApplier applyResolution,
    required VoidCallback notifyListeners,
  }) {
    return _run(
      pendingMessage: '正在尋找可用來源...',
      notifyListeners: notifyListeners,
      action:
          () => _facade.autoChangeSourceForCurrentChapter(
            book: book,
            targetChapterIndex: targetChapterIndex,
            targetChapterTitle: targetChapterTitle,
            applyResolution: applyResolution,
          ),
    );
  }

  Future<ReaderSourceSwitchResult?> changeBookSource({
    required Book book,
    required SearchBook searchBook,
    required int targetChapterIndex,
    required String targetChapterTitle,
    required ReaderSourceSwitchApplier applyResolution,
    required VoidCallback notifyListeners,
  }) {
    return _run(
      pendingMessage: '正在切換來源...',
      notifyListeners: notifyListeners,
      action:
          () => _facade.changeBookSource(
            book: book,
            searchBook: searchBook,
            targetChapterIndex: targetChapterIndex,
            targetChapterTitle: targetChapterTitle,
            applyResolution: applyResolution,
          ),
    );
  }

  Future<ReaderSourceSwitchResult?> _run({
    required String pendingMessage,
    required VoidCallback notifyListeners,
    required Future<ReaderSourceSwitchResult> Function() action,
  }) async {
    if (_isSwitching) return null;

    _isSwitching = true;
    _message = pendingMessage;
    notifyListeners();

    try {
      final result = await action();
      _message = result.message;
      if (!result.changed) {
        notifyListeners();
      }
      return result;
    } finally {
      _isSwitching = false;
      notifyListeners();
    }
  }
}
