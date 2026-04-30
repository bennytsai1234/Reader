# Reader x Legado 模組索引

## 這份文檔的用途與使用原則

- 這份索引只負責幫你快速定位模組，不進細節。
- 當 `reader` 出問題時，先從這裡找最接近的模組，再切到 `docs/reader_legado/` 看詳細文檔。
- `legado` 在這套文檔裡是參考老師，只用來借鏡責任切法、流程安排與穩定化策略，不是新功能需求來源。
- 目標是優化 `reader` 現有功能，不擴需求、不追求功能對齊。

## 模組清單

- [App Shell](/home/benny/projects/reader/docs/reader_legado/app_shell.md)
- [Bookshelf](/home/benny/projects/reader/docs/reader_legado/bookshelf.md)
- [Discovery And Search](/home/benny/projects/reader/docs/reader_legado/discovery_and_search.md)
- [Book Detail](/home/benny/projects/reader/docs/reader_legado/book_detail.md)
- [Reader Runtime](/home/benny/projects/reader/docs/reader_legado/reader_runtime.md)
- [Source Manager And Browser](/home/benny/projects/reader/docs/reader_legado/source_manager_and_browser.md)
- [Rules And Local Books](/home/benny/projects/reader/docs/reader_legado/rules_and_local_books.md)
- [Settings And Cache](/home/benny/projects/reader/docs/reader_legado/settings_and_cache.md)
- [Integration And Diagnostics](/home/benny/projects/reader/docs/reader_legado/integration_and_diagnostics.md)

## 每個模組的 2-4 行摘要

### App Shell
- 處理 app 啟動、初始化、主導航與全域 provider 組裝。
- 適合排查啟動卡住、首頁狀態不一致、全域設定沒有生效這類問題。
- 如果問題發生在進入功能前就出現，先看這份。

### Bookshelf
- 處理書架列表、重載、書本進入點，以及書架層與資料更新之間的邊界。
- 適合排查書架不刷新、排序異常、進入書本路徑不穩這類問題。
- 如果症狀從書架觸發，再往下接 `Book Detail` 或 `Reader Runtime`。

### Discovery And Search
- 把發現、探索、搜書放在同一個查找面，因為它們都在處理來源內容的入口與結果展示。
- 適合排查探索頁載入、搜尋結果、換來源後結果不一致這類問題。
- 如果結果進入書本後才出問題，再切去 `Book Detail`。

### Book Detail
- 聚焦書籍詳情、目錄、換源、換封面，以及從詳情頁開啟閱讀的邊界。
- 適合排查章節列表異常、詳情頁資料錯誤、換源後資料污染這類問題。
- 這個模組通常同時連到 `Source Manager` 和 `Reader Runtime`。

### Reader Runtime
- 這是 `reader_v2` 主線，包含閱讀畫面、runtime、viewport、render，以及閱讀器內功能。
- 適合排查翻頁、章節切換、進度同步、TTS 跟隨、自動翻頁這類核心閱讀問題。
- 如果問題出在閱讀過程中，通常先看這份。

### Source Manager And Browser
- 把書源管理、書源除錯、訂閱、WebView 驗證與登入放在同一組。
- 適合排查書源編輯、來源驗證、登入失敗、驗證碼、Cookie 相關問題。
- 如果問題是「來源拿不到內容」，大多從這份開始。

### Rules And Local Books
- 把替換規則與本地書解析放在一起；TXT 目錄規則與字典規則目前只保留資料相容層，不再作為使用者功能盤點。
- 適合排查內容淨化、章節目錄解析、本地 TXT/EPUB/UMD 導入與轉換問題。
- 如果問題是文字內容本身不對，而不是 UI 顯示不對，先看這份。

### Settings And Cache
- 把設定、外觀、TTS 設定、備份恢復、下載與快取放在同一組支撐模組。
- 適合排查設定不生效、下載任務異常、離線內容不一致、備份恢復問題。
- 這份更偏支撐層，不是主入口，但很常是上游原因。

### Integration And Diagnostics
- 處理外部匯入、關聯喚起、關於頁、log 與 crash 診斷。
- 適合排查 app 外部導入流程、錯誤回報、版本與診斷資訊不足這類問題。
- 如果問題不是功能本身，而是進入路徑或定位資訊不足，先看這份。
