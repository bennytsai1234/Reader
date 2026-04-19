import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';

import 'source_validation_support.dart';

void main() {
  final service = BookSourceService();
  final start = int.tryParse(Platform.environment['SOURCE_START'] ?? '') ?? 0;
  final limit = int.tryParse(Platform.environment['SOURCE_LIMIT'] ?? '') ?? 10;
  late final List results;

  setUpAll(() async {
    await initSourceValidationEnvironment();
    final fetched = await fetchSources(limit: start + limit);
    final sources = fetched.skip(start).take(limit).toList();
    results = <SourceValidationResult>[];
    for (var i = 0; i < sources.length; i++) {
      final result = await validateSourceFlow(
        service,
        sources[i],
        index: start + i + 1,
      ).timeout(const Duration(minutes: 3));
      results.add(result);
      // ignore: avoid_print
      print('[batch] ${result.toSummaryLine()}');
    }
  });

  test(
    'audit configured imported sources',
    () {
      expect(results, hasLength(limit));

      final typedResults = results.cast<SourceValidationResult>();
      final passed = typedResults.where((it) => it.passed).length;
      // ignore: avoid_print
      print(
        '[batch] summary: range=${start + 1}-${start + limit} pass=$passed fail=${typedResults.length - passed}',
      );
    },
    timeout: const Timeout(Duration(minutes: 35)),
  );
}
