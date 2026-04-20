# 目標架構

更新日期：2026-04-20

本文描述墨頁（Inkpage）應收斂的架構方向。它不是一次性重寫指令，而是用來約束整理順序與責任邊界。閱讀器 runtime 現況請先看 [reader_architecture_current.md](reader_architecture_current.md)。

## 一句話結論

- `main.dart` 與 app-level 組裝保持很薄
- `core/` 承擔跨模組基礎能力
- `features/` 承擔產品功能
- `core/engine/` 視為獨立子系統，不是零碎 helper
- `shared/` 只放跨模組 UI 共用物

專案不是缺功能，而是繼續把「功能模組」、「底層能力」與「書源引擎」三者的邊界切清楚。

## 目前的真實形狀

```text
lib/
  core/
    database/   Drift schema、DAO、tables、migration
    di/         get_it 組裝
    engine/    規則解析、JS、Web 書源、URL 分析、charset
    local_book/ TXT / EPUB / MOBI / PDF / UMD
    network/   Dio、API 包裝、Cookie、攔截
    services/   備份、還原、TTS、下載、書源校驗、換源、widget
    storage/    路徑 registry、metrics
    utils/      純工具
  features/
    reader/         閱讀器與 runtime（最複雜）
    bookshelf/      書架
    book_detail/    書籍詳情
    search/         搜尋（SearchProvider → SearchModel）
    explore/        發現（雙層書源）
    source_manager/ 書源管理、登入、校驗、隔離、清理
    local_book/     本地匯入
    settings/       設定
    association/    深連結、檔案關聯
    browser/        內建瀏覽器
    welcome/        啟動、隱私、主頁
    about/          關於、crash log、app log
    bookmark/       書籤
    cache_manager/  快取與下載管理
    debug/          除錯
    dict/           字典
    read_record/    閱讀記錄
    replace_rule/   替換規則
    txt_toc_rule/   TXT 目錄規則
  shared/
    theme/          主題（含閱讀主題色表）
    widgets/        跨 feature UI 共用
```

## 分層原則

### `main.dart` / app root

只處理：啟動流程、全域初始化、DI 註冊、app-level provider 掛載、MaterialApp、全域錯誤處理。**不處理** feature 業務、parser 行為、DAO 細節。

### `core/`

放跨 app 可能依賴的基礎能力：

- Drift database 與 DAO
- Dio、cookie、網路攔截
- `AppStoragePaths`、快取、容量指標
- 備份、還原、匯出、更新、widget、TTS 等 service
- 本地書解析
- 通用工具與常數

判斷標準：如果不是某個 feature 專屬、是多處共用，就應該在 `core/`。

### `core/engine/`

書源引擎子系統，應與 UI 明確解耦。涵蓋：

- rule analyze
- analyze URL（含 charset 偵測）
- CSS / XPath / JsonPath / Regex / JS 解析
- 字體、網路、檔案、string JS 擴充
- Web 書源、headless webview、Promise bridge
- 搜尋、書籍詳情、章節、正文解析
- source login 流程支援

設計要求：

- 輸入輸出盡量純化
- 不依賴 widget
- 能被單測與 integration test 保護
- 與 Legado 對齊時以可驗證行為為準

補充：

- 書源健康狀態屬於**系統狀態**，不應長期與使用者手動分組語義耦合。
- 目前 app 仍以來源 tag / comment 推導 runtime health，屬過渡實作；後續應收斂為正式欄位或獨立狀態表。

### `features/`

產品功能主場。每個 feature 內部至少分出三種責任：畫面 / widget、狀態協調、feature-specific 資料適配。不一定要立刻搬成 presentation/application/domain/data 四層，但新代碼應往這個方向靠。

### `shared/`

只放跨 feature 共用的呈現層資產（主題、通用 widgets、少量 presentation helper）。不要把某個 feature 專屬的 provider 或 engine 細節放進來。

## 邊界規則

### UI 不直接碰 DAO 與檔案系統

`Page` / `Widget` **不應**：

- 呼叫 DAO
- 自行拼 SQL
- 自行組檔案系統路徑
- 直接操作 parser 細節

它們只面向 provider / controller / service 的語意接口。**M5（2026-04-05）已完成**全域 Widget 層 DAO 呼叫消除。

### Provider / Controller 只做協調

**可以**：組合 service / DAO / runtime 物件、維護頁面狀態、協調 restore / jump / save / load 流程。

**不應**：大量直接寫 SQL、自己決定平台存儲路徑、同時背 UI 細節與底層 I/O 細節。

### 路徑與容量集中

快取、備份、匯出、下載、widget、暫存目錄都收斂到 `core/storage` 與對應 service，不分散各 feature 自行處理。

### 閱讀器 runtime 與 view delegate 解耦

- 核心狀態在 controller / runtime objects
- view delegate 只負責渲染與執行
- restore / progress / TTS follow / auto-page 的語意不回流到 widget 層

### DAO 只做資料存取

DAO 責任窄：CRUD、watch / query、針對資料表的聚合查詢。**不應**混入 widget 邏輯、業務流程、多來源資料整合。

### Service / Repository 負責整合

需要整合多個資料來源時由 service 或 repository 處理。典型情況：

- 章節內容：DB + network + parser + cache
- 備份：DB + file + zip + share
- 匯出：chapter dao + storage path + share
- 書源校驗：source dao + engine + runtime health policy
- 換源：搜尋快取 + source dao + chapter/book migration

## 近期應避免

- 再引入第二套狀態管理方案
- 再引入第二套 HTTP client 或資料層抽象
- 為了修一個 feature 再堆出平行 page / provider / service
- 讓 feature 直接依賴 engine 內部細節，而不是穩定語意接口

## 判斷一個改動是不是對的

如果能同時做到下面幾點，大概率在正方向上：

- 減少重複實作
- 讓真源更清楚
- 讓測試更容易寫
- 讓 feature 之間更少互相知道內部細節
- 讓文件能用更少篇幅描述清楚

## 架構規則清單

今後新增代碼時，先檢查：

- 這段邏輯屬於哪個 module？
- 它屬於 presentation、application、domain 還是 data？
- 它是否在重複現有功能？
- 它是否在 UI 層直接做了資料或檔案工作？
- 它是否應該進 `core` 而不是某個 feature？
- 它是否應該進 `engine` 而不是一般 service？

答不出來就先不要寫。
