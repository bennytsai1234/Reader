# 閱讀器架構現況

更新日期：2026-04-20

這份文檔只描述目前 `features/reader` 真的存在的結構，並和 `legado` 的閱讀器做手動對照。

## 一句話結論

`reader` 的閱讀器現在是一個以 `ReadBookController` 為中心的 runtime 子系統。

它不是單純的頁面 provider，也不是 `legado` 式的單一 activity 巨型控制器。它的實際切法是：

- provider/mixin：接線與歷史相容層
- runtime：命令、restore、progress、session、chapter 語義
- engine：內容載入、分頁、preload、page model
- view：scroll/slide delegate 與執行器

## 入口與主控

外部入口：

- [reader_provider.dart](/home/benny/projects/reader/lib/features/reader/reader_provider.dart:1)
- [reader_page.dart](/home/benny/projects/reader/lib/features/reader/reader_page.dart:1)

真正主控：

- [read_book_controller.dart](/home/benny/projects/reader/lib/features/reader/runtime/read_book_controller.dart:1)

目前 `ReaderProvider` 只是 `ReadBookController` 的薄封裝。這表示：

- 真正的閱讀器狀態已不在一般 feature provider
- `ReadBookController` 才是閱讀期真源

## 繼承鏈與 mixin

目前鏈路是：

```text
ReaderProviderBase
  -> ReaderSettingsMixin
  -> ReaderContentFacadeMixin
  -> ReaderAutoPageMixin
  -> ReaderTtsMixin
  -> ReaderBatteryMixin
  -> ReadBookController
```

這個形狀很重要，因為它說明了兩件事：

1. 閱讀器確實已經往 runtime 子系統方向移動。
2. 但 mixin 時代的歷史介面還沒有完全退出。

## runtime 子域

`features/reader/runtime/` 現在已經不是輔助資料夾，而是整個閱讀器內核。

目前可以直接點名的子域有：

- `ReaderNavigationController`
- `ReaderRestoreCoordinator`
- `ReaderProgressStore`
- `ReaderProgressCoordinator`
- `ReaderScrollVisibilityCoordinator`
- `ReaderDisplayCoordinator`
- `ReaderSessionCoordinator`
- `ReadViewRuntimeCoordinator`
- `ReadAloudController`
- `ReaderPositionResolver`
- `ReaderPageFactory`
- `ReaderChapterProvider`
- `ReaderCommandGuard`
- `ReaderAutoPageCoordinator`
- `ReaderTtsFollowCoordinator`

這表示 `reader` 的閱讀器已經有明確拆分：

- 命令優先級
- restore token
- durable progress
- visible tracking
- 顯示投影
- TTS 跟隨

## 章內語義

`ReaderChapter` 是 runtime 的核心模型之一。

它統一承擔：

- `charOffset <-> pageIndex`
- `charOffset <-> localOffset`
- restore target
- highlight range
- TTS data
- scroll anchor

這是 `reader` 相對 `legado` 的一個結構優勢：

- `legado` 的閱讀器能力更完整，但章內定位語義更多散在 activity、page provider、read view 鏈上
- `reader` 比較明確地把章內語義壓到 runtime model

## 內容生命週期

內容生命週期主體在：

- [reader_content_facade_mixin.dart](/home/benny/projects/reader/lib/features/reader/provider/reader_content_facade_mixin.dart:1)
- [chapter_content_manager.dart](/home/benny/projects/reader/lib/features/reader/engine/chapter_content_manager.dart:1)

`ChapterContentManager` 目前做的事情：

- 正文抓取
- 主動載入與靜默預載去重
- cache 與 runtime 分頁快取管理
- preload queue
- whole-book preload 切換
- window 內外驅逐

可驗證的現況：

- `wholeBookPreloadEnabled` 仍存在
- slide 模式確實有邊界預抓與 deferred warmup
- preload 行為不是單純 page view 自己做，而是 content manager 主導

