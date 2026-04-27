# B 系列書架功能驗證手冊

這份文件用來驗證「B 系列：書架」功能。當書架打開書籍、本地匯入、網址書籍、排序、多選、分組、匯入匯出、更新檢查或正文快取備份出問題時，先照這份文件查。

## 適用範圍

- 書架頁：`lib/features/bookshelf/bookshelf_page.dart`
- 書架狀態：`lib/features/bookshelf/bookshelf_provider.dart`
- 書架 UI / 分組邏輯：`lib/features/bookshelf/provider/bookshelf_logic_mixin.dart`
- 書架匯入邏輯：`lib/features/bookshelf/provider/bookshelf_import_mixin.dart`
- 書架更新與下載：`lib/features/bookshelf/provider/bookshelf_update_mixin.dart`
- 分組管理頁：`lib/features/bookshelf/group_manage_page.dart`
- 本地書匯入：`lib/core/services/local_book_service.dart`
- 書架 JSON 匯入匯出：`lib/core/services/bookshelf_exchange_service.dart`
- ZIP 備份還原：`lib/core/services/backup_service.dart`、`lib/core/services/restore_service.dart`
- 正文快取：`lib/core/database/dao/reader_chapter_content_dao.dart`、`lib/core/services/reader_chapter_content_store.dart`
- 書籍 / 章節 / 分組 DAO：`lib/core/database/dao/book_dao.dart`、`lib/core/database/dao/chapter_dao.dart`、`lib/core/database/dao/book_group_dao.dart`
- 書架狀態標記：`lib/core/services/bookshelf_state_tracker.dart`

## 快速驗證命令

```bash
flutter analyze
flutter test test/features/bookshelf/bookshelf_provider_test.dart \
  test/backup_service_test.dart \
  test/features/search/search_model_test.dart \
  test/features/search/search_provider_test.dart \
  test/features/explore/explore_show_provider_test.dart \
  --name "BookshelfProvider|BackupService manifest|書架狀態|matchesPrecisionSearch|relevance rank"
```

修改本地書、正文快取或備份還原時，至少再手動驗證一次 TXT / EPUB / UMD 匯入與 ZIP 還原。備份 `reader_chapter_contents` 只能保證已讀、已快取或已下載章節，不等同於備份原始本地書檔或完整全書正文。

## 功能表

| 編號 | 功能 | 現況 | 主要驗證點 |
| --- | --- | --- | --- |
| B1 | 打開書架上的一本書 | 保留 | 點書進 `ReaderPage`，使用 `ReaderOpenTarget.resume(book)` 恢復進度 |
| B2 | 匯入本地書 TXT / EPUB / UMD | 保留 | 建立 `Book`、`BookChapter`，本地正文讀取後寫入 `reader_chapter_contents` |
| B3 | 添加網址書籍 | 保留 | 輸入小說詳情頁 URL，依啟用且可閱讀書源解析資訊與章節後加入書架 |
| B4 | 書架搜尋入口 | 保留 | 書架搜尋 icon 進 `SearchPage` |
| B5 | 書架列表 / 網格切換 | 保留 | 切換 `isGridView` 並寫入 `bookshelf_is_grid` |
| B6 | 書架排序 | 保留 | 最近閱讀、加入時間、更新時間、書名、作者、自訂排序 |
| B7 | 書架多選管理 | 保留 | 多選、全選、移入分組、刪除、批次下載、批次檢查更新 |
| B8 | 書架分組管理 | 保留 | 新增、改名、刪除、排序、顯示/隱藏、分組篩選 |
| B9 | 匯入書架 | 保留 | 從 JSON 檔、JSON 網址或 ZIP 備份匯入書架資料 |
| B10 | 匯出書架 | 保留 | 匯出 books、chapters、sources、chapterContents 並分享 JSON |
| B11 | 手動檢查書架更新 | 保留 | 下拉刷新或初始化刷新會檢查網路書，略過本地書 |
| B12 | 顯示書籍更新狀態 | 部分保留 | 列表顯示最新章節；`lastCheckCount`、`lastCheckTime` 目前主要存在資料層 |
| B13 | 單本書檢查更新 | 底層保留 | `checkBookUpdate(book)` 存在；目前書架 UI 主要從批次與整體刷新入口觸發 |
| B14 | 最近閱讀入口 | 部分保留 | 以「最近閱讀」排序呈現，沒有獨立最近閱讀區塊 |
| B15 | 重複書籍檢測 | 收斂 | 不做同名作者提示；本地同路徑直接回傳既有書，搜尋標記依 `origin + bookUrl` |
| B16 | 合併書籍 / 合併閱讀進度 | 不做 | 每個書源視為獨立書籍；不提供重複書籍合併流程 |
| B17 | 空書架提示 | 簡化保留 | 空狀態顯示文字提示，沒有多個引導按鈕 |
| B18 | 書籍刪除撤銷 | 不做 | 刪除後不提供 undo snackbar |

