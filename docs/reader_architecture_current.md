# 閱讀器架構（現況）

更新日期：2026-04-20

本文只描述 `lib/features/reader` 目前已落地的閱讀器架構，不沿用舊版 mixin 時代或早期對照稿的說法。

## 一句話結論

閱讀器已形成以 `ReadBookController` 為中心的 runtime 內核：

- **核心層**：navigation、restore、progress、session、chapter runtime
- **協調層**：content lifecycle、read aloud、auto page、visible tracking
- **視圖層**：scroll / slide delegate、scroll execution、restore execution

`ReaderContentMixin` / `ReaderSettingsMixin` / `ReaderAutoPageMixin` 仍是 mixin 鏈的一部分，但真正的控制權已回收到 controller、coordinator 與 store。

## 主控與真源

主控：`lib/features/reader/runtime/read_book_controller.dart`。

職責：

- 閱讀生命週期（`loading → ready`）
- 目前閱讀位置與可見位置
- 章節 runtime 快取
- 對外 jump / persist / TTS 命令入口
- 閱讀失敗後的自動換源 / 手動換源協調

閱讀進度持久化真源仍是 `Book` 上的：

- `book.durChapterIndex`
- `book.durChapterPos`

`pageIndex` 與 `localOffset` 只是 runtime / display 投影，最後都要收斂回章內 char offset。

## Mixin 鏈

```
ReaderProviderBase
  → ReaderSettingsMixin
  → ReaderContentMixin
  → ReaderAutoPageMixin
  → ReadBookController (with WidgetsBindingObserver)
```

`ReaderProviderBase` 提供 `batchUpdate` 與 `notifyListeners` override。

## Coordinator 子域

`ReadBookController` 內部拆出的子域物件：

- `ReaderNavigationController` — jump reason、command guard、page change reason、auto-page step 決策
- `ReaderRestoreCoordinator` — pending restore token / target 建立、消費、清除
- `ReaderProgressStore` — durable progress 回寫與 `book.durChapter*` 同步
- `ReaderProgressCoordinator` — 閱讀進度更新（含 debounce）
- `ReaderScrollVisibilityCoordinator` — scroll visible chapter 去重、補載、preload 中心判定
- `ReaderTtsFollowCoordinator` — TTS follow safe-zone、follow target 決策
- `ReaderSessionCoordinator` — session 狀態（`ReaderSessionState`）與 lifecycle 協調
- `ReaderDisplayCoordinator` — 顯示資訊投影
- `ReaderContentCoordinator` — 內容載入協調
- `ReadViewRuntimeCoordinator` — view runtime 橋接

這代表 restore、save、visible preload、TTS follow 已不再主要由 view 層自行判斷。

## 章節 Runtime

核心物件：`lib/features/reader/runtime/models/reader_chapter.dart` 的 `ReaderChapter`。

承擔整個章內定位語義：

- `charOffset ↔ localOffset`
- `charOffset ↔ pageIndex`
- highlight range
- restore target
- scroll anchor
- page 前後跳轉
- paragraph / line query
- read aloud data 組裝

restore、scroll follow、TTS、auto-page 共用同一套章內語義，而不是各自掃 page 做定位。

## 內容生命週期

`ChapterContentManager`（`engine/chapter_content_manager.dart`）是章節生命週期服務，實際承擔：

- 正文抓取協調
- 主動載入與靜默預載去重
- 分頁快取與 progressive paginate
- preload queue / priority
- 視窗內外驅逐

主要外部 API：

- `ensureChapterReady(...)`
- `warmChaptersAround(...)`
- `repaginateVisibleWindow(...)`
- `prioritize(...)`
- `evictOutside(...)`

內容來源三路：

- 本地書：`LocalBookService`
- 網路書：`BookSourceService`（含 charset 偵測）
- 快取：`ChapterDao` + cache manager

典型主流程：

```
ReadBookController._init()
  → initContentManager()
  → loadChapterWithPreloadRadius()
  → ChapterContentManager.ensureChapterReady()
  → _fetchChapterData()
  → ContentProcessor.process()
  → ChapterProvider.paginate() 或 progressive paginate
  → 更新 chapterPagesCache
  → refreshChapterRuntime(index)
```

## Restore 與 Progress

`ReaderContentMixin` / `ReaderProgressCoordinator` 是轉譯與接線層：

- 把 visible scroll position 轉成 char offset
- 把 restore target 轉成 jump 語意
- 把保存動作導回 `ReaderProgressStore`

Restore 鏈：

```
Target 狀態      ReaderRestoreCoordinator
  ↓
Jump 語意        ReaderNavigationController
  ↓
章內定位          ReaderChapter.resolveRestoreTarget()
  ↓
Scroll retry     ScrollRestoreRunner
  ↓
完成切換          ReadBookController.completeRestoreTransition()
```

## View Runtime 與 Delegate

