# 夜讀 Night Reader Atlas Index

The navigation map for this project. Daily work enters through the `atlas-planner`
skill, which reads this index, picks the relevant module(s), and carries its own
change/investigate discipline — this index holds the map, not the process.

- Use it to locate the relevant module before inspecting code; keep details in the
  module docs. This index answers *what owns this, where do I start, what must I
  not break*; grep answers *where exactly is it*.
- Neither the execution manager nor an implementation agent reads this file. One
  enters through a dispatch plan, the other receives the module doc paths it
  needs as starting points in its task package.
- Codebase Atlas runs once to build this map, and is rerun only when a human
  asks. A **refresh** re-scans just the modules the repository changed under
  since the build below; a **rebuild** discards the map and scans everything.

Working language: 繁體中文 · Delivery: commit and push · Reporting: technical
Atlas built: 2026-08-24 · from commit c9a473b · format 5

## Project Operating Constraints

Inherited rules from existing project guidance. All work must follow these:

- **語言**：對使用者與專案規則討論使用繁體中文（`AGENTS.md` 明確要求）。
- **維護政策**：**feature freeze**（功能凍結）— 以維護、修 bug、效能調校、重構、既有功能內部改進為主；不新增產品線功能（`DEVELOPMENT.md`）。
- **發布流程**：Android release 由 `.github/workflows/android-release.yml` 處理，`v*` tag 觸發、可 `workflow_dispatch`；本機不做 build，APK 由 CI 建置。標準流程 `flutter pub get → flutter analyze → flutter test → git push origin HEAD → git tag vX.Y.Z → git push origin vX.Y.Z`；需改版號時先更新 `pubspec.yaml` 並先提交；先推送 branch/commit 再建 tag；推送 tag 後確認 GitHub Actions 的 Android Release workflow 已開始建置即可結束任務（`AGENTS.md` / `DEVELOPMENT.md`）。
- **驗證指令**：`flutter analyze`、`flutter test` 為基本驗證；書源相關變更優先用 `tool/` 腳本在真實書源上回歸（`tool/source_single_debug_test.dart`、`source_batch_validation_test.dart`、`explore_batch_validation_test.dart` 搭配 `tool/run_source_validation.sh` / `flutter_test_with_quickjs.sh`）；Drift schema 變更需 `dart run build_runner build --delete-conflicting-outputs` 重新生成 `.g.dart`。
- **技術棧**：Flutter `3.47.0` / Dart `^3.13.0` / Java `17` / Android SDK；`provider` + `event_bus` 狀態管理；`drift` + SQLite 持久化；`dio` + `cookie_jar` 網路；`flutter_js`（QuickJS）規則引擎；`webview_flutter` 無頭 WebView；`flutter_tts` + `audio_service` 朗讀（`pubspec.yaml` / `DEVELOPMENT.md`）。
- **背景 isolate 契約**：`lib/main.dart:callbackDispatcher` 的 Workmanager 背景任務在 isolate 執行，必須重跑 `configureDependencies()` 重建 GetIt DI（不跨 isolate）；依 `DEVELOPMENT.md` 背景任務不可執行 JS 規則。例外：書源批次校驗 isolate 在 `SourceValidationContext.runNonInteractive` 關閉 xhr/WebView 後可執行 JS（`lib/core/engine/js/js_engine.dart:50`）。
- **三方同步**：`SettingsProvider` ↔ `AppConfig` ↔ `PreferKey` 三者須保持一致；新增全域偏好 key 若 Model 層或 Reader 排版層要讀預設值，必須同時鏡像 `lib/core/config/app_config.dart`（`DEVELOPMENT.md`）。
- **本地建置邊界**：本機僅做靜態分析與測試，不做 `flutter build`；APK 建置與發布一律由 GitHub Actions 處理（`DEVELOPMENT.md`）。

## Architecture Decisions

Cross-module decisions recorded during development. Module-level decisions live in
each module's Known Risks or Boundaries section.

| Date | Decision | Context |
|------|----------|---------|
| _（初始化）_ | _（空 — 待開發過程累積）_ | _—_ |

## Module List

- [應用殼層 (app_shell)](night_reader/app_shell.md) — 應用啟動、DI 組裝、導航與主題基建
- [規則引擎 (engine)](night_reader/engine.md) — Legado 書源規則解析與抓取編排
- [資料持久化 (data)](night_reader/data.md) — Drift 資料庫、領域模型與本地書/快取儲存
- [書源與網路 (source_network)](night_reader/source_network.md) — HTTP 傳輸、書源 CRUD、校驗與換源
- [圖書館 (library)](night_reader/library.md) — 書架、搜尋、發現與書籍詳情
- [閱讀器 (reader)](night_reader/reader.md) — 閱讀會話、排版引擎與混合滾動視口
- [營運能力 (operations)](night_reader/operations.md) — 設定、備份、下載、快取、TTS 與橫切工具

