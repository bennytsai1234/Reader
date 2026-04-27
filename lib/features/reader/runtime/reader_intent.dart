import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';

sealed class ReaderIntent {
  const ReaderIntent();
}

class JumpToLocationIntent extends ReaderIntent {
  const JumpToLocationIntent(this.location);
  final ReaderLocation location;
}

class JumpToChapterIntent extends ReaderIntent {
  const JumpToChapterIntent(this.chapterIndex);
  final int chapterIndex;
}

class SwitchReaderModeIntent extends ReaderIntent {
  const SwitchReaderModeIntent(this.pageMode);
  final ReaderPageMode pageMode;
}
