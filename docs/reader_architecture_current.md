# Reader Architecture (Current)

更新日期：2026-03-20

本文只描述目前 `lib/features/reader` 內已經落地的閱讀器架構，不再使用舊版 mixin 時代或 legado 對照稿中的描述。

## 1. 一句話結論

目前閱讀器已經收斂成一個以 `ReadBookController` 為中心的 runtime 內核：

- 內核：navigation / restore / progress / chapter runtime
- 中層：content lifecycle / read aloud / auto page
- 外層：view runtime / mode delegates / scroll execution

仍然保留 `ReaderContentMixin`、`ReaderProgressMixin`、`ReaderAutoPageMixin`，但控制權已大幅回收到 controller 與各種 coordinator / store。

## 2. 主控與狀態真源

主控在 [read_book_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_book_controller.dart)。

它目前負責：

- 閱讀生命週期：`loading -> restoring -> ready`
- 當前閱讀位置：
  - `currentChapterIndex`
  - `currentPageIndex`
  - `visibleChapterIndex`
  - `visibleChapterLocalOffset`
- 章節 runtime 快取：`_chapterRuntimeCache`
- 對外閱讀命令入口：
  - `jumpToSlidePage(...)`
  - `jumpToChapterLocalOffset(...)`
  - `jumpToChapterCharOffset(...)`
  - `persistCurrentProgress(...)`

目前閱讀器的進度真源仍是書籍模型上的：

- `book.durChapterIndex`
- `book.durChapterPos`

也就是說，`pageIndex` 與 `localOffset` 都是 display/runtime 投影，最終會收斂回 chapter char offset。

## 3. 已拆出的 controller 子域

`ReadBookController` 內部已經把幾塊高耦合職責拆成明確子域：

- [reader_navigation_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/reader_navigation_controller.dart)
  - jump reason
  - page change reason
  - command guard 入口
  - auto-scroll step 決策
  - visible progress suppression

- [reader_restore_coordinator.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/reader_restore_coordinator.dart)
  - pending restore token
  - pending restore target
  - restore target consume / clear

- [reader_progress_store.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/reader_progress_store.dart)
  - durable progress 寫回
  - 立即保存策略
  - `book.durChapter*` 同步

- [reader_scroll_visibility_coordinator.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/reader_scroll_visibility_coordinator.dart)
  - scroll 可見章節去重
  - 可見章節 ensure
  - visible preload 中心章判斷

- [reader_tts_follow_coordinator.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/reader_tts_follow_coordinator.dart)
  - TTS follow safe-zone 判斷
  - follow target 產生

這代表「跳轉、restore、保存、visible preload、TTS follow」現在都不再主要由 view 層自己做判斷。

## 4. 內容生命週期

內容鏈主入口仍在 [reader_content_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_content_mixin.dart)，但語義已經和早期版本不同。

主要流程是：

1. `ReadBookController._init()`
2. `initContentManager()`
3. `loadChapterWithPreloadRadius(...)`
4. `ChapterContentManager.ensureChapterReady(...)`
5. `_fetchChapterData(...)`
6. `ContentProcessor.process(...)`
7. `ChapterProvider.paginate(...)` 或 `paginateProgressive(...)`
8. `chapterPagesCache[index]`
9. `refreshChapterRuntime(index)`

內容來源：

- 本地書：`LocalBookService`
- 網路書：`BookSourceService`
- 快取：`ChapterDao` + `CacheManager`

## 5. ChapterContentManager 的實際角色

[chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart) 現在已不只是「純 queue 管理器」，而是一個章節生命週期服務。

它目前實際承擔：

- 正文抓取協調
- 主動載入與靜默預載去重
- 分頁快取
- progressive paginate
- preload queue 與 priority
- 視窗內外快取驅逐
- 部分 lifecycle-oriented API

目前對外可直接使用的語義 API：

- `ensureChapterReady(...)`
- `warmChaptersAround(...)`
- `repaginateVisibleWindow(...)`
- `prioritize(...)`
- `evictOutside(...)`

仍然保留 `targetWindow`，但它已經比較偏 manager 內部細節，而不是推薦給上層直接操作的核心語義。

## 6. Chapter Runtime

