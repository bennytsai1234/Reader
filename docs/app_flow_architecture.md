# App 流程圖與架構圖

這份文件用 Mermaid 描述墨頁 Inkpage 目前 `main` 的整體架構與主要流程。圖中的節點只描述已存在的實作，不包含未接線的設計稿。

## 圖例

- `features/*`：頁面、feature provider、feature controller 與 UI orchestration。
- `core/services`：跨 feature 業務服務。
- `core/engine`：書源規則、JS、HTML/JSON/XPath/CSS/Regex parser 與 WebBook。
- `core/database`：Drift tables、DAO、SQLite。
- `SharedPreferences`：偏好設定與部分 reader setting。

## 總架構圖

```mermaid
flowchart TB
  subgraph App["Flutter App"]
    Main["main.dart\nDI, error handling, Workmanager, MaterialApp"]
    Providers["app_providers.dart\nMultiProvider"]
    Splash["SplashPage"]
    Shell["MainPage\nBottom Navigation + IndexedStack"]
  end

  subgraph Features["features/"]
    Bookshelf["bookshelf\nBookshelfProvider"]
    Search["search\nSearchProvider + SearchModel"]
    Explore["explore\nExploreProvider"]
    BookDetail["book_detail\nBookDetailProvider"]
    Reader["reader\nReaderPage + ReaderRuntime"]
    SourceManager["source_manager\nSourceManagerProvider"]
    Settings["settings\nSettingsProvider"]
    Browser["browser\nWebView / verification"]
    OtherFeatures["bookmark / dict / replace_rule\ncache_manager / txt_toc_rule"]
  end

  subgraph Core["core/"]
    DI["di/get_it"]
    Services["services\nBookSourceService, Backup, Restore,\nTTS, Download, CheckSource"]
    Engine["engine\nAnalyzeUrl, AnalyzeRule, WebBook,\nJS bridge, parsers"]
    Database["database\nAppDatabase, DAOs, Drift tables"]
    Models["models\nBook, BookSource, Chapter,\nSearchBook, rules"]
    Storage["storage\nAppStoragePaths"]
    Network["network + NetworkService\nDio, CookieJar, interceptors"]
    LocalBook["local_book\nTXT / EPUB / UMD parsers"]
  end

  subgraph External["Platform / External"]
    SQLite["SQLite\ninkpage_reader.db"]
    Prefs["SharedPreferences"]
    Assets["assets/default_sources\nOpenCC, web assets, fonts"]
    Web["Book source websites"]
    Files["Local files\nbackup zip, local books, covers"]
    TTS["System TTS / audio"]
  end

  Main --> DI
  Main --> Providers
  Providers --> Splash
  Splash --> Shell
  Shell --> Bookshelf
  Shell --> Explore
  Shell --> Settings

  Bookshelf --> BookDetail
  Search --> BookDetail
  Explore --> BookDetail
  BookDetail --> Reader
  Settings --> SourceManager
  Settings --> OtherFeatures
  SourceManager --> Browser

  Features --> Services
  Features --> Database
  Features --> Prefs
  Reader --> LocalBook
  Reader --> Services
  Reader --> Database

  Services --> Engine
  Services --> Database
  Services --> Storage
  Services --> Network
  Engine --> Network
  Engine --> Models
  Database --> SQLite
  Storage --> Files
  Network --> Web
  Services --> TTS
  Splash --> Assets
```

## 啟動流程

```mermaid
flowchart TD
  Start["App process starts"] --> Binding["WidgetsFlutterBinding.ensureInitialized"]
  Binding --> ErrorHandling["Register Flutter/ErrorWidget/zoned error handling"]
  ErrorHandling --> ConfigureDI["configureDependencies"]
  ConfigureDI --> RegisterDb["Create AppDatabase singleton\nRegister all DAOs"]
  RegisterDb --> RegisterServices["Register NetworkService, TTSService, Logger"]
  RegisterServices --> InitServices["CrashHandler.init\nNetworkService.init\nTTSService.init"]
  InitServices --> RunApp["runApp(MultiProvider + LegadoReaderApp)"]
  RunApp --> MaterialApp["MaterialApp\nhome: SplashPage"]
  MaterialApp --> Splash["SplashPage"]
  Splash --> Essential["DefaultData.initEssential\nAppTheme.init"]
  Essential --> MainPage["Navigator.pushReplacement(MainPage)"]
  MainPage --> FirstFrame["Post first frame startup"]
  FirstFrame --> Deferred["DefaultData.initDeferred"]
  Deferred --> Defaults["Import default sources,\nTXT TOC rules, HTTP TTS, dict rules"]
  Deferred --> Maintenance["Maintenance\nadjust source sort,\nclear old search history,\nclear expired cache"]
  FirstFrame --> Workmanager["Initialize Workmanager"]

  Workmanager --> BackgroundTask["Background isolate task"]
  BackgroundTask --> BackgroundDI["configureDependencies again"]
  BackgroundDI --> ReadBookshelf["BookDao.getInBookshelf"]
```

