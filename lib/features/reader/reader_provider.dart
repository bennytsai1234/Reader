import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_open_target.dart';
import 'package:inkpage_reader/features/reader/runtime/read_book_controller.dart';

export 'package:inkpage_reader/features/reader/runtime/read_book_controller.dart';

class ReaderProvider extends ReadBookController {
  ReaderProvider({
    required Book book,
    ReaderOpenTarget? openTarget,
    List<BookChapter> initialChapters = const [],
  }) : super(
         book: book,
         initialLocation:
             (openTarget ?? ReaderOpenTarget.resume(book)).location,
         initialChapters: initialChapters,
       );
}
