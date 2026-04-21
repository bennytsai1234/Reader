# 目前架構

更新日期：2026-04-20

這份文檔不描述理想狀態，而是描述現在 `reader` 的實際結構，並手動對照 `legado` 現況。

## 一句話結論

`reader` 現在不是把 `legado` 原樣搬到 Flutter，而是把小說閱讀主線拆成四層：

- app root 與全域 provider
- `core/` 的資料層、書源引擎、平台服務
- `features/` 的產品頁面與 provider/controller
- `features/reader` 裡相對獨立的閱讀器 runtime

`legado` 對應的是一個 Android app，`ui/*`、`data/*`、`model/*`、`help/*` 混合得比較重；`reader` 則把資料層、引擎與產品模組切得更明顯，但功能面更窄。

## 目錄真實形狀

```text
lib/
  main.dart
  app_providers.dart
  core/
    config/ constant/ exception/ utils/
    database/      Drift schema + DAO
    di/            get_it
    engine/        書源規則解析、JS、Web 書源
    local_book/    TXT / EPUB / UMD 解析
    network/       Dio 與攔截器
    services/      備份、還原、TTS、書源校驗、換源、下載等
    storage/       路徑與容量資訊
    widgets/       少量非 feature 專屬 widget
  features/
    bookshelf/
    book_detail/
    search/
    explore/
    source_manager/
    reader/
    settings/
    bookmark/
    cache_manager/
    browser/
    dict/
    replace_rule/
    txt_toc_rule/
    read_record/
    association/
    about/
    welcome/
  shared/
    theme/
    widgets/
```

## App Root

入口是 [main.dart](/home/benny/projects/reader/lib/main.dart:1)。

目前職責：

- 啟動 Flutter binding
- 建立錯誤頁與全域 error logging
- 初始化 `configureDependencies()`、`ChineseUtils.initialize()`
- 掛載 `AppProviders.providers`
- 啟動 `MaterialApp`
- 初始化 `Workmanager`

這一層仍然偏薄，但不是完全純組裝：

- `main.dart` 仍直接處理 debug 模式 log 開關
- 背景 task 目前只做最小初始化，還沒有真正延伸成完整更新系統

相對 `legado`：

- `legado` 的主入口是 `MainActivity`，同時承擔隱私協議、版本提示、備份同步、自動更新書籍等大量 Android 生命周期邏輯。
- `reader` 把這些重型流程大多移到 service 或直接不做，只保留閱讀器主體必需的啟動流程。

## 全域狀態與 DI

[app_providers.dart](/home/benny/projects/reader/lib/app_providers.dart:1) 與 [core/di/injection.dart](/home/benny/projects/reader/lib/core/di/injection.dart:1) 共同構成 app 層組裝。

目前模式：

- DAO、`NetworkService`、`TTSService` 用 `get_it`
- 頁面級與 app 級 UI state 用 `provider`
- `TTSService` 同時作為 DI 單例與 `ChangeNotifierProvider.value`

這和 `legado` 不同：

- `legado` 主力是 Android `ViewModel` + app singleton + DB 單例，不存在 Flutter 的 provider tree。
- `reader` 的 provider 比較接近頁面協調層，而非資料真源。

## core 層

### `core/database`

- Drift + SQLite
- 20 張表、20 個 DAO
- `Books` / `Chapters` / `BookSources` 是核心主線

和 `legado` 相比：

- `reader` 的 schema 明顯更小，沒有 RSS 相關表，也沒有 `legado` 那套更重的 app-level 設定與內容類型資料。
- `reader` 把書源 health 暫時塞在 `bookSourceGroup` / `bookSourceComment`，還沒有獨立狀態表。

### `core/engine`

目前這一塊是 `reader` 最接近 `legado` 的部分，包含：

- `analyze_url.dart`
- `analyze_rule.dart`
- `rule_analyzer/`
- `parsers/`：CSS、XPath、JsonPath、Regex
- `js/`：QuickJS、async rewrite、JS bridge、encode helpers
- `web_book/`：搜尋、詳情、目錄、正文 parser 與 `headless_webview_service.dart`
- `explore_url_parser.dart`

手動對照 `legado`：

- `reader/core/engine/*` 對應 `legado` 的 `model/analyzeRule/*`、部分 `help/source/*`、`ui/book/source/debug/*` 背後使用的解析能力。
- `reader` 把 parser 與 UI 分離得更乾淨。
- `legado` 的 Android runtime 與 Java/Kotlin helper 更完整，尤其在 WebView、登入、加密腳本、站點特例上仍較成熟。

### `core/local_book`

現在只看到三條真實解析路徑：

- TXT
- EPUB
- UMD

從 [local_book_formats.dart](/home/benny/projects/reader/lib/core/local_book/local_book_formats.dart:1) 可以直接確認目前支援副檔名只有 `txt`、`epub`、`umd`。

這裡和 `legado` 的差異要寫清楚：

- `legado` 有更完整的本地與外部檔案整合路徑，包含 TXT、EPUB、MOBI，以及更多 Android 檔案流程。
- `reader` 雖然保留「本地書」產品線，但目前不是全面對齊 `legado` 的本地格式能力。

### `core/services`

服務很多，但大致可分四類：

