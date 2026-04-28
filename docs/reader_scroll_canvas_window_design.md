# Reader Scroll Canvas Window Design

日期：2026-04-28

## 目的

這份文件定義 scroll 模式的 canvas window、PageCache window、signed `virtualScrollY`、滑動中位置 cache，以及保存時機。

## 核心定案

```text
scroll 模式不使用 ListView chapter children 作為 scroll 真源。
scroll 模式使用固定 viewport canvas。
scroll 模式自己管理 signed virtualScrollY，允許正負。
scroll 模式使用 PageCache window。
第一版 PageCache window 以章節為單位：previous / current / next。
滑動中更新 visibleLocation cache，不寫 DB。
scroll idle 才 saveProgress() 寫 DB。
```

## 白話模型

```text
viewport = 一塊固定大小的玻璃
PageCache window = 玻璃後面目前已準備好的頁面帶
page = 一張可繪製的頁
virtualScrollY = 玻璃目前看著頁面帶的哪個位置
```

畫 page 時：

```text
screenY = page.virtualTop - virtualScrollY
```

`virtualTop` 是 page 在虛擬垂直內容帶上的位置。

`virtualScrollY` 是目前 viewport 看向虛擬內容帶的位置。

兩者相減，就知道 page 要畫在螢幕哪裡。

## signed virtualScrollY

`virtualScrollY` 可以是正數，也可以是負數。

原因：

```text
使用者可能從第 100 章開始閱讀。
目前章可以放在 virtualY 0 附近。
下一章在正方向。
上一章在負方向。
```

所以：

```text
往下滑 -> virtualScrollY 增加。
往上滑 -> virtualScrollY 減少，可以小於 0。
```

第一版不做原點重定位。

`virtualScrollY` 不保存到 DB。退出後下次開書用 `ReaderLocation` 重新建立 window。

## PageCache window

第一版 window 以章節為單位。

正常情況保留：

```text
previous chapter pages
current chapter pages
next chapter pages
```

也就是：

```text
currentChapterIndex - 1
currentChapterIndex
currentChapterIndex + 1
```

這三章都使用同一套 PageCache 模型。

## 為什麼以章節為單位

以章節為單位比只保留上下幾頁更適合 reader 第一版。

原因：

```text
上下滑動時，不容易馬上碰到 not ready page。
不用頻繁重新從 DB / content store 載入附近頁。
第一版不做 ImageCache，PageCache 只是 TextLine/page data，三章記憶體可接受。
邏輯比頁級 evict 簡單。
```

未來如果遇到超長章節記憶體問題，再考慮章內 page window。

第一版不做章內 page window。

## window placement

目前章可以放在 virtualY 0 附近。

例如 current chapter 有三頁：

```text
current p0 virtualTop = 0
current p1 virtualTop = viewportHeight
current p2 virtualTop = viewportHeight * 2
```

上一章接在目前章上方：

```text
previous last page virtualTop = -viewportHeight
previous page before last virtualTop = -viewportHeight * 2
```

下一章接在目前章下方：

```text
next p0 virtualTop = currentChapterHeight
next p1 virtualTop = currentChapterHeight + viewportHeight
```

實作不要求一定以 current p0 為 0，但必須滿足：

```text
window pages 上下連續排列。
page.virtualTop 可以是負數。
page.height 必須是 finite 且 > 0。
```

## window preload / shift

window shift 不能等 scroll idle。

滑動中就要維護 PageCache window，否則快速滑動時會滑到 ready window 底部。

滑動中要做：

```text
更新 virtualScrollY。
capture anchor。
更新 visibleLocation cache。
根據 anchor 所在章節 preload / shift window。
```

不做：

```text
不 saveProgress()。
不寫 DB。
```

## anchor 進入鄰章時

當 anchor line 進入 next chapter 或 previous chapter 後，window 可以即時 shift。

往下：

```text
current = next
舊 current -> previous
舊 next -> current
開始載入新的 next
```

往上：

```text
current = previous
舊 current -> next
舊 previous -> current
開始載入新的 previous
```

為了避免章節邊界抖動，切換可以加小門檻：

```text
anchor 必須進入鄰章一小段距離後才 shift。
```

建議第一版門檻：

```text
threshold = min(120px, viewportHeight * 0.2)
```

