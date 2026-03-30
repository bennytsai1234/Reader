# Database Overview

更新日期：2026-03-30

本文只描述目前可以直接由代碼驗證的資料庫事實，主要依據：

- `lib/core/database/app_database.dart`
- `lib/core/database/tables/app_tables.dart`

## 基本資訊

- 資料庫技術：`Drift` + native SQLite
- 主要入口：`lib/core/database/app_database.dart`
- schema version：`8`
- 資料庫檔案：`ApplicationSupportDirectory/databases/legado_reader.db`

## 表與 DAO 規模

目前 `AppDatabase` 註冊了 20 張資料表與 20 個 DAO。

### 核心閱讀資料

- `Books`
  書籍主資料、書架狀態、閱讀進度、閱讀設定
- `Chapters`
  章節清單與正文快取
- `Bookmarks`
  書籤
- `ReadRecords`
  閱讀記錄

### 書源與規則

- `BookSources`
  書源規則、登入設定、解析規則
- `ReplaceRules`
  正文替換規則
- `DictRules`
  字典規則
- `RuleSubs`
  規則訂閱
- `SourceSubscriptions`
  書源訂閱
- `TxtTocRules`
  TXT 目錄規則

### 搜尋、快取與網路狀態

- `SearchHistoryTable`
  搜尋歷史
- `SearchBooks`
  搜尋結果快取
- `SearchKeywords`
  關鍵字統計
- `CacheTable`
  通用 key-value 快取
- `Cookies`
  站點 cookie

### 其他功能資料

- `BookGroups`
  書籍分組
- `Servers`
  服務端設定
- `HttpTtsTable`
  HTTP TTS 設定
- `KeyboardAssists`
  鍵盤輔助設定
- `DownloadTasks`
  下載任務

## 對閱讀器最重要的表

### `Books`

主鍵：`bookUrl`

閱讀器最常依賴的欄位：

- `durChapterTitle`
- `durChapterIndex`
- `durChapterPos`
- `durChapterTime`
- `readConfig`
- `isInBookshelf`

這張表是目前閱讀進度的持久化真源。

### `Chapters`

主鍵：`url`

閱讀器與書源流程常用欄位：

- `bookUrl`
- `title`
- `index`
- `content`
- `start`
- `end`
- `startFragmentId`
- `endFragmentId`

這張表承擔章節目錄與正文快取。

### `Bookmarks`

與閱讀器定位直接相關的欄位：

- `bookUrl`
- `chapterIndex`
- `chapterPos`
- `chapterName`
- `bookText`

## DAO 清單

目前已註冊的 DAO：

- `BookDao`
- `ChapterDao`
- `BookSourceDao`
- `BookGroupDao`
- `BookmarkDao`
- `ReplaceRuleDao`
- `SearchHistoryDao`
- `CookieDao`
- `DictRuleDao`
- `HttpTtsDao`
- `ReadRecordDao`
- `ServerDao`
- `TxtTocRuleDao`
- `CacheDao`
- `KeyboardAssistDao`
- `RuleSubDao`
- `SourceSubscriptionDao`
- `SearchBookDao`
- `DownloadDao`
- `SearchKeywordDao`

## 與閱讀器的主要交互

閱讀器相關流程最常碰到的資料接口是：

- `BookDao`
  讀寫書籍資料、進度、書架狀態
- `ChapterDao`
  讀章節目錄與正文快取
- `BookSourceDao`
  讀取書源設定
- `ReplaceRuleDao`
  讀取內容替換規則
- `BookmarkDao`
  建立書籤

## Migration 現況

目前可直接確認的 migration 行為：

- schema version 是 `8`
- `from < 7` 時會刪除舊 RSS 相關表
- `from < 8` 時會為 `download_tasks` 增加：
  - `startChapterIndex`
  - `endChapterIndex`
- `beforeOpen` 會再確保所有註冊表存在

這代表資料庫升級策略偏保守，重點是避免舊版升級路徑因缺表而失敗。

## 實務判讀

這個資料層目前的真相很明確：

- `Books` 是閱讀進度與書架狀態真源
- `Chapters` 是章節目錄與正文快取真源
- 其他表多數是書源、規則、搜尋、下載與周邊功能支撐

後續如果要再細拆文檔，建議分成「閱讀器核心表」、「書源規則表」與「周邊能力表」三份，而不是再堆一份更長的總表。
