# Source Manager And Browser

## 目標專案目前狀態

- 書源管理在 `lib/features/source_manager`，核心狀態是 `source_manager_provider.dart`，支援匯入 JSON/URL、預覽新增/更新/無變化、篩選、排序、分組、選取、分享、匯出與批次操作。
- 書源匯入由 `SourceImportService` 處理，解析時會把非純文字小說書源停用並加入標籤。
- 書源校驗在 `lib/core/services/check_source_service.dart`，支援搜尋/發現/詳情/目錄/正文階段、timeout、取消、runtime health 標籤、清理候選與進度 log。
- 書源除錯在 `source_debug_provider.dart` 與 `SourceDebugService`。
- WebView 與驗證在 `lib/features/browser`：`BrowserProvider` 解析 `AnalyzeUrl`、同步 Cookie、保存驗證結果；`SourceVerificationCoordinator` 監聽 `SourceVerificationService` 並排隊開啟 browser 或驗證碼對話框。

## 目標專案上下游

- 上游依賴：`BookSourceDao`、`BookSource`/`BookSourcePart`、`NetworkService`、`BookSourceService`、`AnalyzeUrl`、`CookieStore`、`WebViewDataService`、`SourceVerificationService`、`SourceValidationContext`。
- 下游影響：`Discovery And Search`、`Book Detail`、`Reader Runtime`、設定頁、來源健康度、登入 Cookie 與所有書源規則執行。
- 書源資料模型與 runtime health 是跨模組契約；修改欄位、group/comment 健康標記或啟用條件時，要同步檢查搜尋、探索、詳情與閱讀。

## 參考對應

- `legado/app/src/main/java/io/legado/app/ui/book/source`
- `legado/app/src/main/java/io/legado/app/ui/book/source/debug`
- `legado/app/src/main/java/io/legado/app/ui/book/source/edit`
- `legado/app/src/main/java/io/legado/app/ui/book/source/manage`
- `legado/app/src/main/java/io/legado/app/ui/browser`
- `legado/app/src/main/java/io/legado/app/ui/login`
- `legado/app/src/main/java/io/legado/app/service/CheckSourceService.kt`
- `legado/app/src/main/java/io/legado/app/help/source/SourceVerificationHelp.kt`

## 可參考模式

- 書源清單、編輯器、除錯器、校驗器、登入/驗證應各自保留入口，透過資料模型與服務層銜接。
- 校驗流程可參考 Legado 的分階段健康判定，但 `reader` 應保留目前的非互動批次策略、timeout budget 與 runtime health 分類。
- 驗證流程要把人工互動從批次校驗中隔離，避免整批來源被單一驗證頁卡住。

## 目標專案變更入口

- 書源清單與匯入：`lib/features/source_manager/source_manager_provider.dart`、`widgets/import_preview_dialog.dart`。
- 書源 UI：`source_manager_page.dart`、`source_editor_page.dart`、`source_group_manage_page.dart`、`source_subscription_page.dart`。
- 書源校驗：`lib/core/services/check_source_service.dart`、`tool/source_validation_support.dart`、`tool/run_source_validation.sh`。
- 除錯：`lib/features/source_manager/source_debug_provider.dart`、`lib/core/services/source_debug_service.dart`。
- Browser/驗證：`lib/features/browser/browser_provider.dart`、`source_verification_coordinator.dart`、`lib/core/services/source_verification_service.dart`。
- 測試：`flutter test test/features/source_manager/source_manager_provider_test.dart test/features/source_manager/source_manager_page_smoke_test.dart test/features/source_manager/source_login_test.dart test/core/services/check_source_service_test.dart test/core/services/source_verification_service_test.dart test/tool/source_validation_support_test.dart`。

## 已知風險

- `CheckSourceService` 會把健康狀態寫回 source group/comment；變更標籤或 message 合成會影響清理候選、搜尋池與 UI 分組。
- 批次校驗使用 worker concurrency、stage timeout、source timeout 與 cancel token；修改時要避免慢源佔滿 worker 或 cancel 後仍寫回資料庫。
- 非小說來源目前會被停用並標記，這是匯入層與校驗層共同假設。
- `BrowserProvider.saveVerificationResult()` 可能回寫 Cookie 並重新抓取 HTML；修改驗證流程要確認 Cookie domain normalization。
- Source manager provider cache `_visibleSourcesCache` 依 dirty flag 更新；新增過濾或排序條件時要記得標記 dirty。

## 不要做

- 不把 WebView 擴張成一般瀏覽器產品。
- 不因為 `legado` 支援更多來源類型就新增 `reader` 未要求的 RSS、音訊或漫畫來源能力。
- 不在書源管理 UI 直接實作規則解析；規則執行仍屬 `core/engine` 與 `BookSourceService`。
