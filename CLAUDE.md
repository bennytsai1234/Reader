# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概述

**墨頁 Inkpage** — Flutter 跨平台小說閱讀器（package name `inkpage_reader`），移植自 Android 的 Legado（閱讀 3.0）。版本 `0.2.1+16`，Dart SDK `^3.7.0`，Drift schema v8。

## 常用指令

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # 修改 Drift table 後必跑
flutter analyze                    # 靜態分析
flutter test                       # 全部測試（58 個測試檔）
flutter test test/features/reader/read_book_controller_test.dart  # 單一測試
flutter run                        # 啟動
flutter build apk --release        # Android release
flutter build ios --release --no-codesign  # iOS unsigned
```

> 修改 `lib/core/database/tables/` 下的 Drift 定義後，必須重新執行 `build_runner`。

## 技術棧

- **語言**：Dart / Flutter（SDK `^3.7.0`）
- **狀態管理**：Provider + ChangeNotifier（禁止引入第二套）
- **DI**：get_it
- **資料庫**：Drift（SQLite ORM，schema v8）
- **網路**：Dio + CookieJar
- **JS 引擎**：flutter_js（取代 Android Rhino）
- **WebView**：webview_flutter
- **TTS**：flutter_tts, audio_service
- **本機書籍**：TXT、EPUB（epubx）
- **加解密**：crypto、encrypt、pointycastle（取代 Android hutool-crypto）
- **HTML/XML**：html、csslib、xml、xpath_selector、json_path
- **Web 伺服器**：shelf（取代 Android NanoHTTPD）
- **背景任務**：workmanager
- **本機 widget**：home_widget

## 目錄結構

```
lib/
├── main.dart                 # 入口：DI、TTSService、Workmanager、MaterialApp
├── app_providers.dart        # 全域 Provider 集中註冊
├── core/
│   ├── base/                 # BaseProvider：統一 loading/error 與 runTask()
│   ├── config/               # AppConfig、PreferenceKey、預設資料
│   ├── constant/             # PageAnim、BookType 等列舉
│   ├── database/             # Drift schema (v8) / DAO / tables / migration
│   ├── di/                   # GetIt 依賴註冊（injection.dart）
│   ├── engine/               # 書源解析引擎（下方詳述）
│   ├── local_book/           # 本機格式解析器（TXT/EPUB/MOBI/PDF/UMD）
│   ├── models/               # 資料模型（Book、Chapter、BookSource、…）
│   ├── network/              # Dio、API 包裝、Cookie、HTTP 攔截
│   ├── services/             # 備份、還原、TTS、下載、資源、更新、widget
│   ├── storage/              # AppStoragePaths、storage metrics、cache
│   ├── exception/            # 應用例外類型
│   ├── utils/                # LRU、純工具
│   └── widgets/              # 非 feature 專屬的共用 widgets（書封等）
├── features/                 # 產品功能模組
│   ├── reader/               # 閱讀器（最複雜，見下）
│   ├── bookshelf/            # 書架
│   ├── book_detail/          # 書籍詳情
│   ├── search/               # 搜尋（SearchProvider → SearchModel）
│   ├── source_manager/       # 書源管理與登入
│   ├── explore/              # 發現頁
│   ├── local_book/           # 本機書匯入
│   ├── settings/             # 設定
│   ├── association/          # 深連結與檔案關聯
│   ├── browser/              # 內建 WebView 瀏覽器
│   ├── welcome/              # 啟動 / 隱私協議 / 主頁
│   ├── about/                # 關於 / crash log / app log
│   ├── bookmark/             # 書籤
│   ├── cache_manager/        # 快取 / 下載管理
│   ├── debug/                # 除錯頁
│   ├── dict/                 # 字典
│   ├── read_record/          # 閱讀記錄
│   ├── replace_rule/         # 替換規則
│   └── txt_toc_rule/         # TXT 目錄規則
└── shared/
    ├── theme/                # 亮/暗主題、閱讀主題色表
    └── widgets/              # 跨 feature 共用 widget
