# Integration And Diagnostics

## Reader 現況

- 關聯 / 匯入：`lib/features/association`
- 關於 / 診斷：`lib/features/about`
- 代表檔案：
  - `lib/features/about/about_page.dart`
  - `lib/features/about/crash_log_page.dart`

## Reader 上下游依賴

- 直接上游依賴：`lib/core/services/local_book_service.dart`、`lib/core/services/book_storage_service.dart`、`lib/core/models`、`lib/core/services/app_log_service.dart`、`lib/core/services/app_version.dart`、`lib/core/services/crash_handler.dart`
- 直接下游影響：`lib/features/bookshelf`、`lib/features/book_detail`、`lib/features/settings/settings_page.dart`，以及外部匯入、本地匯入後導入書架與問題診斷的流程

## Legado 對照

- 關聯：`legado/app/src/main/java/io/legado/app/ui/association`
- 外部 API：`legado/app/src/main/java/io/legado/app/api`
- About：`legado/app/src/main/java/io/legado/app/ui/about`
- 說明文件：`legado/api.md`

## 可借鏡的方向

- 外部匯入入口如何與 app 內部流程接起來
- 外部資料導入時如何驗證與容錯
- 問題回報、版本資訊、log 與 crash 資訊如何集中

## 不要做的事

- 不擴增成大型外部 API 平台
- 不把診斷頁面做成新的進階產品面
