# 資料層

更新日期：2026-04-20

本文只描述目前可以由代碼直接驗證的資料庫事實，依據：

- `lib/core/database/app_database.dart`
- `lib/core/database/tables/`
- `lib/core/database/dao/`

## 基本資訊

- 技術：Drift（SQLite ORM） + `sqlite3_flutter_libs` native SQLite
- 主要入口：`lib/core/database/app_database.dart`
- Schema version：**8**
- 資料庫檔案：`ApplicationSupportDirectory/databases/inkpage_reader.db`
- 對應產生程式碼：`app_database.g.dart`（build_runner 產出，**不要手動編輯**）

## 表與 DAO 規模

`AppDatabase` 目前註冊 **20 張資料表** 與 **20 個 DAO**。

### 核心閱讀資料

| 表 | 用途 |
|----|------|
| `Books` | 書籍主資料、書架狀態、閱讀進度、閱讀設定 |
| `Chapters` | 章節清單與正文快取 |
| `Bookmarks` | 書籤 |
| `ReadRecords` | 閱讀記錄 |

### 書源與規則

| 表 | 用途 |
|----|------|
| `BookSources` | 書源規則、登入設定、解析規則 |
| `ReplaceRules` | 正文替換規則 |
| `DictRules` | 字典規則 |
| `RuleSubs` | 規則訂閱 |
| `SourceSubscriptions` | 書源訂閱 |
| `TxtTocRules` | TXT 目錄規則 |

### 搜尋、快取與網路狀態

| 表 | 用途 |
|----|------|
| `SearchHistoryTable` | 搜尋歷史 |
| `SearchBooks` | 搜尋結果快取 |
| `SearchKeywords` | 關鍵字統計 |
| `CacheTable` | 通用 key-value 快取 |
| `Cookies` | 站點 cookie |

### 其他功能資料

| 表 | 用途 |
|----|------|
| `BookGroups` | 書籍分組 |
| `Servers` | 服務端設定 |
| `HttpTtsTable` | HTTP TTS 設定 |
| `KeyboardAssists` | 鍵盤輔助設定 |
| `DownloadTasks` | 下載任務 |

## 對閱讀器最重要的三張表

### `Books`

**主鍵**：`bookUrl`

**閱讀器常用欄位**：

- `durChapterTitle`
- `durChapterIndex` — **閱讀進度真源（章節 index）**
- `durChapterPos` — **閱讀進度真源（章內 char offset）**
- `durChapterTime`
- `readConfig`
- `isInBookshelf`

這張表是閱讀進度的持久化真源。閱讀器 runtime 內的 `pageIndex` 與 `localOffset` 都只是投影，最後都要收斂回 `durChapterIndex` + `durChapterPos`。

### `Chapters`

**主鍵**：`url`

**閱讀器與書源常用欄位**：

- `bookUrl`
- `title`
- `index`
- `content` — 正文快取
- `start`、`end`
- `startFragmentId`、`endFragmentId`

承擔章節目錄與正文快取。

### `Bookmarks`

閱讀器定位相關欄位：

- `bookUrl`
- `chapterIndex`
- `chapterPos`
- `chapterName`
- `bookText`

## DAO 清單

| DAO | 主要職責 |
|-----|---------|
| `BookDao` | 書籍資料、進度、書架狀態 |
| `ChapterDao` | 章節目錄、正文快取 |
| `BookSourceDao` | 書源 CRUD 與查詢 |
| `BookGroupDao` | 書籍分組 |
| `BookmarkDao` | 書籤 |
| `ReplaceRuleDao` | 替換規則 |
| `SearchHistoryDao` | 搜尋歷史 |
| `CookieDao` | 站點 cookie |
| `DictRuleDao` | 字典規則 |
| `HttpTtsDao` | HTTP TTS |
| `ReadRecordDao` | 閱讀記錄 |
| `ServerDao` | 服務端設定 |
| `TxtTocRuleDao` | TXT 目錄規則 |
| `CacheDao` | 通用快取 |
| `KeyboardAssistDao` | 鍵盤輔助 |
| `RuleSubDao` | 規則訂閱 |
| `SourceSubscriptionDao` | 書源訂閱 |
| `SearchBookDao` | 搜尋結果快取 |
| `DownloadDao` | 下載任務 |
| `SearchKeywordDao` | 關鍵字統計 |

## 與閱讀器的主要交互

閱讀器流程最常碰到：

- `BookDao` — 讀寫書籍資料、進度、書架狀態
- `ChapterDao` — 讀章節目錄與正文快取
- `BookSourceDao` — 讀書源設定
- `ReplaceRuleDao` — 讀內容替換規則
- `BookmarkDao` — 建立書籤

書源引擎會透過 service / repository 向 DAO 寫入章節內容，不直接在 parser 層寫 DB。

## 書源健康狀態（目前實作）

`BookSources` 目前**沒有**獨立的「健康狀態 / 校驗結果」欄位。

目前 app 的書源健康狀態是透過：

- `bookSourceGroup` 中的系統 tag
- `bookSourceComment` 中的錯誤註解

來推導，例如：

- `搜尋失效`
- `詳情失效`
- `目錄失效`
- `正文失效`
- `上游異常`
- `下載站`
- `非小說源`
- `需要登入`

這是 `v0.2.4` 引入的過渡設計，已能支撐搜尋池過濾、閱讀隔離、來源管理清理與換源流程；但後續若要做校驗歷史、排序、篩選與統計，應考慮把這套狀態正規化為正式欄位或獨立表。

## Migration 現況

可由代碼直接確認的 migration 行為：

- schema version = **8**
- `from < 7` — 刪除舊 RSS 相關表
- `from < 8` — 為 `download_tasks` 新增 `startChapterIndex`、`endChapterIndex`
- `beforeOpen` — 確保所有註冊表存在

升級策略偏保守，重點是避免舊版升級路徑因缺表而失敗。

## 改動 schema 時

1. 編輯 `lib/core/database/tables/` 下的 table 定義
2. 在 `app_database.dart` 的 `schemaVersion` 提高版本號
3. 在 `migration` 對應 `from < N` 分支加遷移邏輯
4. 跑 `flutter pub run build_runner build --delete-conflicting-outputs`
5. 加 migration 測試（可參考既有 schema 測試）

## 實務判讀

- `Books` 是閱讀進度與書架狀態真源
- `Chapters` 是章節目錄與正文快取真源
- 其他表多數是書源、規則、搜尋、下載與周邊功能支撐

UI 層不應直接呼叫 DAO（M5 已完成消除）。跨 DAO 或整合性邏輯應在 `core/services/` 或 feature 層的 repository 類別中組裝。