## 主導航與頁面流程

```mermaid
flowchart LR
  Splash["SplashPage"] --> Main["MainPage"]

  Main --> BookshelfTab["書架 tab\nBookshelfPage"]
  Main --> ExploreTab["發現 tab\nExplorePage"]
  Main --> MineTab["我的 tab\nSettingsPage"]

  BookshelfTab --> BookDetail["BookDetailPage"]
  BookshelfTab --> SearchPage["SearchPage"]
  BookshelfTab --> ImportLocal["Local book import\nTXT / EPUB / UMD"]

  ExploreTab --> ExploreShow["ExploreShowPage"]
  ExploreShow --> BookDetail

  SearchPage --> SearchScope["Search scope sheet"]
  SearchPage --> BookDetail

  BookDetail --> ReaderPage["ReaderPage"]
  BookDetail --> ChangeSource["Change source sheet"]
  BookDetail --> DownloadQueue["Download task queue"]

  ReaderPage --> ReaderMenus["Reader menus\nsettings, TTS, auto page, bookmark"]
  ReaderMenus --> ReplaceRule["ReplaceRulePage"]
  ReaderMenus --> SearchPage
  ReaderMenus --> SettingsPage["SettingsPage"]

  MineTab --> SourceManager["SourceManagerPage"]
  MineTab --> Backup["BackupSettingsPage"]
  MineTab --> TtsSettings["TTS settings"]
  MineTab --> Appearance["Appearance / reading settings"]
  MineTab --> Dict["DictRulePage"]
  MineTab --> TxtToc["TxtTocRulePage"]
```

## 找書到閱讀流程

```mermaid
flowchart TD
  UserSearch["User searches keyword"] --> SearchProvider["SearchProvider.search"]
  SearchProvider --> SaveKeyword["SearchKeywordDao.saveKeyword"]
  SearchProvider --> SearchModel["SearchModel.search"]
  SearchModel --> Scope["SearchScope.getBookSources"]
  Scope --> EnabledSources["Enabled BookSource list"]
  EnabledSources --> Pool["Pool controls concurrent source searches"]
  Pool --> WebBookSearch["WebBook.searchBookAwait per source"]
  WebBookSearch --> AnalyzeUrl["AnalyzeUrl\nbuild URL, headers, charset, request"]
  AnalyzeUrl --> SourceSite["Book source website"]
  SourceSite --> HtmlJson["HTML / JSON / text response"]
  HtmlJson --> Parser["BookListParser\nAnalyzeRule + CSS/XPath/JSON/Regex/JS"]
  Parser --> SearchBookDao["SearchBookDao cache"]
  SearchBookDao --> Results["SearchProvider results"]
  Results --> BookDetail["BookDetailPage"]

  BookDetail --> DetailProvider["BookDetailProvider"]
  DetailProvider --> UpsertBook["BookDao upsert Book"]
  DetailProvider --> LoadSource["BookSourceDao.getByUrl"]
  LoadSource --> GetInfo["BookSourceService.getBookInfo"]
  GetInfo --> WebBookInfo["WebBook book info parser"]
  WebBookInfo --> UpsertBook
  DetailProvider --> GetToc["BookSourceService.getChapterList"]
  GetToc --> WebBookToc["WebBook chapter list parser"]
  WebBookToc --> ChapterDao["ChapterDao.insertChapters"]
  ChapterDao --> OpenReader["Open ReaderPage"]
```

## 閱讀器架構與流程

