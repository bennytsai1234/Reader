# Reader Runtime

## 目標專案目前狀態

- 閱讀主線是 `lib/features/reader_v2`，依責任拆成 `application`、`content`、`layout`、`render`、`runtime`、`viewport`、`shell`、`features`。
- `ReaderV2ChapterRepository` 管章節列表、正文載入、正文快取、替換規則與簡繁轉換；線上正文走 `ReaderChapterContentStorage`，本地 fallback 走 chapter content。
- `ReaderV2Runtime` 管狀態機、打開書、跳章、切換排版/模式、預載、進度保存、slide/scroll 邊界與效能 metrics。
- `ReaderV2LayoutEngine` 管文字測量、禁則、分行與分頁；`render` 與 `viewport` 管實際畫面、scroll/slide 互動與可見位置捕捉。
- 閱讀器內功能在 `features/reader_v2/features/*`，包含 menu、settings、TTS、bookmark、auto_page、replace_rule。

## 目標專案上下游

- 上游依賴：`Book`、`BookChapter`、`BookDao`、`ChapterDao`、`BookSourceDao`、`ReplaceRuleDao`、`ReaderChapterContentDao`、`BookSourceService`、`SettingsProvider`、reader_v2 prefs repository。
- 下游影響：閱讀畫面、TTS 高亮、自動翻頁、書籤、閱讀器內替換規則、詳情頁開啟閱讀、書架進度排序。
- `Reader Runtime` 是使用者可見核心流程；任何 layout signature、進度 anchor 或 content cache 變更都會影響回到同一位置的能力。

## 參考對應

- `legado/app/src/main/java/io/legado/app/ui/book/read`
- `legado/app/src/main/java/io/legado/app/model/ReadBook.kt`
- `legado/app/src/main/java/io/legado/app/model/ReadAloud.kt`
- `legado/app/src/main/java/io/legado/app/constant/PageAnim.kt`
- `legado/app/src/main/java/io/legado/app/help/book/ContentProcessor.kt`

## 可參考模式

- 參考 Legado 將閱讀殼層、狀態核心、排版、翻頁、朗讀與設定拆責任，但不要直接搬移 Android view/model 架構。
- 章節切換、預載與進度保存要有 stale request 防護，避免舊 layout 或舊內容覆蓋新狀態。
- Scroll 與 Slide 模式應共享內容與排版核心，但各自保留 viewport 行為。

## 目標專案變更入口

- 閱讀頁殼層：`lib/features/reader_v2/shell/reader_v2_page.dart`、`reader_v2_page_shell.dart`。
- 協調層：`lib/features/reader_v2/application/reader_v2_page_coordinator.dart`、`reader_v2_controller_host.dart`。
- Runtime：`lib/features/reader_v2/runtime/reader_v2_runtime.dart`、`reader_v2_resolver.dart`、`reader_v2_preload_scheduler.dart`、`reader_v2_progress_controller.dart`。
- 內容：`lib/features/reader_v2/content/reader_v2_chapter_repository.dart`、`reader_v2_content_transformer.dart`。
- 排版與 viewport：`lib/features/reader_v2/layout/`、`render/`、`viewport/`。
- 測試：`flutter test test/features/reader_v2`，效能或 viewport 變更至少跑對應 `reader_v2_viewport*_test.dart` 與 `reader_v2_layout_engine_test.dart`。

## 已知風險

- `ReaderV2Runtime` 透過 request id、layout generation 與 capture/restore callback 避免 stale async 更新；新增 async 流程時要延續這套防護。
- `ReaderV2ChapterRepository` 的 content cache generation 會在 reload 或設定變更時清除；替換規則、簡繁轉換或來源切換不能沿用舊內容。
- 進度保存包含 `chapterIndex`、`charOffset`、`visualOffsetPx` 與可能的 anchor JSON；改 layout 或 viewport 時要驗證回復定位。
- TTS 高亮會要求 viewport 滾到字元範圍；修改 line box、char offset 或 paragraph offset 會影響朗讀跟隨。
- Slide neighbor placeholder 與預載失敗處理是邊界敏感區，不能只測單頁跳轉。

## 不要做

- 不把 `legado` Android 閱讀頁架構直接搬進 `reader_v2`。
- 不在 runtime 中直接處理書源管理、詳情頁 UI 或設定頁 CRUD。
- 不為了單一閱讀器功能破壞 `application/content/layout/render/runtime/viewport` 的分層。
