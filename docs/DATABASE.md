# 資料庫

這份文件描述 `lib/core/database/` 目前真實存在的 Drift 結構。

## 基本資訊

- 入口：`lib/core/database/app_database.dart`
- 資料庫類別：`AppDatabase`
- 連線模式：singleton
- schema version：`1`
- 檔案路徑：`<ApplicationSupportDirectory>/databases/inkpage_reader.db`

## 存取原則

- UI 不直接碰 SQLite
- 所有正式查詢 / 寫入都應經過 DAO
- table 定義在 `lib/core/database/tables/app_tables.dart`
- 變更 table / dao 後必須重新跑：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 資料表分組

### 書籍與閱讀資料

- `books`
- `chapters`
- `reader_chapter_contents`
- `bookmarks`
- `read_records`
- `download_tasks`
- `cache_table`

這組資料負責：

- 書架中的書籍狀態
- 章節目錄
- 已儲存正文
- 閱讀進度
- 書籤
- 離線下載任務

### 書源與規則資料

- `book_sources`
- `cookies`
- `rule_subs`
- `source_subscriptions`
- `replace_rules`
- `dict_rules`
- `http_tts_table`
- `txt_toc_rules`
- `servers`

這組資料負責：

- 書源規則本體
- cookie / 登入狀態
- 書源訂閱
- 文字替換規則
- 字典與 TTS 補充規則

### 搜尋與輔助資料

- `search_history_table`
- `search_books`
- `search_keywords`
- `keyboard_assists`
- `book_groups`

這組資料負責：

- 搜尋歷史與快取
- 使用者自訂分組
- 輔助輸入資料

## migration 重點

目前以全新 app schema 為準，只保留 `onCreate: createAll()`。
不保留舊資料庫升級路徑，也不在 `beforeOpen` 補做舊表或舊欄位修補。

## 與閱讀器直接相關的資料欄位

### `books`

閱讀器最核心的持久化欄位在 `books`：

- `durChapterTitle`
- `chapterIndex`
- `charOffset`
- `durChapterTime`
- `readConfig`
- `isInBookshelf`

其中：

- `chapterIndex`
- `charOffset`

是閱讀器 durable progress 的最主要資料落點。

### `chapters`

`chapters` 保存：

- 章節標題
- 章節 URL
- 章節索引

### `reader_chapter_contents`

`reader_chapter_contents` 保存：

- 正文 storage key
- 書籍 URL / 章節 URL / 章節索引
- 已 materialize 的純文字正文
- ready / failed 狀態與失敗訊息

### `read_records`

保存閱讀紀錄頁實際顯示所需的最近閱讀資訊。

## 維護規則

- 不在 UI 層自行拼裝 SQL
- 目前以全新 app schema 為準，不保留舊資料庫 migration 路徑
- schema 變更時，同步更新這份文件中的：
  - schema version
  - migration 節點
  - 資料表分組
