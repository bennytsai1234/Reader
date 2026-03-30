# Reader Architecture (Current)

更新日期：2026-03-30

本文只描述目前 `lib/features/reader` 已經落地的閱讀器架構，不再沿用舊版 mixin 時代或早期對照稿的說法。

## 一句話結論

目前閱讀器已經形成一個以 `ReadBookController` 為中心的 runtime 內核：

- 核心層：navigation、restore、progress、chapter runtime
- 協調層：content lifecycle、read aloud、auto page、visible tracking
- 視圖層：scroll / slide delegate、scroll execution、restore execution

雖然 `ReaderContentMixin`、`ReaderProgressMixin`、`ReaderSettingsMixin`、`ReaderAutoPageMixin` 仍存在，但真正的控制權已大幅回收到 controller、coordinator 與 store。

## 主控與真源

主控在 `lib/features/reader/runtime/read_book_controller.dart`。

它負責：

- 閱讀生命週期：`loading -> restoring -> ready`
- 目前閱讀位置與可見位置
- 章節 runtime 快取
- 對外 jump / persist / TTS 命令入口

目前閱讀進度的持久化真源仍是 `Book` 上的：

- `book.durChapterIndex`
- `book.durChapterPos`

`pageIndex` 與 `localOffset` 只是 runtime / display 投影，最後都要收斂回章內 char offset。

## 已拆出的子域

`ReadBookController` 內部已把幾塊高耦合責任拆成子域物件：

- `reader_navigation_controller.dart`
  管 jump reason、command guard、page change reason 與 auto-page step 決策
- `reader_restore_coordinator.dart`
  管 pending restore token / target 的建立、消費與清除
- `reader_progress_store.dart`
  管 durable progress 回寫與 `book.durChapter*` 同步
- `reader_scroll_visibility_coordinator.dart`
  管 scroll visible chapter 去重、補載與 preload 中心判定
- `reader_tts_follow_coordinator.dart`
  管 TTS follow safe-zone 與 follow target 決策

這代表 restore、save、visible preload、TTS follow 已不再主要由 view 層自行判斷。

## 內容生命週期

內容鏈主入口仍由 `ReaderContentMixin` 提供，但語義已經轉成「讓 controller 觸發 manager 與 runtime 流程」。

主流程大致是：

1. `ReadBookController._init()`
2. `initContentManager()`
3. `loadChapterWithPreloadRadius(...)`
4. `ChapterContentManager.ensureChapterReady(...)`
5. `_fetchChapterData(...)`
6. `ContentProcessor.process(...)`
7. `ChapterProvider.paginate(...)` 或 progressive paginate
8. 更新 `chapterPagesCache`
9. `refreshChapterRuntime(index)`

內容來源仍分三路：

- 本地書：`LocalBookService`
- 網路書：`BookSourceService`
- 快取：`ChapterDao` + cache manager

## `ChapterContentManager` 的角色

`chapter_content_manager.dart` 現在不是單純的 queue 管理器，而是章節生命週期服務。

它實際承擔：

- 正文抓取協調
- 主動載入與靜默預載去重
- 分頁快取與 progressive paginate
- preload queue / priority
- 視窗外內容驅逐

目前比較有語意的外部 API 是：

- `ensureChapterReady(...)`
- `warmChaptersAround(...)`
- `repaginateVisibleWindow(...)`
- `prioritize(...)`
- `evictOutside(...)`

## `ReaderChapter` 的地位

`lib/features/reader/runtime/models/reader_chapter.dart` 是整個閱讀器最關鍵的 runtime 物件。

它現在承擔的不只是 page 容器，而是整個章內定位語義，包括：

- `charOffset <-> localOffset`
- `charOffset <-> pageIndex`
- highlight range
- restore target
- scroll anchor
- page 前後跳轉
- paragraph / line query
- read aloud data 組裝

這件事很重要，因為 restore、scroll follow、TTS、auto page 開始共用同一套章內語義，而不是各自掃 page 做定位。

## Restore 與 Progress

`ReaderProgressMixin` 仍存在，但定位已下降為轉譯與接線層。現在它主要做三件事：

- 把 visible scroll position 轉成 char offset
- 把 restore target 轉成 jump 語意
- 把保存動作導回 `ReaderProgressStore`

目前 restore 鏈是：

