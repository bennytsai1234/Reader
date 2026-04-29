# Reader Current State

日期：2026-04-29

## 狀態

reader 的主要重構主幹已經落地。接下來不是再討論是否要做 scroll canvas window、PageCache 或 layout mapping，而是進入手機實測，根據實際手感、跨章穩定性、TTS 跟隨、恢復保存與效能表現繼續修 bug。

已完成主幹：

- `ReaderLocation(chapterIndex, charOffset, visualOffsetPx)` 作為 durable progress。
- chapter display text 作為 `charOffset` 真源，標題算進同一套 offset。
- `ChapterLayout` / `TextLine` / `LineLayout` 提供 layout 與座標查詢。
- `PageCache` 作為第一版 render tile。
- scroll 模式使用固定 viewport canvas、signed `_virtualScrollY`、previous/current/next chapter window。
- slide 模式使用同一份 PageCache / ReaderTileLayer。
- restore 不寫 DB，saveProgress 先 capture 目前 anchor。
- loading/error/placeholder 不產生正式閱讀位置。
- TTS highlight 使用整行 rect overlay，第一版不做 glyph-level highlight。
- 舊 runtime candidate/coordinator 與舊 runtime TTS engine 已清理；目前 runtime 目錄只保留主線會用到的 `ReaderRuntime`、session/exit/progress helper、viewport window、TTS highlight 支援。

## Reader Mainline

```text
ReaderPage
  -> ReaderDependencies
  -> ChapterRepository
  -> ReaderRuntime
  -> PageResolver / LayoutEngine
  -> EngineReaderScreen
  -> SlideReaderViewport / ScrollReaderViewport
```

主要檔案：

```text
lib/features/reader/reader_page.dart
lib/features/reader/controllers/reader_dependencies.dart
lib/features/reader/engine/chapter_repository.dart
lib/features/reader/engine/layout_engine.dart
lib/features/reader/engine/chapter_layout.dart
lib/features/reader/engine/line_layout.dart
lib/features/reader/engine/page_cache.dart
lib/features/reader/engine/reader_location.dart
lib/features/reader/runtime/reader_runtime.dart
lib/features/reader/viewport/reader_screen.dart
lib/features/reader/viewport/scroll_reader_viewport.dart
lib/features/reader/viewport/slide_reader_viewport.dart
lib/features/reader/viewport/reader_tile_layer.dart
lib/features/reader/viewport/tts_highlight_overlay_layer.dart
```

## Reader Folder Ownership

reader 目前放在 `lib/features/reader/`，因為它是一個完整產品功能，不是全 app 的底層核心。內部資料夾分工如下：

```text
lib/features/reader/
  reader_page.dart        reader feature 入口與頁面級 orchestration
  controllers/            ReaderPage 使用的 UI/controller 狀態
  engine/                 reader 專用的文字、layout、page、location 模型
  runtime/                閱讀 session 狀態、progress、preload、window helper
  viewport/               scroll/slide viewport、tile layer、painter、gesture/display
  widgets/                reader menu、shell、drawer、sheet 等 reader UI
  models/                 reader feature 內的小型資料模型或 enum
  settings/               reader 設定相關 UI/資料
  source/                 reader 換源或來源相關 feature glue
  debug/                  reader 除錯輔助
```

判斷規則：

- 放 `reader/engine`：它描述閱讀內容如何變成可定位、可分頁、可繪製的資料。例如 `ReaderLocation`、`ChapterLayout`、`PageCache`。
- 放 `reader/runtime`：它描述一本書打開後的閱讀 session 如何運作。例如 `ReaderRuntime`、`ReaderProgressController`、`PageWindow`。
- 放 `reader/viewport`：它真的負責畫面顯示與互動。例如 scroll canvas、slide viewport、tile painter、TTS highlight overlay。
- 放 `reader/controllers`：它是 `ReaderPage` 周邊的 UI 控制器，例如選單、設定、TTS、自動翻頁、書籤。
- 放 `core`：只有當這個東西離開 reader 仍然是整個 app 的底層能力，且不 import reader feature。

