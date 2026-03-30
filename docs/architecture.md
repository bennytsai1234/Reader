# Reader Architecture

更新日期：2026-03-30

本文描述的是這個專案接下來應收斂到的架構方向。它不是要求一次性重寫，而是用來約束之後的整理順序與責任邊界。

如果要看閱讀器 runtime 的現況，請先讀 [reader_architecture_current.md](reader_architecture_current.md)。

## 一句話結論

這個專案目前最合理的收斂方式是：

- `main.dart` 與 app-level 組裝保持很薄
- `core/` 承擔跨模組基礎能力
- `features/` 承擔產品功能
- `core/engine/` 視為獨立子系統，而不是零碎 helper
- `shared/` 只放跨模組 UI 共用物

也就是說，這個專案不是缺功能，而是要繼續把「功能模組」、「底層能力」與「書源引擎」三者的邊界切清楚。

## 目前的真實形狀

截至 `0.1.6`，專案已經大致形成這個結構：

```text
lib/
  core/
    database/   Drift schema、DAO、migration
    di/         get_it 組裝
    engine/     規則解析、JS、Web 書源、URL 分析
    local_book/ TXT / EPUB / PDF 等本地書能力
    network/    Dio 與 API 包裝
    services/   備份、還原、TTS、更新、資源、下載
    storage/    路徑、快取、容量指標
    utils/      純工具
  features/
    reader/         閱讀器與 runtime
    bookshelf/      書架
    search/         搜尋
    explore/        探索
    source_manager/ 書源管理與登入
    local_book/     本地匯入
    settings/       設定
    ...
  shared/
    theme/
    widgets/
```

這個形狀基本可用，但還沒有完全做到語意清晰。幾個主要的歷史包袱仍然存在：

- `features/*` 裡仍有部分 provider / mixin / service 邊界交疊
- `core/services` 偶爾承擔了偏 feature-specific 的協調邏輯
- `core/engine` 已經像獨立引擎，但命名與對外接口還不夠一致
- `main.dart` 與 app 根組裝仍偏胖，後續可再薄化

## 建議的責任劃分

### `main.dart` / app root

只處理：

- 啟動流程
- 全域初始化
- DI 註冊
- app-level provider 掛載
- MaterialApp 與全域錯誤處理

不處理：

- feature 業務流程
- parser 行為
- DAO 操作細節

### `core/`

放跨整個 app 都可能依賴的基礎能力：

- Drift database 與 DAO
- Dio、cookie、網路攔截
- 檔案路徑、快取、容量統計
- 備份、還原、匯出、更新、widget、TTS 等 service
- 本地書解析
- 通用工具與常數

判斷標準很簡單：如果它不是某個 feature 專屬，而是多處共用，就應該在 `core/`。

### `core/engine/`

這層是專案的書源引擎子系統，應與 UI 明確解耦。

它目前涵蓋：

- rule analyze
- analyze URL
- CSS / XPath / JsonPath / Regex / JS 解析
- 字體與網路 JS 擴充
- Web 書源與 headless webview
- 搜尋、書籍詳情、章節、正文解析
- source login 流程支援

這層的設計要求應該是：

- 輸入輸出盡量純化
- 不依賴 widget
- 能被單測與 integration test 保護
- 與 Legado 對齊時，以可驗證行為為準，不依賴印象對齊

### `features/`

`features/` 是產品功能主場。每個 feature 內部至少要分出三種責任：

- 畫面與 widget
- 狀態協調與頁面流程
- feature-specific 資料適配

不一定要立刻搬成 `presentation/application/domain/data` 四層，但新代碼應往這個方向靠攏。

### `shared/`

只放跨 feature 共用的呈現層資產：

- 主題
- 通用 widgets
- 少量 presentation-level helper

不要把某個 feature 專屬 provider 或引擎邏輯放進來。

## 目前最重要的邊界

### UI 不直接碰 DAO 與檔案系統

`Page` / `Widget` 不應直接：

- 呼叫 DAO
- 自行拼 SQL
- 自行組檔案系統路徑
- 直接操作 parser 細節

它們應該只面向 provider / controller / service 的語意接口。

### Provider / Controller 只做協調

它們可以：

- 組合 service、DAO、runtime 物件
- 維護頁面狀態
- 協調 restore、jump、save、load 之類的流程

但不應該：

- 大量直接寫 SQL
- 自己決定平台存儲路徑
- 同時背 UI 細節與底層 I/O 細節

### 路徑與容量管理集中

快取、備份、匯出、下載、widget、暫存目錄都應收斂到 `core/storage` 與對應 service，不再分散在各 feature 自行處理。

