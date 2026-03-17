# Legado Reader 資料庫設計文件 (iOS/Flutter)

本文件詳述了 Legado Reader iOS 專案中使用的所有 SQLite 資料表結構及其對應的 DAO 方法。資料庫目前使用 `Drift` 進行管理，但 DAO 層級主要透過 `DriftCompatDao` 執行原始 SQL 查詢以維持與 Android 版的邏輯一致性。

---

## 資料表概覽

| 表名（Dart class） | SQLite 表名 | DAO 檔案 | 說明 |
|---|---|---|---|
| Books | books | book_dao.dart | 書架書籍元數據與閱讀進度 |
| Chapters | chapters | chapter_dao.dart | 書籍章節列表與快取內容 |
| BookSources | book_sources | book_source_dao.dart | 書源規則配置 |
| BookGroups | book_groups | book_group_dao.dart | 書籍分組管理 |
| Bookmarks | bookmarks | bookmark_dao.dart | 用戶手動/自動書籤 |
| SearchHistory | search_history | search_history_dao.dart | 搜尋歷史關鍵字 |
| SearchBooks | search_books | search_book_dao.dart | 搜尋結果快取 |
| ReplaceRules | replace_rules | replace_rule_dao.dart | 內容淨化與替換規則 |
| Cookies | cookies | cookie_dao.dart | 各站點 Cookie 持久化 |
| DictRules | dict_rules | dict_rule_dao.dart | 字典搜尋規則 |
| HttpTts | http_tts | http_tts_dao.dart | 自定義 HTTP TTS 朗讀引擎配置 |
| ReadRecords | read_records | read_record_dao.dart | 閱讀統計記錄 |
| Servers | servers | server_dao.dart | 遠端服務配置 (如 WebDAV 等) |
| TxtTocRules | txt_toc_rules | txt_toc_rule_dao.dart | 本地 TXT 目錄解析正則 |
| Cache | cache | cache_dao.dart | 通用鍵值對快取 |
| KeyboardAssists | keyboard_assists | keyboard_assist_dao.dart | 鍵盤輔助輸入配置 |
| RuleSubs | rule_subs | rule_sub_dao.dart | 規則訂閱列表 |
| SourceSubscriptions | source_subscriptions | source_subscription_dao.dart | 書源訂閱來源 |
| DownloadTasks | download_tasks | download_dao.dart | 背景下載任務進度 |
| SearchKeywords | search_keywords | search_keyword_dao.dart | 搜尋關鍵字熱度統計 |

---

## 核心資料表詳細說明

### 1. books（書架書籍）
儲存所有匯入書架的書籍資訊及當前閱讀進度。

| 欄位 | 類型 | 說明 |
|------|------|------|
| bookUrl | TEXT PK | 書籍唯一識別符 (通常為詳情頁連結) |
| name | TEXT | 書名 |
| author | TEXT | 作者 |
| coverUrl | TEXT | 封面連結 |
| durChapterIndex | INTEGER | 當前閱讀章節索引 |
| durChapterPos | INTEGER | 當前章節內的字元偏移量 |
| isInBookshelf | INTEGER | 是否在書架上 (1: 是, 0: 否) |

#### DAO 方法 (BookDao)
- `getInBookshelf()` → 取得書架上的所有書籍。
- `updateProgress(bookUrl, index, title, pos)` → 更新書籍的閱讀進度。
- `getLastReadBook()` → 獲取最後一次閱讀的書籍。

### 2. chapters（書籍章節）
儲存書籍的目錄資訊及已下載的章節內容。

| 欄位 | 類型 | 說明 |
|------|------|------|
| url | TEXT PK | 章節唯一連結 |
| bookUrl | TEXT | 所屬書籍連結 |
| title | TEXT | 章節標題 |
| index | INTEGER | 章節在目錄中的順序 |
| content | TEXT | 章節正文內容 (若有快取) |

#### DAO 方法 (ChapterDao)
- `getChapterList(bookUrl)` → 獲取指定書籍的目錄。
- `saveContent(url, content)` → 儲存或更新章節正文內容。
- `getChapterCount(bookUrl)` → 獲取章節總數。

### 3. book_sources（書源規則）
定義如何從特定網站解析書籍資訊。

| 欄位 | 類型 | 說明 |
|------|------|------|
| bookSourceUrl | TEXT PK | 書源唯一標識 (Base URL) |
| bookSourceName | TEXT | 書源名稱 |
| ruleSearch | TEXT | 搜尋解析規則 (JSON) |
| ruleToc | TEXT | 目錄解析規則 (JSON) |
| ruleContent | TEXT | 正文解析規則 (JSON) |

#### DAO 方法 (BookSourceDao)
- `getAllEnabled()` → 獲取所有啟用的書源。
- `upsert(source)` → 插入或更新書源規則。

### 4. replace_rules（淨化規則）
用於過濾正文中的廣告或不必要的文字。

| 欄位 | 類型 | 說明 |
|------|------|------|
| id | INTEGER PK | 自動增量 ID |
| pattern | TEXT | 匹配的正則表達式 |
| replacement | TEXT | 替換後的文字 |
| isEnabled | INTEGER | 是否啟用 |

---

## 其它輔助資料表

### cookies（站點 Cookie）
儲存各書源站點的登入狀態或訪問憑證。

### http_tts（自定義朗讀）
儲存第三方 TTS 引擎的 API 呼叫規則。

### txt_toc_rules（TXT 目錄規則）
儲存用於分割本地 TXT 檔案的正則表達式列表。

---

## 備註
- RSS 相關資料表已於 v7 版本正式移除。
- `schemaVersion` 目前為 `7`。
