# C 系列搜尋與發現功能驗證手冊

這份文件用來驗證「C 系列：搜尋與發現」功能。當搜尋範圍、精準搜尋、搜尋結果排序篩選、失敗重試、發現分類或發現列表出問題時，先照這份文件查，不需要從整個系統重新翻起。

## 適用範圍

- 搜尋頁：`lib/features/search/search_page.dart`
- 搜尋狀態：`lib/features/search/search_provider.dart`
- 搜尋引擎：`lib/features/search/search_model.dart`
- 搜尋範圍：`lib/features/search/models/search_scope.dart`
- 搜尋輸入列：`lib/features/search/widgets/search_app_bar.dart`
- 搜尋範圍彈窗：`lib/features/search/widgets/search_scope_sheet.dart`
- 搜尋歷史：`lib/features/search/widgets/search_history_view.dart`
- 搜尋結果項目：`lib/features/search/widgets/search_result_item.dart`
- 發現頁：`lib/features/explore/explore_page.dart`
- 發現來源狀態：`lib/features/explore/explore_provider.dart`
- 發現列表：`lib/features/explore/explore_show_page.dart`
- 發現列表狀態：`lib/features/explore/explore_show_provider.dart`
- 發現書籍項目：`lib/features/explore/widgets/explore_book_item.dart`
- 書架狀態標記：`lib/core/services/bookshelf_state_tracker.dart`
- 書源 runtime 能力判斷：`lib/core/models/source/book_source_logic.dart`

## 快速驗證命令

```bash
dart analyze lib/features/search lib/features/explore test/features/search test/features/explore
flutter test test/features/search test/features/explore
```

全專案驗證：

```bash
flutter analyze
flutter test
```

注意：目前 `flutter analyze` 可能仍會回報 `lib/features/bookshelf/bookshelf_page.dart` 的 Radio deprecated info；那不是 C 系列搜尋/發現改動造成。

## 功能表

