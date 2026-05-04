# Book Detail

## 目標專案目前狀態

- 主要目錄是 `lib/features/book_detail`，核心狀態在 `book_detail_provider.dart`，UI 在 `book_detail_page.dart` 與 `widgets/`。
- `BookDetailProvider` 會載入既有書籍、來源、書籍詳情、章節目錄、封面資產與單本快取狀態。
- 詳情頁支援加入/移出書架、目錄搜尋與倒序、換源、換封面、檢查更新、清理快取、排程下載全書/範圍/缺失章節。
- 換源候選在 `source/book_detail_change_source_provider.dart`，封面搜尋在 `change_cover_provider.dart` 與 `change_cover_sheet.dart`。

## 目標專案上下游

- 上游依賴：`BookDao`、`ChapterDao`、`BookSourceDao`、`ReaderChapterContentDao`、`BookSourceService`、`BookCoverStorageService`、`DownloadService`、`ReaderChapterContentStore`、`SearchBook`。
- 下游影響：`Reader Runtime` 開啟閱讀、`Bookshelf` 同步、`Source Manager` 書源狀態、下載任務、封面儲存與單本正文快取。
- 詳情頁是搜尋/探索/書架到閱讀器之間的資料邊界；修改書籍主資料時要保留進度、書架狀態、自訂封面、自訂簡介與章節 index。

## 參考對應

- `legado/app/src/main/java/io/legado/app/ui/book/info`
- `legado/app/src/main/java/io/legado/app/ui/book/toc`
- `legado/app/src/main/java/io/legado/app/ui/book/changesource`
- `legado/app/src/main/java/io/legado/app/ui/book/changecover`

## 可參考模式

- 書籍資訊、目錄、操作區、換源與換封面應各自保留邊界，避免詳情頁變成跨功能控制中心。
- 換源時可參考 Legado 的「保留使用者書籍狀態、替換來源資料」流程，但要以 `reader` 的 `Book.migrateTo` 與內容儲存模型為主。
- 章節與正文快取應用明確 key 與 origin 判定，避免舊來源內容被新來源誤用。

## 目標專案變更入口

- 詳情狀態：`lib/features/book_detail/book_detail_provider.dart`。
- 詳情 UI：`lib/features/book_detail/book_detail_page.dart`、`lib/features/book_detail/widgets/`。
- 換源：`lib/features/book_detail/source/book_detail_change_source_provider.dart`、`lib/features/book_detail/widgets/change_source_sheet.dart`。
- 換封面：`lib/features/book_detail/change_cover_provider.dart`、`lib/features/book_detail/change_cover_sheet.dart`。
- 測試：`flutter test test/features/book_detail/book_detail_provider_test.dart test/features/book_detail/book_detail_page_compile_test.dart test/features/book_detail/book_info_header_smoke_test.dart`。

## 已知風險

- `changeSource()` 會先取得候選來源詳情與章節，再用舊書資料遷移；任何欄位漏保留都可能造成進度、書架狀態或自訂資訊遺失。
- 快取狀態只計入同 `origin` 且 ready 的 `ReaderChapterContentEntry`；改變儲存 key 或 origin 判定會影響詳情頁與閱讀器。
- 下載排程前會確保章節 metadata；章節列表空、來源 disabled、runtime health 不允許閱讀時要回傳清楚訊息。
- 目錄搜尋 debounce 與 provider dispose 有關，新增 async 流程要避免 dispose 後 notify。

## 不要做

- 不把詳情頁擴張成書源管理頁或閱讀器設定頁。
- 不為了對齊 `legado` 新增 `reader` 沒有的詳情頁分支。
- 不在詳情頁直接解析規則；應委派 `BookSourceService` 與 engine。