## Module Summaries

### 應用殼層 (app_shell)
擁有應用生命週期殼層與全域組裝邊界。進入點 `lib/main.dart` 的 `main()` / `_startApp()` / `callbackDispatcher`（Workmanager 背景 isolate）、`lib/core/di/injection.dart:configureDependencies()` 的 GetIt 單例註冊、`lib/app_providers.dart:AppProviders.providers` 的 `MultiProvider` 組裝、`lib/shared/theme/*` 的設計系統與 `lib/shared/navigation/book_open_route.dart:BookOpenRoute` 的閱讀器轉場、`lib/features/welcome/main_page.dart:MainPage` 的三頁籤主導航與 `lib/features/association/association_handler_service.dart` 的深連結/分享接收。當任務涉及啟動時序、新增全域 Provider、調整主題 token、新增導航分頁或深連結 scheme 時，從此模組開始。

### 規則引擎 (engine)
擁有 Legado 書源規則的完整語意。以 `lib/core/engine/analyze_rule.dart:AnalyzeRule` 為總控，串 `AnalyzeRuleBase/Element/String/RegexHelper/Script/Support` 六檔分治、`lib/core/engine/rule_analyzer.dart:RuleAnalyzer` 的 `&&/||/%%/@` 算子切割與 `lib/core/engine/parsers/*` 四後端（CSS/XPath/JsonPath/Regex）等價封裝、`lib/core/engine/analyze_url.dart:AnalyzeUrl` 的 URL 編譯與 charset 感知解碼、`lib/core/engine/js/js_engine.dart:JsEngine` 的 QuickJS 雙向橋（`__asyncCall/__resolvePending/__ruleDone` 20s 超時）與 `lib/core/engine/web_book/web_book_service.dart:WebBook` 的五入口抓取編排（搜尋/發現/詳情/目錄/正文，含 `%%` 有界並發與 daisy-chain）。當任務涉及規則語法、JS 相容、HTML 解析或書源抓取邏輯時，從此模組開始。

### 資料持久化 (data)
擁有全應用結構化資料的唯一真相來源。以 `lib/core/database/app_database.dart:AppDatabase`（`@DriftDatabase(tables:20, daos:20)`、25 個效能索引、含 `inkpage_reader.db → night_reader.db` 一次性重命名）為單例根，`lib/core/database/tables/app_tables.dart` 定義落盤欄位與 8 個 `TypeConverter`（`EmptyStringConverter` 將 `''↔null` 等）、`lib/core/models/*` 定義記憶體語意、`lib/core/storage/app_cache.dart:AppCache`（`sha256(key)` 檔名 + `"$millis-$seconds "` TTL + 50MB/1M 檔 LRU）與 `lib/core/storage/app_storage_paths.dart:AppStoragePaths` 管理檔案系統、`lib/core/local_book/txt_parser.dart:TxtParser.splitChapters` 負責 TXT 位移映射。當任務涉及表結構、DAO、模型欄位、本地書格式、快取或偏好 key 時，從此模組開始。

### 書源與網路 (source_network)
擁有全應用 HTTP 唯一出口與書源生命週期。以 `lib/core/services/network_service.dart:NetworkService` 單例封裝 `Dio`（15s 超時）與 `lib/core/network/interceptors/app_interceptor.dart:AppInterceptor` 手動重定向（10 跳、跨域剝離 `Authorization/Cookie`）、`lib/core/network/interceptors/lenient_cookie_manager.dart:LenientCookieManager` 容錯 `Set-Cookie` 黏連，`lib/core/models/source/book_source_logic.dart:SourceRuntimeHealth` 定 16 分組標籤的四維健康語意，`lib/core/services/check_source_service.dart:CheckSourceService` 以 8 worker + 同域/JS 雙訊號量 + `Isolate.spawn`（`lib/core/services/source_check_isolate.dart`）執行五階段探測並回寫 `bookSourceGroup`，`lib/features/source_manager/source_manager_provider.dart:SourceManagerProvider` 承載過濾/排序/批次與 `lib/features/source_manager/source_editor_page.dart:SourceEditorPage` 六 Tab 規則編輯。當任務涉及網路傳輸、Cookie、書源匯入/編輯/校驗或換源（`SourceSwitchService` 的 `Pool(6)`）時，從此模組開始。