| 編號 | 功能 | 現況 | 主要驗證點 |
| --- | --- | --- | --- |
| C1 | 搜尋關鍵字 → 多書源搜尋 → 搜尋結果 → 書籍詳情 | 保留 | 輸入關鍵字後多書源搜尋，結果可點進 `BookDetailPage` |
| C2 | 搜尋範圍控制 | 保留 | 全部書源、指定分組、指定單一書源；只使用 runtime 允許搜尋的書源 |
| C3 | 搜尋範圍選擇 UI | 保留 | 分組多選、書源單選、書源搜尋、全部書源 |
| C4 | 精準搜尋 | 保留 | 標準化後完全匹配書名或作者，不再是包含匹配 |
| C5 | 搜尋設定持久化 | 保留 | 搜尋範圍與精準搜尋開關會寫入 preferences |
| C6 | 搜尋歷史 | 保留 | 點選再次搜尋、長按刪除、清空全部、最近 50 筆 |
| C7 | 搜尋進度 | 保留 | 顯示進度條、目前搜尋書源、完成比例、失敗數 |
| C8 | 搜尋中取消 | 保留 | AppBar stop / FAB stop 可取消目前搜尋 |
| C9 | 搜尋併發與逾時 | 保留 | 讀取 `thread_count`，單書源 timeout 30 秒 |
| C10 | 搜尋結果快取 | 保留 | 搜尋結果寫入 `SearchBookDao`，供後續詳情、換源、封面使用 |
| C11 | 搜尋結果去重 | 收斂 | 只合併同一來源的重複結果，不跨書源合併同名同作者 |
| C12 | 搜尋結果排序 | 保留 | 支援相關度、書源數、書源順序、書名、作者、最新章節 |
| C13 | 搜尋結果篩選 | 保留 | 支援書源、作者、分類、已加入書架、有封面 |
| C14 | 批次加入書架 | 不做 | 不提供多選批次加入；維持進詳情後單本加入 |
| C15 | 搜尋失敗處理 | 保留 | 顯示失敗數、查看失敗書源、查看錯誤原因、重試失敗書源 |
| C16 | 搜尋結果來源標記 | 保留 | 每筆顯示來源，多來源結果可展開來源資訊 |
| C17 | 搜尋結果書架狀態標記 | 保留 | 依 `origin + bookUrl` 標記已加入書架 |
| C18 | 發現頁入口 | 保留 | 主頁底部導覽固定有 `發現` tab |
| C19 | 發現頁 → 分類 → 書籍列表 → 書籍詳情 | 保留 | 展開來源分類，進列表，再進詳情 |
| C20 | 發現頁來源篩選 | 保留 | 搜尋發現書源、依分組篩選、清除條件 |
| C21 | 發現頁來源操作 | 保留 | 長按來源可登入、編輯、搜尋、刷新分類 |
| C22 | 發現頁來源額外操作 | 保留 | 長按來源可置頂、刪除 |
| C23 | 發現分類快取與刷新 | 保留 | 分類解析有快取，刷新會清快取重載 |
| C24 | 發現來源自動更新 | 保留 | 監聽書源變化，匯入/編輯/刪除後列表更新 |
| C25 | 發現頁排除不可用來源 | 保留 | 只顯示可參與發現的純文字小說來源 |
| C26 | 發現分類錯誤顯示 | 保留 | 分類解析失敗顯示 ERROR，點擊可看錯誤 |
| C27 | 發現書籍列表分頁載入 | 保留 | 初始載入、滑到底載入更多、載入更多失敗可重試 |
| C28 | 發現書籍列表下拉刷新 | 保留 | `RefreshIndicator` 重新載入列表 |
| C29 | 發現列表請求取消與過期結果保護 | 保留 | refresh / dispose 取消舊請求，舊結果不覆蓋新結果 |
| C30 | 發現書籍列表書架狀態標記 | 保留 | 發現列表項目顯示已加入書架 |
| C31 | 發現頁空狀態 / 錯誤狀態 | 保留 | 空狀態可重新整理/清除條件，錯誤狀態可重試/查看錯誤 |

## 驗證步驟

### C1-C3 搜尋入口與搜尋範圍

入口鏈路：

```text
BookshelfPage / ReaderPage / ExplorePage
  -> SearchPage
  -> SearchProvider
  -> SearchScope.getBookSources()
  -> SearchModel.search()
  -> WebBook.searchBookAwait()
  -> SearchResultItem
  -> BookDetailPage
```

手動驗證：

1. 從書架或閱讀器進入搜尋頁。
2. 輸入常見書名或作者，送出搜尋。
3. 預期搜尋中出現進度列與目前書源。
4. 搜尋完成後預期顯示搜尋結果。
5. 點擊任一搜尋結果，預期進入書籍詳情。
6. 回到搜尋頁，打開搜尋範圍彈窗。
7. 選擇 `全部書源`、任一分組、任一單一書源，各自重搜一次。
8. 預期單一書源模式只搜尋該來源；分組模式只搜尋分組內來源。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 搜尋頁入口 | `features/search/search_page.dart` / `SearchPage` |
| 搜尋範圍 | `features/search/models/search_scope.dart` / `getBookSources()` |
| 搜尋範圍彈窗 | `features/search/widgets/search_scope_sheet.dart` |
| 搜尋引擎 | `features/search/search_model.dart` / `search()` |
| 搜尋結果詳情 | `features/search/widgets/search_result_item.dart` |

常見故障定位：

- 沒有任何書源被搜尋：先看 `SearchScope.getBookSources()` 是否因 `isSearchEnabledByRuntime` 全部過濾掉。
- 單一書源選不到：看 `SearchScopeSheet._loadSources()` 是否只列 runtime 可搜尋來源。
- 點結果無法進詳情：檢查 `SearchResultItem.onTap` 與 `BookDetailPage(searchBook: ...)`。

### C4-C6 精準搜尋、設定持久化與搜尋歷史