外層視圖主入口：`lib/features/reader/view/read_view_runtime.dart`。

職責：

- 接收 controller / provider 狀態
- 建立 scroll / slide delegate
- 執行 restore / jump / TTS follow
- 接收 raw visible positions
- 啟動 scroll auto-page ticker

細節拆出：

- `scroll_execution_adapter.dart` — scroll pixel、ensureVisible、anchor 執行
- `scroll_restore_runner.dart` — scroll restore retry、reload、完成判定
- `scroll_runtime_executor.dart` — scroll runtime 指令執行
- `delegate/page_mode_delegate.dart` — 平移翻頁模式（`PageAnim.slide`）
- `delegate/scroll_mode_delegate.dart` — 捲動模式（`PageAnim.scroll`）
- `slide_page_controller.dart` — 平移模式底層的 `PageView` 管理器（用 `SlideWindow`/`SlideSegment`，`PageController(initialPage:)` 重建替代延遲 jumpToPage）

使用者可選的翻頁模式僅兩種：**平移**與**捲動**。`PageAnim` 類別另保留 `simulation` / `none` 常數僅作為 Legado 設定匯入相容性，不對應實際實作。

## 正文失敗與換源恢復

`ReadBookController` 現在已接入來源切換恢復鏈：

- 章節內容抓取失敗時，`ReaderChapterContentLoader` 會把失敗訊息透過 `FetchResult.failureMessage` 回傳
- `ReaderContentMixin` 會按章節保存失敗狀態
- `page_view_widget.dart` 會在頁面內顯示恢復卡片，而不是只丟一行錯誤字串
- 使用者可以：
  - 直接點「自動換源」讓 controller 尋找同名同作者的可用來源
  - 點「手動換源」打開 `reader_source_fallback_sheet.dart`

這條鏈的定位是**閱讀期恢復機制**，不是 parser / 書源健康判定的替代品。

## Read Aloud / TTS

`read_aloud_controller.dart` — 朗讀主控，負責：

- 建立 read aloud session
- TTS offset map
- 朗讀進度到章內 offset 映射
- highlight 同步
- next / prev page 或章節跳轉
- 預抓下一章朗讀資料

大量依賴 `ReaderChapter` 來取 highlight 範圍、page start offset、scroll anchor、read aloud data。

底層播放由 `lib/core/services/tts_service.dart` 提供，`TTSService` 為全域單例，在 `main()` 初始化，與 `audio_service` 整合提供系統通知欄控制。

## Auto Page

`ReaderAutoPageMixin` 負責啟停與速度控制，核心 timer / state 交給 `reader_auto_page_coordinator.dart`。

- `slide` 模式偏 page-based
- `scroll` 模式仍由 `ReadViewRuntime` ticker 驅動
- 下一步 target 由 `ReaderNavigationController.evaluateScrollAutoPageStep()` 決定

## 優點

- 核心狀態真源清楚
- 章內語義統一
- restore / progress / TTS / visible tracking 不再四散
- 有實質 runtime 測試保護主流程

## 仍存在的限制

- mixin 時代遺留介面尚未完全退出
- scroll 模式的 auto-page ticker 仍在 `ReadViewRuntime` 層
- `ChapterContentManager.targetWindow` 尚未完全收回內部細節
- `ReadBookController` 本身仍偏大
- 換源目前仍偏向「正文失敗後恢復」，尚未前移到詳情 / 目錄階段做更無感的自癒

## 測試保護

目前覆蓋閱讀器 runtime 的測試（`test/features/reader/`）：

- `read_book_controller_test.dart`
- `read_aloud_controller_test.dart`
- `read_view_runtime_coordinator_test.dart`
- `reader_navigation_controller_test.dart`
- `reader_command_guard_test.dart`
- `reader_restore_coordinator_test.dart`
- `reader_progress_coordinator_test.dart`
- `reader_progress_store_test.dart`
- `reader_position_resolver_test.dart`
- `reader_session_coordinator_test.dart`
- `reader_display_coordinator_test.dart`
- `reader_scroll_visibility_coordinator_test.dart`
- `reader_tts_follow_coordinator_test.dart`
- `reader_runtime_flow_test.dart`
- `reader_chapter_runtime_test.dart`
- `chapter_content_manager_test.dart`
- `chapter_content_manager_lifecycle_test.dart`
- `chapter_position_resolver_test.dart`
- `chapter_provider_test.dart`
- `slide_page_controller_test.dart`
- `text_page_test.dart`
- `text_page_serialization_test.dart`
- `page_anim_test.dart`

這代表目前閱讀器可以透過測試而非純手測來維持演進。

## 總結

閱讀器從「多個 mixin + widget 邏輯拼裝」進化成「有 controller 內核、有 chapter runtime、有 coordinator/store、有 lifecycle-oriented content manager」的閱讀 runtime。這是目前整個專案裡最接近穩定內核的一塊。
