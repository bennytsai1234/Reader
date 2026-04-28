# Reader Visible Location Design

日期：2026-04-28

## 目的

這份文件只定義 reader 的可視位置與保存接口。

核心位置模型固定為：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

- `chapterIndex`：第幾章。
- `charOffset`：章內字元位置，標題也算進同一套 offset。
- `visualOffsetPx`：目前 anchor line 和 `charOffset` 對應文字行之間的垂直差值，可正可負。

scroll / slide 都使用同一個 `ReaderLocation`。差別只在恢復方式：

- scroll：用三元位置算 `targetScrollY`。
- slide：用三元位置找 anchor line 附近最接近 `charOffset` 的 page。

## 公開接口

只需要兩個公開入口：

```dart
ReaderLocation? captureVisibleLocation();

Future<ReaderLocation?> saveProgress();
```

不需要 `reason` 參數，也不需要公開的 `requestVisibleLocationCapture()`。

畫面動作完成、viewport 已經停下來、layout 已經穩定後，由該動作的流程自己呼叫這兩個入口。

## captureVisibleLocation()

用途：我現在想知道畫面 anchor line 對應的位置。

它做的事：

```text
1. 向目前 active viewport 取得 anchor line capture。
2. 驗證 capture 是否可信。
3. normalize ReaderLocation。
4. 更新 runtime.visibleLocation。
5. 回傳 ReaderLocation。
```

它不做的事：

```text
1. 不寫 DB。
2. 不更新 committedLocation。
3. 不觸發保存流程。
4. 不負責等畫面停下來。
```

呼叫者只需要拿到三個關鍵資料：

```text
chapterIndex
charOffset
visualOffsetPx
```

但 `visibleLocation` 的寫入仍然集中在這個入口內完成，不讓外部到處手動改 runtime 狀態。

如果目前畫面不能產生可信位置，回傳 `null`。

## saveProgress()

用途：我現在要把目前畫面位置保存成閱讀進度。

它做的事：

```text
1. 內部先呼叫 captureVisibleLocation()。
2. capture 失敗就不保存，回傳 null。
3. capture 成功後更新 runtime.visibleLocation。
4. 將同一個 ReaderLocation 推進為 runtime.committedLocation。
5. 寫入 DB / 本地儲存。
6. 回傳已保存的 ReaderLocation。
```

`saveProgress()` 本身不判斷「畫面是不是已經停下來」。這件事由呼叫方負責。

也就是說：

```text
scroll 滑動中：不要呼叫 saveProgress()
scroll 停下來：呼叫 saveProgress()
slide 翻頁動畫中：不要呼叫 saveProgress()
slide page settled：呼叫 saveProgress()
app paused / dispose：呼叫 saveProgress()
```

如果保存時發現位置和 `committedLocation` 完全相同，可以跳過 DB 寫入，但仍可回傳該位置。

## Anchor Capture

viewport 只負責回答一件事：

```text
目前 anchor line 看到哪一行？
```

capture 規則：

```text
anchorLineY = readableContentTop + anchorLineOffsetPx
visualOffsetPx = lineTopOnScreen - anchorLineY
```

選行規則：

```text
1. 候選行包含標題和正文。
2. 排除 loading / error / empty placeholder。
3. 優先選 vertical range 包住 anchorLineY 的文字行。
4. 沒有包住 anchorLineY 的行時，選 anchorLineY 下方最近的可見文字行。
5. 下方沒有可見文字行時，選 anchorLineY 上方最近的可見文字行。
6. 保存該行 startCharOffset，不保存行中間某個字。
```

`visualOffsetPx` 允許負值。建議 normalize 範圍：

```text
-80 <= visualOffsetPx <= 120
```

NaN、無限大、或遠超過合理範圍的值直接視為 invalid capture，不保存。

## 不能 Capture 的狀態

以下狀態 `captureVisibleLocation()` 應回傳 `null`：

