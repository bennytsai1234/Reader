# Reader Overlay And Gesture Design

日期：2026-04-28

## 目的

這份文件只定義第一版 reader scroll canvas 的上層互動與覆蓋層：

```text
TTSHighlightOverlayLayer
GestureLayer
ReaderPageShell existing overlays
```

第一版不支援文字選取，不做 glyph-level hit test，不做選取手柄，也不做複製選單。

## Layer Stack

完整畫面分層從底到上是：

```text
1. BackgroundLayer
2. RenderTileCanvasLayer
3. TTSHighlightOverlayLayer
4. GestureLayer
5. ReaderPageShell existing overlays
```

這份文件只處理第 3、4、5 層。

## 3. TTSHighlightOverlayLayer

### 責任

TTSHighlightOverlayLayer 只負責朗讀高亮。

TTS 功能會提供目前朗讀位置，例如：

```text
chapterIndex
highlightStart
highlightEnd
```

Overlay 用 layout 查詢這段 range 跨到哪些 `TextLine`，再把這些行整行畫出高亮。

第一版不做逐字高亮：

```text
不做 charOffset -> x position。
不做 glyph rect。
不只高亮句子中的幾個字。
```

第一版做整行/多行高亮：

```text
只要朗讀 range 碰到某一行，就整行畫高亮。
如果 range 跨三行，就三行都高亮。
如果 TTS 以段落為單位，也可以把該段落跨到的所有行整行高亮。
```

### 視覺

高亮是 overlay，不會改底層正文 tile。

建議效果：

```text
半透明 rect
圓角
柔和 shadow / blur
```

可以用類似陰影或模糊的方式讓目前朗讀行有柔和背景。具體數值留給 UI 實作調整，例如：

```text
fill alpha: 0.12 - 0.22
blur radius: 16 - 50
corner radius: 4 - 8
```

如果 blur 太重造成掉幀，實作可以降低 blur 或改成純半透明 rect。視覺效果不能要求 `RenderTileCanvasLayer` 重新產生文字 tile。

### 不負責

TTSHighlightOverlayLayer 不負責：

```text
不啟動或停止 TTS。
不控制自動跟隨 scroll。
不保存進度。
不改 RenderTile cache。
不處理手勢。
```

TTS 自動跟隨如果需要捲動畫面，應由 TTS flow 呼叫 viewport 接口，例如：

```text
ensureCharRangeVisible(chapterIndex, highlightStart, highlightEnd)
```

Overlay 只負責把目前 TTS flow 給的位置畫出來。

## 4. GestureLayer

### 第一版處理範圍

第一版 GestureLayer 只處理：

```text
drag / pan -> scroll canvas
tap -> 九宮格 action
long press -> no-op
```

文字選取留到未來版本。

### 手勢優先順序

#### 1. ReaderPageShell controls visible

```text
controlsVisible == true
```

此時 content GestureLayer 不處理手勢。

事件交給既有 `ReaderPageShell` overlay：

```text
tap -> 關閉或操作既有選單
TopMenu / BottomMenu / Drawer / scrim -> 保持既有行為
```

#### 2. drag / pan

拖動正文時，交給 scroll canvas：

```text
ScrollCanvasController.dragBy(delta)
```

慣性與 fling 由 scroll canvas controller 自己處理。

scroll idle / inertia stopped 後，由 scroll flow 呼叫：

```text
saveProgress()
```

GestureLayer 不直接保存 DB。

#### 3. tap

普通 tap 交回既有點擊流程：

```text
onContentTapUp(details)
```

既有流程會使用九宮格設定：

```text
ReaderPage._handleTap()
ReaderTapAction
settings.clickActions
```

所以九宮格點擊動作不重做，沿用原本行為。

#### 4. long press

第一版暫不處理：

```text
long press -> no-op
```

未來如果要做文字選取，再新增 selection hit test、SelectionOverlay、handles 與 copy menu。

### 不負責

GestureLayer 不負責：

```text
不計算 ReaderLocation。
不寫 DB。
不畫 TTS highlight。
不畫文字。
不直接啟動或停止 TTS。
不直接開發新的九宮格選單。
```

GestureLayer 只負責把輸入事件分流給既有流程或 scroll canvas controller。

## 5. ReaderPageShell Existing Overlays

這一層沿用現有實作，不重做。

目前既有內容包括：

```text
TopMenu
BottomMenu
Drawer
controls scrim
PermanentInfoBar
九宮格點擊設定
```

scroll canvas viewport 只作為 `ReaderPageShell.content` 放入：

```text
ReaderPageShell(
  content: ScrollCanvasViewport(...)
)
```

ReaderPageShell 負責控制選單顯示、遮罩、目錄、底部控制列與既有設定入口。

## Auto Page

Auto page 不是畫面 layer。

它是 controller / flow，應呼叫 scroll canvas viewport 的控制接口：

```text
scrollBy(delta)
animateBy(delta)
```

scroll canvas controller 負責：

```text
更新 signed virtualScrollY
確保目標方向 tile ready
tile 不 ready 時停住或回報 false
scroll idle 後觸發保存流程
```

Auto page 不直接操作 RenderTile，也不直接寫 DB。

## TTS Follow

TTS follow 不是畫面 layer。

TTS flow 如果需要讓朗讀位置進入可視範圍，應呼叫 viewport 接口：

```text
ensureCharRangeVisible(chapterIndex, highlightStart, highlightEnd)
```

TTSHighlightOverlayLayer 只畫高亮。是否跟隨、何時跟隨、是否暫停自動翻頁，都由 TTS flow / runtime 決定。

## 第一版不做

第一版明確不做：

```text
文字選取
複製選單
selection handles
glyph-level hit test
逐字 TTS highlight
charOffset -> x position
自訂 ReaderPageShell 選單
```

保留未來擴充空間：

```text
SelectionOverlayLayer
glyph positions
text selection controller
copy/share/action menu
```

