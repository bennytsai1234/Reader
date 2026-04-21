import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/source_switch_service.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_source_switch_facade.dart';

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
  group('ReaderSourceSwitchFacade', () {
    test(
      'autoChangeSourceForCurrentChapter 成功時會套用 resolution 並回傳成功訊息',
      () async {
        final service =
            _FakeSourceSwitchService()..autoResolution = _makeResolution();
        final facade = ReaderSourceSwitchFacade(service: service);
        SourceSwitchResolution? appliedResolution;

        final result = await facade.autoChangeSourceForCurrentChapter(
          book: _makeBook(),
          targetChapterIndex: 2,
          targetChapterTitle: '章節 3',
          applyResolution: (resolution) async {
            appliedResolution = resolution;
          },
        );

        expect(result.changed, isTrue);
        expect(result.message, '已切換到 來源 B');
        expect(result.error, isNull);
        expect(appliedResolution, isNotNull);
      },
    );

    test('autoChangeSourceForCurrentChapter 找不到來源時回傳未切換訊息', () async {
      final service = _FakeSourceSwitchService();
      final facade = ReaderSourceSwitchFacade(service: service);

      final result = await facade.autoChangeSourceForCurrentChapter(
        book: _makeBook(),
        targetChapterIndex: 1,
        targetChapterTitle: '章節 2',
        applyResolution: (_) async {},
      );

      expect(result.changed, isFalse);
      expect(result.message, '找不到可自動切換的可用來源');
      expect(result.error, isNull);
    });

    test('changeBookSource 失敗時會保留錯誤供上層處理', () async {
      final service =
          _FakeSourceSwitchService()
            ..manualError = StateError('manual switch failed');
      final facade = ReaderSourceSwitchFacade(service: service);

      final result = await facade.changeBookSource(
        book: _makeBook(),
        searchBook: _makeSearchBook(),
        targetChapterIndex: 0,
        targetChapterTitle: '章節 1',
        applyResolution: (_) async {},
      );

      expect(result.changed, isFalse);
      expect(result.message, contains('換源失敗'));
      expect(result.error, isA<StateError>());
    });

    test('changeBookSource 成功時會套用 resolution 並回傳成功訊息', () async {
      final service =
          _FakeSourceSwitchService()..manualResolution = _makeResolution();
      final facade = ReaderSourceSwitchFacade(service: service);
      SourceSwitchResolution? appliedResolution;

      final result = await facade.changeBookSource(
        book: _makeBook(),
        searchBook: _makeSearchBook(),
        targetChapterIndex: 0,
        targetChapterTitle: '章節 1',
        applyResolution: (resolution) async {
          appliedResolution = resolution;
        },
      );

      expect(result.changed, isTrue);
      expect(result.message, '已切換到 來源 B');
      expect(appliedResolution, isNotNull);
    });
  });
}
