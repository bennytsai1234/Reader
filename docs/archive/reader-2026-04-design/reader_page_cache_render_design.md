# Reader Page Cache Render Design

日期：2026-04-28

## 目的

這份文件定義第一版 reader 的 RenderTile 模型。

定案：

```text
第一版使用 PageCache 作為 RenderTile 模型。
一頁 = 一個可繪製快取單位。
scroll 模式把 pages 上下拼接。
slide 模式把 pages 左右拼接。
第一版不做 ImageCache。
PageCache 直接畫 TextLine。
ImageCache 只作為未來效能優化。
PageCache 不作為 DB 進度。
```

## 核心邊界

PageCache 不是文字真源。

文字真源是：

```text
chapter display text
ChapterLayout
TextLine
```

PageCache 只是把同一份 `TextLine` 分成一頁一頁，方便 scroll 和 slide 繪製。

PageCache 不是進度真源。

DB 只保存：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

DB 不保存：

```text
pageIndex
virtualTop
virtualLeft
pageSlot
```

## PageCache 欄位

第一版 page 欄位建議：

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

### chapterIndex

這頁屬於第幾章。

用途：

```text
定位章節
anchor capture
restore
TTS highlight
debug
```

### pageIndexInChapter

這頁是該章裡的第幾頁。

用途：

```text
runtime/render 查找
slide 顯示當前頁
debug
```

`pageIndexInChapter` 不是 durable progress，不寫 DB。

### startCharOffset

這頁第一個文字行在 chapter display text 裡的起始 offset。

用途：

```text
知道這頁起點
判斷 charOffset 是否落在這頁
restore 時找 page
TTS highlight range 相交判斷
debug
```

### endCharOffset

這頁最後覆蓋到的 chapter display text offset。

用途：

```text
知道這頁結尾
判斷 charOffset 是否落在這頁
TTS highlight range 相交判斷
debug
```

### localStartY

這頁在章節連續排版座標裡從哪個 y 開始。

白話：

```text
這頁在本章裡是從高度多少開始切出來的。
```

### localEndY

這頁在章節連續排版座標裡到哪個 y 結束。

用途：

```text
判斷 line/localY 是否在這頁
scroll 上下拼接時計算位置
restore 時計算 page 與 line 的關係
```

### width

這頁的繪製寬度。

第一版通常等於 viewport width。

### height

這頁的繪製高度。

第一版通常等於 viewport height。

### lines

這頁要畫的 `TextLine`。

第一版沒有 ImageCache，所以 `RenderTileCanvasLayer` 直接使用 `lines` 畫文字：

```text
for line in page.lines:
  draw line.text
```

## Placement 欄位

Page 本身只描述「這頁是誰、包含哪些文字、章內 y 範圍是多少」。

scroll / slide 還需要描述「這頁在目前 viewport window 裡放在哪裡」。

因此 placement 和 page data 分開。

### Scroll placement

scroll 使用：

```text
virtualTop
```

`virtualTop` 表示這頁貼在虛擬垂直內容帶上的 y 位置。

畫到螢幕時：

```text
screenY = virtualTop - virtualScrollY
```

白話：

```text
virtualTop 是這頁在長條內容裡的位置。
virtualScrollY 是目前螢幕看向長條內容的位置。
兩者相減，就知道這頁要畫在螢幕哪裡。
```

`virtualTop` 可以是負數，因為 scroll canvas 使用 signed virtual coordinate。

### Slide placement

slide 可以使用：

```text
virtualLeft
pageSlot
```

`virtualLeft` 表示這頁貼在水平翻頁帶上的 x 位置。

畫到螢幕時：

```text
screenX = virtualLeft - pageOffsetX
```

`pageSlot` 表示目前 slide window 裡的位置，例如：

```text
-1 = previous
 0 = current
 1 = next
```

slide placement 只用於 runtime/render，不寫 DB。

## scroll page 怎麼切

第一版 scroll page 直接使用 PageCache。

切法：

```text
1. content 處理完成，得到 chapter display text。
2. layout engine 排出 ChapterLayout.lines。
3. 按 viewportHeight 把 lines 分成 pages。
4. 每個 page 高度約等於 viewportHeight。
5. scroll 模式把 pages 依 virtualTop 上下拼接。
```

不要用「一頁幾個字」去猜 page。

原因：

```text
字級、行距、標題、段距、標點、段落都會影響實際高度。
先 layout 出 TextLine，再按高度分 page 才穩。
```

## slide page 怎麼切

第一版 slide page 也使用同一份 PageCache。

切法：

```text
1. 使用同一份 ChapterLayout.lines。
2. 使用同一份 page grouping。
3. slide 模式把 pages 依 virtualLeft / pageSlot 左右拼接。
```

不能讓 slide 重新切一套 page。

原因：

```text
scroll 和 slide 如果各自切 page，charOffset 和 line 落點容易漂移。
```

## scroll / slide 共用範圍

共用：

```text
chapter display text
ChapterLayout
TextLine
PageCache
startCharOffset / endCharOffset
localStartY / localEndY
```

不同：

```text
scroll 使用 virtualTop / virtualScrollY。
slide 使用 virtualLeft / pageOffsetX 或 pageSlot。
```

白話：

```text
同一批排版好的文字行，
scroll 把 pages 上下接起來，
slide 把 pages 左右接起來。
```

## ready / not ready

只有 layout ready 的 page 可以進入 scroll / slide window。

如果下一頁或上一頁 not ready：

```text
不能滑進 placeholder。
不能用 placeholder 產生 ReaderLocation。
不能用 placeholder 保存進度。
```

scroll 到 ready window 邊界時：

```text
停住
或顯示邊界 loading
或等待 page ready 後再繼續
```

第一版不做 estimated height，也不做高度補償。

## ImageCache

第一版不做 ImageCache。

也就是第一版繪製方式是：

```text
PageCache -> TextLine -> canvas draw text
```

未來如果效能需要，可以新增：

```text
PageImageCache
```

未來 ImageCache 只能作為效能優化：

```text
if page image ready:
  drawImage(page image)
else:
  draw TextLine
```

即使未來有 ImageCache，定位、anchor、restore、TTS highlight 仍然使用：

```text
ChapterLayout
TextLine
PageCache
```

不能從 image 反推文字位置。

## 和其他系統的關係

### anchor capture

anchor capture 使用 PageCache 找到 visible page，再使用 `TextLine` 找 anchor line。

保存：

```text
charOffset = selectedLine.startCharOffset
visualOffsetPx = anchorLineY - lineTopOnScreen
```

### restore

restore 使用：

```text
ReaderLocation -> TextLine -> PageCache -> placement
```

scroll restore 會設定 `virtualScrollY`。

slide restore 會設定 current page / pageSlot。

### TTS highlight

TTS highlight 使用：

```text
highlightStart / highlightEnd
 -> PageCache range intersection
 -> TextLine range intersection
 -> 整行 rect overlay
```

第一版不做逐字 highlight。

### auto page

Auto page 不操作 PageCache。

Auto page 只呼叫 viewport：

```text
scrollBy(delta)
animateBy(delta)
```

viewport 根據 PageCache 和 placement 移動畫面。