```text
content loading
error placeholder
empty placeholder
layout not ready
layout unstable
restore jump in progress
slide transition in progress
active viewport missing
no visible text line
```

原則是：寧可不更新、不保存，也不要把 placeholder 或不穩定畫面寫成閱讀進度。

## 誰在什麼時候呼叫

### 開書恢復完成

```text
DB location loaded
 -> content ready
 -> layout ready
 -> scroll/slide restored
 -> next stable frame
 -> captureVisibleLocation()
```

只更新 `visibleLocation`，不需要立刻保存 DB。

### scroll 模式

```text
scroll moving
 -> 不保存

scroll idle / inertia stopped
 -> saveProgress()
```

如果 UI 需要滑動中的即時章節或百分比，可以在 scroll movement 中呼叫 `captureVisibleLocation()`，但不要寫 DB。

### slide 模式

```text
page transition start
 -> 不 capture
 -> 不保存

page settled
 -> saveProgress()
```

如果使用者快速連續翻頁，只保存最後 settled page。

### 章節切換

```text
chapter loading
 -> 不 capture
 -> 不保存

chapter content/layout ready
 -> viewport settled
 -> saveProgress()
```

跨章 scroll 時，anchor line 落在哪一章，就保存哪一章的 `chapterIndex`。

### layout 改變

包含字級、行距、字體、padding、viewport size、orientation 改變。

```text
layout change requested
 -> 用舊 visibleLocation 做 restore
 -> layout ready
 -> viewport settled
 -> captureVisibleLocation()
```

layout 改變本身不一定要立刻保存 DB；如果接著 app paused / exit，再由 `saveProgress()` 保存最新 anchor。

### 模式切換

```text
before mode switch
 -> final location = captureVisibleLocation()
 -> 用 final location 進入新模式

new mode restored and settled
 -> saveProgress()
```

scroll -> slide 和 slide -> scroll 都保留完整三元位置，不把 `visualOffsetPx` 歸零。

### app paused / exit / dispose

```text
app paused / exit / dispose
 -> saveProgress()
```

正常退出和意外退出共用同一個保存入口。呼叫方要盡量在 viewport 還存在、layout 還可用時呼叫。

### 書籤 / 筆記 / 標註

```text
user action
 -> location = captureVisibleLocation()
 -> location == null 時取消該次定位動作
 -> location != null 時用它建立書籤 / 筆記 / 標註
```

這類動作不一定要保存閱讀進度；它只是需要目前畫面位置。

## 模組責任

### Viewport

負責：

```text
anchor line 選行
lineTopOnScreen 計算
visualOffsetPx 計算
回傳 ReaderLocation?
```

不負責：

```text
寫 DB
管理 committedLocation
決定保存時機
```

### Runtime

負責：

```text
提供 captureVisibleLocation()
提供 saveProgress()
持有 visibleLocation
持有 committedLocation
驗證 capture 是否可信
把成功 capture 推給 progress 保存
```

### Progress / Storage

負責：

```text
保存 ReaderLocation
跳過重複寫入
處理同時多次 saveProgress() 的最後位置寫入
```

不直接認識 viewport。

## 狀態語意

```text
visibleLocation
= runtime 最後一次可信的畫面 anchor 位置

committedLocation
= 已經交給保存流程，或已成功保存的最後位置

DB progress
= app 下次開書時使用的持久化位置
```

`captureVisibleLocation()` 最多只推進 `visibleLocation`。

`saveProgress()` 會推進：

```text
visibleLocation
 -> committedLocation
 -> DB progress
```

## 實作順序

1. 補齊 `ReaderLocation(chapterIndex, charOffset, visualOffsetPx)`。
2. 讓 scroll / slide viewport 都能提供 anchor capture。
3. 在 runtime 實作 `captureVisibleLocation()`。
4. 在 runtime 實作 `saveProgress()`。
5. 把 restore / scroll idle / slide settled / mode switch / app lifecycle 接到這兩個接口。
6. 最後再處理 UI 進度、書籤、筆記、標註等呼叫點。