## 驗證步驟

### B1 打開書架書籍並恢復閱讀位置

入口鏈路：

```text
BookshelfPage
  -> _openBook(context, book)
  -> ReaderPage(book, openTarget: ReaderOpenTarget.resume(book))
  -> ReaderRuntime.openBook()
  -> 依 book.chapterIndex / charOffset / readerAnchorJson 恢復進度
```

手動驗證：

1. 書架至少準備一本已加入書架的文字書。
2. 點書籍封面或列表項。
3. 預期進入閱讀器。
4. 翻到非第一章或非起始位置。
5. 返回書架，再次點同一本書。
6. 預期回到上次閱讀章節與位置。
7. 若書籍 `type == 2`，預期顯示「有聲書播放功能已移除」提示，不進閱讀器。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 書架點擊 | `features/bookshelf/bookshelf_page.dart` / `_openBook()` |
| 閱讀器入口 | `features/reader/reader_page.dart` |
| 開書目標 | `features/reader/runtime/models/reader_open_target.dart` |
| 進度寫入 | `core/database/dao/book_dao.dart` / `updateProgress()` |

常見故障定位：

- 點書進不了閱讀器：檢查 `_isMultiSelect` 是否為 true，或書籍是否為 `type == 2`。
- 進度沒恢復：檢查 `BookDao.updateProgress()` 是否寫入 `chapterIndex`、`charOffset`、`readerAnchorJson`。
- 本地書內容打不開：先看 B2 的本地檔案路徑與章節索引。

### B2 本地書 TXT / EPUB / UMD 匯入與正文快取

入口鏈路：

```text
BookshelfPage menu 添加本地
  -> FilePicker
  -> BookshelfProvider.importLocalBookPath(path)
  -> LocalBookService.importBook(path)
  -> BookDao.upsert(book)
  -> ChapterDao.insertChapters(chapters)
  -> ReaderChapterContentStore.saveRawContent() 讀取後才寫正文快取
```

手動驗證：

1. 準備 `.txt`、`.epub`、`.umd` 測試檔。
2. 書架右上選單點 `添加本地`。
3. 分別選取三種格式。
4. 預期匯入後書架新增書籍，書名、作者、封面盡量顯示。
5. 點本地書進閱讀器，預期可讀取章節正文。
6. 讀過任一章後，檢查正文快取應以 `origin=local`、`bookUrl=local://path` 寫入 `reader_chapter_contents`。
7. 匯入同一路徑本地書，預期不重複新增，直接回傳成功。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 支援格式 | `core/local_book/local_book_formats.dart` |
| 本地匯入 | `features/bookshelf/provider/bookshelf_import_mixin.dart` / `importLocalBookPath()` |
| 本地解析 | `core/services/local_book_service.dart` / `importBook()` |
| TXT 解析 | `core/local_book/txt_parser.dart` |
| EPUB 解析 | `core/services/epub_service.dart` |
| UMD 解析 | `core/local_book/umd_parser.dart` |
| 正文快取 | `core/services/reader_chapter_content_store.dart` |

常見故障定位：

- 檔案選不到：檢查 `allowedExtensions` 是否包含 `txt`、`epub`、`umd`。
- TXT 章節錯位：檢查 `BookChapter.start/end` 與 `TxtParser.splitChapters()`。
- 本地書重啟後讀不到：本地書主要保留原檔路徑，確認原始檔沒有移動或刪除。
- 備份還原後不是完整書：這是目前模型限制，只還原已存在的 `reader_chapter_contents`，不是原始本地檔。

