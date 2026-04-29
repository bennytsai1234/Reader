# Reader Layout Coordinate Design

日期：2026-04-28

## 目的

這份文件定義 reader 的 layout 與 coordinate mapping。

它要解決的是：

```text
文字位置、文字行、頁、scroll virtual coordinate、screen coordinate 之間怎麼互相換算。
```

所有 anchor capture、restore、saveProgress、TTS highlight、PageCache window 都必須使用同一套 mapping。

## 核心定案

```text
charOffset 的真源是最終 chapter display text。
標題算進 charOffset。
TextLine 是定位最小單位。
PageCache 是 TextLine 的分組結果。
scroll / slide 共用同一份 ChapterLayout / TextLine / PageCache。
Painter 只畫 TextLine，不負責定位。
第一版不做 glyph-level hit test。
第一版 TTS highlight 使用整行 rect。
```

## chapter display text

`charOffset` 只對最終 chapter display text 有意義。

處理流程：

```text
原始章節
 -> 標題合併
 -> 內容清理
 -> 替換規則
 -> 繁簡轉換
 -> 分段 / 空白 normalize
 -> chapter display text
 -> layout
```

DB 裡的 `charOffset` 不是：

```text
原始書源 offset
替換前 offset
繁簡轉換前 offset
paragraph index
page index
```

DB 裡的 `charOffset` 是：

```text
最終 chapter display text 裡的位置。
```

## 標題

標題算進 chapter display text。

建議格式：

```text
title + "\n\n" + body
```

如果沒有 title：

```text
body
```

如果沒有 body：

```text
title
```

標題行可以產生 `TextLine`，也可以作為 anchor line。

不為標題建立另一套 offset。

## TextLine

`TextLine` 是定位最小單位。

第一版欄位：

```text
chapterIndex
lineIndex
startCharOffset
endCharOffset
text
top
bottom
height
isTitle
isParagraphEnd
```

### chapterIndex

這行屬於第幾章。

### lineIndex

這行是該章 layout 後的第幾行。

只用於 runtime / debug，不寫 DB。

### startCharOffset

這行在 chapter display text 裡的起始 offset。

anchor capture 保存：

```text
charOffset = selectedLine.startCharOffset
```

### endCharOffset

這行在 chapter display text 裡的結束 offset。

用途：

```text
判斷 charOffset 是否落在該行
range highlight 相交判斷
debug
```

### text

這行實際顯示的文字。

### top / bottom / height

這行在章節連續 layout coordinate 裡的位置。

```text
height = bottom - top
```

`top` / `bottom` 是章內 localY，不是 screenY。

### isTitle

表示標題行。

標題行可以作為 anchor。

### isParagraphEnd

表示段落結尾行。

可用於排版、段距、debug。

## 空白行與段距

第一版不產生空白 `TextLine` 作為 anchor。

段落空白用行與行之間的 y 間距表示：

```text
previousLine.bottom < nextLine.top
```

anchor line 落在空白或段距時，使用 `lineAtOrNearLocalY()` 的 fallback 規則找附近文字行。

## ChapterLayout

每章 layout 後產生：

```text
chapterIndex
displayText
lines
pages
contentHeight
layoutSignature
```

### displayText

最終 chapter display text。

### lines

章內連續坐標的 `TextLine` 列表。

`lines` 是 anchor、restore、TTS highlight、PageCache 的共同真源。

### pages

PageCache 頁列表。

`pages` 是由同一批 `lines` 按 viewport height 分組而來。

### contentHeight

整章內容高度。

必須是 finite 且 `> 0`，除非章節沒有可顯示文字。

### layoutSignature

layout 版本簽名。

以下任一變更都應產生新 signature：

```text
displayText
viewport width
viewport height
font size
line height
font family
letter spacing
padding
paragraph spacing
title style
```

signature 改變時，舊 ChapterLayout / PageCache 失效。

## PageCache grouping

PageCache 是 `TextLine` 的分組結果。

第一版分頁規則：

```text
按 viewportHeight 分頁。
頁邊界必須落在 line 邊界。
不能把一條 TextLine 切成兩半。
scroll / slide 使用同一份 pages。
```

每頁包含：

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

PageCache 不寫 DB。

## 必要查詢接口

ChapterLayout / mapper 必須提供以下查詢。

### lineForCharOffset

```dart
TextLine? lineForCharOffset(int charOffset);
```

語意：

```text
找 startCharOffset <= charOffset < endCharOffset 的 line。
```

如果 `charOffset` 剛好落在頁尾或章尾，可以回傳最近的有效文字行。

### lineAtOrNearLocalY

```dart
TextLine? lineAtOrNearLocalY(double localY);
```

語意：

```text
1. 優先找 top <= localY < bottom 的 line。
2. 沒有時，找 localY 下方最近的 line。
3. 下方沒有時，找 localY 上方最近的 line。
```

這個接口用於 anchor capture。

### pageForCharOffset

