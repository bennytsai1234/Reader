# Reader Recovery Analysis

日期：2026-04-28

## 結論

建議採用方案 2：重構現有 `reader`，但要把它當成「閱讀器穩定化專案」，不是繼續零散補 bug。

不建議直接退回 `reader-0.2.28` 作為長期方向。舊版有不少值得保留的行為設計，尤其是精準 restore anchor、scroll restore、flush 與測試覆蓋，但主線是 2546 行的 `ReadBookController` 加多個 mixin，耦合太高。退回會把現在已經拆出的 engine/runtime 架構價值丟掉，也會重新承擔舊版的可維護性問題。

不建議完全重做。新版目前不是「方向錯」，而是「重構未收斂」。核心 engine、`ReaderRuntime`、`PageResolver`、`LayoutEngine`、`chapterIndex + charOffset` 這些方向是對的。完全重做會再次踩同樣的內容載入、定位、viewport、flush、資料庫升級問題。

## 目前狀態

`reader` 目前主線：

- `ReaderPage` 建立 `ReaderRuntime`、`ReaderProgressController`、reader controllers。
- `ReaderRuntime` 持有 `ReaderState`，負責開書、跳位置、翻頁、mode switch、進度排程。
- `ChapterRepository` 負責章節與正文載入。
- `PageResolver` 負責 `ReaderLocation(chapterIndex, charOffset)` 到 `TextPage` 的投影。
- `SlideReaderViewport` 和 `ScrollReaderViewport` 直接接 `ReaderRuntime`。

`reader-0.2.28` 主線：

- `ReaderProvider` 是 `ReadBookController` 的薄封裝。
- `ReadBookController` 同時管 session、content lifecycle、viewport command、progress、restore、TTS、auto page、source switch。
- scroll/slide restore、anchor 與 flush 邏輯更完整，但集中在同一個超大 controller 和多個 mixin 裡。

## 主要風險判斷

### 1. 資料庫進度欄位在正式升級前有風險

`reader-0.2.28` 使用：

- `Book.durChapterIndex`
- `Book.durChapterPos`
- database schemaVersion 10

目前 `reader` 使用：

- `Book.chapterIndex`
- `Book.charOffset`
- database schemaVersion 1

這在正式提供升級路徑時是高風險問題。不過目前專案仍在開發階段，維護者會刪除舊 app 並用新資料庫重來，所以它不是當前 reader recovery 的阻塞項。當前只要求 fresh install 的 schema、DAO、model 欄位一致。

### 2. 新版進度 flush 太簡化

目前主線 `ReaderProgressController` 是 400ms debounce 加單一 `_activeFlush`。如果 DB 寫入進行中又收到新位置，新的 pending location 可能被留在記憶體裡，直到下一次 schedule 或手動 flush 才會寫出。退出或 lifecycle flush 若剛好撞上 active write，也可能只等到舊位置。

這會造成「我明明滑到後面，重開又回到舊位置」。

### 3. 新版捨棄了舊版 anchor 保護

舊版會保存 `readerAnchorJson`，裡面有：

- `chapterIndex + charOffset`
- `localOffsetSnapshot`
- `pageIndexSnapshot`
- `contentHash`
- `layoutSignature`

目前主線寫進度時會把 `readerAnchorJson` 清成 `null`。 durable truth 仍應是 `chapterIndex + charOffset`，但 anchor 對 scroll restore 很有價值，尤其是重開後 layout 還沒完整完成、章節高度還是估算時。

因此 recovery 後必須把 `ReaderAnchor` 序列化保存到 `books.readerAnchorJson`。如果只存在記憶體，app 重啟後 `localOffsetSnapshot` / `pageIndexSnapshot` 就會消失，scroll 精準恢復也就失效。

### 4. scroll viewport 邊界不清

目前 `ScrollReaderViewport` 自己維護：

- loaded chapter cache
- estimated chapter extent
- in-flight chapter loads
- global offset 與 chapter base offset
- runtime visible location 回報