### B3 添加網址書籍

入口鏈路：

```text
BookshelfPage menu 添加網址書籍
  -> _showAddBookUrlDialog()
  -> BookshelfProvider.importBookFromUrl(url)
  -> enabled sources where isReadingEnabledByRuntime
  -> bookUrlPattern 優先匹配書源
  -> BookSourceService.getBookInfo()
  -> BookSourceService.getChapterList()
  -> BookDao.upsert(book)
  -> ChapterDao.insertChapters(chapters)
```

手動驗證：

1. 確認至少有一個啟用且可閱讀的書源。
2. 書架右上選單點 `添加網址書籍`。
3. 輸入該書源可解析的小說詳情頁 URL。
4. 預期成功後提示 `已加入「書名」`。
5. 書架刷新後預期看到該書。
6. 點書進閱讀器，預期可讀取章節。
7. 用不匹配任何書源的 URL 測試，預期提示解析失敗，不應新增空書。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| UI dialog | `features/bookshelf/bookshelf_page.dart` / `_showAddBookUrlDialog()` |
| URL 匯入 | `features/bookshelf/provider/bookshelf_import_mixin.dart` / `importBookFromUrl()` |
| 書源能力 | `core/models/source/book_source_logic.dart` / `isReadingEnabledByRuntime` |
| 書籍資訊解析 | `core/services/book_source_service.dart` / `getBookInfo()` |
| 章節解析 | `core/services/book_source_service.dart` / `getChapterList()` |

常見故障定位：

- 顯示沒有可用書源：檢查書源是否 enabled 且 runtime 健康狀態允許閱讀。
- 明明是正確 URL 卻解析失敗：檢查書源 `bookUrlPattern`、詳情規則與網路請求。
- 加入後沒有章節：`importBookFromUrl()` 會拒絕空章節，先看 `getChapterList()`。
- 同源同 URL 重複加入覆蓋資料：目前 `books.bookUrl` 是主鍵，需確認 `bookUrl` 是否穩定。

### B4-B6 搜尋入口、列表網格與排序

手動驗證：

1. 書架點搜尋 icon，預期進入 `SearchPage`。
2. 返回書架，右上選單切換 `列表視圖 / 網格視圖`。
3. 關閉並重開 app，預期視圖偏好保留。
4. 右上選單點 `排序`。
5. 分別選擇：
   - `最近閱讀`
   - `加入時間`
   - `更新時間`
   - `書名`
   - `作者`
   - `自訂排序`
6. 預期書架順序符合選擇。
7. 選 `自訂排序` 且目前為列表視圖時，拖曳列表項，預期順序保存。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 搜尋入口 | `features/bookshelf/bookshelf_page.dart` |
| 視圖偏好 | `features/bookshelf/provider/bookshelf_logic_mixin.dart` / `setGridView()` |
| 排序模式 | `features/bookshelf/provider/bookshelf_provider_base.dart` / `BookshelfSortMode` |
| 排序實作 | `features/bookshelf/bookshelf_provider.dart` / `_sortBooks()` |
| 自訂排序 | `features/bookshelf/provider/bookshelf_logic_mixin.dart` / `reorderBooks()` |
| 偏好 key | `core/constant/prefer_key.dart` / `bookshelfSort` |

常見故障定位：

- 視圖重啟後不保留：檢查 `SharedPreferences` 的 `bookshelf_is_grid`。
- 排序重啟後不保留：檢查 `PreferKey.bookshelfSort`。
- 自訂排序拖曳沒出現：目前只在 `sortMode == custom` 且非多選時使用 `ReorderableListView`。
- 書名或作者中文排序不符合語言習慣：目前使用 Dart 字串排序，未接中文拼音或 locale collator。

### B7 多選管理、批次下載與批次檢查更新

手動驗證：