### 閱讀器 runtime 與 view delegate 解耦

閱讀器已經有明確的 runtime 中心，後續應繼續保持：

- 核心狀態在 controller / runtime objects
- view delegate 只負責渲染與執行
- restore / progress / TTS follow / auto-page 的語意不回流到 widget 層

## 近期應避免的事情

- 再引入第二套狀態管理方案
- 再引入第二套 HTTP client 或資料層抽象
- 為了修一個 feature 再堆出平行 page / provider / service
- 讓 feature 直接依賴 engine 內部細節，而不是穩定語意接口

## 判斷一個改動是不是對的

如果一個改動能同時做到下面幾點，它大概率就在正方向上：

- 減少重複實作
- 讓真源更清楚
- 讓測試更容易寫
- 讓 feature 之間更少互相知道內部細節
- 讓文件能用更少篇幅描述清楚

## 4.3 DAO 只做資料存取

DAO 的責任應該很窄：

- CRUD
- watch / query
- 針對資料表的聚合查詢

不應：

- 混入 widget 邏輯
- 混入業務流程
- 承擔多來源資料整合

## 4.4 Service / Repository 負責整合

需要整合多個資料來源時，應由 service 或 repository 處理。

典型情況：

- 章節內容：DB + network + parser + cache
- 備份：DB + file + zip + share
- 匯出：chapter dao + storage path + share

## 5. 閱讀器架構定位

`reader` 是這個專案最重要的 module。

它應該有以下子域：

- runtime
- content lifecycle
- progress / restore
- read aloud
- view delegate
- settings projection

建議對應分層：

- `modules/reader/presentation`
  - `reader_page`
  - `read_view_runtime`
  - delegate / widgets

- `modules/reader/application`
  - `ReadBookController`
  - coordinator
  - provider facade

- `modules/reader/domain`
  - `ReaderChapter`
  - chapter position semantics
  - restore / progress domain rules

- `modules/reader/data`
  - chapter content datasource
  - repository / adapters to local book, source service, cache

## 6. 書源引擎架構定位

書源不是一般 feature，它更接近平台內核。

因此建議保留在 `engine/`，而不是切進一般 UI module。

可拆成：

- `engine/rule`
- `engine/parser`
- `engine/js`
- `engine/analyze_url`
- `engine/book`

而 `source_manager` module 則只負責：

- 書源清單
- 書源管理 UI
- 書源導入 / 匯出流程
- 書源調試入口

也就是：

- `engine` 負責「怎麼解析」
- `source_manager` 負責「怎麼管理」

## 7. 儲存與檔案系統策略

檔案系統是目前最容易失控的地方之一，因此需要集中。

原則：

- app-owned 路徑統一進 `core/storage`
- 任何匯出、字體、規則快取、圖片快取都不能在 feature 內各自硬寫路徑
- 目錄清理、容量統計、暫存規則應可共用

這類能力應集中在：

- storage path registry
- storage metrics
- resource / export / cache service

## 8. 設定模組策略

`settings` 常見問題是越寫越胖。

目標：

- `presentation` 只承接設定頁與子頁
- `application` 只維護設定 state 與更新入口
- `data` 只處理 `SharedPreferences` / local persistence

原則：

- 設定頁不直接處理重資源邏輯
- cache / export / font / backup 這類功能不應只是某個設定頁內的隨手實作
- 這些能力應有自己的 service 或 module 邊界

## 9. 平台能力策略

平台相關能力建議收斂到 `core/platform` 或 `core/services`：

- crash handler
- workmanager
- app links
- sharing intent
- background task
- local notification

判斷標準：

- 如果能力與作業系統、裝置環境、app lifecycle 強相關，它就不應零散散落在一般 feature page

## 10. 遷移方式

這份架構不是要求一次全部重命名或搬檔。

建議遷移策略：

1. 先新增新邊界，不急著全部搬
2. 新功能一律按新規則進新位置
3. 舊功能只在改到時順手搬正
4. 每次只重整一個 module 或一個 cross-cutting concern

推薦順序：

1. `settings / cache / storage`
2. `reader`
3. `source_manager + engine`
4. `bookshelf / search / book_detail`

## 11. 架構規則清單

今後新增代碼時，應先檢查這些規則：

- 這段邏輯屬於哪個 module？
- 它屬於 presentation、application、domain 還是 data？
- 它是否在重複現有功能？
- 它是否在 UI 層直接做了資料或檔案工作？
- 它是否應該進 `core` 而不是某個 feature？
- 它是否應該進 `engine` 而不是一般 service？

如果這些問題答不出來，先不要寫。
