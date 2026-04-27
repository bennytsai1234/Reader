import 'dart:convert';

import 'package:crypto/crypto.dart';

class BookContent {
  const BookContent({
    required this.chapterIndex,
    required this.title,
    required this.paragraphs,
    required this.plainText,
    required this.contentHash,
  });

  final int chapterIndex;
  final String title;
  final List<String> paragraphs;
  final String plainText;
  final String contentHash;

  factory BookContent.fromRaw({
    required int chapterIndex,
    required String title,
    required String rawText,
  }) {
    final normalized = normalizeRawText(rawText);
    final paragraphs =
        normalized.isEmpty
            ? <String>[]
            : normalized
                .split(RegExp(r'\n{2,}'))
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList(growable: false);
    final plainText = paragraphs.join('\n\n');
    final hashMaterial = '$chapterIndex\n$title\n$plainText';
    return BookContent(
      chapterIndex: chapterIndex,
      title: title.trim(),
      paragraphs: List<String>.unmodifiable(paragraphs),
      plainText: plainText,
      contentHash: sha1.convert(utf8.encode(hashMaterial)).toString(),
    );
  }

  static String normalizeRawText(String rawText) {
    return rawText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