1. 長按任一本書，或右上選單點 `書架管理`。
2. 預期進入多選模式，AppBar 顯示已選本數。
3. 點不同書籍，預期選取狀態切換。
4. 點 `全選`，預期全選；再次點預期清空。
5. 點 `移入分組`，選擇分組或未分組，預期書籍分組更新。
6. 選網路書後點 `批次下載`，預期加入下載任務，已快取章節被略過。
7. 選網路書後點 `批次檢查更新`，預期顯示有更新本數、新章節數與失敗本數。
8. 選本地書批次下載或檢查更新，預期本地書被略過。
9. 點刪除並確認，預期書籍、章節、正文快取與封面資源被清掉。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 多選 UI | `features/bookshelf/bookshelf_page.dart` |
| 分組批次更新 | `features/bookshelf/provider/bookshelf_logic_mixin.dart` / `batchUpdateGroup()` |
| 刪除資料 | `core/services/book_storage_service.dart` / `discardBook()` |
| 批次下載 | `features/bookshelf/provider/bookshelf_update_mixin.dart` / `batchDownload()` |
| 批次檢查更新 | `features/bookshelf/provider/bookshelf_update_mixin.dart` / `batchCheckUpdate()` |
| 下載服務 | `core/services/download_service.dart` |
| 已快取章節判斷 | `core/services/reader_chapter_content_store.dart` / `storedChapterIndices()` |

常見故障定位：

- 批次下載全部略過：檢查是否選到本地書、書源不存在、書源不可閱讀或章節已全部快取。
- 下載任務沒有開始：檢查 `DownloadService.addDownloadTask()` 與 `DownloadScheduler.startDownloads()`。
- 更新檢查插入成另一本文：檢查 `checkBookUpdate()` 是否維持原本 `book.bookUrl`。
- 刪除後正文還在：檢查 `BookStorageService.discardBook()` 是否呼叫 `ReaderChapterContentDao.deleteByBook()`。
- 按返回鍵沒有退出多選：檢查 `BookshelfPage` 的 `PopScope`。

### B8 分組管理與分組篩選

手動驗證：

1. 書架右上選單點 `分組管理`。
2. 點新增，輸入分組名稱，可選封面，預期新增分組。
3. 回書架，預期上方分組列出現新分組。
4. 多選書籍移入該分組，點分組 chip，預期只顯示該分組書籍。
5. 點 `未分組`，預期只顯示 group 為 0 的書。
6. 回分組管理，修改名稱或封面，預期保存。
7. 切換顯示開關，預期書架分組列隱藏或顯示該分組。
8. 拖曳分組排序，回書架後預期分組順序更新。
9. 刪除分組，預期書籍移出該分組，不刪除書籍本身。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 分組列 | `features/bookshelf/bookshelf_page.dart` / `_buildGroupBar()` |
| 分組管理頁 | `features/bookshelf/group_manage_page.dart` |
| 分組 DAO | `core/database/dao/book_group_dao.dart` |
| 分組篩選 | `core/database/dao/book_dao.dart` / `getInGroup()` |
| 分組 bit mask | `core/models/book_group.dart`、`core/models/book/book_logic.dart` |

常見故障定位：

- 新分組沒有出現在書架：檢查 `BookGroup.show` 是否為 true，以及 `loadGroups()` 是否重跑。
- 未分組顯示錯誤：檢查 `BookDao.getInGroup(0)` 是否同時限制 `isInBookshelf == true`。
- 刪除分組後書籍消失：檢查 `deleteGroup()` 是否只移除 group mask，不刪書。
- 分組排序不保留：檢查 `BookGroupDao.updateOrder()` 與 `getAll()` 的 orderBy。

### B9-B10 匯入、匯出書架與 ZIP 備份正文快取

手動驗證 JSON 匯出匯入：

1. 準備至少一本網路書、一本文本地書，並打開讀過部分章節。
2. 書架右上選單點 `匯出書架`。
3. 預期分享 `bookshelf-export.inkpage.json`。
4. 檢查 JSON 應包含：
   - `kind`
   - `version`
   - `books`
   - `chapters`
   - `sources`
   - `chapterContents`
5. 用 `從檔案匯入書架` 匯入 JSON。
6. 預期提示匯入本數、章節數、書源數與正文快取數。
7. 用 `從網址匯入書架` 匯入同格式 JSON URL，預期結果一致。