同時 `ReaderRuntime` 和 `PageResolver` 也有 layout/cache/window。這會形成兩套狀態：runtime 以 `PageWindow` 思考，scroll viewport 以整書 `ListView` 和章節高度估算思考。只要載入、估高、跳轉、設定變更、mode switch 交錯，就容易出現位置漂移。

### 5. 舊版不是乾淨基準

舊版雖然在 restore/flush 上比較完整，但主要問題是：

- `ReadBookController` 太大，責任過多。
- provider/mixin/callback 互相呼叫，依賴方向不穩。
- content、viewport、progress、session 的狀態分散。
- 修一個問題很容易影響其他流程。

所以舊版適合作為行為參考，不適合作為長期架構。

## 保留與丟棄

應從舊版保留：

- `ReaderAnchor` 的語義：content hash、layout signature、local offset、page snapshot。
- `flushNow()` 的語義：退出、背景、TTS、scroll pending 都要 drain。
- scroll restore 期間不要把暫態 visible state 寫成正式進度。
- mode switch / repaginate / restore 都以 `chapterIndex + charOffset` 為核心。
- 舊版 reader 測試中關於 restore、viewport command、progress、scroll runner 的案例。

不應直接保留：

- 2546 行 `ReadBookController` 作為主線。
- provider mixin callback 網。
- `ScrollablePositionedList` 方案本身不必照搬，除非重構後能明確收斂責任。
- 以頁碼或 scroll offset 作 durable progress。

## 推薦目標架構

重構後主線應該只有一個狀態真源：

```text
ReaderRuntime
  - ReaderState
  - ReaderLocation(chapterIndex, charOffset)
  - ReaderAnchor? for restore precision only
  - ReaderProgressController
  - PageResolver / LayoutEngine
```

viewport 只做兩件事：

1. 接收 runtime 給的 presentation model。
2. 回報 user intent 或 visible anchor。

viewport 不直接決定 durable progress，不自行保存 DB，不自行創造與 runtime 競爭的內容生命周期。

## 決策矩陣

| 方案 | 可行性 | 風險 | 速度 | 長期維護 | 判斷 |
| --- | --- | --- | --- | --- | --- |
| 退回 0.2.28 | 高 | 中高 | 快 | 差 | 只適合緊急止血 |
| 重構現有版本 | 高 | 中 | 中 | 好 | 推薦 |
| 完全重做 | 中低 | 高 | 慢 | 未知 | 不推薦 |

## 立即處理順序

1. 修 `ReaderProgressController`：active flush 期間的新 pending location 必須被 drain。
2. 恢復 `ReaderAnchor` 作為 restore precision，保存到 `books.readerAnchorJson`，但不把它當 durable truth。
3. 收斂 scroll viewport 與 runtime 的責任邊界。
4. 穩定 chapter content 接入、layout、charOffset 與 visual offset 映射。
5. 補上 0.2.28 中有價值的 restore/progress/viewport 測試。
6. 清理未接主線的 runtime 旁支，避免文檔與測試誤導。
7. 保持 fresh install DB schema 一致；正式需要升級相容時再補 migration。

## 最低驗收

必須通過以下行為，才算 reader 被救回來：

- fresh install 後，書籍進度欄位、DAO、model 讀寫一致。
- 打開書後能穩定載入目前章節正文。
- slide 翻頁後退出再進，落在同一頁或同一字元附近。
- scroll 滑動後立刻退出，重開落在最後可視位置附近。
- 字級、行距、padding 改變後，以同一個 `charOffset` 回到合理位置。
- slide/scroll 切換後，`chapterIndex + charOffset` 不漂移。
- DB 寫入慢時，最後一次 pending progress 不會被舊 flush 吃掉。
- app 進入 paused/inactive/detached 時，pending progress 會 flush。
- 單章正文載入失敗不會把 placeholder 當成正式 progress。
