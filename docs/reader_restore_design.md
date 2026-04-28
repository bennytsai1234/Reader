# Reader Restore Design

日期：2026-04-28

## 目的

這份文件定義「開書恢復」的接口和邊界。

restore 的工作只有一個：

```text
消費 DB 裡保存的 ReaderLocation，把畫面放回接近上次閱讀的位置。
```

restore 不負責產生新的 DB 進度。

核心位置模型：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

## 定案原則

```text
restore 期間不寫 DB。
restore 成功後也不寫 DB。
restore 成功後只更新 runtime.visibleLocation。
```

真正寫入 DB 的時機只有：

```text
scroll idle
slide page settled
mode switch settled
app paused / exit / dispose
```

`restore` 是讀取並消費持久化位置；`saveProgress()` 是產生新的持久化位置。兩者不能混在一起。

## restore 成功後為什麼更新 visibleLocation

`visibleLocation` 是 runtime memory 裡的目前位置 cache。

DB location 代表：

```text
上次保存的位置
```

restore 完成後的 `visibleLocation` 代表：

```text
這次 session 畫面實際成功落到的位置
```

兩者通常接近，但不保證完全一樣。原因包括：

```text
字級 / 行距 / padding / viewport 改變
chapter content 改變
charOffset 被 normalize
visualOffsetPx 被 normalize
原本的 line 找不到，fallback 到附近 line
slide restore 落到相鄰 page
```

所以 restore 成功後要把實際落點存進 runtime memory：

```text
runtime.visibleLocation = finalCapturedLocation
```

這不是保存，不會寫 DB。它只是讓後續「目前位置」相關操作有正確基準，例如：

```text
mode switch
layout 改變後重新定位
目前章節 / 進度 UI
TOC 高亮
書籤 / 筆記 / 標註
TTS 起讀位置
下一次 saveProgress() 前的 runtime 狀態
```

## 公開接口

建議 runtime 對外提供一個 restore 入口：

```dart
Future<bool> restoreFromLocation(ReaderLocation location);
```

語意：

```text
用 ReaderLocation 讓目前 reader mode 的 viewport 定位。
成功回傳 true。
失敗回傳 false。
不寫 DB。
不呼叫 saveProgress()。
```

mode 分支留在 restore 內部：

```text
ReaderMode.scroll -> restore scroll viewport
ReaderMode.slide  -> restore slide viewport
```

## restore pipeline

```text
1. 讀取 DB ReaderLocation。
2. normalize chapterIndex / charOffset / visualOffsetPx。
3. 進入 restore guard。
4. 載入 chapter content。
5. 建立 chapter layout。
6. 依目前 mode 定位 viewport。
7. 等 viewport settled / next stable frame。
8. 做 final captureVisibleLocation()。
9. capture 成功：更新 runtime.visibleLocation，restore completed。
10. capture 失敗：restore failed，不覆蓋 DB。
```

restore pipeline 結尾不接 `saveProgress()`。

## 輸入 normalize

DB 讀出的 `ReaderLocation` 要修正成合法值。

```text
chapterIndex < 0 -> 0
chapterIndex >= chapterCount -> last chapter
charOffset < 0 -> 0
charOffset > chapterLength -> chapterLength
visualOffsetPx NaN / infinite -> 0
visualOffsetPx 超過合理範圍 -> clamp 到合理範圍
```

`charOffset` 的上限需要等 chapter content ready 後才能精準判斷。

建議 `visualOffsetPx` 範圍：

```text
-80 <= visualOffsetPx <= 120
```

`clamp` 的意思是把值限制在合法範圍內。例如 scroll target 小於 `0` 就拉回 `0`，大於最大可 scroll 值就拉回最大值。

DB 沒有保存位置時，使用預設：

```text
ReaderLocation(chapterIndex: 0, charOffset: 0, visualOffsetPx: 0)
```

## restore guard

restore 定位途中，不能讓半成品畫面污染 runtime 或 DB。

restore guard active 時：

```text
一般 viewport scroll listener 不更新 visibleLocation。
一般 captureVisibleLocation() 應回 null。
saveProgress() 不寫 DB。
loading / error / empty placeholder 不會變成閱讀位置。
```

final capture 是 restore 流程的一部分，必須在 viewport 已經定位且 settled 後執行。實作上可以：

```text
1. 先把狀態切到 readyForRestoreCapture，再呼叫 captureVisibleLocation()。
2. 或由 restore coordinator 允許一次 final capture。
```

重點是：

```text
定位中的一般事件不能更新位置。
定位完成後的 final capture 只更新 visibleLocation。
```

