import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/source_switch_service.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_source_switch_facade.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_source_switch_runtime.dart';

class _DummyBookSourceDao implements BookSourceDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSourceSwitchService extends SourceSwitchService {
  _FakeSourceSwitchService()
    : super(service: BookSourceService(), sourceDao: _DummyBookSourceDao());

  SourceSwitchResolution? autoResolution;
  Object? autoError;
  SourceSwitchResolution? manualResolution;
  Object? manualError;

  @override
  Future<SourceSwitchResolution?> autoResolveSwitch(
    Book currentBook, {
    bool checkAuthor = true,
    int? targetChapterIndex,
    String? targetChapterTitle,
  }) async {
    if (autoError != null) throw autoError!;
    return autoResolution;
  }

  @override
  Future<SourceSwitchResolution> resolveSwitch(
    Book currentBook,
    SearchBook candidate, {
    int? targetChapterIndex,
    String? targetChapterTitle,
    bool validateTargetContent = false,
  }) async {
    if (manualError != null) throw manualError!;
    if (manualResolution == null) {
      throw StateError('manualResolution not configured');
    }
    return manualResolution!;
  }
}

Book _makeBook() => Book(
  bookUrl: 'https://example.com/book',
  name: '測試書籍',
  author: 'Author',
  origin: 'https://example.com/source',
);

BookSource _makeSource({
  String url = 'https://example.com/source-b',
  String name = '來源 B',
}) => BookSource(bookSourceUrl: url, bookSourceName: name);

SearchBook _makeSearchBook({String origin = 'https://example.com/source-b'}) =>
    SearchBook(
      bookUrl: 'https://example.com/new-book',
      name: '測試書籍',
      author: 'Author',
      origin: origin,
      originName: '來源 B',
    );

SourceSwitchResolution _makeResolution() {
  final source = _makeSource();
  return SourceSwitchResolution(
    searchBook: _makeSearchBook(origin: source.bookSourceUrl),
    source: source,
    migratedBook: _makeSearchBook(origin: source.bookSourceUrl).toBook(),
    chapters: <BookChapter>[
      BookChapter(
        title: '章節 1',
        index: 0,
        bookUrl: 'https://example.com/new-book',
      ),
    ],
    targetChapterIndex: 0,
    validatedContent: 'validated content',
  );
}

void main() {
  group('ReaderSourceSwitchRuntime', () {
    test(
      'autoChangeSourceForCurrentChapter 會暴露 in-flight state 並在完成後復位',
      () async {
        final service =
            _FakeSourceSwitchService()..autoResolution = _makeResolution();
        final runtime = ReaderSourceSwitchRuntime(
          facade: ReaderSourceSwitchFacade(service: service),
        );
        final notifications = <String?>[];
        final releaseApply = Completer<void>();

        final future = runtime.autoChangeSourceForCurrentChapter(
          book: _makeBook(),
          targetChapterIndex: 0,
          targetChapterTitle: '章節 1',
          applyResolution: (_) async {
            expect(runtime.isSwitching, isTrue);
            expect(runtime.message, '正在尋找可用來源...');
            await releaseApply.future;
          },
          notifyListeners: () => notifications.add(runtime.message),
        );

        expect(runtime.isSwitching, isTrue);
        expect(runtime.message, '正在尋找可用來源...');
        expect(notifications, ['正在尋找可用來源...']);

        releaseApply.complete();
        final result = await future;

        expect(result, isNotNull);
        expect(result!.changed, isTrue);
        expect(runtime.isSwitching, isFalse);
        expect(runtime.message, '已切換到 來源 B');
        expect(notifications.last, '已切換到 來源 B');
      },
    );

    test('忙碌中重複觸發會直接忽略第二次請求', () async {
      final service =
          _FakeSourceSwitchService()..autoResolution = _makeResolution();
      final runtime = ReaderSourceSwitchRuntime(
        facade: ReaderSourceSwitchFacade(service: service),
      );
      final releaseApply = Completer<void>();

      final first = runtime.autoChangeSourceForCurrentChapter(
        book: _makeBook(),
        targetChapterIndex: 0,
        targetChapterTitle: '章節 1',
        applyResolution: (_) => releaseApply.future,
        notifyListeners: () {},
      );

      final second = await runtime.changeBookSource(
        book: _makeBook(),
        searchBook: _makeSearchBook(),
        targetChapterIndex: 0,
        targetChapterTitle: '章節 1',
        applyResolution: (_) async {},
        notifyListeners: () {},
      );

      expect(second, isNull);
      expect(runtime.isSwitching, isTrue);

      releaseApply.complete();
      final firstResult = await first;
      expect(firstResult?.changed, isTrue);
      expect(runtime.isSwitching, isFalse);
    });

    test('changeBookSource 失敗時會保留錯誤結果並恢復 idle state', () async {
      final service =
          _FakeSourceSwitchService()
            ..manualError = StateError('manual switch failed');
      final runtime = ReaderSourceSwitchRuntime(
        facade: ReaderSourceSwitchFacade(service: service),
      );
      final notifications = <String?>[];

      final result = await runtime.changeBookSource(
        book: _makeBook(),
        searchBook: _makeSearchBook(),
        targetChapterIndex: 0,
        targetChapterTitle: '章節 1',
        applyResolution: (_) async {},
        notifyListeners: () => notifications.add(runtime.message),
      );

      expect(result, isNotNull);
      expect(result!.changed, isFalse);
      expect(result.error, isA<StateError>());
      expect(runtime.isSwitching, isFalse);
      expect(runtime.message, contains('換源失敗'));
      expect(notifications.first, '正在切換來源...');
      expect(notifications.last, contains('換源失敗'));
    });
  });
}
