# Reader Implementation Order

日期：2026-04-28

## 目的

這份文件給後續接手的 agent / developer 使用。

目標是按照依賴順序實作 reader 修復設計，避免先做 UI 或 viewport，最後才發現底層位置模型、layout mapping、PageCache 還沒準備好。

總覽文件：

```text
docs/reader_repair_plan.md
```

設計文件：

```text
docs/reader_visible_location_design.md
docs/reader_restore_design.md
docs/reader_overlay_gesture_design.md
docs/reader_page_cache_render_design.md
docs/reader_scroll_canvas_window_design.md
docs/reader_layout_coordinate_design.md
```

## 使用 Sub Agent

可以使用 sub agent 並行處理，但必須尊重依賴。

適合並行的工作：

```text
單元測試補齊
DB / storage 欄位更新
文檔與實作差異檢查
TTS overlay prototype
既有九宮格 / menu 行為確認
舊 scroll viewport 移除影響分析
```

不適合太早並行的工作：

```text
ScrollCanvasWindow
Restore
captureVisibleLocation()
saveProgress()
Slide/scroll mode switch
```

原因是這些都依賴同一套：

```text
ReaderLocation
ChapterLayout
TextLine
PageCache
coordinate mapping
```

如果底層還沒定好，並行做 viewport 很容易寫出多套位置算法。

## 總順序

推薦順序：

```text
0. 總覽與範圍確認
1. ReaderLocation / DB / Progress storage
2. Layout / Coordinate Mapping
3. PageCache Render Model
4. Visible Location / Progress Interfaces
5. Scroll Canvas Window
6. Restore
7. Slide 共用 PageCache
8. Overlay / Gesture
9. TTS / Auto Page viewport interfaces
10. Integration validation
```

## 0. 總覽與範圍確認

先讀：

```text
docs/reader_repair_plan.md
```

確認本次實作範圍：

```text
目前 reader 視為全新 app baseline。
不以舊 DB migration 作阻塞。
不回退到 reader-0.2.28。
第一版不做文字選取。
第一版不做 ImageCache。
第一版 scroll canvas 不用 ListView child 作 scroll 真源。
```

## 1. ReaderLocation / DB / Progress Storage

來源文件：

```text
docs/reader_visible_location_design.md
docs/reader_repair_plan.md
```

要做：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
visualOffsetPx normalize: -80 <= value <= 120
NaN / infinite -> 0
Book / DB / storage 保存 visualOffsetPx
progress store 支援三元位置
copyWith / equality / hashCode / serialization 全部包含 visualOffsetPx
```

這一步必須先做。

原因：

```text
後面 layout、restore、saveProgress、mode switch 都依賴三元 ReaderLocation。
```

可並行：

```text
DB/storage 欄位更新
ReaderLocation tests
Progress store tests
```

不可跳過。

## 2. Layout / Coordinate Mapping

來源文件：

```text
docs/reader_layout_coordinate_design.md
```

要做：

```text
chapter display text 作為 offset 真源
標題算進 charOffset
TextLine 欄位補齊
ChapterLayout 補齊 lines / pages / contentHeight / layoutSignature
PageCache grouping 按 viewportHeight 分頁
scroll / slide 共用同一份 ChapterLayout / TextLine / PageCache
```

必要查詢：

```text
lineForCharOffset
lineAtOrNearLocalY
pageForCharOffset
pageForLocalY
linesForRange
fullLineRectsForRange
```

這一步必須在 scroll canvas、restore、TTS highlight 前完成。

可並行：

```text
chapter display text / content pipeline 檢查
TextLine invariant tests
range -> line tests
page grouping tests
```

不要在這一步做 viewport UI。

## 3. PageCache Render Model

來源文件：

```text
docs/reader_page_cache_render_design.md
```

要做：

```text
使用 PageCache 作為第一版 RenderTile 模型
一頁 = 一個可繪製快取單位
PageCache 直接畫 TextLine
第一版不做 ImageCache
scroll / slide 共用同一份 PageCache
placement 與 page data 分離
```

Page 欄位：

```text
chapterIndex
pageIndexInChapter
startCharOffset
endCharOffset
localStartY
localEndY
width
height
lines
```

Placement：

```text
scroll: virtualTop
slide: virtualLeft / pageSlot
```

這一步依賴第 2 步。

可並行：

```text
PageCache data model
Page painter using TextLine
Page grouping tests
```

不要實作 ImageCache。文檔只把 ImageCache 留作未來效能優化。

## 4. Visible Location / Progress Interfaces

來源文件：

```text
docs/reader_visible_location_design.md
```

公開入口：

```dart
ReaderLocation? captureVisibleLocation();