手動驗證 ZIP 備份還原：

1. 從設定或備份入口建立 ZIP 備份。
2. 解壓或檢查 ZIP 應包含 `readerChapterContent.json`。
3. 用書架 `從檔案匯入書架` 選 ZIP。
4. 預期還原成功。
5. 重開相關頁面，檢查書架、章節、已快取正文可用。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 書架匯入匯出 | `core/services/bookshelf_exchange_service.dart` |
| JSON 檔匯入 | `features/bookshelf/bookshelf_page.dart` / `_handleBookshelfImport()` |
| JSON URL 匯入 | `features/bookshelf/bookshelf_page.dart` / `_showImportBookshelfUrlDialog()` |
| ZIP 備份 | `core/services/backup_service.dart` / `createBackupZip()` |
| ZIP 還原 | `core/services/restore_service.dart` / `restoreFromZip()` |
| 正文快取序列化 | `core/models/reader_chapter_content.dart` |
| 正文快取 DAO | `core/database/dao/reader_chapter_content_dao.dart` |

常見故障定位：

- 匯入後書不在書架：檢查 `BookshelfExchangeService.importFromText()` 是否將 `isInBookshelf` 正規化為 true。
- 匯入後章節缺失：檢查 JSON 是否有 `chapters`，以及 `ChapterDao.insertChapters()` 是否成功。
- 匯入後正文快取缺失：檢查 JSON 的 `chapterContents` 或 ZIP 的 `readerChapterContent.json`。
- 還原 ZIP 失敗：檢查 `manifest.json` 是否存在且 schema 相容。
- 本地書還原後無法讀完整書：這是目前模型限制，備份只保留已快取正文，不保留原始本地檔。

### B11-B13 更新檢查與更新狀態

手動驗證：

1. 書架下拉刷新。
2. 預期網路書進行更新檢查，本地書略過。
3. 若有新章節，預期 `lastCheckCount` 更新，列表最新章節文字更新。
4. 選一本或多本網路書進多選，點 `批次檢查更新`。
5. 預期 Snackbar 顯示更新本數、新章節數與失敗本數。
6. 書源失效時，預期不崩潰，該書 `lastCheckTime` 仍更新並回報失敗。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 書架刷新 | `features/bookshelf/bookshelf_page.dart` / `RefreshIndicator` |
| 整體更新 | `features/bookshelf/provider/bookshelf_update_mixin.dart` / `refreshBookshelf()` |
| 單本更新 | `features/bookshelf/provider/bookshelf_update_mixin.dart` / `checkBookUpdate()` |
| 批次更新 | `features/bookshelf/provider/bookshelf_update_mixin.dart` / `batchCheckUpdate()` |
| 書源解析 | `core/services/book_source_service.dart` |

常見故障定位：

- 下拉刷新沒有檢查：確認書架不是空、書籍不是本地書，且 `book.origin` 能找到書源。
- 更新後閱讀進度被覆蓋：檢查 `checkBookUpdate()` 是否保留 `chapterIndex`、`charOffset`、`durChapterTitle`、`readerAnchorJson`。
- 新章節數永遠 0：檢查舊 `totalChapterNum` 與新章節列表長度。
- UI 看不到最後檢查時間：目前主要存在資料層，書架列表只顯示最新章節文字。

### B14-B18 收斂功能與非目標驗證

手動驗證：

1. 選 `最近閱讀` 排序，閱讀一本書後回書架，預期該書靠前。
2. 搜尋或添加不同來源同名同作者書籍，預期不因同名作者被搜尋標記或結果合併成同一本。
3. 匯入同一路徑本地書，預期不重複新增。
4. 刪除書籍後，預期沒有 undo snackbar。
5. 清空書架或使用空資料庫啟動，預期顯示 `書架空空如也，去搜尋看看吧`。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 最近閱讀排序 | `features/bookshelf/bookshelf_provider.dart` / `_sortBooks()` |
| 搜尋去重 | `features/search/search_model.dart` / `_isSameSourceDuplicate()` |
| 書架標記 | `core/services/bookshelf_state_tracker.dart` |
| 本地書重複路徑 | `features/bookshelf/provider/bookshelf_import_mixin.dart` / `importLocalBookPath()` |
| 空書架提示 | `features/bookshelf/bookshelf_page.dart` |

