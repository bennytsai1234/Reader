# Reader Architecture (Target)

更新日期：2026-03-29

本文回答的是「這個專案應該怎麼分層、怎麼分模組、每層負責什麼」。  
它描述的是未來目標架構，不等於今天所有代碼都已經到位。

如果要理解目前閱讀器 runtime 的實際狀態，請另外看：

- [reader_architecture_current.md](reader_architecture_current.md)

## 1. 一句話結論

這個專案應該收斂成：

- `app` 管啟動與全域組裝
- `modules` 管產品功能
- `core` 管基礎能力
- `engine` 管書源解析與閱讀規則
- `shared` 管跨模組共用 UI 與主題

核心原則是：

- 功能按模組切
- 邏輯按層切
- 路徑與平台能力集中
- parser / runtime 與 UI 解耦

## 2. 目標目錄

建議目標結構如下：

```text
lib/
  app/
    bootstrap/
    routing/
    providers/
  core/
    database/
    network/
    platform/
    services/
    storage/
    utils/
  engine/
    rule/
    parser/
    js/
    analyze_url/
    book/
  modules/
    reader/
      presentation/
      application/
      domain/
      data/
    bookshelf/
      presentation/
      application/
      domain/
      data/
    source_manager/
      presentation/
      application/
      domain/
      data/
    settings/
      presentation/
      application/
      domain/
      data/
    local_book/
      presentation/
      application/
      domain/
      data/
  shared/
    theme/
    widgets/
    models/
```

這不是要求一次性大搬家，而是未來所有整理都應朝這個方向收斂。

## 3. 分層責任

## 3.1 `app`

用途：

- 啟動流程
- 全域初始化
- DI 組裝
- Provider 根註冊
- 導航入口

適合放：

- `main.dart`
- app bootstrap
- app-level provider registration
- root routing / shell

不應承擔：

- feature 業務邏輯
- parser 邏輯
- DAO 邏輯

## 3.2 `core`

用途：

- 跨整個專案共用的基礎能力

可包含：

- `database`
- `network`
- `services`
- `storage`
- `platform`
- `utils`

判斷標準：

- 如果一個能力不是某個 feature 專屬，而是多處都會依賴，它就應該進 `core`

典型例子：

- `Drift` database
- `Dio` network stack
- cache / resource / export / backup / file path 管理
- app-wide logging

## 3.3 `engine`

用途：

- 書源規則解析與抓取內核

這層應該被視為獨立子系統，而不是零散 helper 集合。

責任：

- rule analyze
- URL analyze
- CSS / XPath / JsonPath / Regex / JS parser
- source login 協議支持
- chapter / content / toc / book info 解析

不應承擔：

- page widget
- app route
- settings page

原則：

- 輸入輸出盡量純化
- 可單測、可 integration test
- 行為與 legado 對齊時，以可驗證事實為準

## 3.4 `modules`

用途：

- 產品功能的主舞台

每個 module 建議有四層：

- `presentation`
- `application`
- `domain`
- `data`

### `presentation`

放：

- page
- dialog
- bottom sheet
- widget

### `application`

放：

- provider
- controller
- coordinator
- use case 組裝

### `domain`

放：

- 純規則
- 介面
- 語意模型
- 不依賴 Flutter UI 的邏輯

### `data`

放：

- repository implementation
- feature-specific datasource
- feature-specific adapter

## 3.5 `shared`

用途：

- 跨多個 module 重用的 UI 或表示層共用資產

適合放：

- app theme
- shared widget
- 跨模組 presentation model

不適合放：

- 某個 feature 專用 provider
- 某個 feature 專用 parser

## 4. 責任邊界

## 4.1 UI 不直接碰資料層

`Widget / Page` 不應直接：

- 呼叫 DAO
- 硬寫檔案路徑
- 操作 `File` / `Directory`
- 拼 SQL
- 直接碰 parser 細節

它們只應：

- 呼叫 provider / controller
- 消費狀態
- 發送互動事件

## 4.2 Provider / Controller 不直接背所有細節

`Provider` 或 controller 的責任是協調，不是包辦全部：

- 可以組合 service / repository
- 可以維護狀態
- 可以處理頁面流程

但不應：

- 直接實作大量 SQL 細節
- 到處自己組平台路徑
- 同時兼管 UI 細節與底層 I/O

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
