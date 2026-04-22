import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_coordinator.dart';

void main() {
  group('ReaderSessionCoordinator', () {
    test('persistLocation 會同步 session/durable state 與 book progress', () async {
      final writes = <({int chapterIndex, String title, int charOffset})>[];
      final book = Book(
        bookUrl: 'book',
        name: 'Book',
        durChapterIndex: 0,
        durChapterPos: 0,
      );
      final state = ReaderSessionState(
        initialLocation: const ReaderLocation(chapterIndex: 0, charOffset: 0),
      );
      final coordinator = ReaderSessionCoordinator(
        state: state,
        store: ReaderProgressStore(),
        book: () => book,
        chapters:
            () => [
              BookChapter(title: 'c0', index: 0, bookUrl: 'book'),
              BookChapter(title: 'c1', index: 1, bookUrl: 'book'),
            ],
        writeProgress: (chapterIndex, title, charOffset) async {
          writes.add((
            chapterIndex: chapterIndex,
            title: title,
            charOffset: charOffset,
          ));
        },
      );

      await coordinator.persistLocation(
        const ReaderLocation(chapterIndex: 1, charOffset: 24),
      );

      expect(
        coordinator.committedLocation,
        const ReaderLocation(chapterIndex: 1, charOffset: 24),
      );
      expect(
        coordinator.durableLocation,
        const ReaderLocation(chapterIndex: 1, charOffset: 24),
      );
      expect(book.durChapterIndex, 1);
      expect(book.durChapterPos, 24);
      expect(writes.single.chapterIndex, 1);
      expect(writes.single.charOffset, 24);
    });

    test('updatePhase 會推進 session state machine', () {
      final coordinator = ReaderSessionCoordinator(
        state: ReaderSessionState(
          initialLocation: const ReaderLocation(chapterIndex: 0, charOffset: 0),
        ),
        store: ReaderProgressStore(),
        book: () => Book(bookUrl: 'book', name: 'Book'),
        chapters: () => const [],
        writeProgress: (_, __, ___) async {},
      );

      coordinator.updatePhase(ReaderSessionPhase.contentLoading);
      expect(coordinator.phase, ReaderSessionPhase.contentLoading);

      coordinator.updatePhase(ReaderSessionPhase.restoring);
      expect(coordinator.phase, ReaderSessionPhase.restoring);

      coordinator.updatePhase(ReaderSessionPhase.ready);
      expect(coordinator.phase, ReaderSessionPhase.ready);
    });
  });
}
