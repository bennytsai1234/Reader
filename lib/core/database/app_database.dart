import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// AppDatabase - SQLite 全域管理器
/// 負責資料庫初始化、版本遷移 (Migration) 與實例維護
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'legado_reader.db');

    return await openDatabase(
      path,
      version: 5, // 升級版本 (新增淨化規則欄位)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 建立所有核心表格 (對標 Android Room Schema)
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    debugPrint('Database: Creating tables...');
    
    _createTable(batch, 'books', '''
      bookUrl TEXT PRIMARY KEY,
      tocUrl TEXT,
      origin TEXT,
      originName TEXT,
      name TEXT NOT NULL,
      author TEXT,
      kind TEXT,
      customTag TEXT,
      coverUrl TEXT,
      customCoverUrl TEXT,
      intro TEXT,
      customIntro TEXT,
      charset TEXT,
      type INTEGER DEFAULT 0,
      `group` INTEGER DEFAULT 0,
      latestChapterTitle TEXT,
      latestChapterTime INTEGER DEFAULT 0,
      lastCheckTime INTEGER DEFAULT 0,
      lastCheckCount INTEGER DEFAULT 0,
      totalChapterNum INTEGER DEFAULT 0,
      durChapterTitle TEXT,
      durChapterIndex INTEGER DEFAULT 0,
      durChapterPos INTEGER DEFAULT 0,
      durChapterTime INTEGER DEFAULT 0,
      wordCount TEXT,
      canUpdate INTEGER DEFAULT 1,
      `order` INTEGER DEFAULT 0,
      originOrder INTEGER DEFAULT 0,
      variable TEXT,
      readConfig TEXT,
      syncTime INTEGER DEFAULT 0,
      isInBookshelf INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'chapters', '''
      url TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      isVolume INTEGER DEFAULT 0,
      baseUrl TEXT,
      bookUrl TEXT NOT NULL,
      `index` INTEGER NOT NULL,
      isVip INTEGER DEFAULT 0,
      isPay INTEGER DEFAULT 0,
      resourceUrl TEXT,
      tag TEXT,
      wordCount TEXT,
      start INTEGER,
      `end` INTEGER,
      startFragmentId TEXT,
      endFragmentId TEXT,
      variable TEXT,
      content TEXT
    ''');
    batch.execute('CREATE INDEX idx_chapters_bookUrl ON chapters (bookUrl)');

    _createTable(batch, 'book_sources', '''
      bookSourceUrl TEXT PRIMARY KEY,
      bookSourceName TEXT NOT NULL,
      bookSourceType INTEGER DEFAULT 0,
      bookSourceGroup TEXT,
      bookSourceComment TEXT,
      loginUrl TEXT,
      loginUi TEXT,
      loginCheckJs TEXT,
      coverDecodeJs TEXT,
      bookUrlPattern TEXT,
      header TEXT,
      variableComment TEXT,
      customOrder INTEGER DEFAULT 0,
      weight INTEGER DEFAULT 0,
      enabled INTEGER DEFAULT 1,
      enabledExplore INTEGER DEFAULT 1,
      enabledCookieJar INTEGER DEFAULT 1,
      lastUpdateTime INTEGER DEFAULT 0,
      respondTime INTEGER DEFAULT 180000,
      jsLib TEXT,
      concurrentRate TEXT,
      exploreUrl TEXT,
      exploreScreen TEXT,
      searchUrl TEXT,
      ruleSearch TEXT,
      ruleExplore TEXT,
      ruleBookInfo TEXT,
      ruleToc TEXT,
      ruleContent TEXT,
      ruleReview TEXT
    ''');

    _createTable(batch, 'book_groups', '''
      groupId INTEGER PRIMARY KEY,
      groupName TEXT NOT NULL,
      `order` INTEGER DEFAULT 0,
      show INTEGER DEFAULT 1,
      coverPath TEXT,
      enableRefresh INTEGER DEFAULT 1,
      bookSort INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'search_history', '''
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyword TEXT UNIQUE NOT NULL,
      searchTime INTEGER NOT NULL
    ''');

    _createTable(batch, 'replace_rules', '''
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      pattern TEXT NOT NULL,
      replacement TEXT,
      scope TEXT,
      scopeTitle INTEGER DEFAULT 0,
      scopeContent INTEGER DEFAULT 1,
      excludeScope TEXT,
      isEnabled INTEGER DEFAULT 1,
      isRegex INTEGER DEFAULT 1,
      timeoutMillisecond INTEGER DEFAULT 3000,
      `group` TEXT,
      `order` INTEGER DEFAULT 0
    ''');


    _createTable(batch, 'bookmarks', '''
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      time INTEGER NOT NULL,
      bookName TEXT NOT NULL,
      bookAuthor TEXT,
      chapterIndex INTEGER DEFAULT 0,
      chapterPos INTEGER DEFAULT 0,
      chapterName TEXT,
      bookUrl TEXT NOT NULL,
      bookText TEXT,
      content TEXT
    ''');

    _createTable(batch, 'cookies', '''
      url TEXT PRIMARY KEY,
      cookie TEXT NOT NULL
    ''');

    _createTable(batch, 'dict_rules', '''
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      urlRule TEXT,
      showRule TEXT,
      enabled INTEGER DEFAULT 1,
      sortNumber INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'http_tts', '''
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      url TEXT NOT NULL,
      contentType TEXT,
      concurrentRate TEXT,
      loginUrl TEXT,
      loginUi TEXT,
      header TEXT,
      jsLib TEXT,
      enabledCookieJar INTEGER DEFAULT 0,
      loginCheckJs TEXT,
      lastUpdateTime INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'read_records', '''
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookName TEXT NOT NULL,
      deviceId TEXT NOT NULL,
      readTime INTEGER DEFAULT 0,
      lastRead INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'rss_articles', '''
      link TEXT PRIMARY KEY,
      origin TEXT NOT NULL,
      sort TEXT NOT NULL,
      title TEXT NOT NULL,
      `order` INTEGER DEFAULT 0,
      pubDate TEXT,
      description TEXT,
      content TEXT,
      image TEXT,
      `group` TEXT DEFAULT '預設分組',
      read INTEGER DEFAULT 0,
      variable TEXT
    ''');

    _createTable(batch, 'rss_sources', '''
      sourceUrl TEXT PRIMARY KEY,
      sourceName TEXT NOT NULL,
      sourceIcon TEXT,
      sourceGroup TEXT,
      sourceComment TEXT,
      enabled INTEGER DEFAULT 1,
      variableComment TEXT,
      jsLib TEXT,
      enabledCookieJar INTEGER DEFAULT 1,
      concurrentRate TEXT,
      header TEXT,
      loginUrl TEXT,
      loginUi TEXT,
      loginCheckJs TEXT,
      coverDecodeJs TEXT,
      sortUrl TEXT,
      singleUrl INTEGER DEFAULT 0,
      articleStyle INTEGER DEFAULT 0,
      ruleArticles TEXT,
      ruleNextPage TEXT,
      ruleTitle TEXT,
      rulePubDate TEXT,
      ruleDescription TEXT,
      ruleImage TEXT,
      ruleLink TEXT,
      ruleContent TEXT,
      contentWhitelist TEXT,
      contentBlacklist TEXT,
      shouldOverrideUrlLoading TEXT,
      style TEXT,
      enableJs INTEGER DEFAULT 1,
      loadWithBaseUrl INTEGER DEFAULT 1,
      injectJs TEXT,
      lastUpdateTime INTEGER DEFAULT 0,
      customOrder INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'rss_stars', '''
      link TEXT NOT NULL,
      origin TEXT NOT NULL,
      sort TEXT NOT NULL,
      title TEXT NOT NULL,
      starTime INTEGER DEFAULT 0,
      pubDate TEXT,
      description TEXT,
      content TEXT,
      image TEXT,
      `group` TEXT DEFAULT '默认分组',
      variable TEXT,
      PRIMARY KEY (link, origin)
    ''');

    _createTable(batch, 'servers', '''
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      config TEXT,
      sortNumber INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'txt_toc_rules', '''
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      rule TEXT NOT NULL,
      example TEXT,
      serialNumber INTEGER DEFAULT -1,
      enable INTEGER DEFAULT 1
    ''');

    _createTable(batch, 'cache', '''
      `key` TEXT PRIMARY KEY,
      `value` TEXT,
      deadline INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'keyboard_assists', '''
      `key` TEXT PRIMARY KEY,
      type INTEGER DEFAULT 0,
      `value` TEXT,
      serialNo INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'rss_read_records', '''
      record TEXT PRIMARY KEY,
      title TEXT,
      readTime INTEGER DEFAULT 0,
      read INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'rule_subs', '''
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      url TEXT NOT NULL,
      type INTEGER DEFAULT 0,
      enabled INTEGER DEFAULT 1,
      `order` INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'source_subscriptions', '''
      url TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type INTEGER DEFAULT 0,
      enabled INTEGER DEFAULT 1,
      `order` INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'search_books', '''
      bookUrl TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      author TEXT,
      kind TEXT,
      coverUrl TEXT,
      intro TEXT,
      wordCount TEXT,
      latestChapterTitle TEXT,
      origin TEXT,
      originName TEXT,
      originOrder INTEGER DEFAULT 0,
      type INTEGER DEFAULT 0,
      addTime INTEGER DEFAULT 0,
      variable TEXT,
      tocUrl TEXT
    ''');

    _createTable(batch, 'download_tasks', '''
      bookUrl TEXT PRIMARY KEY,
      bookName TEXT NOT NULL,
      currentChapterIndex INTEGER DEFAULT 0,
      totalChapterCount INTEGER DEFAULT 0,
      status INTEGER DEFAULT 0,
      successCount INTEGER DEFAULT 0,
      errorCount INTEGER DEFAULT 0,
      addTime INTEGER DEFAULT 0
    ''');

    _createTable(batch, 'search_keywords', '''
      word TEXT PRIMARY KEY,
      usage INTEGER DEFAULT 0,
      lastUseTime INTEGER DEFAULT 0
    ''');

    await batch.commit();
    debugPrint('Database Tables Created Successfully');
  }

  void _createTable(Batch batch, String name, String columns) {
    debugPrint('Database: Registering table $name');
    batch.execute('CREATE TABLE $name ($columns)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final batch = db.batch();
      // 為 books 表格補上缺失欄位
      batch.execute('ALTER TABLE books ADD COLUMN tocUrl TEXT');
      batch.execute('ALTER TABLE books ADD COLUMN kind TEXT');
      batch.execute('ALTER TABLE books ADD COLUMN charset TEXT');
      batch.execute('ALTER TABLE books ADD COLUMN wordCount TEXT');
      batch.execute('ALTER TABLE books ADD COLUMN originOrder INTEGER DEFAULT 0');
      batch.execute('ALTER TABLE books ADD COLUMN readConfig TEXT');
      batch.execute('ALTER TABLE books ADD COLUMN syncTime INTEGER DEFAULT 0');
      // 移除 Model 不存在的 customName (選用，SQLite 不直接支援 DROP COLUMN, 這裡先留著或無視)
      await batch.commit();
      debugPrint('Database Upgraded to v2: Added missing columns to books table');
    }

    if (oldVersion < 3) {
      final batch = db.batch();
      // 為 chapters 表格補上缺失欄位
      batch.execute('ALTER TABLE chapters ADD COLUMN isVolume INTEGER DEFAULT 0');
      batch.execute('ALTER TABLE chapters ADD COLUMN baseUrl TEXT');
      batch.execute('ALTER TABLE chapters ADD COLUMN isPay INTEGER DEFAULT 0');
      batch.execute('ALTER TABLE chapters ADD COLUMN resourceUrl TEXT');
      batch.execute('ALTER TABLE chapters ADD COLUMN wordCount TEXT');
      batch.execute('ALTER TABLE chapters ADD COLUMN start INTEGER');
      batch.execute('ALTER TABLE chapters ADD COLUMN `end` INTEGER');
      await batch.commit();
      debugPrint('Database Upgraded to v3: Added missing columns to chapters table');
    }

    if (oldVersion < 4) {
      final batch = db.batch();
      // 為 book_sources 表格補上缺失欄位
      batch.execute('ALTER TABLE book_sources ADD COLUMN loginUi TEXT');
      // 確保其他可能缺失的欄位也補上 (依據 _onCreate 的定義)
      // 如果 respondTime 之前是 0, 這裡可以更新為預設值 180000
      batch.execute('UPDATE book_sources SET respondTime = 180000 WHERE respondTime = 0 OR respondTime IS NULL');
      await batch.commit();
      debugPrint('Database Upgraded to v4: Added missing columns to book_sources table');
    }
    if (oldVersion < 5) {
      final batch = db.batch();
      // 為 replace_rules 補上缺失欄位
      batch.execute('ALTER TABLE replace_rules ADD COLUMN scopeTitle INTEGER DEFAULT 0');
      batch.execute('ALTER TABLE replace_rules ADD COLUMN scopeContent INTEGER DEFAULT 1');
      batch.execute('ALTER TABLE replace_rules ADD COLUMN excludeScope TEXT');
      batch.execute('ALTER TABLE replace_rules ADD COLUMN isEnabled INTEGER DEFAULT 1');
      batch.execute('ALTER TABLE replace_rules ADD COLUMN timeoutMillisecond INTEGER DEFAULT 3000');
      
      // 遷移舊的 enabled 數據到新的 isEnabled
      try {
        batch.execute('UPDATE replace_rules SET isEnabled = enabled');
      } catch (_) {}
      
      await batch.commit();
      debugPrint('Database Upgraded to v5: Added missing columns to replace_rules table');
    }
  }


  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}

/// BaseDao - SQLite DAO 基底類別
abstract class BaseDao<T> {
  final AppDatabase appDatabase;
  final String tableName;

  BaseDao(this.appDatabase, this.tableName);

  Future<Database> get db => appDatabase.database;

  /// 通用插入或更新 (UPSERT) 邏輯
  Future<int> insertOrUpdate(Map<String, dynamic> row) async {
    final client = await db;
    return await client.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> delete(String where, [List<dynamic>? whereArgs]) async {
    final client = await db;
    return await client.delete(tableName, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> queryAll({String? orderBy}) async {
    final client = await db;
    return await client.query(tableName, orderBy: orderBy);
  }

  Future<int> clear() async {
    final client = await db;
    return await client.delete(tableName);
  }
}