- target 狀態：`ReaderRestoreCoordinator`
- jump 語意：`ReaderNavigationController`
- 章內定位：`ReaderChapter.resolveRestoreTarget(...)`
- scroll retry：`ScrollRestoreRunner`
- 完成切換：`ReadBookController.completeRestoreTransition()`

這套鏈條相較早期版本已明顯清楚得多。

## View Runtime 與 Delegate

外層視圖主入口在 `lib/features/reader/view/read_view_runtime.dart`。

它目前主要負責：

- 接收 controller/provider 狀態
- 建立 scroll 或 slide delegate
- 執行 restore / jump / TTS follow
- 接收 raw visible positions
- 啟動 scroll auto-page ticker

相關細節已拆出到：

- `scroll_execution_adapter.dart`
  負責 scroll pixel、ensureVisible、anchor 執行
- `scroll_restore_runner.dart`
  負責 scroll restore retry、reload 與完成判定
- `delegate/scroll_mode_delegate.dart`
  負責 scroll 模式渲染
- `delegate/slide_mode_delegate.dart`
  負責 slide 模式渲染

## Read Aloud / TTS

`read_aloud_controller.dart` 是朗讀流程主控。

它目前負責：

- 建立 read aloud session
- TTS offset map
- 朗讀進度到章內 offset 的映射
- highlight 同步
- next / prev page 或章節跳轉
- 預抓下一章朗讀資料

它已經大量依賴 `ReaderChapter` 來完成：

- highlight 範圍
- page start offset
- scroll anchor
- read aloud data 組裝

底層播放仍由 `lib/core/services/tts_service.dart` 提供。

## Auto Page

`ReaderAutoPageMixin` 仍負責啟停與速度控制，但核心 timer / state 已交給 `reader_auto_page_coordinator.dart`。

目前差異是：

- `slide` 模式偏 page-based
- `scroll` 模式仍由 `ReadViewRuntime` ticker 驅動
- 下一步 target 則由 `ReaderNavigationController.evaluateScrollAutoPageStep(...)` 決定

也就是說，auto page 的決策已較集中，但 scroll 模式的執行仍帶有 view 層責任。

## 目前架構的優點

- 核心狀態真源比過去清楚
- 章內語義開始統一
- restore / progress / TTS / visible tracking 不再四散
- 已有實質 runtime 測試保護主流程

## 目前仍存在的限制

- mixin 時代遺留介面還沒完全退出
- content lifecycle 仍有部分責任散在 provider / manager / runtime 間
- scroll 模式的執行層還帶有較多 view 細節
- 部分命名仍混合「頁面語義」與「章內語義」

## 測試現況

目前已經有一批直接保護閱讀器 runtime 的測試，包括：

- `chapter_content_manager_test.dart`
- `chapter_content_manager_lifecycle_test.dart`
- `reader_command_guard_test.dart`
- `reader_navigation_controller_test.dart`
- `reader_restore_coordinator_test.dart`
- `reader_progress_store_test.dart`
- `reader_scroll_visibility_coordinator_test.dart`
- `reader_tts_follow_coordinator_test.dart`
- `reader_runtime_flow_test.dart`
- `reader_chapter_runtime_test.dart`
- `chapter_position_resolver_test.dart`
- `chapter_provider_test.dart`

這代表目前閱讀器已經可以透過測試而不是純手測來維持演進。
- `restore ready`
- `tts speak`
- `tts prefetched next chapter`
- `tts chapter handoff nextChapter`
- `tts handoff speak`
- content fetch / process / paginate

目前已具備初步的性能定位能力，但還不是完整 telemetry。

## 13. 仍未完全解決的點

目前仍需要持續優化的，不是「主鏈不存在」，而是以下幾點：

- `ReadBookController` 仍然偏大
- `ReaderContentMixin` / `ReaderProgressMixin` 仍有部分歷史責任
- `ReadViewRuntime` 還保留 scroll auto-page ticker 與部分 orchestration
- `ChapterContentManager.targetWindow` 仍未完全退回內部細節
- `ReadBookController / ReadAloudController` 的 full integration test 仍可再補深

## 14. 總結

目前閱讀器模組的真實狀態是：

它已經從「多個 mixin + widget 邏輯拼裝」進化成「有 controller 內核、有 chapter runtime、有 coordinator/store、有 lifecycle-oriented content manager」的閱讀 runtime。

這是目前整個專案裡最接近穩定內核的一塊。
