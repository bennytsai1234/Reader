# Settings And Cache

## 目標專案目前狀態

- 設定主狀態在 `lib/features/settings/settings_provider.dart`，基底在 `provider/settings_base.dart`，以 `SharedPreferences` 儲存偏好並透過 `ChangeNotifier` 通知 UI。
- 設定頁分散在 `lib/features/settings/*_settings_page.dart`，閱讀器內設定在 `lib/features/reader_v2/features/settings`。
- TTS 全域服務是 get_it 的 `TTSService`，`SettingsProvider` 會同步 rate/pitch/volume，`reader_v2` 也有自己的 TTS controller。
- 下載在 `lib/core/services/download_service.dart`，由 `DownloadBase`、`DownloadScheduler`、`DownloadExecutor` 拆分，並持久化 `DownloadTask`。
- 章節內容儲存、預備與排程在 `ReaderChapterContentStore`、`ReaderChapterContentStorage`、`ChapterContentPreparationPipeline`、`ChapterContentScheduler`。
- 備份與還原在 `BackupService`、`RestoreService`，會輸出/匯入書架、書源、替換規則、書籤、閱讀紀錄、分組、下載任務、章節內容與 `config.json`。

## 目標專案上下游

- 上游依賴：`SharedPreferences`、`PreferKey`、`AppConfig`、`AppDatabase` schema、各 DAO、`BookSourceService`、`NetworkService`、`TTSService`、檔案系統 storage paths。
- 下游影響：App Shell 主題與語系、Reader Runtime 排版/朗讀、Book Detail 快取與下載、Bookshelf 批次下載、Source Manager 校驗設定、備份還原完整性。
- 偏好 key 與備份 schema 是長期相容契約；改名或移除要有遷移策略。

## 參考對應

- `legado/app/src/main/java/io/legado/app/ui/config`
- `legado/app/src/main/java/io/legado/app/help/config`
- `legado/app/src/main/java/io/legado/app/ui/book/cache`
- `legado/app/src/main/java/io/legado/app/service/DownloadService.kt`
- `legado/app/src/main/java/io/legado/app/service/CacheBookService.kt`
- `legado/app/src/main/java/io/legado/app/help/storage/Backup.kt`
- `legado/app/src/main/java/io/legado/app/help/storage/Restore.kt`

## 可參考模式

- 設定頁可按閱讀、外觀、TTS、備份、隱私等主題拆分，但設定套用要透過 provider/service，而不是頁面直接操作下游模組。
- 下載與快取任務要能暫停、恢復、重試、取消，並避免前景閱讀被背景任務拖慢。
- 備份還原要先驗證 manifest/schema，再匯入資料，失敗時應有清楚中止點。

## 目標專案變更入口

- 設定狀態：`lib/features/settings/settings_provider.dart`、`lib/features/settings/provider/settings_base.dart`、`lib/core/constant/prefer_key.dart`。
- 設定 UI：`lib/features/settings/*.dart`、`lib/features/reader_v2/features/settings/`。
- 下載：`lib/core/services/download_service.dart`、`lib/core/services/download/`、`lib/features/cache_manager/download_manager_page.dart`。
- 內容儲存：`lib/core/services/reader_chapter_content_*`、`lib/core/services/chapter_content_*`。
- 備份還原：`lib/core/services/backup_service.dart`、`restore_service.dart`。
- 測試：`flutter test test/features/settings test/download_executor_test.dart test/backup_service_test.dart test/core/services/tts_state_test.dart`，內容儲存變更再加 reader_v2 與 book_detail tests。

## 已知風險

- `SettingsProvider` 同時載入大量偏好；新增欄位要補預設值、setter、`PreferKey`，必要時補 UI 與測試。
- `DownloadService` 是 singleton 且在 constructor 載入任務；測試與重複初始化要避免共享殘留狀態。
- 下載任務與 chapter content store 都依賴章節 index/bookUrl/origin；來源切換或章節重建會影響快取命中。
- `BackupService.currentSchemaVersion` 依 `AppDatabase().schemaVersion`，還原會拒絕缺少或不相容 manifest；備份格式變更要同步 restore。
- `SharedPreferences` 裡的舊 key 可能仍被現有使用者資料依賴，不能只看目前 UI 是否使用。

## 不要做

- 不把快取或下載擴張成新的產品功能，除非使用者明確要求。
- 不為了對齊 `legado` 新增 `reader` 未使用的設定分類或 TTS 引擎。
- 不讓設定頁直接修改 reader_v2 runtime 內部狀態；應透過既有 controller/repository/provider。
