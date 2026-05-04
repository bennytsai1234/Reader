# Rules And Local Books

## 目標專案目前狀態

- 書源規則解析核心在 `lib/core/engine`，包含 `AnalyzeRule`、`AnalyzeUrl`、`RuleAnalyzer`、CSS/JSONPath/XPath/regex parser、JavaScript engine extensions、TTF 查詢與 web book parser。
- `BookSourceService` 是書源業務調度門面，包裝 `WebBook.getBookInfoAwait`、`getChapterListAwait`、`getContentAwait`、`searchBookAwait`、`exploreBookAwait`。
- 替換規則 UI 與狀態在 `lib/features/replace_rule`，閱讀器內替換規則入口在 `lib/features/reader_v2/features/replace_rule`。
- 本地書解析在 `lib/core/local_book` 與 `LocalBookService`，目前支援 TXT、EPUB、UMD；`local_book_formats.dart` 是支援格式白名單。
- 字典規則與 TXT 目錄規則相關資料表仍存在於 database/model/dao，主要作為相容層，不是目前使用者主入口。

## 目標專案上下游

- 上游依賴：`BookSource` 規則模型、`NetworkService`、`CookieStore`、`flutter_js`、HTML/CSS/XPath/JSONPath 套件、`EpubService`、`ResourceService`、`fast_gbk`。
- 下游影響：搜尋、探索、詳情、閱讀正文、書源除錯、來源校驗、替換規則、簡繁轉換、本地書匯入與 reader_v2 內容載入。
- 規則解析是來源相容性的核心契約；任何解析語義變更都要優先跑 engine 與 source compatibility 測試。

## 參考對應

- `legado/app/src/main/java/io/legado/app/model/analyzeRule`
- `legado/app/src/main/java/io/legado/app/model/webBook`
- `legado/app/src/main/java/io/legado/app/help/JsExtensions.kt`
- `legado/app/src/main/java/io/legado/app/help/ReplaceAnalyzer.kt`
- `legado/app/src/main/java/io/legado/app/ui/replace`
- `legado/app/src/main/java/io/legado/app/model/localBook`
- `legado/modules/book`

## 可參考模式

- 規則解析、網路請求、JavaScript 擴充、資料模型轉換要維持可測試的細分層，避免把 parser 行為藏在 UI provider。
- 書源相容性可以參考 Legado 的語義，但應由 `reader` 的 tests/fixtures 鎖定實際行為。
- 本地書解析要把格式判定、metadata、章節索引與正文讀取分離；TXT offset、EPUB href、UMD parsed cache 都是不同責任。

## 目標專案變更入口

- 規則解析：`lib/core/engine/analyze_rule.dart`、`lib/core/engine/rule_analyzer.dart`、`lib/core/engine/parsers/`。
- URL 與 WebBook：`lib/core/engine/analyze_url.dart`、`lib/core/engine/web_book/`、`lib/core/services/book_source_service.dart`。
- JS：`lib/core/engine/js/`。
- 替換規則：`lib/features/replace_rule/`、`lib/features/reader_v2/features/replace_rule/`、`lib/core/database/dao/replace_rule_dao.dart`。
- 本地書：`lib/core/local_book/`、`lib/core/services/local_book_service.dart`、`lib/core/services/epub_service.dart`。
- 測試：`tool/flutter_test_with_quickjs.sh test/core/engine`，以及 `flutter test test/core/local_book test/core/models/replace_rule_test.dart test/features/reader_v2/reader_v2_content_transformer_test.dart`。

## 已知風險

- Legado 規則語義龐大，`reader` 目前是 Flutter/Dart 實作；不要假設 Kotlin 行為已完整覆蓋。
- JavaScript engine 與 async rewrite 對 timeout、promise bridge、extension API 敏感；相關變更要使用 QuickJS/JS 專用測試腳本。
- TXT 讀取依賴 byte offset 與 charset；重新解析或複製檔案路徑變更會讓已存章節 offset 失效。
- UMD 解析有小型 LRU future cache；錯誤時要清除 failed future，避免後續讀取永遠失敗。
- 字典規則與 TXT 目錄規則保留資料相容性；刪除表或 DAO 會影響備份還原與舊資料。

## 不要做

- 不新增未規劃的本地格式或規則體系，除非使用者明確要求。
- 不為了追 Legado 完整功能而改變 `reader` 已有 parser 對測試 fixture 的相容性。
- 不在本地書服務中處理書架 UI 或閱讀器 viewport。