```

## 閱讀器架構（最重要）

閱讀器以 `ReadBookController` 為中心的 runtime 內核，搭配 mixin 鏈與 coordinator 模式：

### Mixin 鏈

```
ReaderProviderBase → ReaderSettingsMixin → ReaderContentMixin
  → ReaderAutoPageMixin → ReadBookController
```

Mixin 負責設定投影與內容載入入口，真正的控制權已大幅回收到 controller 與 coordinator。

### Coordinator 子域

`ReadBookController` 是閱讀生命週期（`loading → ready`）主控，內部拆出的 coordinator：

- `ReaderNavigationController` — jump reason、command guard、page change reason、auto-page step
- `ReaderRestoreCoordinator` — restore token/target 建立、消費、清除
- `ReaderProgressStore` — durable progress 回寫與 `book.durChapter*` 同步
- `ReaderProgressCoordinator` — 閱讀進度更新（含 debounce）
- `ReaderScrollVisibilityCoordinator` — scroll visible chapter 去重、補載、preload 判定
- `ReaderTtsFollowCoordinator` — TTS follow safe-zone 與 follow target 決策
- `ReaderSessionCoordinator` — session 狀態（`ReaderSessionState`）與 lifecycle 協調
- `ReaderDisplayCoordinator` — 顯示資訊投影
- `ReaderContentCoordinator` — 內容載入協調
- `ReadViewRuntimeCoordinator` — view runtime 橋接

### 章節 Runtime

`lib/features/reader/runtime/models/reader_chapter.dart` 的 `ReaderChapter` 是核心共用 runtime 物件，統一提供：

- `charOffset ↔ localOffset ↔ pageIndex` 互轉
- highlight range、restore target、scroll anchor 解析
- paragraph / line query
- read aloud data 組裝

restore、scroll follow、TTS、auto-page 共用同一套章內語義，而非各自掃 page 做定位。

### 內容生命週期

`ChapterContentManager`（`lib/features/reader/engine/chapter_content_manager.dart`）是章節生命週期服務：

- 正文抓取協調（`_fetchChapterData`）
- 主動載入與靜默預載去重
- 分頁快取與 progressive paginate
- preload queue / priority
- 視窗內外驅逐

主流程：`ReadBookController._init()` → `initContentManager()` → `loadChapterWithPreloadRadius()` → `ChapterContentManager.ensureChapterReady()` → `ContentProcessor.process()` → `ChapterProvider.paginate()` → 更新 `chapterPagesCache` → `refreshChapterRuntime()`。

### View Runtime

- `ReadViewRuntime`（`view/read_view_runtime.dart`）— 主視圖控制器
- `PageModeDelegate` / `ScrollModeDelegate`（`view/delegate/`）— 對應使用者可選的兩種翻頁模式：平移（`PageAnim.slide`）與捲動（`PageAnim.scroll`）
- `SlidePageController`（`view/slide_page_controller.dart`）— 平移模式底層的 `PageView` 管理器，用 `SlideWindow`/`SlideSegment`
- `ScrollExecutionAdapter` / `ScrollRestoreRunner` / `ScrollRuntimeExecutor` — 捲動執行與還原

> `PageAnim` 類別另保留 `simulation` / `none` 常數僅作為 Legado 設定匯入相容性，不對應實際實作；UI 選單只暴露兩種翻頁模式。

### TTS 設計

- `TTSService`（`core/services/tts_service.dart`）— 全域單例，在 `main()` 初始化
- `ReadAloudController`（`runtime/read_aloud_controller.dart`）— 朗讀主控，負責：
  - TTS session 建立與 offset map
  - progress → chapter offset 映射
  - highlight 同步、章節預抓、無縫銜接
  - 底層仍使用錨點游標模式，朗讀以整章為單位

## 書源引擎（`core/engine/`）

應視為獨立子系統，對外呈現穩定語意 API，不依賴 widget：

- `analyze_rule/` — 規則解析核心（`analyze_rule_base.dart`、`analyze_rule_script.dart`）
- `analyze_url.dart` — URL 建構與請求發送（含 charset 偵測、`ResponseType.bytes` 流程）
- `explore_url_parser.dart` — 探索 URL 展開
- `parsers/` — CSS / XPath / JSON / Regex
- `rule_analyzer/` — 範圍 / 匹配 / 分割
- `web_book/` — 搜尋、書籍資訊、章節、正文抓取服務
- `reader/` — 內容後處理（`content_processor.dart`、`chinese_text_converter.dart`）
- `js/` — flutter_js 沙盒、JS extensions（file/network/font/string 等）、shared scope、Promise bridge
- `book/` — `book_help.dart`

### 書源 Charset 處理

`AnalyzeUrl.getStrResponse()` 使用 `ResponseType.bytes` + 多層 charset 偵測（書源 charset → HTTP Content-Type → HTML meta → EncodingDetect 自動偵測），對標 Legado 的 `ResponseBody.text()`。不要改回 `ResponseType.plain`，否則會出現中文亂碼。

## 資料層

- `core/database/app_database.dart` — `AppDatabase` 註冊 20 張表、20 個 DAO
- Schema version = 8
- 資料檔：`ApplicationSupportDirectory/databases/inkpage_reader.db`
- `core/database/tables/` — table 定義（改動後必跑 build_runner）
- `core/database/dao/` — DAO 實作（所有 DB 操作應走 DAO，不直接呼叫 Drift API）
- 閱讀進度真源：`Books.durChapterIndex` + `Books.durChapterPos`
- 章節正文真源：`Chapters.content`

## 平台與儲存

- `core/storage/AppStoragePaths` — 統一路徑管理（備份、快取、匯出、字體、widget 都要走這裡）
- `core/services/backup_service.dart` — 本地 ZIP 備份
- `core/services/download_service.dart` + `services/download/` — 下載排程與執行
- `core/services/update_service.dart` — 更新檢查
- `core/services/widget_service.dart` — Android home_widget 橋接

## 開發規範

- **禁止引入第二套狀態管理**（已統一 Provider）
- 繼承 `BaseProvider` 的類別用 `runTask()` 處理非同步，不手動維護 loading/error（`BookshelfProviderBase` 繼承 `ChangeNotifier` 為例外）
- DB 操作統一走 DAO；跨 DAO 整合邏輯放 Service / Repository，不讓 UI 直接碰 DAO
- 新的解析邏輯放在 `core/engine/` 對應子目錄
- UI 不直接碰 DAO、檔案路徑或平台 API；路徑統一經 `core/storage`
- Dart null-safety；`await` 後使用 `context` 前必加 `if (!mounted) return;`
- `assets/` 含字型、預設書源、OpenCC 字典，不可刪或改名
- `analysis_options.yaml` 為嚴格 lint，新程式碼必須通過
- 改動完成必跑 `flutter analyze && flutter test`

## 品牌與識別符

- 顯示名：**墨頁** / Inkpage
- Dart package：`inkpage_reader`
- Android `applicationId` / `namespace`：`com.inkpage.reader`
- iOS bundle ID：`com.inkpage.reader`
- iOS URL scheme：`legado://`（保留相容 Legado 書源連結，勿改）
- 資料庫檔名：`inkpage_reader.db`

## 參考

- Android 原版 Legado 在 `../legado/`，書源規則邏輯可對照 `../legado/app/src/main/java/io/legado/app/model/analyzeRule/`
- 設計文檔在 `docs/`：`architecture.md`、`reader_architecture_current.md`、`DATABASE.md`、`roadmap.md`
- Release notes 在 `release-notes/`
