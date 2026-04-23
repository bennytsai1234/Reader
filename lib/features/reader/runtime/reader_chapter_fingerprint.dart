import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

class ReaderChapterFingerprint {
  const ReaderChapterFingerprint._();

  static String? structureDigest({
    required int chapterIndex,
    required List<TextPage> pages,
  }) {
    if (pages.isEmpty) return null;

    int scale(double value) => (value * 100).round();

    final buffer =
        StringBuffer()
          ..write('chapter=')
          ..write(chapterIndex)
          ..write(';pages=')
          ..write(pages.length);

    for (final page in pages) {
      buffer
        ..write('|p:')
        ..write(page.index)
        ..write(':')
        ..write(page.lines.length)
        ..write(':')
        ..write(ChapterPositionResolver.firstCharOffset(page))
        ..write(':')
        ..write(ChapterPositionResolver.pageEndCharOffset(page));

      for (final line in page.lines) {
        final image = line.image;
        buffer
          ..write('|l:')
          ..write(line.chapterPosition)
          ..write(':')
          ..write(line.text.length)
          ..write(':')
          ..write(scale(line.lineTop))
          ..write(':')
          ..write(scale(line.lineBottom))
          ..write(':')
          ..write(line.isTitle ? 1 : 0)
          ..write(':')
          ..write(line.isParagraphStart ? 1 : 0)
          ..write(':')
          ..write(line.isParagraphEnd ? 1 : 0)
          ..write(':')
          ..write(line.shouldJustify ? 1 : 0)
          ..write(':')
          ..write(line.paragraphNum)
          ..write(':')
          ..write(image == null ? 0 : 1);
        if (image != null) {
          buffer
            ..write(':')
            ..write(scale(image.width))
            ..write(':')
            ..write(scale(image.height))
            ..write(':')
            ..write(scale(image.left))
            ..write(':')
            ..write(scale(image.top));
        }
      }
    }

    return md5.convert(utf8.encode(buffer.toString())).toString();
  }
}
