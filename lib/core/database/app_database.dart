import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/app_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Books,
  Chapters,
  BookSources,
  BookGroups,
  SearchHistory,
  ReplaceRules,
  Bookmarks,
  Cookies,
  DictRules,
  HttpTts,
  ReadRecords,
  Servers,
  TxtTocRules,
  Cache,
  KeyboardAssists,
  RuleSubs,
  SourceSubscriptions,
  SearchBooks,
  DownloadTasks,
  SearchKeywords,
])
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 7) {
        // 使用 customStatement 進行原始 SQL 執行
        await customStatement('DROP TABLE IF EXISTS rss_articles');
        await customStatement('DROP TABLE IF EXISTS rss_sources');
        await customStatement('DROP TABLE IF EXISTS rss_stars');
        await customStatement('DROP TABLE IF EXISTS rss_read_records');
      }
    },
  );

  static Future<String> getDatabasePath() async {
    final appSupportDir = await getApplicationSupportDirectory();
    return p.join(appSupportDir.path, 'databases', 'legado_reader.db');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(appSupportDir.path, 'databases'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    final file = File(p.join(dbDir.path, 'legado_reader.db'));
    return NativeDatabase.createInBackground(file);
  });
}
