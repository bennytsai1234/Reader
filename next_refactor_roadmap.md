# Next Refactor Roadmap

更新日期：2026-03-20

本文不是舊版重構計畫的延續，而是以目前已完成的大重構結果為起點，重新整理接下來仍值得做的事情。

## 1. 目前已完成的重構基線

目前已落地的核心變更：

- `ReadBookController` 已成為閱讀器主控入口
- command path 已統一：
  - `jumpToSlidePage(...)`
  - `jumpToChapterLocalOffset(...)`
  - `jumpToChapterCharOffset(...)`
  - `persistCurrentProgress(...)`
- 已拆出 controller 子域：
  - `ReaderNavigationController`
  - `ReaderRestoreCoordinator`
  - `ReaderProgressStore`
  - `ReaderScrollVisibilityCoordinator`
  - `ReaderTtsFollowCoordinator`
- `ReaderChapter` 已成為共用 chapter runtime
- `ReadViewRuntime` 已抽出：
  - `ScrollExecutionAdapter`
  - `ScrollRestoreRunner`
- `ChapterContentManager` 已具備第一版 lifecycle-oriented API
- runtime helper / coordinator / integration-style tests 已建立第一版
- 性能 trace 已接到首章預熱、restore、TTS handoff 等主鏈

也就是說，閱讀器目前的問題已經不再是「主鏈不存在」，而是「內核已形成，但還可以更穩、更薄、更可測」。

## 2. 接下來的工作原則

後續不建議再做大面積推倒重來。原則應改成：

1. 小步收斂 controller 邊界
2. 用 integration tests 鎖住主鏈
3. 用真機 trace 驗證性能瓶頸
4. 只在高收益處再拆分

## 3. 優先級排序

### P0. 補齊真正的 runtime integration tests

這是現在最值得做的事。

目前雖然已有 integration-style flow test，但對核心 controller / read aloud 還不夠深。

應優先新增：

- `ReadBookController` restore flow test
  - scroll restore 到指定 `chapterIndex + localOffset`
  - slide restore 到指定 `pageIndex`
  - repaginate 後 progress 不漂移

- `ReadAloudController` runtime test
  - highlight 不重複更新
  - next/prev page or chapter 行為一致
  - prefetched handoff 正常接續

- command interaction test
  - `user` 打斷 `autoPage`
  - `user` 打斷 `tts`
  - `restore` 期間不寫 visible progress

完成標準：

- 後面再改 controller / view runtime 時，不需要靠手測判斷主鏈有沒有壞

### P1. 繼續縮小 ReadBookController

`ReadBookController` 雖然已經拆了幾個子域，但整體還是偏大。

下一步不需要再引入大量新類，而是把剩下幾塊責任再切清楚：

- 把更多 progress/restore 細節從 mixin 回收到明確 domain object
- 把 `ReadBookController` 保持在 orchestration 層
- 避免再新增橫切狀態到 controller 本體

完成標準：

- controller 更像 assembler / orchestrator
- 子域更像可單測的 runtime component

### P1. 弱化 ReaderContentMixin 的歷史責任

`ReaderContentMixin` 現在仍保留很多早期時代的流程責任。

後續應逐步讓它變成薄的 content facade，而不是同時承擔：

- fetch
- cache
- paginate
- window sync
- loadChapter orchestration
- preload interaction

方向：

- 讓 `ChapterContentManager` 再承接更多 lifecycle 語義
- 讓上層更少直接碰 `targetWindow`

完成標準：

- `ReaderContentMixin` 的重心回到「呼叫內容服務」，而不是自己掌握細節

### P2. 繼續瘦身 ReadViewRuntime

目前 `ReadViewRuntime` 已比重構前乾淨很多，但還不是純 execution layer。

仍可持續上收的點：

- scroll auto-page ticker
- 部分 restore orchestration
- 少量 scroll follow / viewport interaction policy

這一步不急，但值得持續做。

完成標準：

- `ReadViewRuntime` 更接近純執行層
- 策略判斷盡量停在 controller/coordinator

### P2. 把 performance trace 從 debug print 進一步產品化

現在的 trace 已能幫助開發期定位，但還偏 debug 工具。

下一步可以做：

- 統一 trace label 命名
- 補更多關鍵點：
  - visible preload ready
  - repaginate visible window
  - scroll new chapter ready
- 真機上做一次完整時間鏈整理

完成標準：

- 可以清楚判斷卡頓來自 fetch / process / paginate / scroll execution / TTS handoff

## 4. 不建議現在做的事

以下事情暫時不應優先：

- 再做一輪大規模架構改名
- 重新推倒 `ReaderContentMixin`
- 強行完全移除所有 mixin
- 引入更多抽象層但沒有測試保護
- 為了對齊 legado 命名而大面積改檔

原因很簡單：

目前最值錢的是「主鏈已穩」，不是「名義上更漂亮」。

## 5. 建議的執行順序

### Round 1

- 補 `ReadBookController` runtime integration tests
- 補 `ReadAloudController` runtime tests
- 補 command interaction tests

### Round 2

- 繼續縮小 `ReadBookController`
- 讓 `ReaderContentMixin` 更薄
- 再弱化 `targetWindow` 暴露

### Round 3

- 把 scroll auto-page ticker 再上收
- 補完整 performance trace
- 依真機結果做性能修正

## 6. 結論

現在的閱讀器不需要再靠大重構找方向，方向已經很明確。

接下來的最佳策略是：

- 用測試保住主鏈
- 用 trace 量出瓶頸
- 用小步重構繼續把 controller、content、view 邊界做乾淨

只要照這個順序推，後續加功能時就不會再回到「每加一個能力就重新扯動整條閱讀鏈」的狀態。