手動驗證：

1. 在搜尋頁右上角選單打開 `精準搜尋（完全匹配）`。
2. 搜尋完整書名，預期可命中。
3. 搜尋只包含部分書名的關鍵字，預期精準搜尋會排除非完全匹配結果。
4. 離開搜尋頁再回來，預期精準搜尋設定仍保留。
5. 搜尋幾個關鍵字，回到空搜尋狀態。
6. 點歷史 chip，預期會再次搜尋。
7. 長按歷史 chip，預期可刪除單筆。
8. 點 `清空`，預期所有歷史清除。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 精準搜尋判斷 | `features/search/search_model.dart` / `matchesPrecisionSearch()` |
| 搜尋文字標準化 | `features/search/search_model.dart` / `normalizeSearchText()` |
| 精準搜尋偏好 | `features/search/search_provider.dart` / `togglePrecisionSearch()` |
| 搜尋歷史 DAO | `core/database/dao/search_keyword_dao.dart` |
| 搜尋歷史 UI | `features/search/widgets/search_history_view.dart` |

常見故障定位：

- 精準搜尋仍像包含匹配：檢查 `matchesPrecisionSearch()` 是否使用 `==` 而不是 `contains()`。
- 設定沒保存：檢查 `SharedPreferences` 的 `precision_search`。
- 歷史沒出現：檢查 `SearchKeywordDao.saveKeyword()` 與 `SearchProvider.loadHistory()`。

### C7-C10 搜尋進度、取消、併發與快取

手動驗證：

1. 使用全部書源搜尋一個關鍵字。
2. 搜尋中確認進度條、目前書源與百分比會變化。
3. 點 AppBar stop 或 FAB stop。
4. 預期搜尋停止，狀態顯示已停止，不再追加新結果。
5. 重新搜尋同一關鍵字。
6. 搜尋完成後進入詳情或換源流程，確認搜尋結果可被後續流程使用。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 搜尋進度 callback | `features/search/search_model.dart` / `onSearchProgress()` |
| 搜尋取消 | `features/search/search_model.dart` / `cancelSearch()` |
| UI 停止按鈕 | `features/search/widgets/search_app_bar.dart`、`features/search/search_page.dart` |
| 併發控制 | `features/search/search_model.dart` / `Pool(threadCount)` |
| 搜尋快取 | `core/database/dao/search_book_dao.dart` / `insertList()` |

常見故障定位：

- 取消後仍繼續追加結果：檢查 `_isCancelled` 與 `CancelToken` 是否有傳到 `WebBook.searchBookAwait()`。
- 進度永遠 0：檢查 `_totalCount` 是否在搜尋開始後被正確更新。
- 某些書源搜尋過慢：檢查 `thread_count` 與單來源 30 秒 timeout。

### C11-C13 搜尋結果去重、排序與篩選

手動驗證：

1. 搜尋一個有多個結果的關鍵字。
2. 確認同一來源同一 `bookUrl` 不重複顯示。
3. 確認不同書源的同名同作者書籍不被強制合併成一本。
4. 使用排序 chip 切換：
   - `相關度`
   - `書源數`
   - `書源順序`
   - `書名`
   - `作者`
   - `最新章節`
5. 打開篩選，分別測試：
   - 書源
   - 作者包含
   - 分類包含
   - 只看已加入書架
   - 只看有封面
6. 套用篩選後確認結果數顯示為 `篩選後數量/總數量`。
7. 點清除篩選，預期回到完整搜尋結果。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 去重判斷 | `features/search/search_model.dart` / `_isSameSourceDuplicate()` |
| 結果排序 | `features/search/search_provider.dart` / `_sortedResults()` |
| 結果篩選 | `features/search/search_provider.dart` / `_filteredResults()` |
| 排序 / 篩選 UI | `features/search/search_page.dart` / `_buildResultToolbar()` |
| 書架狀態 | `core/services/bookshelf_state_tracker.dart` |

