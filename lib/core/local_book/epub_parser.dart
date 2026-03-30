import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/services/app_log_service.dart';

/// EpubParser - 解析 EPUB 格式書籍
/// (原 Android model/localBook/EpubFile.kt)
class EpubParser {
  final File file;
  EpubBook? _epubBook;

  EpubParser(this.file);

  /// 載入並解析 EPUB 結構
  Future<void> load() async {
    try {
      final bytes = await file.readAsBytes();
      _epubBook = await EpubReader.readBook(bytes);
    } catch (e) {
      AppLog.e('EpubParser load error: $e', error: e);
      throw Exception('Failed to load EPUB file: $e');
    }
  }

  /// 取得書名
  String get title {
    return _epubBook?.Title ?? 'Unknown Title';
  }

  /// 取得作者
  String get author {
    return _epubBook?.Author ?? 'Unknown Author';
  }

  /// 取得封面圖片 (如果有的話)
  Future<Uint8List?> getCoverImage() async {
    if (_epubBook == null) return null;
    try {
      final coverImage = _epubBook!.CoverImage;
      if (coverImage != null) {
        // img.Image to bytes
        // epubx uses 'image' package for CoverImage which is img.Image.
        // Needs a workaround to get bytes directly or encode to png.
        // For simplicity, we can read the raw bytes from the manifest if needed,
        // but let's just return the raw bytes from the content directly if possible.

        // Find cover image in Contents.Images
        String? coverId;
        _epubBook!.Schema?.Package?.Manifest?.Items?.forEach((item) {
          if (item.Properties != null &&
              item.Properties!.contains('cover-image')) {
            coverId = item.Id;
          }
        });

        if (coverId != null) {
          final coverFile = _epubBook!.Content?.Images?[coverId];
          if (coverFile != null) {
            return Uint8List.fromList(coverFile.Content!);
          }
        }

        // Fallback: just return the first image if it's named cover
        for (var key in _epubBook!.Content?.Images?.keys ?? []) {
          if (key.toString().toLowerCase().contains('cover')) {
            return Uint8List.fromList(
              _epubBook!.Content!.Images![key]!.Content!,
            );
          }
        }
      }
    } catch (e) {
      AppLog.e('EpubParser getCover error: $e', error: e);
    }
    return null;
  }

  /// 取得章節列表，回傳 { title, href } 格式
  List<Map<String, String>> getChapters() {
    if (_epubBook == null) return [];
    final chapters = <Map<String, String>>[];

    void processChapters(List<EpubChapter> epubChapters, int level) {
      for (final chapter in epubChapters) {
        final title = chapter.Title ?? 'Unnamed Chapter';
        // 為了層級顯示可以在前面加空格
        final prefix = List.filled(level * 2, ' ').join();
        chapters.add({
          'title': '$prefix$title',
          'href': chapter.ContentFileName ?? '',
        });

        if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
          processChapters(chapter.SubChapters!, level + 1);
        }
      }
    }

    if (_epubBook!.Chapters != null) {
      processChapters(_epubBook!.Chapters!, 0);
    }

    return chapters;
  }

  /// 透過 href 讀取章節內容 (回傳 HTML 字串)
  String getChapterContent(String href) {
    if (_epubBook == null || _epubBook!.Content?.Html == null) {
      return '';
    }

    // Sometimes href contains anchor e.g. "chapter1.html#sec1"
    final fileName = href.split('#').first;

    final htmlFile = _epubBook!.Content!.Html![fileName];
    if (htmlFile != null) {
      return htmlFile.Content ?? '';
    }

    return '';
  }
}