## view 層

view 層主要在 `features/reader/view/`。

核心檔：

- `read_view_runtime.dart`
- `delegate/scroll_mode_delegate.dart`
- `delegate/page_mode_delegate.dart`
- `scroll_execution_adapter.dart`
- `scroll_restore_runner.dart`
- `scroll_runtime_executor.dart`

目前 UI 上只有兩種正式模式：

- slide
- scroll

`PageAnim` 類別雖然還保留其他值做相容，但目前沒有完整對應更多閱讀模式。

## TTS 與自動翻頁

目前 TTS 主線是：

- runtime 內的 `ReadAloudController`
- 全域 `TTSService`
- `ReaderTtsMixin`
- `ReaderTtsFollowCoordinator`

auto page 則是：

- `ReaderAutoPageMixin`
- `reader_auto_page_coordinator.dart`
- scroll 模式由 `ReadViewRuntime` 執行器驅動

和 `legado` 對照：

- `legado` 的朗讀與閱讀設定 dialog 更完整，Android 系統整合也更多
- `reader` 已把 TTS 跟讀與翻頁核心邏輯拆得更可測，但產品收尾還沒做完

## restore 與 durable progress

`reader` 現在最穩的一塊之一是 restore/progress 鏈。

主鏈條：

1. `ReaderRestoreCoordinator` 保存 pending restore target
2. `ReaderNavigationController` 產生命令語義
3. `ReaderPositionResolver` 把 durable location 轉成 slide/scroll target
4. `ReaderProgressCoordinator` 處理 visible position 與 debounce save
5. `ReaderProgressStore` 落回 `Book.durChapterIndex` / `durChapterPos`

這一塊有大量測試保護，這也是目前 `reader` 相比 `legado` 更可推理的區域。

## 正文失敗與換源

目前換源機制已接入閱讀器主鏈，但要準確描述它：

- 它主要是閱讀期恢復機制
- 不是來源健康系統的替代品
- 目前仍偏向正文失敗後補救

實際表現：

- 章節抓取失敗可顯示恢復卡片
- 可自動換源
- 可手動開換源面板
- 會盡量保留閱讀進度

和 `legado` 對照：

- `legado` 也有換源與換章來源能力
- `reader` 已把這條鏈接到 runtime
- 但目前還沒把恢復前移到詳情失敗、目錄失敗與更主動的 source scoring

## 與 legado 的手動對照

### 已明顯對齊的地方

- 閱讀頁是獨立產品主線，不是附屬頁
- 有 slide / scroll 兩種正式模式
- 有 TTS、自動翻頁、章節切換、書籤、替換規則入口
- 有章節預載與內容快取

### `reader` 比較好的地方

- runtime 拆分清楚
- restore / progress / navigation / TTS 有明確 coordinator
- 測試覆蓋比 Android activity 流更集中

### `reader` 仍落後的地方

- mixin 殘留仍多
- `ReadBookController` 還是偏大
- 閱讀器周邊工具能力不如 `legado` 完整
- 某些 UI 收尾還不夠乾淨
- Android 專屬交互與系統整合遠不如 `legado`

## 目前可以明說的限制

1. `ReadBookController` 仍是大物件。
2. `ReaderContentFacadeMixin` 仍是 facade 入口，但主要 lifecycle 已下沉到 `ReaderContentRuntimeOwner`。
3. 閱讀器頁面還有舊 API 與交互細節待收尾，例如返回處理仍用 `WillPopScope`。
4. TTS / auto-page 雖已可用，但不是全產品層面完全收口。
5. 部分殘留 widget 仍存在未接線或半成品狀態。

## 結論

最準確的描述不是「Flutter 版 `ReadBookActivity`」，而是：

> `reader` 已經把閱讀器做成可測試的 runtime 子系統，但產品收尾與周邊能力仍未完全達到 `legado` 的成熟度。