常見故障定位：

- 不同書源被錯誤合併：檢查 `_isSameSourceDuplicate()` 是否仍要求 `origin` 相同。
- 排序看起來沒變：相關度排序會保留搜尋引擎合併後順序；改用書名或作者排序確認 UI 是否正常。
- 已加入書架篩選不準：檢查 `BookshelfStateTracker.makeBookshelfKey()` 是否用 `origin + bookUrl`。
- 書源篩選沒選項：檢查 `SearchBook.originName` 與 `sourceLabels` 是否有值。

### C14 批次加入書架不做

C14 已決定不實作。驗證重點是不要出現以下 UI 或流程：

- 搜尋結果多選模式
- 批次加入書架按鈕
- 搜尋結果頁直接大量寫入書架

目前正確流程：

```text
搜尋結果
  -> 書籍詳情
  -> 放入書架
```

相關檔案：

- `features/search/search_page.dart`
- `features/search/widgets/search_result_item.dart`
- `features/book_detail/book_detail_provider.dart` / `toggleInBookshelf()`

### C15-C17 搜尋失敗、來源標記與書架標記

手動驗證：

1. 使用一批包含失效書源的來源搜尋。
2. 搜尋完成後若有失敗，預期顯示 `N 個書源搜尋失敗`。
3. 點 `查看`，預期看到失敗書源與錯誤原因。
4. 點單筆失敗，預期彈窗顯示完整錯誤文字。
5. 點 `重試失敗`，預期只重試失敗來源，既有結果保留。
6. 檢查搜尋結果項目，預期顯示來源名稱。
7. 已加入書架的搜尋結果應顯示 `書架` 標記。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 搜尋失敗模型 | `features/search/search_model.dart` / `SearchFailure` |
| 失敗 callback | `features/search/search_model.dart` / `onSearchFailure()` |
| 失敗狀態 | `features/search/search_provider.dart` / `sourceFailures` |
| 失敗 UI | `features/search/search_page.dart` / `_showFailureSheet()` |
| 來源標記 UI | `features/search/widgets/search_result_item.dart` |
| 書架標記 | `core/services/bookshelf_state_tracker.dart` |

常見故障定位：

- 只有失敗數沒有明細：檢查 catch 區塊是否呼叫 `callback.onSearchFailure(...)`。
- 重試失敗沒有反應：檢查失敗來源是否仍 `isSearchEnabledByRuntime`。
- 已加入書架標記錯誤：先確認書架資料中的 `origin` 與搜尋結果 `origin` 一致。

### C18-C25 發現頁入口、來源篩選與來源操作

入口鏈路：

```text
MainPage index 1
  -> ExplorePage
  -> ExploreProvider.watchAll()
  -> source.canParticipateInDiscovery
  -> ExploreUrlParser.parseAsync()
```

手動驗證：

1. 進入主頁，點底部 `發現`。
2. 預期看到可參與發現的書源列表。
3. 使用搜尋框搜尋書源名稱，預期列表被篩選。
4. 使用右上角分組篩選，預期只顯示該分組來源。
5. 清除搜尋或分組，預期回完整列表。
6. 點來源列展開分類。
7. 長按來源列，逐項驗證：
   - 編輯：進入 `SourceEditorPage`
   - 置頂：來源排序更新
   - 登入書源：有 `loginUrl` 時外部打開
   - 搜索：進入單一書源搜尋頁
   - 刷新分類：清除分類快取並重載
   - 刪除：確認後刪除來源

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 主頁發現 tab | `features/welcome/main_page.dart` |
| 發現頁 | `features/explore/explore_page.dart` |
| 發現狀態 | `features/explore/explore_provider.dart` |
| 可參與發現判斷 | `core/models/source/book_source_logic.dart` / `canParticipateInDiscovery` |
| 分類解析 | `core/engine/explore_url_parser.dart` |
| 來源編輯 | `features/source_manager/source_editor_page.dart` |

常見故障定位：

