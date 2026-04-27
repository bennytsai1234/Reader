import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_auto_page_controller.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_bookmark_controller.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_menu_controller.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_settings_controller.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';

class _ManualTimer implements Timer {
  _ManualTimer(this.callback);

  final void Function(Timer timer) callback;
  bool canceled = false;

  void fire() => callback(this);

  @override
  void cancel() => canceled = true;

  @override
  bool get isActive => !canceled;

  @override
  int get tick => 0;
}

class _FakeRuntime implements ReaderRuntime {
  _FakeRuntime({
    this.nextPageResults = const <bool>[],
    ReaderLocation? visibleLocation,
    this.visibleText = 'first line\nsecond line',
  }) : state = ReaderState(
         mode: ReaderMode.scroll,
         phase: ReaderPhase.ready,
         committedLocation:
             visibleLocation ??
             const ReaderLocation(chapterIndex: 0, charOffset: 0),
         visibleLocation:
             visibleLocation ??
             const ReaderLocation(chapterIndex: 0, charOffset: 0),
         layoutSpec: LayoutSpec.fromViewport(
           viewportSize: const Size(320, 480),
           style: const ReadStyle(
             fontSize: 18,
             lineHeight: 1.5,
             letterSpacing: 0,
             paragraphSpacing: 1,
             paddingTop: 0,
             paddingBottom: 0,
             paddingLeft: 0,
             paddingRight: 0,
             pageMode: ReaderPageMode.scroll,
           ),
         ),
         layoutGeneration: 0,
       );

  final List<bool> nextPageResults;
  final String visibleText;
  int nextPageCalls = 0;

  @override
  ReaderState state;

  @override
  int get chapterCount => 3;

  @override
  bool moveToNextPage() {
    final index = nextPageCalls;
    nextPageCalls += 1;
    return index < nextPageResults.length ? nextPageResults[index] : false;
  }

  @override
  String titleFor(int index) => 'chapter $index';

  @override
  Future<String> textFromVisibleLocation() async => visibleText;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBookmarkDao implements BookmarkDao {
  Bookmark? saved;

  @override
  Future<void> upsert(Bookmark bookmark) async {
    saved = bookmark;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('ReaderSettingsController', () {
    test('builds ReadStyle from current settings without loading content', () {
      final controller = ReaderSettingsController();
      controller
        ..fontSize = 22
        ..lineHeight = 1.8
        ..letterSpacing = 0.5
        ..paragraphSpacing = 1.2
        ..textPadding = 20
        ..pageTurnMode = PageAnim.scroll;

      final style = controller.readStyleFor(
        const EdgeInsets.only(top: 24, bottom: 8),
      );

      expect(style.fontSize, 22);
      expect(style.lineHeight, 1.8);
      expect(style.letterSpacing, 0.5);
      expect(style.paragraphSpacing, 1.2);
      expect(style.textIndent, 2);
      expect(style.textFullJustify, isTrue);
      expect(style.selectText, isTrue);
      expect(style.paddingLeft, 20);
      expect(style.paddingRight, 20);
      expect(style.pageMode, ReaderPageMode.scroll);
    });

    test(
      'layout signature includes indent and justify but ignores selection',
      () {
        const baseStyle = ReadStyle(
          fontSize: 18,
          lineHeight: 1.5,
          letterSpacing: 0,
          paragraphSpacing: 1,
          paddingTop: 0,
          paddingBottom: 0,
          paddingLeft: 0,
          paddingRight: 0,
          textIndent: 2,
          textFullJustify: true,
          selectText: true,
          pageMode: ReaderPageMode.scroll,
        );
        final base = LayoutSpec.fromViewport(
          viewportSize: const Size(320, 480),
          style: baseStyle,
        );

        expect(
          LayoutSpec.fromViewport(
            viewportSize: const Size(320, 480),
            style: baseStyle.copyWith(textIndent: 0),
          ).layoutSignature,
          isNot(base.layoutSignature),
        );
        expect(
          LayoutSpec.fromViewport(
            viewportSize: const Size(320, 480),
            style: baseStyle.copyWith(textFullJustify: false),
          ).layoutSignature,
          isNot(base.layoutSignature),
        );
        expect(
          LayoutSpec.fromViewport(
            viewportSize: const Size(320, 480),
            style: baseStyle.copyWith(selectText: false),
          ).layoutSignature,
          base.layoutSignature,
        );
      },
    );
  });

  group('ReaderMenuController', () {
    test('controls visibility is UI-only state', () {
      final controller = ReaderMenuController();

      controller.toggleControls();
      expect(controller.controlsVisible, isTrue);

      controller.dismissControls();
      expect(controller.controlsVisible, isFalse);
    });

    test('scrub state records pending chapter navigation', () {
      final controller = ReaderMenuController();

      controller.onScrubStart(2);
      controller.onScrubbing(4);
      controller.onScrubEnd(5);

      expect(controller.isScrubbing, isFalse);
      expect(controller.scrubIndex, 5);
      expect(controller.pendingChapterNavigationIndex, 5);

      controller.completeChapterNavigation();
      expect(controller.pendingChapterNavigationIndex, isNull);
    });
  });

  group('ReaderAutoPageController', () {
    test('timer tick advances runtime page', () {
      _ManualTimer? timer;
      final runtime = _FakeRuntime(nextPageResults: const <bool>[true]);
      final controller = ReaderAutoPageController(
        runtime: runtime,
        timerFactory: (interval, callback) {
          timer = _ManualTimer(callback);
          return timer!;
        },
      );

      controller.start();
      timer!.fire();

      expect(runtime.nextPageCalls, 1);
      expect(controller.isRunning, isTrue);
    });

    test('stops when runtime cannot move forward', () {
      _ManualTimer? timer;
      final runtime = _FakeRuntime(nextPageResults: const <bool>[false]);
      final controller = ReaderAutoPageController(
        runtime: runtime,
        timerFactory: (interval, callback) {
          timer = _ManualTimer(callback);
          return timer!;
        },
      );

      controller.start();
      timer!.fire();

      expect(runtime.nextPageCalls, 1);
      expect(controller.isRunning, isFalse);
      expect(timer!.canceled, isTrue);
    });
  });

  group('ReaderBookmarkController', () {
    test('builds bookmark from runtime visible location', () async {
      final runtime = _FakeRuntime(
        visibleLocation: const ReaderLocation(chapterIndex: 1, charOffset: 7),
        visibleText: 'visible text\nremaining',
      );
      final dao = _FakeBookmarkDao();
      final controller = ReaderBookmarkController(
        book: Book(
          bookUrl: 'book-url',
          name: 'Book',
          author: 'Author',
          origin: 'local',
        ),
        runtime: runtime,
        bookmarkDao: dao,
        now: () => DateTime.fromMillisecondsSinceEpoch(1234),
      );

      final bookmark = await controller.addVisibleLocationBookmark();

      expect(dao.saved, bookmark);
      expect(bookmark.chapterIndex, 1);
      expect(bookmark.chapterPos, 7);
      expect(bookmark.chapterName, 'chapter 1');
      expect(bookmark.bookText, 'visible text');
      expect(bookmark.time, 1234);
    });
  });
}
