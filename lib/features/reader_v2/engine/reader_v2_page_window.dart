import 'package:inkpage_reader/features/reader/engine/text_page.dart';

class ReaderV2PageWindow {
  const ReaderV2PageWindow({
    required this.prev,
    required this.current,
    required this.next,
    this.lookAhead = const <TextPage>[],
  });

  final TextPage? prev;
  final TextPage current;
  final TextPage? next;
  final List<TextPage> lookAhead;

  List<TextPage> get pages => <TextPage>[
    if (prev != null) prev!,
    current,
    if (next != null) next!,
    ...lookAhead,
  ];

  Set<int> get chapterIndexes => pages.map((page) => page.chapterIndex).toSet();

  ReaderV2PageWindow copyWith({
    TextPage? prev,
    bool clearPrev = false,
    TextPage? current,
    TextPage? next,
    bool clearNext = false,
    List<TextPage>? lookAhead,
  }) {
    return ReaderV2PageWindow(
      prev: clearPrev ? null : (prev ?? this.prev),
      current: current ?? this.current,
      next: clearNext ? null : (next ?? this.next),
      lookAhead: lookAhead ?? this.lookAhead,
    );
  }

  List<TextPage> get paintForwardPages => <TextPage>[
    current,
    if (next != null) next!,
    ...lookAhead,
  ];
}