- 發現頁沒有來源：檢查來源是否 `enabled`、`enabledExplore`、有 `exploreUrl` 且 `runtimeHealth.allowsReading`。
- 分組篩選結果錯誤：檢查 `bookSourceGroup` 分隔符是否為 `,` 或 `，`。
- 長按選單沒出現：檢查 `ExplorePage._showSourceMenu()` 與 `onLongPressStart`。

### C26-C31 發現分類、列表、刷新與錯誤狀態

入口鏈路：

```text
ExplorePage
  -> 點分類 ExploreKind
  -> ExploreShowPage
  -> ExploreShowProvider
  -> WebBook.exploreBookAwait()
  -> ExploreBookItem
  -> BookDetailPage
```

手動驗證：

1. 在發現頁展開一個來源。
2. 點可用分類。
3. 預期進入分類書籍列表。
4. 列表初始載入時顯示 loading。
5. 有內容時預期顯示書籍列表，點書可進詳情。
6. 向下滑到底，預期自動載入更多。
7. 下拉刷新，預期清空舊資料並重新載入第 1 頁。
8. 若分類解析失敗，預期分類區出現 `ERROR:` 項目，點擊可看錯誤。
9. 若分類列表載入失敗，預期顯示 `分類載入失敗`、`查看錯誤`、`重試`。
10. 若分類列表無內容，預期顯示 `暫無內容` 與 `重新整理`。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 分類 tag UI | `features/explore/explore_page.dart` / `_buildKindTags()` |
| 分類錯誤彈窗 | `features/explore/explore_page.dart` / `_showKindError()` |
| 分類列表頁 | `features/explore/explore_show_page.dart` |
| 分類列表狀態 | `features/explore/explore_show_provider.dart` |
| 書籍列表 loader | `core/engine/web_book/web_book_service.dart` / `exploreBookAwait()` |
| 書籍項目 | `features/explore/widgets/explore_book_item.dart` |

常見故障定位：

- 點分類沒反應：檢查 `ExploreKind.url` 是否為空；空 URL 分類不會導航。
- 分類快取沒有刷新：檢查 `ExploreProvider.refreshKindsCache()` 是否呼叫 `ExploreUrlParser.clearCache()`。
- refresh 後舊資料覆蓋新資料：檢查 `ExploreShowProvider._requestSerial` 與 `CancelToken` 判斷。
- 載入更多一直轉圈：檢查 `_hasMore` 是否在空結果或錯誤時設為 false。
- 已加入書架標記不準：檢查 `ExploreShowProvider.isInBookshelf()` 與 `BookshelfStateTracker`。

## 已移除 / 不列入 C 系列目標

| 項目 | 決策 | 原因 |
| --- | --- | --- |
| 搜尋結果批次加入書架 | 不做 | 維持「進詳情後單本加入」，避免批次寫入不完整書籍資料 |
| 搜尋結果依更新時間排序 | 不做 | 搜尋結果模型目前沒有可靠更新時間 |
| 完結 / 連載篩選 | 不做 | 來源資料不穩定，`kind` / `latestChapterTitle` 不足以可靠判定 |
| 以封面或最新章節作為強去重依據 | 不做 | 容易誤合併不同書籍；只可作為人工參考 |
| 發現頁空狀態的獨立「切換來源」按鈕 | 不做 | 發現頁本身就是來源列表；用清除條件與分組篩選即可 |

## 測試覆蓋

目前 C 系列主要測試：

```text
test/features/search/search_model_test.dart
test/features/search/search_provider_test.dart
test/features/explore/explore_provider_test.dart
test/features/explore/explore_show_provider_test.dart
test/features/explore/widgets/legado_explore_kind_flow_test.dart
test/features/explore/explore_page_compile_test.dart
```

建議每次修改 C 系列後至少執行：

```bash
dart analyze lib/features/search lib/features/explore test/features/search test/features/explore
flutter test test/features/search test/features/explore
```
