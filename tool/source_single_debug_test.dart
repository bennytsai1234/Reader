import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:inkpage_reader/core/engine/analyze_rule.dart' as rule_engine;
import 'package:inkpage_reader/core/engine/analyze_rule.dart';
import 'package:inkpage_reader/core/engine/analyze_url.dart';
import 'package:inkpage_reader/core/engine/explore_url_parser.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';

import 'source_validation_support.dart';

void main() {
  final service = BookSourceService();
  final sourceIndex =
      int.tryParse(Platform.environment['SOURCE_INDEX'] ?? '') ?? 1;
  final probeCount =
      int.tryParse(Platform.environment['PROBE_COUNT'] ?? '') ?? 5;
  final keywordOverride = Platform.environment['KEYWORD']?.trim();
  final searchOnly = Platform.environment['SEARCH_ONLY'] == '1';
  final exploreOnly = Platform.environment['EXPLORE_ONLY'] == '1';
  final debugSearchParse = Platform.environment['DEBUG_SEARCH_PARSE'] == '1';
  final debugRawCss = Platform.environment['DEBUG_RAW_CSS']?.trim();
  final debugPattern = Platform.environment['DEBUG_PATTERN']?.trim();
  final debugJsIntermediate =
      Platform.environment['DEBUG_JS_INTERMEDIATE'] == '1';

  test('debug single source flow', () async {
    await initSourceValidationEnvironment();
    final sources = await fetchSources(limit: sourceIndex);
    final source = sources[sourceIndex - 1];

    // ignore: avoid_print
    print('[debug] source #$sourceIndex ${source.bookSourceName}');

    if (exploreOnly) {
      final exploreUrl = source.exploreUrl?.trim() ?? '';
      if (exploreUrl.isNotEmpty) {
        final kinds = await ExploreUrlParser.parseAsync(
          exploreUrl,
          source: source,
        );
        // ignore: avoid_print
        print('[debug] explore kinds=${kinds.length}');
        for (final kind in kinds.take(3)) {
          // ignore: avoid_print
          print('[debug] explore kind=${kind.title} | url=${kind.url}');
          final books = await service.exploreBooks(
            source,
            kind.url ?? '',
            page: 1,
          );
          // ignore: avoid_print
          print('[debug] explore books=${books.length}');
          for (final book in books.take(8)) {
            // ignore: avoid_print
            print(
              '[debug] explore result=${book.name} | '
              'author=${book.author ?? ''} | url=${book.bookUrl}',
            );
          }
        }
      }
      return;
    }

    final keyword =
        keywordOverride != null && keywordOverride.isNotEmpty
            ? keywordOverride
            : await pickKeyword(service, source);
    // ignore: avoid_print
    print('[debug] keyword=$keyword');

    if (debugSearchParse) {
      final analyzeUrl = await AnalyzeUrl.create(
        source.searchUrl!,
        source: source,
        key: keyword,
        page: 1,
      );
      // ignore: avoid_print
      print(
        '[debug] prefetched '
        'url=${analyzeUrl.debugPrefetchedResponseUrl} | '
        'request=${analyzeUrl.debugPrefetchedResponseRequestUrl} | '
        'redirect=${analyzeUrl.debugPrefetchedResponseRedirectUrl}',
      );
      final response = await analyzeUrl.getStrResponse();
      final searchRule = source.ruleSearch;
      final parser = rule_engine.AnalyzeRule(
        source: source,
      ).setContent(response.body, baseUrl: response.url);
      final listRule = searchRule?.bookList ?? '';
      final elements = parser.getElements(listRule);
      // ignore: avoid_print
      print(
        '[debug] search response url=${response.url} '
        'len=${response.body.length} elements=${elements.length}',
      );
      if (debugRawCss != null && debugRawCss.isNotEmpty) {
        final document = html_parser.parse(response.body);
        final cssElements = document.querySelectorAll(debugRawCss);
        // ignore: avoid_print
        print(
          '[debug] raw css selector=$debugRawCss count=${cssElements.length}',
        );
        if (cssElements.isNotEmpty) {
          // ignore: avoid_print
          print('[debug] raw css first=${cssElements.first.outerHtml}');
        }
      }
      if (debugPattern != null && debugPattern.isNotEmpty) {
        final index = response.body.indexOf(debugPattern);
        // ignore: avoid_print
        print('[debug] pattern=$debugPattern index=$index');
        if (index >= 0) {
          final start = (index - 200).clamp(0, response.body.length);
          final end = (index + 800).clamp(0, response.body.length);
          // ignore: avoid_print
          print(
            '[debug] pattern excerpt=${response.body.substring(start, end)}',
          );
        }
      }
      // ignore: avoid_print
      print('[debug] search body=${_previewBody(response.body)}');
      for (final element in elements.take(3)) {
        final itemRule = rule_engine.AnalyzeRule(
          source: source,
        ).setContent(element, baseUrl: response.url);
        // ignore: avoid_print
        print(
          '[debug] parsed item '
          'name=${await itemRule.getStringAsync(searchRule?.name ?? '')} | '
          'author=${await itemRule.getStringAsync(searchRule?.author ?? '')} | '
          'bookUrl=${await itemRule.getStringAsync(searchRule?.bookUrl ?? '', isUrl: true)}',
        );
      }
    }

    final searchBooks = await service.searchBooks(source, keyword);
    // ignore: avoid_print
    print('[debug] search results=${searchBooks.length}');
    for (final book in searchBooks.take(5)) {
      // ignore: avoid_print
      print(
        '[debug] result=${book.name} | author=${book.author ?? ''} | '
        'url=${book.bookUrl}',
      );
    }
    if (searchOnly) {
      expect(searchBooks, isNotEmpty);
      return;
    }
    final selected = selectBook(searchBooks);
    // ignore: avoid_print
    print('[debug] search hit=${selected.name} | url=${selected.bookUrl}');

    final book = await service.getBookInfo(source, selected);
    // ignore: avoid_print
    print('[debug] detail name=${book.name} | tocUrl=${book.tocUrl}');

    final chapters = await service.getChapterList(source, book);
    final readable = chapters.where((chapter) => !chapter.isVolume).toList();
    // ignore: avoid_print
    print('[debug] chapters=${chapters.length} readable=${readable.length}');

    for (var i = 0; i < readable.length && i < probeCount; i++) {
      final chapter = readable[i];
      final nextChapterUrl =
          readable.length > i + 1 ? readable[i + 1].url : null;
      if (debugJsIntermediate && i == 0 && source.ruleContent != null) {
        await _printJsIntermediate(source, book, chapter);
      }
      final content = await service.getContent(
        source,
        book,
        chapter,
        nextChapterUrl: nextChapterUrl,
      );
      // ignore: avoid_print
      print(
        '[debug] chapter#${i + 1} title=${chapter.title} | '
        'len=${content.trim().runes.length} | '
        'readable=${looksReadable(content)}',
      );
      // ignore: avoid_print
      print('[debug] preview=${_previewContent(content)}');
    }

    expect(book.name, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

String _previewContent(String content) {
  final normalized = content.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return '<empty>';
  const maxLength = 180;
  if (normalized.runes.length <= maxLength) {
    return normalized;
  }
  return '${String.fromCharCodes(normalized.runes.take(maxLength))}...';
}

String _previewBody(String content) {
  final normalized = content.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return '<empty>';
  const maxLength = 500;
  if (normalized.runes.length <= maxLength) {
    return normalized;
  }
  return '${String.fromCharCodes(normalized.runes.take(maxLength))}...';
}

Future<void> _printJsIntermediate(
  dynamic source,
  dynamic book,
  dynamic chapter,
) async {
  final analyzeUrl = await AnalyzeUrl.create(
    chapter.url,
    source: source,
    ruleData: book,
  );
  final response = await analyzeUrl.getStrResponse();
  final rule = AnalyzeRule(
    source: source,
    ruleData: book,
  ).setContent(response.body, baseUrl: response.url).setChapter(chapter);

  final intermediate = await rule.evalJSAsync(r'''
      jms = JSON.parse(result);
      jm = String(jms.body.content).split("a2o@");
      key = "S3VqaWFuZ0FwcDc0NzYwNQ==";
      iv = jm[0];
      data = jm[1];
      decrypted = java.aesBase64DecodeToString(
        data,
        java.base64Decode(key),
        "AES/CBC/PKCS5Padding",
        java.base64Decode(iv)
      );
      decoded = "";
      withDecoded = "";
      bridgeBufferLength = -1;
      strBytesRaw = "";
      strBytesType = "";
      strBytesKeys = "";
      if (decrypted) {
        try {
          rawBytes = sendMessage("strToBytes", JSON.stringify([" ", "UTF-8"]));
          strBytesRaw = JSON.stringify(rawBytes);
          strBytesType = typeof rawBytes;
          if (rawBytes && typeof rawBytes === "object") {
            strBytesKeys = Object.keys(rawBytes).join(",");
          }
        } catch (e) {
          strBytesRaw = "RAW_ERROR:" + e;
        }
        try {
          decoded = java.gzipToString(
            java.base64DecodeToByteArray(decrypted),
            "UTF-8"
          );
        } catch (e) {
          decoded = "GZIP_ERROR:" + e;
        }
        try {
          var javaImport = new JavaImporter();
          javaImport.importPackage(
            Packages.java.lang,
            Packages.java.io,
            Packages.java.util,
            Packages.java.util.zip
          );
          with (javaImport) {
            function decodeWithBridge(content) {
              decodeWithBridge = Base64.getDecoder().decode(String(content));
              byteArrayOutputStream = new ByteArrayOutputStream();
              byteArrayInputStream = new ByteArrayInputStream(decodeWithBridge);
              gZIPInputStream = new GZIPInputStream(byteArrayInputStream);
              bArr = String(" ").getBytes();
              bridgeBufferLength = bArr.length;
              while (true) {
                read = gZIPInputStream.read(bArr);
                if (read > 0) {
                  byteArrayOutputStream.write(bArr, 0, read);
                } else {
                  gZIPInputStream.close();
                  byteArrayInputStream.close();
                  byteArrayOutputStream.close();
                  return byteArrayOutputStream.toString();
                }
              }
            }
          }
          withDecoded = decodeWithBridge(decrypted);
        } catch (e) {
          withDecoded = "WITH_ERROR:" + e;
        }
      }
      JSON.stringify({
        iv: iv,
        decryptedLength: decrypted ? String(decrypted).length : 0,
        decryptedPreview: decrypted ? String(decrypted).substring(0, Math.min(120, String(decrypted).length)) : "",
        decodedLength: decoded ? String(decoded).length : 0,
        decodedPreview: decoded ? String(decoded).substring(0, Math.min(180, String(decoded).length)) : "",
        strBytesRaw: strBytesRaw,
        strBytesType: strBytesType,
        strBytesKeys: strBytesKeys,
        bridgeBufferLength: bridgeBufferLength,
        withDecodedLength: withDecoded ? String(withDecoded).length : 0,
        withDecodedPreview: withDecoded ? String(withDecoded).substring(0, Math.min(180, String(withDecoded).length)) : ""
      });
    ''', response.body);
  // ignore: avoid_print
  print('[debug] js intermediate=$intermediate');

  final rawContent = await rule.getStringAsync(
    source.ruleContent?.content ?? '',
    unescape: false,
  );
  // ignore: avoid_print
  print(
    '[debug] raw rule output len=${rawContent.trim().runes.length} '
    'preview=${_previewContent(rawContent)}',
  );
}