## scroll restore

scroll restore 使用 layout data，不從 canvas 像素反推。

輸入：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

流程：

```text
1. 確保 chapter content ready。
2. 確保 chapter layout ready。
3. 找 charOffset 對應或附近的 TextLine。
4. 算 anchorLineY。
5. 算 targetScrollY。
6. targetScrollY clamp 到合法 scroll 範圍。
7. jumpTo targetScrollY。
8. 等 next stable frame。
9. final captureVisibleLocation()。
```

公式：

```text
lineTopOnScreen = anchorLineY + visualOffsetPx

targetScrollY =
  chapterBaseY
  + paddingTop
  + line.top
  - anchorLineY
  - visualOffsetPx
```

如果找不到 line：

```text
fallback 1：找 charOffset 前後最近的 line。
fallback 2：charOffset 超界時用章首或章尾。
fallback 3：整章沒有 line 時，定位到該章開頭。
```

如果目標章節還沒載入完成：

```text
等待 layout ready。
不能用 placeholder 高度完成 restore。
```

## slide restore

slide restore 也使用 `visualOffsetPx`，但不是拿來 scroll，而是拿來選 page。

流程：

```text
1. 確保 chapter content ready。
2. 確保 chapter layout ready。
3. 計算 desiredLineTopOnScreen。
4. 先用 pageForCharOffset(charOffset) 找基準 page。
5. 取基準 page 前後少量候選頁。
6. 對每個候選 page，找 desiredLineTopOnScreen 附近的 line。
7. 選該 line.startCharOffset 最接近 charOffset 的 page。
8. 顯示該 page。
9. 等 page settled。
10. final captureVisibleLocation()。
```

公式：

```text
desiredLineTopOnScreen = anchorLineY + visualOffsetPx
```

fallback：

```text
fallback 1：pageForCharOffset(charOffset)。
fallback 2：該章第一頁。
fallback 3：第一章第一頁。
```

## Painter / Canvas 邊界

採用 Painter 不會阻止 restore，也不會阻止 anchor 定位。

restore 不問 canvas：

```text
你現在畫到哪個字？
```

restore 問 layout data：

```text
anchorLineY 落在哪一條 TextLine？
charOffset 對應哪一條 TextLine？
TextLine.top / bottom / startCharOffset 是多少？
```

Painter 只負責把 layout 已經產生的 `TextLine` 畫出來。

正確邊界：

```text
Layout：產生 TextLine + 坐標 + charOffset。
Viewport：根據 scroll/page 狀態定位與 capture。
Runtime：管理 restore / visibleLocation / saveProgress。
Painter：只畫文字。
DB：只保存 ReaderLocation。
```

## restore 成功標準

不能只因為 `jumpTo()` 或 page index 設定完成就算成功。

restore completed 必須滿足：

```text
content ready
layout ready
viewport positioned
viewport settled
final captureVisibleLocation() 成功
runtime.visibleLocation 已更新
沒有寫 DB
```

## restore 失敗標準

以下情況視為 restore failed：

```text
chapter 載入失敗
layout 建立失敗
找不到有效 line 且 fallback 也失敗
viewport 不存在
viewport 無法定位
final captureVisibleLocation() 失敗
```

restore failed 時：

```text
不寫 DB。
不更新 committedLocation。
不呼叫 saveProgress()。
可以顯示 fallback 畫面或錯誤畫面。
```

如果有 fallback 畫面，後續只有在使用者真的讓畫面 settled，並由正常流程呼叫 `saveProgress()` 時，才會產生新的 DB 位置。

## 和 saveProgress() 的關係

restore 絕對不直接保存。

```text
restoreFromLocation()
 -> final captureVisibleLocation()
 -> update visibleLocation only
```

後續如果發生以下動作，才保存：

```text
scroll idle -> saveProgress()
slide page settled -> saveProgress()
mode switch settled -> saveProgress()
app paused / exit / dispose -> saveProgress()
```

## 實作順序

1. 補齊 `ReaderLocation(chapterIndex, charOffset, visualOffsetPx)`。
2. 補齊 layout 查詢能力：`charOffset -> TextLine`、`anchorY -> TextLine`。
3. 實作 scroll restore target 計算。
4. 實作 slide anchor page 查找。
5. 實作 restore guard。
6. 實作 `restoreFromLocation(location)`。
7. 接上 final `captureVisibleLocation()`，只更新 `visibleLocation`。
8. 驗證 restore 不會呼叫 `saveProgress()`，也不會寫 DB。

