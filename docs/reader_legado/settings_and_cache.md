# Settings And Cache

## Reader 現況

- 設定：`lib/features/settings`
- 快取 / 下載：`lib/features/cache_manager`
- 核心服務：
  - `lib/core/services/download_service.dart`
  - `lib/core/services/cache_manager.dart`
  - `lib/core/services/chapter_content_scheduler.dart`
  - `lib/core/services/chapter_content_preparation_pipeline.dart`
  - `lib/core/services/backup_service.dart`
  - `lib/core/services/restore_service.dart`

## Reader 上下游依賴

- 直接上游依賴：`lib/core/config`、`lib/core/constant`、`lib/core/database`、`lib/core/models`、`lib/core/services/tts_service.dart`、`lib/core/services/book_source_service.dart`、`lib/core/services/network_service.dart`、`lib/features/reader_v2/features/settings`
- 直接下游影響：`lib/features/welcome`、`lib/features/reader_v2`、`lib/features/book_detail`、`lib/features/browser`，以及從設定頁聚合出去的下載、備份、隱私流程；閱讀排版與閱讀器內顯示設定以 `reader_v2` 內建面板為主入口

## Legado 對照

- 設定：`legado/app/src/main/java/io/legado/app/ui/config`
- 字體：`legado/app/src/main/java/io/legado/app/ui/font`
- 偏好與主題：`legado/app/src/main/java/io/legado/app/lib`
- 快取頁：`legado/app/src/main/java/io/legado/app/ui/book/cache`
- 下載與快取服務：`legado/app/src/main/java/io/legado/app/service`

## 可借鏡的方向

- 設定頁如何切成閱讀、外觀、TTS、備份等子區
- 設定儲存與實際功能套用如何解耦
- 快取任務如何排程，並避免和前景閱讀互相卡住

## 不要做的事

- 不為了對齊 `legado` 而新增更多設定分類
- 不把快取系統擴張成新的下載產品功能