- 閱讀主線：`book_source_service.dart`、`local_book_service.dart`、`source_switch_service.dart`
- 書源治理：`check_source_service.dart`、`source_verification_service.dart`、`source_debug_service.dart`
- 平台能力：`backup_service.dart`、`restore_service.dart`、`download_service.dart`、`tts_service.dart`
- 支撐服務：`default_data.dart`、`resource_service.dart`、`network_service.dart`

和 `legado` 相比：

- `reader` 把不少舊的 Android helper 流程重新包成 service。
- 但也因為 service 多，部分責任還在重疊，例如 cache/download/source validation 之間仍有交界待收。

## features 層

### `bookshelf`

現在是主頁第一個 tab，[features/welcome/main_page.dart](/home/benny/projects/reader/lib/features/welcome/main_page.dart:1)。

現況：

- 單一書架頁
- 網格 / 列表切換
- 分組管理
- 本地匯入、網址匯入、書架匯入匯出
- 多選批次操作

和 `legado` 相比：

- `legado` 主頁有兩種書架 style、更多主頁互動與頂層整合。
- `reader` 目前只有一套書架 UI，功能集中，但簡化很多。
- [bookshelf_provider.dart](/home/benny/projects/reader/lib/features/bookshelf/bookshelf_provider.dart:1) 還留有「groupCounts 先做基礎實作」這類訊號，說明書架並非完全收口。

### `search`

目前是獨立頁 [search_page.dart](/home/benny/projects/reader/lib/features/search/search_page.dart:1)。

已有：

- 全部 / 分組 / 單一書源搜尋
- 搜尋歷史
- 精準搜尋
- 搜尋進度與失敗來源提示

和 `legado` 相比：

- 產品流已接近 `SearchActivity`
- 但 Android 版更成熟的 recycler / scope menu /滾動行為與 menu integration 仍更完整
- `reader` 這邊的優勢是把 scope 與結果聚合模型明確做成 Dart 類型

### `explore`

目前是第二個可選 tab，[explore_page.dart](/home/benny/projects/reader/lib/features/explore/explore_page.dart:1)。

已有：

- 以書源為單位的探索入口
- 分組篩選、搜尋、展開
- 探索分類與探索展示頁

和 `legado` 相比：

- 已明顯對照 `ExploreFragment`
- 但 `legado` 的 fragment + menu + DB flow 整合更深
- `reader` 沒有 RSS tab，也沒有把 explore 擴成多內容容器

### `source_manager`

這是目前和 `legado` 對齊最多的產品頁之一，[source_manager_page.dart](/home/benny/projects/reader/lib/features/source_manager/source_manager_page.dart:1)。

已有：

- 匯入、匯出、剪貼簿、檔案、QR
- 編輯、調試、單源搜尋
- 批次啟用停用、批次分組、批次校驗、批次刪除
- 校驗結果狀態列與結果面板

和 `legado` 相比：

- 產品操作流已相當接近 `BookSourceActivity`
- 但資料落點仍不同：`reader` 把校驗結果部分放在 service memory 與 group/comment 推導，`legado` 則有更完整的 Android config 與 check flow
- `reader` 頁面內仍有些清理未完，例如未引用方法與 UI 邊角

### `reader`

這是整個 repo 最複雜的 feature，細節獨立寫在 [reader_architecture_current.md](reader_architecture_current.md)。

目前真實形狀：

- `ReaderProvider` 只是 `ReadBookController` 的別名包裝
- runtime 在 `features/reader/runtime/`
- content lifecycle 與 preload 在 `features/reader/provider/reader_content_facade_mixin.dart`
- view 執行在 `features/reader/view/`

和 `legado` 相比：

- `legado` 是 `ReadBookActivity` + 一大批 page delegate / dialog / config 類別
- `reader` 把閱讀器真正抽成 runtime 內核，測試保護也更集中
- 但 Android 版在閱讀器周邊能力上仍更完整，例如更多 config dialog、硬體/系統整合、全文搜尋、更多閱讀工具頁

### 其他 feature

仍保留但明顯比 `legado` 收斂：

- `bookmark`
- `browser`
- `dict`
- `replace_rule`
- `txt_toc_rule`
- `read_record`
- `cache_manager`
- `association`
- `about`
- `settings`

`reader` 的策略比較明確：

- 保留支撐小說閱讀主線的工具頁
- 不保留 `legado` 的 RSS 線
- 不保留 Android-only 的大量專屬能力
- 不做多媒體內容容器

## shared 層

`shared/theme` 與 `shared/widgets` 主要放跨 feature UI。

這一層在 `reader` 中很輕，沒有像 `legado/ui/widget/*` 那麼龐大的元件庫。這是合理差異：

- `legado` 是成熟 Android UI app，內建大量自訂 widget
- `reader` 仍主要依賴 Flutter 標準 widget 加少量共用包裝

## 當前架構判讀

### 已經成立的部分

- 資料層、書源引擎、產品 feature、閱讀器 runtime 已有清楚區塊
- `reader` 沒有把 `legado` 的 Android page class 原樣複製到 Flutter
- 閱讀器 runtime 已形成可測試子系統

### 尚未完全收口的部分

- 書源 health 仍是過渡設計
- 部分 provider 還混合 UI state 與資料操作
- service 間仍有少量責任重疊
- 某些 feature 仍留有歷史殘件或半成品 UI

## 結論

如果只看現在的程式碼，最準確的描述不是「Flutter 版 `legado`」，而是：

> `reader` 是一個以 `legado` 書源能力為 compatibility 參考、但在產品範圍與架構上明顯收斂過的 Flutter 小說閱讀器。