例子：

- `ReaderLocation` 放 `features/reader/engine`，因為它是 reader 的 durable coordinate，不是全 app 通用 model。
- `TTSService` 放 `core/services`，因為 settings、reader、全域 TTS 都可能用它。
- `ReaderTtsHighlight` 放 `features/reader/runtime/models`，因為它是 reader 畫面朗讀高亮用的 runtime 資料。
- `ReaderTtsSourcePreference` 放 `core/services`，因為它是 TTS 設定 key 的解析規則，不應讓 settings 依賴 reader runtime。

## Durable Progress

DB 與 runtime 保存的閱讀位置是：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

欄位語意：

- `chapterIndex`：目前章節。
- `charOffset`：最終 chapter display text 中的字元位置，標題也算進去。
- `visualOffsetPx`：anchor line 與該文字行 top 的垂直微調位移。

`visualOffsetPx` normalize 範圍：

```text
-80 <= visualOffsetPx <= 120
```

不保存為 durable progress 的資料：

```text
pageIndex
virtualTop
virtualLeft
pageSlot
virtualScrollY
scroll offset
```

## Layout / Coordinate Mapping

文字定位真源是：

```text
chapter display text
  -> TextLine
  -> ChapterLayout
  -> PageCache
```

`TextLine` 是 anchor、restore、TTS highlight 與可視位置計算的最小單位。Painter 只負責畫 `TextLine`，不負責決定閱讀位置。

已存在的查詢能力包含：

```text
charOffset -> TextLine
localY -> TextLine
charOffset -> TextPage/PageCache
range -> TextLine list / full-line rects
```

## PageCache / Render

第一版 render tile 是 `PageCache`。

```text
一頁 = 一個 PageCache
scroll = PageCache 上下拼
slide = PageCache 左右拼
```

第一版不做 ImageCache。`ReaderTileLayer` / `ReaderTilePainter` 直接根據 `PageCache.lines` 畫正文。ImageCache 只保留為未來效能優化方向，不是目前必要模型。

## Scroll Canvas Window

scroll 模式已使用固定 viewport canvas，不再把 ListView 的章節高度當作 scroll 真源。

核心模型：

```text
viewport = 固定玻璃
PageCache window = 玻璃後面的頁面帶
virtualScrollY = 目前看向頁面帶的位置，可正可負
screenY = page.virtualTop - virtualScrollY
```

目前 window 保留：

```text
previous chapter
current chapter
next chapter
```

滑動中會更新 runtime visible location cache，但不寫 DB。scroll idle、app lifecycle pause/exit/dispose、mode switch settled 才保存進度。

## Slide Viewport

slide 模式也透過 `PageCache` 和 `ReaderTileLayer` 畫頁面。page mode 只影響 viewport placement，不應讓 layout cache key 產生另一套 layout truth。

placeholder page 不能被正式 settle，也不能產生正式閱讀位置。

## Overlay / Gesture

目前分層：

```text
Background
ReaderTileLayer / ReaderTilePainter
TtsHighlightOverlayLayer
ReaderGestureLayer
ReaderPageShell overlays
```

第一版不支援文字選取，不做 glyph-level hit test，不做 copy menu 或 selection handles。

TTS highlight 使用整行或多行 rect，overlay 不改底層正文 tile。

## 已驗證測試

和這次 reader 主幹最相關的測試：

```bash
flutter test test/features/reader/page_cache_test.dart test/features/reader/line_layout_test.dart test/features/reader/reader_tile_viewport_test.dart
```

目前結果：

```text
28 tests passed
```

完整 reader 回歸可跑：

```bash
flutter test test/features/reader
flutter analyze
```

## 下一步

進入手機實測與體感 bug 修復。測試流程見 [reader_mobile_test_plan.md](reader_mobile_test_plan.md)。
