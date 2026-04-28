# Reader Repair Plan

日期：2026-04-28

## 開發前提

目前最新 `reader` 視為全新 app 開發，不以舊 app / 舊 DB 升級相容作為阻塞項。每次更新可刪除 app 並重新開始，所以這份計劃只處理「新 reader 要怎麼做穩」。

舊版 `reader-0.2.28` 只作為行為參考，不作為回退目標。

可視位置與保存接口的細節見 `docs/reader_visible_location_design.md`。

開書恢復的接口與邊界見 `docs/reader_restore_design.md`。

Overlay、TTS 高亮與手勢分流見 `docs/reader_overlay_gesture_design.md`。

PageCache 渲染模型見 `docs/reader_page_cache_render_design.md`。

scroll canvas window、signed virtualScrollY 與滑動保存時機見 `docs/reader_scroll_canvas_window_design.md`。

## 核心決策

閱讀位置改成三個值：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

白話意思：

- `chapterIndex`：第幾章。
- `charOffset`：章內第幾個字，這是主要閱讀進度。
- `visualOffsetPx`：以 anchor line 為基準的畫面微調位移，單位是 px。

`visualOffsetPx` 不應是章節內的大型總位移，也不應是新的 page index。它只表示：

```text
恢復時，從 charOffset 對應那一行的 top 往下多少 px，可以對到畫面 anchor line。
```

anchor line 是閱讀畫面裡一條穩定的隱形基準線，建議放在閱讀內容區頂部往下 16 到 32 px。保存時用它選目前讀到的行，恢復時也用它把同一行放回原來的相對位置。

scroll / slide 都保存同一種位置：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

## 為什麼需要第三個值

只存：

```text
chapterIndex + charOffset
```

可以知道「讀到哪個字」，但不知道「這個字離開前在畫面哪個位置」。恢復時如果只靠 `charOffset`，scroll 可能把那行捲到不對的位置，slide 也可能在頁邊界或重排後落到不直覺的頁。

加上 `visualOffsetPx` 後，恢復流程變成：

```text
1. 用 chapterIndex 找章節。
2. 用 charOffset 找到對應文字行。
3. 用 visualOffsetPx 把那一行放回離開前接近的位置。
```

這樣恢復會比單純 `chapterIndex + charOffset` 更準，但又不需要保存龐大的章內 scroll offset 或舊 page index。

## visualOffsetPx 怎麼算

scroll / slide 模式退出、背景、或需要保存進度時：

1. 取閱讀內容區的 anchor 線，建議是內容區頂部往下 16 到 32 px。
2. 找到這條 anchor 線附近的第一條穩定可見文字行。
3. 保存該文字行的：
   - `chapterIndex`
   - `startCharOffset`
   - `visualOffsetPx`

`charOffset` 保存該行的 `startCharOffset`。`visualOffsetPx` 也以這個 `startCharOffset` 對應的文字行 top 為基準。

選行規則：

```text
1. 候選行包含標題和正文，但排除 loading / error placeholder。
2. 優先選 vertical range 包住 anchorLineY 的文字行。
3. 如果沒有行包住 anchorLineY，選 anchorLineY 下方最近的可見文字行。
4. 如果下方沒有可見文字行，選 anchorLineY 上方最近的可見文字行。
5. 保存該行的 startCharOffset，不保存行中間某個字。
```

其中：

```text
anchorLineY = readableContentTop + anchorLineOffsetPx
visualOffsetPx = anchorLineY - lineTopOnScreen
```

例子：

```text
readableContentTop = 72
anchorLineOffsetPx = 24
anchorLineY = 96
lineTopOnScreen = 90
visualOffsetPx = 6
```

保存：

```text
ReaderLocation(
  chapterIndex: 12,
  charOffset: 3456,
  visualOffsetPx: 6,
)
```

建議限制：

```text
-80 <= visualOffsetPx <= 120
```

`visualOffsetPx` 可以是負數。正數代表 anchor line 在該行 top 下方，這是最常見狀態。負數代表 fallback 選到的行 top 在 anchor line 下方，也就是 anchor line 落在該行上方附近。

如果計算出 NaN、無限大、或遠超過合理範圍的值，就回退到 `0`。這個值只做小範圍視覺微調，不應承擔完整 scroll 定位。

## scroll 開書怎麼用

scroll 模式開書恢復：