這個門檻只影響 window/current chapter 切換，不影響保存。

## ready / not ready

window 只允許 ready pages 進入可滾動範圍。

ready 的意思：

```text
content ready
layout ready
PageCache ready
```

not ready 時：

```text
不能滑進 placeholder。
不能用 placeholder capture anchor。
不能用 placeholder saveProgress。
```

如果使用者滑到 ready window 邊界：

```text
下一章/上一章 ready -> 繼續滑。
下一章/上一章 not ready -> 停住或顯示邊界 loading。
```

第一版不做 estimated height，也不做高度補償。

## 滑動中位置更新

滑動中可以更新 runtime memory cache：

```text
captureVisibleLocation()
 -> runtime.visibleLocation
```

這個更新不用 DB，也不用 `saveProgress()`。

用途：

```text
目前章節 UI
TOC 高亮
PageCache window shift
TTS follow 的目前位置判斷
mode switch 前的位置基準
```

滑動中更新可以節流，例如：

```text
anchor chapter/page 改變時
靠近 window 邊界時
每 100ms 左右
```

具體節流策略可以留給實作，但不能在滑動中頻繁寫 DB。

## saveProgress 時機

正常滑動時：

```text
dragging -> 不寫 DB
fling / inertia -> 不寫 DB
scroll idle -> saveProgress()
```

`scroll idle` 的意思：

```text
手指已離開。
慣性滑動已結束。
virtualScrollY 不再變。
畫面 settled。
```

例外情況：

```text
app paused
exit
dispose
mode switch
```

這些情況即使還沒 idle，也要立即呼叫：

```text
saveProgress()
```

## capture 和保存

滑動中：

```text
captureVisibleLocation()
 -> 更新 visibleLocation cache
 -> preload / shift window
 -> 不寫 DB
```

停下來：

```text
saveProgress()
 -> 內部 captureVisibleLocation()
 -> visibleLocation
 -> committedLocation
 -> DB progress
```

保存一定吃 `captureVisibleLocation()` 的結果，不能另寫一套位置算法。

## anchor capture 公式

scroll canvas 中：

```text
anchorVirtualY = virtualScrollY + anchorLineY
```

流程：

```text
1. 用 anchorVirtualY 找 page。
2. 用 page 找 chapter。
3. 換算 chapterLocalY。
4. lineAtOrNearLocalY(chapterLocalY) 找 TextLine。
5. charOffset = selectedLine.startCharOffset。
6. lineTopOnScreen = lineVirtualTop - virtualScrollY。
7. visualOffsetPx = anchorLineY - lineTopOnScreen。
```

最後得到：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

## restore

restore 到某個 `ReaderLocation`：

```text
1. 載入 target chapter。
2. 建立 previous / current / next 三章 PageCache window。
3. 用 charOffset 找 TextLine。
4. 用 TextLine 找 page。
5. 設定 page virtualTop。
6. 計算 virtualScrollY。
```

公式：

```text
virtualScrollY = lineVirtualTop + visualOffsetPx - anchorLineY
```

restore 成功後：

```text
final captureVisibleLocation()
更新 runtime.visibleLocation
不 saveProgress()
不寫 DB
```

## Auto Page

Auto page 不直接操作 DB，也不直接操作 PageCache。

Auto page 呼叫 viewport：

```text
scrollBy(delta)
animateBy(delta)
```

viewport 負責：

```text
更新 virtualScrollY
確保目標方向 page ready
碰到 not ready 邊界時停住或回報 false
scroll idle 後保存
```

## TTS follow

TTS follow 呼叫 viewport：

```text
ensureCharRangeVisible(chapterIndex, highlightStart, highlightEnd)
```

viewport 使用 PageCache / TextLine 找到該 range 的行。

如果目標 page ready：

```text
調整 virtualScrollY 讓 highlight range 進入 viewport。
```

如果目標 page not ready：

```text
等待 page ready
或不跟隨
或回報 false
```

TTS highlight overlay 只畫高亮，不負責 window shift 或保存。

## 不做

第一版不做：

```text
ListView chapter children 作為 scroll 真源
estimated height
高度補償
page placeholder 保存
ImageCache
章內 page window eviction
virtualScrollY 持久化
原點重定位
```