```mermaid
flowchart TB
  ReaderPage["ReaderPage\npage shell and composition"] --> SettingsController["ReaderSettingsController\nReaderPrefsRepository"]
  ReaderPage --> MenuController["ReaderMenuController"]
  ReaderPage --> Dependencies["ReaderDependencies"]
  Dependencies --> ChapterRepository["ChapterRepository"]
  ReaderPage --> Runtime["ReaderRuntime"]
  Runtime --> ProgressController["ReaderProgressController"]
  Runtime --> PageResolver["PageResolver"]
  PageResolver --> LayoutEngine["LayoutEngine"]
  Runtime --> Preload["ReaderPreloadScheduler"]
  ReaderPage --> TtsController["ReaderTtsController"]
  ReaderPage --> AutoPage["ReaderAutoPageController"]
  ReaderPage --> BookmarkController["ReaderBookmarkController"]
  ReaderPage --> Screen["EngineReaderScreen"]

  ChapterRepository --> Chapters["ChapterDao / initialChapters"]
  ChapterRepository --> ContentLoader["ReaderChapterContentLoader"]
  ContentLoader --> ContentStore["ReaderChapterContentStore\nreader_chapter_contents"]
  ContentLoader --> ReplaceRules["ReplaceRuleDao"]
  ContentLoader --> BookSourceService["BookSourceService\nfetch missing content"]

  Runtime --> State["ReaderState\nmode, phase, visibleLocation,\ncommittedLocation, PageWindow"]
  State --> Screen
  Screen --> Slide["SlideReaderViewport\n3-page PageView"]
  Screen --> Scroll["ScrollReaderViewport\npageOffset + fling"]

  Slide --> MoveNextPrev["moveToNextPage / moveToPrevPage"]
  Scroll --> ResolveVisible["resolveVisibleLocation\npageOffset to ReaderLocation"]
  MoveNextPrev --> Runtime
  ResolveVisible --> Runtime

  Runtime --> SaveProgress["schedule / flush progress"]
  SaveProgress --> BookDao["BookDao.updateProgress\nchapterIndex + charOffset"]

  TtsController --> TTSService["TTSService"]
  AutoPage --> Runtime
  BookmarkController --> BookmarkDao["BookmarkDao"]
```

## 閱讀器位置與保存流程

```mermaid
flowchart TD
  Location["ReaderLocation\nchapterIndex + charOffset"] --> PageResolver["PageResolver.pageForLocation"]
  PageResolver --> TextPage["TextPage\nruntime render output"]
  TextPage --> Viewport["Slide / Scroll viewport"]
  Viewport --> UserMoves["User page turn or scroll"]
  UserMoves --> RuntimeUpdate["ReaderRuntime updates\nvisibleLocation and PageWindow"]
  RuntimeUpdate --> Debounce["ReaderProgressController.schedule\n400ms debounce"]
  RuntimeUpdate --> Immediate["jumpToLocation immediate save\nfor chapter/location jump"]
  Debounce --> Flush["flush"]
  Immediate --> Flush
  Flush --> BookRow["books table\nchapterIndex, charOffset,\ndurChapterTitle, readerAnchorJson=null"]

  Exit["ReaderPage.dispose / exit intent"] --> Flush
  Lifecycle["App inactive / paused / detached"] --> Flush
```

## 書源管理與檢查流程

```mermaid
flowchart TD
  SourceManagerPage["SourceManagerPage"] --> Provider["SourceManagerProvider"]
  Provider --> LoadSources["BookSourceDao.getAllPart"]
  Provider --> FilterSort["Filter, search, group, sort"]
  Provider --> CRUD["Create / edit / delete / enable"]
  CRUD --> BookSourceDao["BookSourceDao.upsert/delete"]

  Provider --> Import["Import source JSON / URL / QR"]
  Import --> Parse["Parse BookSource list"]
  Parse --> Preview["ImportPreviewDialog"]
  Preview --> BookSourceDao

  Provider --> Check["CheckSourceService"]
  Check --> SourceList["Selected or filtered sources"]
  SourceList --> CheckSearch["Search check"]
  SourceList --> CheckDiscover["Discovery check"]
  SourceList --> CheckDetail["Detail / TOC / content check"]
  CheckSearch --> BookSourceService["BookSourceService"]
  CheckDiscover --> BookSourceService
  CheckDetail --> BookSourceService
  BookSourceService --> Engine["core/engine WebBook + AnalyzeRule"]
  Engine --> SourceSites["Source websites"]
  Check --> Report["SourceCheckReport\nshown in UI"]

  SourceManagerPage --> Login["Source login / browser"]
  Login --> WebView["BrowserPage / WebView"]
  WebView --> Cookies["CookieDao / CookieJar"]
```

## 本地書流程

```mermaid
flowchart TD
  PickFile["User picks local file"] --> LocalBookService["LocalBookService"]
  LocalBookService --> Detect["Detect format and encoding"]
  Detect --> Txt["TxtParser"]
  Detect --> Epub["EpubParser"]
  Detect --> Umd["UmdParser"]
  Txt --> BookAndChapters["Book + BookChapter list"]
  Epub --> BookAndChapters
  Umd --> BookAndChapters
  BookAndChapters --> BookDao["BookDao"]
  BookAndChapters --> ChapterDao["ChapterDao"]
  BookAndChapters --> ContentStore["ReaderChapterContentStore"]
  ContentStore --> Reader["ReaderPage"]
```

