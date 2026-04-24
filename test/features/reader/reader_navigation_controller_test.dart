import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_navigation_controller.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';

void main() {
  ReaderChapter makeChapter() {
    final pages = <TextPage>[
      TextPage(
        index: 0,
        title: 'chapter',
        chapterIndex: 0,
        pageSize: 2,
        lines: [
          TextLine(
            text: 'AAAA',
            width: 100,
            height: 20,
            chapterPosition: 0,
            lineTop: 0,
            lineBottom: 20,
            paragraphNum: 1,
          ),
          TextLine(
            text: 'BBBB',
            width: 100,
            height: 20,
            chapterPosition: 4,
            lineTop: 20,
            lineBottom: 40,
            paragraphNum: 1,
          ),
        ],
      ),
    ];
    return ReaderChapter(
      chapter: BookChapter(title: 'chapter', index: 0),
      index: 0,
      title: 'chapter',
      pages: pages,
    );
  }

  group('ReaderNavigationController', () {
    test('程式化 jump 會暫時禁止 visible progress persistence', () {
      final nav = ReaderNavigationController();

      expect(nav.beginSlideJump(ReaderCommandReason.tts), isTrue);
      expect(nav.activeNavigationToken, isNotNull);
      expect(nav.shouldPersistVisiblePosition(DateTime.now()), isFalse);
    });

    test('page change consume 會回傳最後一次 slide jump reason', () {
      final nav = ReaderNavigationController();

      expect(nav.beginSlideJump(ReaderCommandReason.autoPage), isTrue);
      expect(nav.consumePendingSlideJumpReason(), ReaderCommandReason.autoPage);
      expect(nav.consumePageChangeReason(), ReaderCommandReason.autoPage);
    });

    test('dispatch 會建立 transaction 並保留 slide jump reason', () {
      final nav = ReaderNavigationController();

      final transaction = nav.dispatch(
        const ReaderNavigationCommand.slide(
          reason: ReaderCommandReason.restore,
        ),
      );

      expect(transaction, isNotNull);
      expect(nav.activeNavigationToken, transaction!.token);
      expect(nav.consumePendingSlideJumpReason(), ReaderCommandReason.restore);
    });

    test('evaluateScrollAutoPageStep 會回傳 scroll 目標位置', () {
      final nav = ReaderNavigationController();
      final chapter = makeChapter();

      final step = nav.evaluateScrollAutoPageStep(
        isAutoPaging: true,
        isAutoPagePaused: false,
        isLoading: false,
        pageTurnMode: PageAnim.scroll,
        viewSize: const Size(200, 400),
        visibleChapterIndex: 0,
        visibleChapterLocalOffset: 0,
        scrollDeltaPerFrame: (viewSize, dtSeconds) => 10,
        chapterAt: (_) => chapter,
        pagesForChapter: (_) => chapter.pages,
        dtSeconds: 0.016,
      );

      expect(step, isNotNull);
      expect(step!.advanceChapter, isFalse);
      expect(step.chapterIndex, 0);
      expect(step.localOffset, 10);
    });

    test('較高優先級 user 命令可以覆蓋較低優先級 autoPage', () {
      final nav = ReaderNavigationController();

      expect(nav.beginSlideJump(ReaderCommandReason.autoPage), isTrue);
      final autoPageToken = nav.activeNavigationToken;
      expect(nav.beginChapterJump(ReaderCommandReason.user), isTrue);
      expect(nav.activeCommandReason, ReaderCommandReason.user);
      expect(nav.activeNavigationToken, isNot(autoPageToken));
    });

    test('userScroll 可以打斷 tts command', () {
      final nav = ReaderNavigationController();

      expect(nav.beginChapterJump(ReaderCommandReason.tts), isTrue);
      expect(nav.beginChapterJump(ReaderCommandReason.userScroll), isTrue);
      expect(nav.activeCommandReason, ReaderCommandReason.userScroll);
    });

    test('restore 期間的 page change reason 不會被誤判成可持久化進度', () {
      final nav = ReaderNavigationController();

      expect(nav.beginSlideJump(ReaderCommandReason.restore), isTrue);
      final restoreToken = nav.activeNavigationToken;
      final jumpReason = nav.consumePendingSlideJumpReason();
      final pageChangeReason = nav.consumePageChangeReason();

      expect(jumpReason, ReaderCommandReason.restore);
      expect(pageChangeReason, ReaderCommandReason.restore);
      expect(nav.shouldPersistForReason(pageChangeReason), isFalse);
      expect(restoreToken, isNotNull);
      expect(nav.shouldPersistVisiblePosition(DateTime.now()), isTrue);
    });

    test('restore 消費完成後會釋放 guard，讓 autoPage 可接手', () {
      final nav = ReaderNavigationController();

      expect(nav.beginSlideJump(ReaderCommandReason.restore), isTrue);
      expect(nav.consumePendingSlideJumpReason(), ReaderCommandReason.restore);
      expect(nav.consumePageChangeReason(), ReaderCommandReason.restore);

      expect(nav.beginSlideJump(ReaderCommandReason.autoPage), isTrue);
      expect(nav.activeCommandReason, ReaderCommandReason.autoPage);
    });

    test('visible target 型 transaction 不會被 explicit callback 提前完成', () {
      final nav = ReaderNavigationController();

      expect(
        nav.beginChapterJump(
          ReaderCommandReason.settingsRepaginate,
          targetLocation: const ReaderLocation(chapterIndex: 0, charOffset: 40),
          completionPolicy:
              ReaderNavigationCompletionPolicy.visibleLocationMatch,
        ),
        isTrue,
      );
      final token = nav.activeNavigationToken;

      nav.completeNavigation(
        (token ?? 0) + 1,
        reason: ReaderCommandReason.settingsRepaginate,
      );
      expect(nav.shouldPersistVisiblePosition(), isFalse);

      nav.reconcileVisibleLocation(
        const ReaderLocation(chapterIndex: 0, charOffset: 40),
      );
      expect(nav.shouldPersistVisiblePosition(), isTrue);
      expect(token, isNotNull);
    });

    test(
      'restore visible target 型 transaction 可在 scroll 完成後 explicit complete',
      () {
        final nav = ReaderNavigationController();

        expect(
          nav.beginChapterJump(
            ReaderCommandReason.restore,
            targetLocation: const ReaderLocation(
              chapterIndex: 0,
              charOffset: 40,
            ),
            targetScrollLocalOffset: 120,
            completionPolicy:
                ReaderNavigationCompletionPolicy.visibleLocationMatch,
          ),
          isTrue,
        );
        final token = nav.activeNavigationToken;

        nav.completeNavigation(token!, reason: ReaderCommandReason.restore);

        expect(nav.shouldPersistVisiblePosition(), isTrue);
      },
    );

    test('scroll transaction 會等待預期 anchor localOffset 才完成', () {
      final nav = ReaderNavigationController();

      expect(
        nav.beginChapterJump(
          ReaderCommandReason.settingsRepaginate,
          targetLocation: const ReaderLocation(chapterIndex: 0, charOffset: 20),
          targetScrollLocalOffset: 80,
          completionPolicy:
              ReaderNavigationCompletionPolicy.visibleLocationMatch,
        ),
        isTrue,
      );

      nav.reconcileVisibleScrollTarget(
        chapterIndex: 0,
        localOffset: 60,
        anchorPadding: 12,
        chapterContentHeight: 200,
        visibleLocation: const ReaderLocation(chapterIndex: 0, charOffset: 20),
      );
      expect(nav.shouldPersistVisiblePosition(), isFalse);

      nav.reconcileVisibleScrollTarget(
        chapterIndex: 0,
        localOffset: 92,
        anchorPadding: 12,
        chapterContentHeight: 200,
        visibleLocation: const ReaderLocation(chapterIndex: 0, charOffset: 24),
      );
      expect(nav.shouldPersistVisiblePosition(), isTrue);
    });

    test('completeNavigation 必須匹配 token 才會釋放 explicit transaction', () {
      final nav = ReaderNavigationController();

      expect(
        nav.beginChapterJump(ReaderCommandReason.settingsRepaginate),
        isTrue,
      );
      final token = nav.activeNavigationToken;

      nav.completeNavigation(
        (token ?? 0) + 1,
        reason: ReaderCommandReason.settingsRepaginate,
      );
      expect(nav.shouldPersistVisiblePosition(), isFalse);

      nav.completeNavigation(
        token!,
        reason: ReaderCommandReason.settingsRepaginate,
      );
      expect(nav.shouldPersistVisiblePosition(), isTrue);
    });

    test('abortNavigation 必須匹配 token 才會釋放 transaction', () {
      final nav = ReaderNavigationController();

      final transaction = nav.dispatch(
        const ReaderNavigationCommand.chapter(reason: ReaderCommandReason.user),
      );

      nav.abortNavigation(
        transaction!.token + 1,
        reason: ReaderCommandReason.user,
      );
      expect(nav.shouldPersistVisiblePosition(), isFalse);

      nav.abortNavigation(transaction.token, reason: ReaderCommandReason.user);
      expect(nav.shouldPersistVisiblePosition(), isTrue);
    });
  });
}
