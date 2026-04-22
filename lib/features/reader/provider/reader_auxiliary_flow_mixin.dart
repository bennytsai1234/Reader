import 'dart:async';

import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/source_switch_service.dart'
    show SourceSwitchResolution;
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_facade.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_source_switch_runtime.dart';

import 'reader_content_facade_mixin.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';

mixin ReaderAuxiliaryFlowMixin
    on ReaderProviderBase, ReaderContentFacadeMixin, ReaderSettingsMixin {
  final ReaderSessionFacade auxiliarySessionFacade =
      const ReaderSessionFacade();
  final ReaderSourceSwitchRuntime readerSourceSwitchRuntime =
      ReaderSourceSwitchRuntime();

  int get displayChapterIndexForAuxiliary;
  int resolveCurrentCharOffsetForAuxiliary();
  ReaderLocation resolveExitLocation();
  ReaderProgressStore get progressStore;
  void clearChapterRuntimeCacheEntry(int index);
  void updateCommittedLocationForAuxiliary(ReaderLocation location);
  void jumpToChapterCharOffset({
    required int chapterIndex,
    required int charOffset,
    ReaderCommandReason reason = ReaderCommandReason.system,
    bool isRestoringJump = false,
  });

  bool get isSwitchingSource => readerSourceSwitchRuntime.isSwitching;
  String? get sourceSwitchMessage => readerSourceSwitchRuntime.message;

  bool shouldPromptAddToBookshelfOnExit() {
    return !book.isInBookshelf && showAddToShelfAlert;
  }

  Future<void> addCurrentBookToBookshelf() async {
    final location = resolveExitLocation();
    final title =
        location.chapterIndex >= 0 && location.chapterIndex < chapters.length
            ? chapters[location.chapterIndex].title
            : (book.durChapterTitle ?? '');
    await auxiliarySessionFacade.addCurrentBookToBookshelf(
      book: book,
      chapters: chapters,
      location: location,
      chapterTitle: title,
      progressStore: progressStore,
      bookDao: bookDao,
      chapterDao: chapterDao,
      onCompleted: notifyListeners,
    );
  }

  Future<void> toggleBookmark() async {
    addBookmark();
  }

  void addBookmark({String? content}) {
    final chapterIndex = displayChapterIndexForAuxiliary;
    final bookmark = auxiliarySessionFacade.buildBookmark(
      book: book,
      chapterIndex: chapterIndex,
      chapterTitle: displayChapterTitleAt(chapterIndex),
      chapterPos: resolveCurrentCharOffsetForAuxiliary(),
      content: content,
    );
    auxiliarySessionFacade.saveBookmark(
      bookmarkDao: bookmarkDao,
      bookmark: bookmark,
      onCompleted: notifyListeners,
    );
  }

  void replaceChapterSource(int index, BookSource source, String content) {
    if (index < 0 || index >= chapters.length) return;
    chapters[index].content = content;
    putChapterContent(index, content);
    clearChapterFailure(index);
    clearChapterRuntimeCacheEntry(index);
    if (index == currentChapterIndex) {
      unawaited(loadChapter(index, reason: ReaderCommandReason.system));
    }
    notifyListeners();
  }

  Future<bool> autoChangeSourceForCurrentChapter() async {
    final result = await readerSourceSwitchRuntime
        .autoChangeSourceForCurrentChapter(
          book: book,
          targetChapterIndex: currentChapterIndex,
          targetChapterTitle: displayChapterTitleAt(currentChapterIndex),
          applyResolution: applySourceSwitchResolution,
          notifyListeners: notifyListeners,
        );
    return result?.changed ?? false;
  }

  Future<void> changeBookSourceTo(SearchBook searchBook) async {
    final result = await readerSourceSwitchRuntime.changeBookSource(
      book: book,
      searchBook: searchBook,
      targetChapterIndex: currentChapterIndex,
      targetChapterTitle: displayChapterTitleAt(currentChapterIndex),
      applyResolution: applySourceSwitchResolution,
      notifyListeners: notifyListeners,
    );
    if (result?.error != null) {
      Error.throwWithStackTrace(
        result!.error!,
        result.stackTrace ?? StackTrace.current,
      );
    }
  }

  Future<void> applySourceSwitchResolution(
    SourceSwitchResolution resolution,
  ) async {
    await auxiliarySessionFacade.applySourceSwitchResolution(
      resolution: resolution,
      book: book,
      setSource: (value) => source = value,
      setChapters: (value) => chapters = List<BookChapter>.from(value),
      clearChapterFailure: clearChapterFailure,
      refreshChapterDisplayTitles: refreshChapterDisplayTitles,
      resetContentLifecycle: resetContentLifecycle,
      putChapterContent: putChapterContent,
      bookDao: bookDao,
      chapterDao: chapterDao,
      updateCommittedLocation: updateCommittedLocationForAuxiliary,
      loadChapter: loadChapter,
      jumpToChapterCharOffset:
          ({
            required chapterIndex,
            required charOffset,
            required ReaderCommandReason reason,
          }) => jumpToChapterCharOffset(
            chapterIndex: chapterIndex,
            charOffset: charOffset,
            reason: reason,
          ),
      reason: ReaderCommandReason.system,
    );
  }
}