## 備份與還原流程

```mermaid
flowchart LR
  subgraph Backup["Backup"]
    BackupPage["BackupSettingsPage"] --> CreateZip["BackupService.createBackupZip"]
    CreateZip --> Manifest["manifest.json\nappVersion, schemaVersion, timestamp"]
    CreateZip --> ExportTables["Export DAO data as JSON"]
    CreateZip --> ExportPrefs["Export SharedPreferences\nconfig.json"]
    Manifest --> Zip["backup-yyyy-MM-dd.zip"]
    ExportTables --> Zip
    ExportPrefs --> Zip
  end

  subgraph Restore["Restore"]
    PickZip["Pick backup zip"] --> RestoreService["RestoreService.restoreFromZip"]
    RestoreService --> DecodeZip["ZipDecoder"]
    DecodeZip --> CheckManifest["Require compatible manifest\nschemaVersion <= current"]
    CheckManifest --> ImportJson["fromJson + DAO upsert"]
    CheckManifest --> RestorePrefs["Restore SharedPreferences"]
  end
```

## 背景任務與下載流程

```mermaid
flowchart TD
  Workmanager["Workmanager callbackDispatcher"] --> BgDI["configureDependencies in background isolate"]
  BgDI --> ReadShelf["BookDao.getInBookshelf"]
  ReadShelf --> CheckUpdates["Future update-check hook"]

  DownloadPage["DownloadManagerPage / BookDetail queue"] --> DownloadService["DownloadService"]
  DownloadService --> Scheduler["DownloadScheduler"]
  Scheduler --> Executor["DownloadExecutor"]
  Executor --> ChapterContent["ReaderChapterContentStorage / Store"]
  Executor --> SourceFetch["BookSourceService fetch content"]
  SourceFetch --> Engine["WebBook + AnalyzeRule"]
  ChapterContent --> DownloadDao["DownloadDao\nDownloadTasks"]
```

## 核心資料落點

```mermaid
flowchart TB
  subgraph SQLite["Drift / SQLite"]
    Books["books\nbook info, bookshelf state,\nchapterIndex, charOffset"]
    Chapters["chapters\nTOC"]
    Contents["reader_chapter_contents\nmaterialized text"]
    Sources["book_sources\nrules and source config"]
    SearchBooks["search_books\nsearch/source-switch cache"]
    Rules["replace_rules, dict_rules,\ntxt_toc_rules, http_tts_table"]
    Misc["bookmarks, read_records,\ndownload_tasks, cookies,\nbook_groups, cache_table"]
  end

  subgraph Prefs["SharedPreferences"]
    AppPrefs["theme, locale, feature prefs"]
    ReaderPrefs["reader font, layout, theme,\npage mode, click actions, TTS prefs"]
  end

  subgraph Files["Filesystem"]
    DbFile["ApplicationSupport/databases/inkpage_reader.db"]
    BackupZip["backup zip"]
    Assets["book assets, covers, fonts,\nruleData, temporary cache"]
  end

  Books --> DbFile
  Chapters --> DbFile
  Contents --> DbFile
  Sources --> DbFile
  SearchBooks --> DbFile
  Rules --> DbFile
  Misc --> DbFile
```

## 端到端主流程摘要

```mermaid
flowchart TD
  Install["Install / first launch"] --> Defaults["Load default data"]
  Defaults --> ManageSources["Manage or import book sources"]
  Defaults --> SearchOrExplore["Search / Explore"]
  ManageSources --> SearchOrExplore
  SearchOrExplore --> BookDetail["Book detail and TOC"]
  BookDetail --> AddShelf["Add to bookshelf"]
  BookDetail --> Read["Read"]
  AddShelf --> Bookshelf["Bookshelf"]
  Bookshelf --> Read
  Read --> Progress["Save progress\nchapterIndex + charOffset"]
  Read --> Bookmark["Bookmark"]
  Read --> TTS["TTS / auto page"]
  Read --> SourceSwitch["Change source if needed"]
  SourceSwitch --> Read
  Progress --> Resume["Resume later"]
  Resume --> Read
  Settings["Settings"] --> Backup["Backup / restore"]
  Settings --> ReaderPrefs["Reading settings"]
  Settings --> SourceManager["Source manager"]
```
