import 'dart:io' hide Cookie;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/app_tables.dart';
// model imports required by app_database.g.dart (part shares this namespace)
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/bookmark.dart';
import '../models/replace_rule.dart';
import '../models/book_source.dart';
import '../models/book_group.dart';
import '../models/cookie.dart';
import '../models/dict_rule.dart';
import '../models/http_tts.dart';
import '../models/read_record.dart';
import '../models/server.dart';
import '../models/txt_toc_rule.dart';
import '../models/cache.dart';
import '../models/keyboard_assist.dart';
import '../models/rule_sub.dart';
import '../models/source_subscription.dart';
import '../models/search_book.dart';
import '../models/download_task.dart';
import '../models/search_keyword.dart';
import 'dao/book_dao.dart';
import 'dao/chapter_dao.dart';
import 'dao/book_source_dao.dart';
import 'dao/book_group_dao.dart';
import 'dao/bookmark_dao.dart';
import 'dao/replace_rule_dao.dart';
import 'dao/search_history_dao.dart';
import 'dao/cookie_dao.dart';
import 'dao/dict_rule_dao.dart';
import 'dao/http_tts_dao.dart';
import 'dao/read_record_dao.dart';
import 'dao/server_dao.dart';
import 'dao/txt_toc_rule_dao.dart';
import 'dao/cache_dao.dart';
import 'dao/keyboard_assist_dao.dart';
import 'dao/rule_sub_dao.dart';
import 'dao/source_subscription_dao.dart';
import 'dao/search_book_dao.dart';
import 'dao/download_dao.dart';
import 'dao/search_keyword_dao.dart';
import 'dao/reader_chapter_content_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Books,
    Chapters,
    ReaderChapterContents,
    BookSources,
    BookGroups,
    SearchHistoryTable,
    ReplaceRules,
    Bookmarks,
    Cookies,
    DictRules,
    HttpTtsTable,
    ReadRecords,
    Servers,
    TxtTocRules,
    CacheTable,
    KeyboardAssists,
    RuleSubs,
    SourceSubscriptions,
    SearchBooks,
    DownloadTasks,
    SearchKeywords,
  ],
  daos: [
    BookDao,
    ChapterDao,
    BookSourceDao,
    BookGroupDao,
    BookmarkDao,
    ReplaceRuleDao,
    SearchHistoryDao,
    CookieDao,
    DictRuleDao,
    HttpTtsDao,
    ReadRecordDao,
    ServerDao,
    TxtTocRuleDao,
    CacheDao,
    KeyboardAssistDao,
    RuleSubDao,
    SourceSubscriptionDao,
    SearchBookDao,
    DownloadDao,
    SearchKeywordDao,
    ReaderChapterContentDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // 確保所有資料表存在（處理舊版升級路徑中缺少的表）
      for (final table in allTables) {
        await m.createTable(table);
      }
      if (from < 7) {
        await customStatement('DROP TABLE IF EXISTS rss_articles');
        await customStatement('DROP TABLE IF EXISTS rss_sources');
        await customStatement('DROP TABLE IF EXISTS rss_stars');
        await customStatement('DROP TABLE IF EXISTS rss_read_records');
      }
      if (from < 8) {
        // DownloadTasks: 新增 startChapterIndex / endChapterIndex 欄位
        await customStatement(
          'ALTER TABLE download_tasks ADD COLUMN "startChapterIndex" INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE download_tasks ADD COLUMN "endChapterIndex" INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 9) {
        await customStatement(
          'ALTER TABLE books ADD COLUMN "readerAnchorJson" TEXT',
        );
      }
      if (from < 11) {
        await customStatement(
          'ALTER TABLE books RENAME COLUMN "durChapterIndex" TO "chapterIndex"',
        );
        await customStatement(
          'ALTER TABLE books RENAME COLUMN "durChapterPos" TO "charOffset"',
        );
      }
      if (from < 13) {
        await customStatement(
          'DROP TABLE IF EXISTS reader_temp_chapter_caches',
        );
        await m.createTable(readerChapterContents);
      }
      if (from < 14) {
        await _addBookStorageColumnsIfMissing();
        await _migrateReaderChapterContentsToStorageSchema(m);
      }
      if (from < 15) {
        await _addReaderChapterContentStatusColumnsIfMissing();
      }
    },
    beforeOpen: (details) async {
      if (!details.wasCreated) {
        // 安全補強：確保所有表存在（處理已在最新版本但資料表缺失的情況）
        final m = Migrator(this);
        for (final table in allTables) {
          await m.createTable(table);
        }
        await _addBookStorageColumnsIfMissing();
        await _migrateReaderChapterContentsToStorageSchema(m);
        await _addReaderChapterContentStatusColumnsIfMissing();
      }
    },
  );

  Future<void> _addBookStorageColumnsIfMissing() async {
    await _addColumnIfMissing(
      tableName: 'books',
      columnName: 'coverLocalPath',
      columnSql: 'ALTER TABLE books ADD COLUMN "coverLocalPath" TEXT',
    );
    await _addColumnIfMissing(
      tableName: 'books',
      columnName: 'customCoverLocalPath',
      columnSql: 'ALTER TABLE books ADD COLUMN "customCoverLocalPath" TEXT',
    );
  }

  Future<void> _migrateReaderChapterContentsToStorageSchema(
    Migrator migrator,
  ) async {
    final hasContentKey = await _columnExists(
      'reader_chapter_contents',
      'contentKey',
    );
    if (hasContentKey) return;

    final hasLegacyCacheKey = await _columnExists(
      'reader_chapter_contents',
      'cacheKey',
    );
    if (!hasLegacyCacheKey) {
      await migrator.createTable(readerChapterContents);
      return;
    }

    await customStatement(
      'ALTER TABLE reader_chapter_contents RENAME TO reader_chapter_contents_old',
    );
    await migrator.createTable(readerChapterContents);
    await customStatement('''
      INSERT OR REPLACE INTO reader_chapter_contents
        ("contentKey", origin, "bookUrl", "chapterUrl", "chapterIndex", content, status, "failureMessage", "updatedAt")
      SELECT
        "cacheKey", origin, "bookUrl", "chapterUrl", "chapterIndex", content, 1, NULL, "updatedAt"
      FROM reader_chapter_contents_old
      WHERE content IS NOT NULL AND content != ''
    ''');
    await customStatement('DROP TABLE IF EXISTS reader_chapter_contents_old');
  }

  Future<void> _addReaderChapterContentStatusColumnsIfMissing() async {
    await _addColumnIfMissing(
      tableName: 'reader_chapter_contents',
      columnName: 'status',
      columnSql:
          'ALTER TABLE reader_chapter_contents ADD COLUMN "status" INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      tableName: 'reader_chapter_contents',
      columnName: 'failureMessage',
      columnSql:
          'ALTER TABLE reader_chapter_contents ADD COLUMN "failureMessage" TEXT',
    );
  }

  Future<void> _addColumnIfMissing({
    required String tableName,
    required String columnName,
    required String columnSql,
  }) async {
    if (await _columnExists(tableName, columnName)) return;
    await customStatement(columnSql);
  }

  Future<bool> _columnExists(String tableName, String columnName) async {
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return rows.any((row) => row.data['name'] == columnName);
  }

  static Future<String> getDatabasePath() async {
    final appSupportDir = await getApplicationSupportDirectory();
    return p.join(appSupportDir.path, 'databases', 'inkpage_reader.db');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(appSupportDir.path, 'databases'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    final file = File(p.join(dbDir.path, 'inkpage_reader.db'));
    return NativeDatabase.createInBackground(file);
  });
}