```dart
CachedReaderPage? pageForCharOffset(int charOffset);
```

語意：

```text
找 startCharOffset <= charOffset < endCharOffset 的 page。
```

找不到時 fallback 到該章第一頁或最後一頁。

### pageForLocalY

```dart
CachedReaderPage? pageForLocalY(double localY);
```

語意：

```text
找 localStartY <= localY < localEndY 的 page。
```

用於 scroll virtualY / chapterLocalY 轉 page。

### linesForRange

```dart
List<TextLine> linesForRange(int startCharOffset, int endCharOffset);
```

語意：

```text
找和 char range 相交的所有 line。
```

用於 TTS highlight。

第一版不做逐字 rect，只要回傳相交 lines。

### fullLineRectsForRange

```dart
List<Rect> fullLineRectsForRange({
  required int startCharOffset,
  required int endCharOffset,
  required double pageTopOnScreen,
});
```

語意：

```text
把 range 相交的 lines 轉成整行 rect。
```

第一版 TTS highlight 使用整行 rect。

## scroll coordinate mapping

scroll canvas 使用 signed virtual coordinate。

核心公式：

```text
screenY = page.virtualTop - virtualScrollY
anchorVirtualY = virtualScrollY + anchorLineY
```

### anchor capture

流程：

```text
1. anchorVirtualY = virtualScrollY + anchorLineY。
2. 用 anchorVirtualY 找 PageCache page。
3. 用 page 找 chapterIndex。
4. chapterLocalY = anchorVirtualY - chapterVirtualTop。
5. line = lineAtOrNearLocalY(chapterLocalY)。
6. charOffset = line.startCharOffset。
7. lineVirtualTop = chapterVirtualTop + line.top。
8. lineTopOnScreen = lineVirtualTop - virtualScrollY。
9. visualOffsetPx = anchorLineY - lineTopOnScreen。
```

結果：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

### scroll restore

輸入：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

流程：

```text
1. line = lineForCharOffset(charOffset)。
2. page = pageForCharOffset(charOffset)。
3. lineVirtualTop = chapterVirtualTop + line.top。
4. virtualScrollY = lineVirtualTop + visualOffsetPx - anchorLineY。
```

restore 後 final capture 只更新 `visibleLocation`，不寫 DB。

## slide coordinate mapping

slide 使用同一份 PageCache。

slide placement 使用：

```text
virtualLeft
pageOffsetX
pageSlot
```

slide restore：

```text
1. line = lineForCharOffset(charOffset)。
2. desiredLineTopOnScreen = anchorLineY - visualOffsetPx。
3. 先用 pageForCharOffset(charOffset) 找基準 page。
4. 在基準 page 附近找哪個 page 的 line top 最接近 desiredLineTopOnScreen。
5. 顯示該 page。
```

如果找不到：

```text
fallback 到 pageForCharOffset(charOffset)。
再失敗則回該章第一頁。
```

## TTS highlight mapping

TTS 提供：

```text
chapterIndex
highlightStart
highlightEnd
```

流程：

```text
1. 找目標 chapter layout。
2. linesForRange(highlightStart, highlightEnd)。
3. 將相交 lines 轉成目前 viewport 上的整行 rect。
4. TTSHighlightOverlayLayer 畫 rect / shadow / blur。
```

第一版不做：

```text
glyph-level rect
逐字高亮
charOffset -> x position
```

## 空章節 / loading / error

以下情況不能產生 `ReaderLocation`：

```text
content loading
error placeholder
empty placeholder
layout not ready
lines empty
page not ready
```

`captureVisibleLocation()` 應回傳 `null`。

`saveProgress()` 不寫 DB。

如果章節只有標題，標題可以產生位置。

如果標題和正文都沒有，不能產生位置。

## layout invalidation

以下任一變更會讓 layout / PageCache 失效：

```text
chapter display text 改變
字級改變
行距改變
字體改變
letter spacing 改變
padding 改變
viewport width / height 改變
title style 改變
paragraph spacing 改變
```

處理方式：

```text
1. 使用舊 visibleLocation 作為重建基準。
2. 重新產生 ChapterLayout。
3. 重新產生 PageCache。
4. 用 ReaderLocation restore。
5. final capture 更新 visibleLocation。
6. 不因 layout invalidation 直接寫 DB。
```

## Invariants

必須維持：

```text
TextLine.top < TextLine.bottom
TextLine.height > 0
TextLine.startCharOffset <= TextLine.endCharOffset
Page.localStartY < Page.localEndY
Page.height > 0
Page.lines 來自同一份 ChapterLayout.lines
scroll / slide 不各自 layout
Painter 不參與定位
DB 不保存 pageIndex / virtualTop / virtualLeft
```

capture / restore 應互為反向操作：

```text
capture -> ReaderLocation -> restore -> capture
```

結果應接近：

```text
chapterIndex 相同
charOffset 相同或落在同一行
visualOffsetPx 誤差在 1-2px 內
```