```text
1. 載入 chapterIndex 對應章節。
2. layout 出行與頁面。
3. 找到 charOffset 對應文字行的章內 localY。
4. 計算目標 scroll：

lineTopOnScreen = anchorLineY - visualOffsetPx

targetScrollY =
  chapterBaseY
  + charLocalY
  + visualOffsetPx
  - anchorLineY
```

白話講：

```text
先找到那個字，再把它對應的那一行放回 anchor line 附近，而且保留離開前那一點點正負偏移。
```

如果 `visualOffsetPx == 0`，代表那一行的頂部要剛好回到 anchor line。

## slide 模式怎麼用

slide 模式也使用 `visualOffsetPx`，但它不是拿來 scroll。它是用來描述「保存時，這個 `charOffset` 對應的文字行在 page 畫面裡離 anchor line 多遠」。

保存：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

恢復：

```text
1. 用 chapterIndex 載入章節。
2. layout 出 pages。
3. 計算 desiredLineTopOnScreen = anchorLineY - visualOffsetPx。
4. 找出在 desiredLineTopOnScreen 附近最接近 charOffset 的 page。
5. 顯示該 page。
```

建議查找方式：

```text
1. 先用 pageForCharOffset(charOffset) 找到基準 page。
2. 取基準 page 前後少量候選頁。
3. 對每一頁查 desiredLineTopOnScreen 附近的文字行。
4. 選該行 startCharOffset 最接近保存 charOffset 的 page。
```

白話講：slide 不保存舊 page index，而是保存「anchor line 附近是哪一行」。重建頁面後，再找哪一頁在同一個 anchor 位置最接近這個 `charOffset`。

如果找不到穩定 anchor page，fallback 才用一般 `pageForCharOffset(charOffset)`。

slide 不應用舊 page index 作主進度，因為字級、行距、螢幕尺寸變了，page index 會變。`visualOffsetPx` 是 page 重建時的微調線索，不是新的 page index。

## 要修改的主要地方

### 1. ReaderLocation

目前 `ReaderLocation` 只有：

```text
chapterIndex
charOffset
```

要改成：

```text
chapterIndex
charOffset
visualOffsetPx
```

要求：

- `visualOffsetPx` 預設為 `0`。
- normalize 時 clamp 到合理範圍，而且允許小幅負值。
- equality / hashCode / copyWith 都包含這個欄位。
- runtime 內所有位置傳遞都用同一個 `ReaderLocation`。

### 2. Book / DB

因為這是全新 app baseline，可以直接調整 fresh schema。

要保存三個位置值：

```text
books.chapterIndex
books.charOffset
books.visualOffsetPx
```

如果不想新增獨立欄位，也可以短期存在 `readerAnchorJson`，但本計劃推薦新增明確欄位，因為這三個值是 reader 的核心進度資料，不應藏在 JSON 裡。

`readerAnchorJson` 後續可以先保留但不作為主線必需資料。

### 3. Progress

`ReaderProgressController` 要負責保存完整三元位置：

```text
chapterIndex
charOffset
visualOffsetPx
```

修復重點：

- 短時間或同時多次 `saveProgress()` 時，只保存最後有效位置。
- active write 期間又收到新位置時，寫入結束後要繼續寫最後位置。
- exit / dispose / app paused 時必須走同一套 saveProgress()。
- loading / error placeholder 不可保存成進度。

正常退出和意外退出不要維護兩套保存流程。只保留同一個保存入口：

```text
saveProgress()
```

這個入口負責：

```text
1. 內部呼叫 captureVisibleLocation()。
2. capture 成功後更新 runtime.visibleLocation。
3. 將同一個 ReaderLocation 推進為 committedLocation。
4. 寫入 DB / 本地儲存。
```

`saveProgress()` 不需要 `reason` 參數。呼叫方要在動作完成、畫面穩定後呼叫它；正常退出和意外退出也都呼叫同一個入口。

### 4. Scroll Viewport

scroll viewport 要能回報目前可視 anchor：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

它不應直接寫 DB，只回報給 runtime/progress。

需要做：

- 從目前可見行找 anchor line。
- 算 `visualOffsetPx = anchorLineY - lineTopOnScreen`。
- 保存前 clamp。
- layout 改變或章節高度從估算變成實際值時，保持 anchor 不跳。

### 5. Runtime

`ReaderRuntime` 是唯一閱讀狀態真源。

要做：

