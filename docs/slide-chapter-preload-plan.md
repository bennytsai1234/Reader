# Slide 章節預載現況

更新日期：2026-04-20

這份文檔不再描述舊的階段性計劃，而是描述目前 `reader` 在 slide 模式下的章節預載機制現況。

## 一句話結論

現在的 slide 模式不是單靠 `PageView` 翻頁，而是依賴：

- `ReaderContentFacadeMixin`
- `ChapterContentManager`
- `SlideWindow`
- `ReadBookController` 的邊界預抓

共同維持「相鄰章節應盡量在使用者滑到邊界前完成分頁」。

## 現在可以直接確認的事

### 1. slide 模式有固定 warmup radius

從 [reader_content_facade_mixin.dart](/home/benny/projects/reader/lib/features/reader/provider/reader_content_facade_mixin.dart:122) 可以直接看到：

- `_defaultSlideWarmupRadius => 2`

這表示目前 slide 模式的預熱預設不是只看相鄰一章。

### 2. `ChapterContentManager` 仍保有 whole-book preload

從 [chapter_content_manager.dart](/home/benny/projects/reader/lib/features/reader/engine/chapter_content_manager.dart:263) 可以直接確認：

- `enableWholeBookPreload()` 還在
- `_wholeBookPreloadEnabled` 仍是正式狀態位

這意味著：

- 全書背景預載不是歷史假設，而是現存能力
- 但是否在產品流程中主動啟用，要看呼叫端

### 3. 閱讀器仍會在 slide 邊界提早預抓鄰近章節

從 [read_book_controller.dart](/home/benny/projects/reader/lib/features/reader/runtime/read_book_controller.dart:641) 可直接看到：

- `_prefetchSlideNeighborIfNearBoundary(...)`

這代表：

- 預抓並不是只在開書初始化時做
- 使用者翻頁過程中也會在接近章節邊界時主動推高預載優先級

### 4. deferred warmup 仍存在

從 [reader_content_facade_mixin.dart](/home/benny/projects/reader/lib/features/reader/provider/reader_content_facade_mixin.dart:442) 可直接看到：

- `scheduleDeferredWindowWarmup(...)`

這表示預載流程仍是分階段的：

- 先確保當前章節
- 再把附近章節陸續拉進背景分頁

## 現在的實際限制

雖然預載機制已存在，但不能把它寫成「完全無等待」。

仍然會遇到的限制：

1. 網路書源慢時，預載仍受下載時間限制。
2. 本地書章節如果很大，分頁仍有 CPU 成本。
3. `slidePages` 只反映目前已建好的頁面結果，所以預載沒完成前，章節邊界仍可能出現等待感。
4. 預載、cache、驅逐邏輯都在同一個內容生命週期系統裡，調整一個點容易連動其他行為。

## 與 legado 的對照

### 相似處

- 都不是單純翻到邊界才開始處理下一章
- 都有章節預熱與分頁快取概念
- 都把閱讀器流暢度建立在內容生命周期管理上

### 不同處

- `reader` 把 preload 相關責任放在 runtime/content manager
- `legado` 的閱讀器更多依附在 Android page provider / read view 鏈
- `reader` 的 preload 行為更容易被單元測試直接保護

## 現在最值得注意的不是「再寫新計劃」

目前更重要的是：

- 釐清 whole-book preload 在產品上什麼時候該開
- 釐清 cache / preload / evict 的責任邊界
- 確認 scroll 與 slide 兩套模式不會互相污染內容生命週期

## 結論

這條線目前應被視為：

- 已有正式實作
- 不是純設計稿
- 但還屬於閱讀器 runtime 收尾的一部分，不應誇大成完全完成