[reader_chapter.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/models/reader_chapter.dart) 是目前整個閱讀器最重要的共用 runtime 物件。

它不再只是 `pages` 容器，現在已實際承擔：

- `charOffset <-> localOffset`
- `charOffset -> pageIndex`
- `pageIndex -> charOffset`
- `localOffset -> pageIndex`
- highlight range
- restore target
- scroll anchor
- page 前後跳轉
- paragraph / line query
- read aloud data build

目前已落地的高頻 API 包括：

- `lineAtCharOffset(...)`
- `paragraphAtCharOffset(...)`
- `pageAtLocalOffset(...)`
- `nextPageStartCharOffset(...)`
- `prevPageStartCharOffset(...)`
- `resolveHighlightRange(...)`
- `resolveRestoreTarget(...)`
- `resolveScrollAnchor(...)`
- `buildReadAloudData(...)`

這讓 `TTS / restore / scroll follow / auto page` 開始共享同一套章內語義，而不是各自掃 `pages`。

## 7. Progress 與 Restore

[reader_progress_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_progress_mixin.dart) 目前仍在，但它已不再是早期那種自成一體的進度控制中心。

它現在主要做的是：

- 把 scroll visible position 轉成 chapter char offset
- 把 restore 的 char offset 轉成 jump target
- 把 `saveProgress(...)` 導回 `ReaderProgressStore`

restore 流程的控制面現在是：

- target 狀態：`ReaderRestoreCoordinator`
- jump 語義：`ReaderNavigationController`
- 章內定位：`ReaderChapter.resolveRestoreTarget(...)`
- scroll retry：`ScrollRestoreRunner`
- 完成切換：`ReadBookController.completeRestoreTransition()`

這表示 restore 不再是 view、provider、mixin 各做一半，而是有比較清楚的責任鏈。

## 8. View Runtime 與 Delegate

外層視圖主入口在 [read_view_runtime.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/read_view_runtime.dart)。

它現在主要負責：

- 接收 provider/controller 狀態
- 建立 scroll 或 slide delegate
- 發起 restore / jump / TTS follow 執行
- 接收 raw visible positions
- 啟動 scroll auto-page ticker

它已經不再直接背整段 scroll 細節，相關職責已拆到：

- [scroll_execution_adapter.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/scroll_execution_adapter.dart)
  - scroll pixel / ensureVisible / page anchor 執行

- [scroll_restore_runner.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/scroll_restore_runner.dart)
  - scroll restore retry / reload / completion

delegate 分工也比較清楚：

- [scroll_mode_delegate.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/delegate/scroll_mode_delegate.dart)
  - scroll 內容渲染
- [slide_mode_delegate.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/delegate/slide_mode_delegate.dart)
  - slide 頁面渲染

## 9. Read Aloud / TTS

[read_aloud_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_aloud_controller.dart) 目前是實際朗讀流程的主控。

它現在負責：

- 建立 read aloud session
- TTS offset map
- progress -> chapter offset 映射
- highlight 同步
- next/prev page or chapter
- prefetch next chapter read-aloud session

它已經開始依賴 `ReaderChapter` 做：

- highlight range
- page start offset
- scroll anchor
- read aloud data 組裝

而不是自己到處掃 `TextPage.lines` 拼定位邏輯。

底層 TTS 播放仍由 [tts_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/tts_service.dart) 負責。

## 10. Auto Page

[reader_auto_page_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_auto_page_mixin.dart) 目前負責啟停與速度控制，但其核心 timer/state 已交給 [reader_auto_page_coordinator.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/reader_auto_page_coordinator.dart)。

目前模式差異：

- `slide`
  - page-based progress
- `scroll`
  - `ReadViewRuntime` ticker 驅動
  - 下一步 target 由 `ReaderNavigationController.evaluateScrollAutoPageStep(...)` 決定

這代表 auto page 的「決策」已開始內聚，但 scroll 模式的實際 ticker 仍在 view 層。

## 11. 測試現況

目前閱讀器已有一批直接保護 runtime 行為的測試：

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

這表示目前架構不再只能靠手測維持。

## 12. 性能觀測

[reader_perf_trace.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/reader_perf_trace.dart) 已經被接入幾個主路徑：

- `prime initial window`
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