### 圖書館 (library)
擁有館藏的入口集合。以 `lib/features/bookshelf/bookshelf_provider.dart:BookshelfProvider`（四 mixin 組裝、6 模式排序、`discardBook` 六表級聯刪除）管理書架，`lib/features/search/search_model.dart:SearchModel`（`Pool(thread_count)` 有界並發 + 同源去重 `origin+bookUrl` + `SearchBook.aggregate` 跨源合併卡 + 三級相關度排序）與 `lib/features/search/search_provider.dart:SearchProvider`/`lib/features/search/models/search_scope.dart:SearchScope`（`''/a,b/name::url` 三模式）管理聯邦搜尋，`lib/features/explore/explore_provider.dart:ExploreProvider`（`watchDiscoveryPart` + `kindsCache` 世代號）與 `lib/features/explore/explore_show_provider.dart:ExploreShowProvider` 管理發現分類，`lib/features/book_detail/book_detail_provider.dart:BookDetailProvider` 聚合書籍資訊/目錄/封面/換源/預下載/匯出，`lib/core/services/local_book_service.dart:LocalBookService`（`compute(TxtParser)` + `RandomAccessFile`）與 `lib/core/services/bookshelf_exchange_service.dart` / `export_book_service.dart` 負責本地書與書架匯出。當任務涉及書架、搜尋合併、發現或詳情頁時，從此模組開始。

### 閱讀器 (reader)
擁有唯一的正文閱讀會話與呈現管線。以 `lib/features/reader_v2/session/reader_v2_runtime.dart:ReaderV2Runtime` 為總控（`cold → loading → layingOut/restoring/switchingMode → ready → error` 狀態機、`hybridViewportActive` 雙軌分流），`lib/features/reader_v2/session/reader_v2_location.dart:ReaderV2Location(chapterIndex, charOffset, visualOffsetPx)` 為座標單一真相（`visualOffsetPx ∈ [-120,120]`、`anchorOffsetInViewport = h*0.2 clamp [24,120]`），`lib/features/reader_v2/session/reader_v2_resolver.dart:ReaderV2Resolver`（`_maxLayoutCacheSize=50/_maxStepExtentPx=3000`）與 `lib/features/reader_v2/hybrid/pump/layout_pump.dart:LayoutPump`（`BudgetGovernor` + `LayoutCostModel` 預算制）為兩條排版管線，`lib/features/reader_v2/hybrid/measure/document_index.dart:DocumentIndex`（雙 Fenwick 索引）與 `lib/features/reader_v2/hybrid/view/hybrid_scroll_view.dart:HybridScrollView` + `hybrid_block_sliver.dart` 自定義 `RenderSliver` 為混合滾動視口，`lib/features/reader_v2/viewport/reader_v2_viewport_controller.dart:ReaderV2ViewportController` 七閉包為唯一操作面。當任務涉及正文獲取/變換、位置保存、排版或滾動/翻頁互動時，從此模組開始。

### 營運能力 (operations)
擁有使用者可見的營運閉環與橫切工具。以 `lib/features/settings/settings_provider.dart:SettingsProvider`（60+ 偏好持久化至 `SharedPreferences`）與 `lib/features/settings/theme_settings_provider.dart:ThemeSettingsProvider`（`AppUiThemeColors/ReaderAreaThemeColors` 六槽 + 12 key）為設定中樞，`lib/core/services/backup_service.dart:BackupService`（8 表 + `config.json` + `manifest.json` → `backup-YYYY-MM-DD.zip`）/ `restore_service.dart`（`manifest.schemaVersion` 閘門）/ `bookshelf_exchange_service.dart` / `export_book_service.dart` 為資料出口，`lib/core/services/download_service.dart:DownloadService`（`DownloadBase(3/5 並發窗) → DownloadScheduler → DownloadExecutor`）與 `lib/core/services/cache_manager.dart:CacheManager`（`LruMemoryCache 50MB`）+ `reader_chapter_content_store/storage/chapter_content_preparation_pipeline` 三級正文管線為內容快取，`lib/core/services/tts_service.dart:TTSService`（`FlutterTts` + `AudioService`）與 `lib/core/services/audio_handler.dart:ReaderAudioHandler` 為朗讀，`lib/core/utils/*` / `lib/core/exception/app_exception.dart` / `lib/core/widgets/book_cover_widget.dart` 為工具與例外。當任務涉及設定、主題、備份/還原、下載佇列、快取、TTS 或工具函式時，從此模組開始。
