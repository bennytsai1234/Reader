# Rules And Local Books

## Reader 現況

- 替換規則：`lib/features/replace_rule`
- TXT 目錄規則：已移除使用者入口與預設匯入，資料表僅保留相容性
- 字典規則：已移除使用者入口、查詢服務與預設匯入，資料表僅保留相容性
- 本地格式解析：`lib/core/local_book`
- 本地書服務：`lib/core/services/local_book_service.dart`

## Reader 上下游依賴

- 直接上游依賴：`lib/core/database`、`lib/core/models`、`lib/core/engine`、`lib/core/storage`、`lib/core/services/epub_service.dart`
- 直接下游影響：`lib/features/reader_v2`、`lib/features/source_manager`、`lib/features/settings`、`lib/features/association`、`lib/features/bookshelf`，以及內容淨化、目錄解析、本地書匯入與閱讀流程

## Legado 對照

- 替換規則：`legado/app/src/main/java/io/legado/app/ui/replace`
- TXT 規則：`legado/app/src/main/java/io/legado/app/ui/book/toc/rule`
- 字典：`legado/app/src/main/java/io/legado/app/ui/dict`
- 本地匯入：`legado/app/src/main/java/io/legado/app/ui/book/import`
- 檔案管理：`legado/app/src/main/java/io/legado/app/ui/file`
- 本地書模型與模組：`legado/app/src/main/java/io/legado/app/model/localBook`、`legado/modules/book`

## 可借鏡的方向

- 規則編輯、預覽、驗證如何分開
- 規則失敗時如何提供可定位的錯誤資訊
- 本地書匯入、格式判定、內容轉換如何各自負責

## 不要做的事

- 不增加 `reader` 目前不打算支持的規則體系
- 不新增 `reader` 目前未規劃的新書籍格式
