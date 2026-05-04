# Bookshelf

## 目標專案目前狀態

- 主要 UI 與狀態在 `lib/features/bookshelf/bookshelf_page.dart`、`lib/features/bookshelf/bookshelf_provider.dart`。
- `BookshelfProvider` 由 `BookshelfProviderBase` 加上三個 mixin 組成：`bookshelf_logic_mixin.dart` 管 UI 偏好、排序、批次選取；`bookshelf_update_mixin.dart` 管更新檢查、批次下載與書架匯入；`bookshelf_import_mixin.dart` 管本地書匯入。
- 書架資料從 `BookDao.getInBookshelf()` 讀取，並透過 `AppEventBus.upBookshelf` 重新載入。
- 刪除書籍時會走 `BookStorageService.discardBook()`，同步清理章節、正文儲存、書籤、下載任務與封面資產。

## 目標專案上下游

- 上游依賴：`BookDao`、`BookSourceDao`、`ChapterDao`、`BookSourceService`、`LocalBookService`、`BookCoverStorageService`、`ReaderChapterContentStore`、`DownloadService`、`BookshelfExchangeService`。
- 下游影響：`lib/features/book_detail`、`lib/features/reader_v2`、`lib/features/settings`、批次下載、書架排序與進入閱讀的主流程。
- 本地書與線上書在更新、下載、章節內容來源上分歧，跨模組變更要先確認 `Book.isLocal` 與 `origin == 'local'` 的路徑。

## 參考對應

- `legado/app/src/main/java/io/legado/app/ui/main/bookshelf`
- `legado/app/src/main/java/io/legado/app/ui/book/manage`
- `legado/app/src/main/java/io/legado/app/ui/book/group`
- `legado/app/src/main/java/io/legado/app/help/book/BookHelp.kt`

## 可參考模式

- 書架列表刷新、分組、排序、批次操作應維持清楚邊界，避免 UI 操作直接混入網路抓取細節。
- 書籍更新流程要保留原書架資訊、進度與自訂資料，再更新來源回傳的書籍與章節。
- 刪除或移除書籍要集中處理 downstream 資產清理，避免留下孤兒章節或下載任務。

## 目標專案變更入口

- 書架狀態：`lib/features/bookshelf/bookshelf_provider.dart` 與 `lib/features/bookshelf/provider/*.dart`。
- 書架 UI：`lib/features/bookshelf/bookshelf_page.dart`。
- 資料清理：`lib/core/services/book_storage_service.dart`。
- 更新與下載：`lib/features/bookshelf/provider/bookshelf_update_mixin.dart`、`lib/core/services/download_service.dart`。
- 測試：`flutter test test/features/bookshelf/bookshelf_provider_test.dart test/features/bookshelf/bookshelf_page_compile_test.dart test/core/services/bookshelf_exchange_service_test.dart`。

## 已知風險

- `loadBooks()` 會排序並通知 UI；排序偏好、手動 reorder 與資料庫 order 需要一致。
- 批次更新同時觸發多個來源請求，錯誤目前以單本結果回報；不要讓單本失敗中斷整批書架刷新。
- 批次下載會依章節儲存狀態過濾待下載章節；修改內容儲存 key 或章節 index 時要一起檢查下載與詳情頁快取狀態。
- 本地書匯入會複製封面與寫入章節；檔案路徑、charset、章節 offset 錯誤會一路影響 Reader Runtime。

## 不要做

- 不因為 `legado` 有更多書架管理能力就擴增 `reader` 未要求的分組或批次功能。
- 不在書架層直接解析書源規則或章節正文。
- 不把閱讀器 runtime 的進度保存邏輯搬進書架 provider。
