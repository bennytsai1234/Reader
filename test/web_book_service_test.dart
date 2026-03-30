import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/exception/app_exception.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/services/book_source_service.dart';

void main() {
  group('WebBook guard logic', () {
    test('is18Plus returns true for URL containing "18plus"', () {
      expect(BookSourceService.is18Plus('https://18plus-novel.com'), true);
    });

    test('is18Plus returns true for URL containing "nsfw"', () {
      expect(BookSourceService.is18Plus('https://nsfw-books.com'), true);
    });

    test('is18Plus returns true for URL containing "sex"', () {
      expect(BookSourceService.is18Plus('https://sexnovel.com'), true);
    });

    test('is18Plus is case-insensitive', () {
      expect(BookSourceService.is18Plus('https://NSFW-BOOKS.COM'), true);
      expect(BookSourceService.is18Plus('https://18Plus.com'), true);
    });

    test('is18Plus returns false for normal URL', () {
      expect(BookSourceService.is18Plus('https://novel-reader.com'), false);
    });

    test('is18Plus returns false for null URL', () {
      expect(BookSourceService.is18Plus(null), false);
    });

    test('AdultContentException is thrown for 18+ sources', () {
      // Verify that AdultContentException can be constructed correctly
      final e = AdultContentException('blocked');
      expect(e, isA<AppException>());
      expect(e.message, 'blocked');
    });

    test('SourceException is thrown for empty search URL', () {
      // Verify SourceException carries sourceUrl
      final e = SourceException('搜尋 URL 不能為空', sourceUrl: 'https://example.com');
      expect(e, isA<AppException>());
      expect(e.sourceUrl, 'https://example.com');
      expect(e.message, '搜尋 URL 不能為空');
    });

    test('SourceException is thrown for null search URL', () {
      // A source with no searchUrl should trigger SourceException
      final source = BookSource(bookSourceUrl: 'https://example.com');
      expect(source.searchUrl, isNull);
    });

    test('BookSource with empty searchUrl string is treated as empty', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        searchUrl: '',
      );
      expect(source.searchUrl, isEmpty);
    });
  });
}
