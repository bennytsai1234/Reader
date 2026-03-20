# Database Overview

更新日期：2026-03-20

本文只整理目前實際可從代碼驗證的資料庫結構與組成，依據：

- [app_database.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/database/app_database.dart)
- [app_tables.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/database/tables/app_tables.dart)

## 1. 基本資訊

資料庫技術：

- Drift
- Native SQLite

主要入口：

- [app_database.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/database/app_database.dart)

目前 schema version：

- `8`

資料庫檔案位置：

- `ApplicationSupportDirectory/databases/legado_reader.db`

## 2. 資料庫組成

目前 `AppDatabase` 註冊了 20 張資料表與對應 DAO。

### 核心閱讀資料

- `Books`
  - 書籍元資料、閱讀進度、書架狀態
- `Chapters`
  - 書籍章節清單與章節內容快取
- `Bookmarks`
  - 書籤
- `ReadRecords`
  - 閱讀記錄

### 書源與規則

- `BookSources`
  - 書源規則與解析設定
- `ReplaceRules`
  - 內容替換/淨化規則
- `DictRules`
  - 字典規則
- `RuleSubs`
  - 規則訂閱
- `SourceSubscriptions`
  - 書源訂閱
- `TxtTocRules`
  - TXT 目錄規則

### 搜尋與快取

- `SearchHistoryTable`
  - 搜尋歷史
- `SearchBooks`
  - 搜尋結果快取
- `SearchKeywords`
  - 關鍵字使用統計
- `CacheTable`
  - 通用 key-value 快取
- `Cookies`
  - 站點 cookie

### 其他功能資料

- `BookGroups`
  - 書籍分組
- `Servers`
  - 服務端設定
- `HttpTtsTable`
  - HTTP TTS 設定
- `KeyboardAssists`
  - 鍵盤輔助
- `DownloadTasks`
  - 下載任務

## 3. 與閱讀器直接相關的表

閱讀器 runtime 最直接依賴的是這幾張表：

### Books

主鍵：

- `bookUrl`

與閱讀器直接相關的欄位：

- `durChapterTitle`
- `durChapterIndex`
- `durChapterPos`
- `durChapterTime`
- `readConfig`
- `isInBookshelf`

這張表承擔目前閱讀進度的持久化真源。

### Chapters

主鍵：

- `url`

與閱讀器直接相關的欄位：

- `bookUrl`
- `title`
- `index`
- `content`
- `start`
- `end`
- `startFragmentId`
- `endFragmentId`

這張表承擔章節目錄與章節正文快取。

### Bookmarks

與閱讀器直接相關的欄位：

- `bookUrl`
- `chapterIndex`
- `chapterPos`
- `chapterName`
- `bookText`

## 4. DAO 組成

目前 `AppDatabase` 註冊的 DAO 有：

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

## 5. 與閱讀器模組的主要交互

閱讀器模組最常直接碰到的是：

- `BookDao`
  - 讀寫書籍進度
- `ChapterDao`
  - 讀章節目錄
  - 讀寫章節內容快取
- `BookSourceDao`
  - 讀書源設定
- `ReplaceRuleDao`
  - 讀正文替換規則
- `BookmarkDao`
  - 新增書籤

## 6. migration 現況

目前 migration 策略在 [app_database.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/database/app_database.dart)。

可直接確認的事實：

- schema version 是 `8`
- `from < 7` 時會刪除舊 RSS 表
- `from < 8` 時會為 `download_tasks` 補：
  - `startChapterIndex`
  - `endChapterIndex`
- `beforeOpen` 會再次確保所有表存在

## 7. 結論

目前資料層的核心形狀很清楚：

- `Books` 是閱讀進度真源
- `Chapters` 是章節目錄與正文快取真源
- 其餘多數表是書源、搜尋、規則、下載與周邊功能支撐

如果後續要補更細的資料文檔，建議按「閱讀器核心表」、「書源規則表」、「周邊功能表」拆開寫，不要再回到一份過長、難以維護的大總表。
