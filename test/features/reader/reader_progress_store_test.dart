import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';

void main() {
  group('ReaderProgressStore', () {
    test('shouldSaveImmediately 會根據距離與章節變化決定', () {
      final store = ReaderProgressStore();

      expect(
        store.shouldSaveImmediately(
          currentCharOffset: 10,
          currentChapterIndex: 0,
          targetChapterIndex: 0,
        ),
        isTrue,
      );
    });

    test('persistCharOffset 會更新 book 並寫入資料層', () async {
      final store = ReaderProgressStore();
      final book = Book(name: 'book', author: 'author', bookUrl: 'url');
      final chapters = [
        BookChapter(title: 'c0', index: 0),
        BookChapter(title: 'c1', index: 1),
      ];

      int? savedChapter;
      String? savedTitle;
      int? savedOffset;

      await store.persistCharOffset(
        write: (chapterIndex, title, charOffset) async {
          savedChapter = chapterIndex;
          savedTitle = title;
          savedOffset = charOffset;
        },
        book: book,
        chapters: chapters,
        chapterIndex: 1,
        charOffset: 345,
      );

      expect(book.durChapterIndex, 1);
      expect(book.durChapterPos, 345);
      expect(book.durChapterTitle, 'c1');
      expect(
        store.lastSavedLocation,
        const ReaderLocation(chapterIndex: 1, charOffset: 345),
      );
      expect(savedChapter, 1);
      expect(savedTitle, 'c1');
      expect(savedOffset, 345);
    });

    test('persistCharOffset 寫入失敗時不拋出例外（並靜默記錄）', () async {
      final store = ReaderProgressStore();
      final book = Book(name: 'book', author: 'author', bookUrl: 'url');
      final chapters = [BookChapter(title: 'c0', index: 0)];

      Future<void> failingWrite(int ci, String title, int charOffset) async {
        throw Exception('DB write failed');
      }

      // Must NOT throw — write failure should be caught and logged
      await expectLater(
        store.persistCharOffset(
          write: failingWrite,
          book: book,
          chapters: chapters,
          chapterIndex: 0,
          charOffset: 100,
        ),
        completes,
      );

      // In-memory state should still be updated (only durable write failed)
      expect(book.durChapterPos, 100);
      expect(
        store.lastSavedLocation,
        const ReaderLocation(chapterIndex: 0, charOffset: 100),
      );
    });

    test('shouldSaveImmediately 會參考完整 lastSavedLocation', () async {
      final store = ReaderProgressStore();
      final book = Book(name: 'book', author: 'author', bookUrl: 'url');
      final chapters = [BookChapter(title: 'c0', index: 0)];

      await store.persistCharOffset(
        write: (_, __, ___) async {},
        book: book,
        chapters: chapters,
        chapterIndex: 2,
        charOffset: 400,
      );

      expect(
        store.shouldSaveImmediately(
          currentCharOffset: 450,
          currentChapterIndex: 2,
          targetChapterIndex: 2,
        ),
        isFalse,
      );
      expect(
        store.shouldSaveImmediately(
          currentCharOffset: 450,
          currentChapterIndex: 2,
          targetChapterIndex: 3,
        ),
        isTrue,
      );
    });
  });
}
