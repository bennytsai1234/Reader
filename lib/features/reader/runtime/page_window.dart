import 'package:inkpage_reader/features/reader/engine/text_page.dart';

class PageWindow {
  const PageWindow({
    required this.prev,
    required this.current,
    required this.next,
    this.lookAhead = const <TextPage>[],
  });

  final TextPage? prev;
  final TextPage current;
  final TextPage? next;
  final List<TextPage> lookAhead;

  PageWindow copyWith({
    TextPage? prev,
    bool clearPrev = false,
    TextPage? current,
    TextPage? next,
    bool clearNext = false,
    List<TextPage>? lookAhead,
  }) {
    return PageWindow(
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
