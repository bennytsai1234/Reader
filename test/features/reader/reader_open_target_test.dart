import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_open_target.dart';

void main() {
  group('ReaderOpenTarget', () {
    test('resume 使用 durable ReaderLocation 三元座標', () {
      final book = Book(
        bookUrl: 'url',
        name: 'book',
        chapterIndex: 3,
        charOffset: 128,
        visualOffsetPx: 18,
        readerAnchorJson:
            '{"chapterIndex":3,"charOffset":128,"localOffsetSnapshot":320}',
      );

      final target = ReaderOpenTarget.resume(book);

      expect(
        target.anchor,
        const ReaderAnchor(
          location: ReaderLocation(
            chapterIndex: 3,
            charOffset: 128,
            visualOffsetPx: 18,
          ),
        ),
      );
      expect(target.location, target.anchor.location);
    });

    test('resume 會在 durable location 改變時丟棄過期 snapshot metadata', () {
      final book = Book(
        bookUrl: 'url',
        name: 'book',
        chapterIndex: 3,
        charOffset: 128,
        readerAnchorJson:
            '{"chapterIndex":3,"charOffset":64,"localOffsetSnapshot":320}',
      );

      final target = ReaderOpenTarget.resume(book);

      expect(
        target.anchor,
        const ReaderAnchor(
          location: ReaderLocation(chapterIndex: 3, charOffset: 128),
        ),
      );
      expect(target.location, target.anchor.location);
    });

    test('bookmark 會保留 bookmark 對應的 anchor location', () {
      final bookmark = Bookmark(
        chapterIndex: 2,
        chapterPos: 77,
        chapterName: 'c2',
        bookName: 'book',
        bookAuthor: 'author',
        bookUrl: 'url',
        time: 1,
      );

      final target = ReaderOpenTarget.bookmark(bookmark);

      expect(
        target.anchor,
        const ReaderAnchor(
          location: ReaderLocation(chapterIndex: 2, charOffset: 77),
        ),
      );
    });

    test('anchor factory 會保留現有 snapshot metadata', () {
      const anchor = ReaderAnchor(
        location: ReaderLocation(chapterIndex: 1, charOffset: 42),
        pageIndexSnapshot: 5,
        localOffsetSnapshot: 320,
      );

      final target = ReaderOpenTarget.anchor(
        anchor,
        intent: ReaderOpenIntent.resume,
      );

      expect(target.anchor, anchor);
      expect(target.intent, ReaderOpenIntent.resume);
    });
  });
}