常見故障定位：

- 同名不同來源被標記已在書架：檢查 `BookshelfStateTracker.makeBookshelfKey()` 是否使用 `origin + bookUrl`。
- 同名不同來源在搜尋結果被合併：檢查 `_isSameSourceDuplicate()` 是否要求同一 `origin`。
- 期待合併閱讀進度：B16 已決定不做；換源遷移進度是另一條流程，不是重複書合併。
- 期待刪除撤銷：B18 已決定不做；刪除會直接移除書籍與相關儲存資料。
- 期待空書架有多個引導按鈕：目前 B17 是簡化文字提示。

## 常見故障定位索引

| 問題 | 先看哪裡 |
| --- | --- |
| 書架空白但資料庫有書 | `BookDao.getInBookshelf()`、`BookshelfProvider.loadBooks()` |
| 點書變成選取而非開書 | `BookshelfPage._isMultiSelect` |
| 本地書匯入失敗 | `LocalBookService.importBook()`、對應 parser、檔案路徑權限 |
| 本地書還原後正文不完整 | `reader_chapter_contents` 是否只有已讀/已快取章節 |
| 網址書籍解析失敗 | `BookshelfImportMixin.importBookFromUrl()`、書源 `bookUrlPattern`、詳情/目錄規則 |
| 書架 JSON 匯入後不顯示 | `BookshelfExchangeService.importFromText()`、`Book.isInBookshelf` |
| ZIP 還原失敗 | `RestoreService._isManifestCompatible()`、`manifest.json`、schema version |
| 批次下載沒有章節 | `ChapterDao.getByBook()`、`BookSourceService.getChapterList()` |
| 已下載章節仍重複下載 | `ReaderChapterContentStore.storedChapterIndices()` |
| 更新檢查覆蓋閱讀進度 | `BookshelfUpdateMixin.checkBookUpdate()` 保留欄位 |
| 分組篩選錯誤 | `BookDao.getInGroup()`、`Book.group` bit mask |
| 刪除後快取殘留 | `BookStorageService.discardBook()`、`ReaderChapterContentDao.deleteByBook()` |
| 書架狀態標記不準 | `BookshelfStateTracker`、搜尋/發現結果的 `origin` 與 `bookUrl` |

## 已移除 / 不列入 B 系列目標

| 項目 | 決策 | 原因 |
| --- | --- | --- |
| 重複書籍合併流程 | 不做 | 每個書源視為獨立書籍，避免誤合併閱讀進度與快取 |
| 書籍刪除撤銷 | 不做 | 目前刪除會同步清理 book、chapters、content cache 與封面資源 |
| 空書架多按鈕 onboarding | 不做 | 目前只保留簡化文字提示，搜尋與匯入入口在 AppBar |
| 本地原始檔備份 | 不做 | 備份 `reader_chapter_contents`，只覆蓋已快取正文 |
| 搜尋結果批次加入書架 | 不做 | 屬 C 系列決策，維持進詳情或添加網址單本加入 |

## 測試覆蓋

目前 B 系列主要測試：

```text
test/features/bookshelf/bookshelf_provider_test.dart
test/backup_service_test.dart
test/features/search/search_provider_test.dart
test/features/explore/explore_show_provider_test.dart
test/features/search/search_model_test.dart
test/core/local_book/txt_parser_test.dart
test/core/local_book/epub_parser_test.dart
test/core/local_book/umd_import_test.dart
test/features/reader/reader_chapter_content_loader_test.dart
```

建議每次修改 B 系列後至少執行：

```bash
flutter analyze
flutter test test/features/bookshelf/bookshelf_provider_test.dart test/backup_service_test.dart
```

若改到本地書、正文快取或書架狀態標記，再加跑：

```bash
flutter test test/core/local_book test/features/reader/reader_chapter_content_loader_test.dart
flutter test test/features/search/search_provider_test.dart test/features/explore/explore_show_provider_test.dart --name "書架狀態"
```