Future<ReaderLocation?> saveProgress();
```

要做：

```text
captureVisibleLocation() 從 active viewport capture anchor。
capture 成功後更新 runtime.visibleLocation。
capture 失敗回 null。
saveProgress() 內部先呼叫 captureVisibleLocation()。
saveProgress() 成功後推進 visibleLocation -> committedLocation -> DB progress。
saveProgress() 不接受 reason 參數。
```

不能做：

```text
不能讓 viewport 直接寫 DB。
不能讓 loading/error/placeholder 產生 ReaderLocation。
不能在滑動中頻繁寫 DB。
```

這一步依賴第 1、2、3 步。

可並行：

```text
runtime state 更新
progress write coalescing
capture failure tests
placeholder 不保存 tests
```

## 5. Scroll Canvas Window

來源文件：

```text
docs/reader_scroll_canvas_window_design.md
```

要做：

```text
固定 viewport canvas
signed virtualScrollY，允許正負
previous/current/next 三章 PageCache window
page.virtualTop placement
drag / pan 更新 virtualScrollY
fling / inertia
滑動中 captureVisibleLocation() 更新 visibleLocation cache
window shift 不等 scroll idle
scroll idle 才 saveProgress()
not ready page 不能滑進去
```

核心公式：

```text
screenY = page.virtualTop - virtualScrollY
anchorVirtualY = virtualScrollY + anchorLineY
visualOffsetPx = anchorLineY - lineTopOnScreen
```

這一步依賴第 1、2、3、4 步。

可並行：

```text
gesture drag/fling controller
PageCache window data structure
ready/not-ready boundary tests
```

但同一時間只能有一套位置算法。不要在 viewport 裡另外發明 progress mapping。

## 6. Restore

來源文件：

```text
docs/reader_restore_design.md
```

要做：

```text
restoreFromLocation(ReaderLocation location)
restore 期間不寫 DB
restore 成功後也不寫 DB
restore 成功後只更新 runtime.visibleLocation
restore 建立 previous/current/next 三章 PageCache window
scroll restore 設定 virtualScrollY
slide restore 找目標 page
restore final captureVisibleLocation()
```

scroll restore 公式：

```text
virtualScrollY = lineVirtualTop + visualOffsetPx - anchorLineY
```

這一步依賴第 5 步。

可並行：

```text
restore normalize tests
restore 不寫 DB tests
missing line fallback tests
```

## 7. Slide 共用 PageCache

來源文件：

```text
docs/reader_page_cache_render_design.md
docs/reader_layout_coordinate_design.md
docs/reader_restore_design.md
```

要做：

```text
slide 不重新 layout 一套 page
slide 使用同一份 PageCache
slide placement 使用 virtualLeft / pageSlot
slide restore 使用 ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
scroll -> slide 保留完整三元位置
slide -> scroll 保留完整三元位置
```

這一步依賴第 2、3、6 步。

可並行：

```text
mode switch tests
slide restore page fallback tests
```

## 8. Overlay / Gesture

來源文件：

```text
docs/reader_overlay_gesture_design.md
```

要做：

```text
TTSHighlightOverlayLayer
GestureLayer
ReaderPageShell existing overlays 沿用現有
```

TTS highlight 第一版：

```text
TTS 提供 chapterIndex / highlightStart / highlightEnd
layout 查 linesForRange
Overlay 畫整行 rect / shadow / blur
不做逐字高亮
```

GestureLayer 第一版：

```text
controlsVisible == true -> 交給 ReaderPageShell
drag / pan -> scroll canvas
tap -> 既有 onContentTapUp / 九宮格
long press -> no-op
```

這一步依賴第 5 步，TTS highlight 依賴第 2 步。

可並行：

```text
TTS overlay painter
GestureLayer tap routing
既有九宮格 regression tests
```

## 9. TTS / Auto Page Viewport Interfaces

來源文件：

```text
docs/reader_overlay_gesture_design.md
docs/reader_scroll_canvas_window_design.md
```

建議接口：

```dart
Future<bool> scrollBy(double delta);

Future<bool> animateBy(double delta);

Future<bool> ensureCharRangeVisible({
  required int chapterIndex,
  required int startCharOffset,
  required int endCharOffset,
});
```

要做：

```text
Auto page 呼叫 scrollBy / animateBy。
TTS follow 呼叫 ensureCharRangeVisible。
viewport 確認目標 page ready。
not ready 時停住、等待或回 false。
TTSHighlightOverlayLayer 只畫高亮，不控制 scroll。
```

這一步依賴第 5、8 步。

可並行：

```text
auto page controller adapter
TTS follow adapter
not ready behavior tests
```

## 10. Integration Validation

最後按 `reader_repair_plan.md` 驗收。

必要場景：

```text
scroll 到章節中段，退出再進，視覺位置接近退出前
scroll 往下跨章，window 即時 shift
scroll 往上跨章，signed virtualScrollY 可為負
scroll idle 後保存 DB
滑動中只更新 visibleLocation cache，不寫 DB
app paused / exit / dispose 立即 saveProgress
restore 不寫 DB
slide/scroll 切換不丟 visualOffsetPx
改字級 / 旋轉後用 visibleLocation restore
TTS 整行高亮不重建正文 tile
loading / error / placeholder 不保存
```

建議補測：

```text
capture -> restore -> capture invariants
visualOffsetPx 正負值
title line 作為 anchor
range highlight 跨多行
not ready page 邊界
```

## 重要提醒

不要保存：

```text
pageIndex
virtualTop
virtualLeft
virtualScrollY
pageSlot
```

只保存：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

不要在以下位置寫 DB：

```text
restore
滑動中
loading/error/placeholder
layout invalidation
```

可以更新 runtime memory cache：

```text
visibleLocation
```

但 DB 寫入只走：

```text
saveProgress()
```