- `visibleLocation` 使用三元 `ReaderLocation`。
- `committedLocation` 使用三元 `ReaderLocation`。
- scroll 更新 visible location 時保留 `visualOffsetPx`。
- slide 更新 visible location 時也保留 `visualOffsetPx`。
- mode switch 時：
  - scroll -> slide：用 `chapterIndex + charOffset + visualOffsetPx` 找 anchor page。
  - slide -> scroll：用 `chapterIndex + charOffset + visualOffsetPx` 找 scroll target。

### 6. Layout / Coordinate Mapping

layout 必須能穩定提供：

```text
charOffset -> line localY
screen visible line -> charOffset
```

需要確認：

- 每條 `TextLine` 有穩定 `startCharOffset/endCharOffset`。
- 標題直接算進 chapter offset，也可以作為 anchor line 候選，避免正文和標題分兩套 offset 規則。也就是說，排版用的 chapter display text 如果包含標題，`charOffset` 就以這份 display text 為準。
- `charOffset` 落在頁邊界時能找對 page / line。
- slide 需要 `charOffset + desiredLineTopOnScreen -> page` 或等價查找，不能只依賴舊 page index。
- 字級、行距、padding 改變後，仍能用 `charOffset` 找回合理行。

### 7. Content

content 負責把章節正文準備好。

需要穩定：

- 章節列表。
- 正文載入。
- 本地 TXT / 遠端書源。
- 替換規則。
- 繁簡轉換。
- 分段。

content 改變時，舊的 visual offset 仍可保留為小範圍視覺修正，但不能相信舊 page index。

## 主要流程

### scroll 退出保存

```text
使用者正在 scroll
 -> viewport 用目前 anchor line 找穩定可見行
 -> 算 chapterIndex
 -> 算 charOffset
 -> 算 visualOffsetPx，允許小幅正負值
 -> runtime 更新 visibleLocation
 -> scroll idle / inertia stopped 時呼叫 saveProgress()
 -> 正常退出 / 意外退出也呼叫 saveProgress()
```

### scroll 開書恢復

```text
開書
 -> 讀取 Book.chapterIndex / charOffset / visualOffsetPx
 -> runtime 載入章節
 -> content 載入正文
 -> layout 排版
 -> charOffset 找到 line localY
 -> viewport 用 anchor line 與 visualOffsetPx scroll 到 targetScrollY
```

### slide 退出保存

```text
使用者翻到某頁
 -> viewport 用目前 anchor line 找該頁上的穩定可見行
 -> 算 chapterIndex
 -> 算 charOffset
 -> 算 visualOffsetPx，允許小幅正負值
 -> 呼叫 saveProgress()
 -> 保存 ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

### slide 開書恢復

```text
開書
 -> 讀取 chapterIndex / charOffset / visualOffsetPx
 -> layout
 -> desiredLineTopOnScreen = anchorLineY - visualOffsetPx
 -> 找 desiredLineTopOnScreen 附近最接近 charOffset 的 page
 -> 顯示 page
```

## 驗收條件

### scroll

- scroll 到章節中段，退出再進，視覺位置接近退出前。
- 同一章內保存的 `visualOffsetPx` 是小範圍正負值，不是章節總 scroll offset。
- app paused 後重開，最後位置不丟。
- 快速滑動後立刻退出，保存最後可視位置。
- loading/error placeholder 不保存進度。

### slide

- slide 翻頁後退出再進，anchor line 附近回到同一段文字。
- slide 保存時也保留小範圍正負 `visualOffsetPx`。
- 改字級後，用 `charOffset` 重新找到合理 page。

### mode switch

- scroll -> slide 不丟 `chapterIndex + charOffset + visualOffsetPx`。
- slide -> scroll 可回到同一段文字附近，並保留 anchor line 的相對偏移。
- mode switch 不依賴舊 page index。

### progress

- 短時間或同時多次 `saveProgress()`，只保存最後有效位置。
- DB 寫入中收到新位置，最後位置仍會被寫出。
- dispose / exit / lifecycle flush 都走同一個 saveProgress()，並能保存最後位置。

## 不做的事

- 不回退到 0.2.28。
- 不以舊 DB migration 作阻塞。
- 不把 page index 作為主進度。
- 不把大型章內 scroll offset 作為主進度。
- 不讓 viewport 直接寫 DB。
- 不維護正常退出與意外退出兩套保存流程。
