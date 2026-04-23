import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_open_target.dart';

void main() {
  group('ReaderOpenTarget', () {
    test('resume 會保留與 durable location 一致的 snapshot metadata', () {
      final book = Book(
        bookUrl: 'url',
        name: 'book',
        durChapterIndex: 3,
        durChapterPos: 128,
        readerAnchorJson: jsonEncode(
          const ReaderAnchor(
            location: ReaderLocation(chapterIndex: 3, charOffset: 128),
            pageIndexSnapshot: 5,
            localOffsetSnapshot: 320,
            layoutSignature: 'slide:390:844',
            contentHash: '3:8:2048:0:2048',
          ).toJson(),
        ),
      );

      final target = ReaderOpenTarget.resume(book);

      expect(
        target.anchor,
        const ReaderAnchor(
          location: ReaderLocation(chapterIndex: 3, charOffset: 128),
          pageIndexSnapshot: 5,
          localOffsetSnapshot: 320,
          layoutSignature: 'slide:390:844',
          contentHash: '3:8:2048:0:2048',
        ),
      );
      expect(target.location, target.anchor.location);
    });

    test('resume 會在 durable location 改變時丟棄過期 snapshot metadata', () {
      final book = Book(
        bookUrl: 'url',
        name: 'book',
        durChapterIndex: 3,
        durChapterPos: 128,
        readerAnchorJson: jsonEncode(
          const ReaderAnchor(
            location: ReaderLocation(chapterIndex: 3, charOffset: 64),
            pageIndexSnapshot: 5,
            localOffsetSnapshot: 320,
            layoutSignature: 'slide:390:844',
            contentHash: '3:8:2048:0:2048',
          ).toJson(),
        ),
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
