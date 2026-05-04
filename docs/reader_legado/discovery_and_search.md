# Discovery And Search

## 目標專案目前狀態

- 探索主頁在 `lib/features/explore/explore_provider.dart` 與 `explore_page.dart`，以 `BookSourceDao.watchAllPart()` 綁定可探索書源，並用 `ExploreUrlParser.parseAsync` 解析分類。
- 探索結果在 `lib/features/explore/explore_show_provider.dart`，透過 `WebBook.exploreBookAwait` 分頁載入，並用 `BookshelfStateTracker` 標記是否已在書架。
- 搜尋邏輯拆成 `lib/features/search/search_model.dart` 與 `search_provider.dart`；`SearchModel` 是多書源並行搜尋引擎，`SearchProvider` 管 UI 狀態、歷史、範圍、篩選與排序。
- 搜尋範圍在 `lib/features/search/models/search_scope.dart`，結果持久化到 `SearchBookDao`，搜尋歷史走 `SearchKeywordDao`。

## 目標專案上下游

- 上游依賴：`BookSourceDao`、`SearchBookDao`、`SearchKeywordDao`、`BookSourceService`、`WebBook`、`ExploreUrlParser`、`BookshelfStateTracker`、`SharedPreferences`。
- 下游影響：`Book Detail` 入口、封面搜尋、換源搜尋、書源健康度帶來的可搜尋/可探索過濾。
- 書源 runtime health 會影響搜尋與探索是否參與，來源校驗變更會間接改變本模組結果。

## 參考對應

- `legado/app/src/main/java/io/legado/app/ui/main/explore`
- `legado/app/src/main/java/io/legado/app/ui/book/explore`
- `legado/app/src/main/java/io/legado/app/ui/book/search`
- `legado/app/src/main/java/io/legado/app/ui/book/searchContent`
- `legado/app/src/main/java/io/legado/app/model/webBook/SearchModel.kt`

## 可參考模式

- 探索入口、探索結果與搜尋結果應分開管理，避免單一 provider 同時持有來源分類、分頁資料與搜尋狀態。
- 多來源搜尋要保留取消、失敗來源統計與結果合併策略，讓慢源或失敗源不拖住整體 UI。
- 搜尋結果合併要明確定義「同源重複」與「跨源同名」的差別，避免污染換源或詳情入口。

## 目標專案變更入口

- 探索來源與分類：`lib/features/explore/explore_provider.dart`、`lib/core/engine/explore_url_parser.dart`。
- 探索結果：`lib/features/explore/explore_show_provider.dart`。
- 搜尋引擎：`lib/features/search/search_model.dart`。
- 搜尋 UI 狀態：`lib/features/search/search_provider.dart`、`lib/features/search/search_page.dart`。
- 測試：`flutter test test/features/explore/explore_provider_test.dart test/features/explore/explore_show_provider_test.dart test/features/search/search_model_test.dart test/features/search/search_provider_test.dart`。

## 已知風險

- `SearchModel` 使用共享 `CancelToken` 與 pool 並行，修改取消或 timeout 時要防止舊結果回寫新搜尋。
- `ExploreShowProvider` 用 request serial 避免 stale response；變更分頁或 refresh 時要保留這個防護。
- 精準搜尋使用全半形與空白 normalization；排序、合併或篩選規則變更可能影響既有測試與換源候選。
- 探索分類快取以 `bookSourceUrl + exploreUrl` 為 key；變更書源規則或快取清理時要避免沿用舊分類。

## 不要做

- 不把探索頁擴張成內容平台或 RSS 入口，除非使用者另行要求。
- 不因為 `legado` 有搜內文等更多搜尋變體就新增需求。
- 不在搜尋 provider 裡直接處理書源編輯、校驗或登入流程。
