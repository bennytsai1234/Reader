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

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Books,
    Chapters,
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
  ],
)
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 9;

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
    },
    beforeOpen: (details) async {
      if (!details.wasCreated) {
        // 安全補強：確保所有表存在（處理已在最新版本但資料表缺失的情況）
        final m = Migrator(this);
        for (final table in allTables) {
          await m.createTable(table);
        }
      }
    },
  );

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
