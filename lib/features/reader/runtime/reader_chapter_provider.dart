import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/engine/reader/content_processor.dart'
    as engine;
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book/book_content.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_provider.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';

class ReaderChapterProvider {
  const ReaderChapterProvider();

  ReaderChapter buildFromPages({
    required BookChapter chapter,
    required int chapterIndex,
    required String title,
    required List<TextPage> pages,
  }) {
    return ReaderChapter(
      chapter: chapter,
      index: chapterIndex,
      title: title,
      pages: pages,
    );
  }

  Future<ReaderChapter> buildChapter({
    required Book book,
    required BookChapter chapter,
    required int chapterIndex,
    required int chapterSize,
    required String rawContent,
    required List<Map<String, dynamic>> rulesJson,
    required int chineseConvertType,
    required Size viewSize,
    required TextStyle titleStyle,
    required TextStyle contentStyle,
    required double paragraphSpacing,
    required int textIndent,
    required bool textFullJustify,
  }) async {
    final BookContent processed = await engine.ContentProcessor.process(
      book: book,
      chapter: chapter,
      rawContent: rawContent,
      rulesJson: rulesJson,
      useReplaceRules: book.getUseReplaceRule(),
      reSegmentEnabled: book.getReSegment(),
    );

    final List<TextPage> pages = await ChapterProvider.paginate(
      content: processed.content,
      chapter: chapter,
      chapterIndex: chapterIndex,
      chapterSize: chapterSize,
      viewSize: viewSize,
      titleStyle: titleStyle,
      contentStyle: contentStyle,
      paragraphSpacing: paragraphSpacing,
      textIndent: textIndent,
      textFullJustify: textFullJustify,
    );

    return ReaderChapter(
      chapter: chapter,
      index: chapterIndex,
      title: chapter.title,
      pages: pages,
    );
  }
}
