import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';

import 'source_validation_support.dart';

void main() {
  final service = BookSourceService();
  final start = int.tryParse(Platform.environment['SOURCE_START'] ?? '') ?? 0;
  final limit = int.tryParse(Platform.environment['SOURCE_LIMIT'] ?? '') ?? 10;
  final perSourceTimeoutSeconds =
      int.tryParse(Platform.environment['SOURCE_TIMEOUT_SECONDS'] ?? '') ?? 20;
  late final List results;

  setUpAll(() async {
    await initSourceValidationEnvironment();
    final fetched = await fetchSources(limit: start + limit);
    final sources = fetched.skip(start).take(limit).toList();
    results = <SourceValidationResult>[];
    for (var i = 0; i < sources.length; i++) {
      late final SourceValidationResult result;
      try {
        result = await validateSourceFlow(
          service,
          sources[i],
          index: start + i + 1,
        ).timeout(Duration(seconds: perSourceTimeoutSeconds));
      } catch (error) {
        final classification = classifyValidationFailure(
          error,
          source: sources[i],
          stage: 'timeout',
        );
        result = SourceValidationResult(
          index: start + i + 1,
          sourceName: sources[i].bookSourceName,
          outcome: classification.outcome,
          stage: 'timeout',
          duration: Duration(seconds: perSourceTimeoutSeconds),
          failure: compactError(error),
          category: classification.category,
        );
      }
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
      final skipped = typedResults.where((it) => it.skipped).length;
      final failed = typedResults.length - passed - skipped;
      final categories = <String, int>{};
      for (final result in typedResults) {
        final category = result.category;
        if (category == null || category.isEmpty) continue;
        categories.update(category, (value) => value + 1, ifAbsent: () => 1);
      }
      // ignore: avoid_print
      print(
        '[batch] summary: range=${start + 1}-${start + limit} '
        'pass=$passed skip=$skipped fail=$failed '
        'categories=$categories',
      );
    },
    timeout: const Timeout(Duration(minutes: 35)),
  );
}
