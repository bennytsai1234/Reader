# Reader 基本閱讀器優化交接

更新日期：2026-04-21

這份文檔只定義 `reader` 目前「基本閱讀器」的優化任務，不擴張產品範圍，不以功能數量對齊 `legado`。

## 一句話目標

把 `reader` 目前已存在的基本閱讀器做成：

- 體感接近 `legado`
- 只保留既有範圍
- 不新增多餘功能
- 行為可預測
- 核心鏈路有測試護欄

這裡的「基本閱讀器」只包含：

1. 閱讀頁 UI 殼
2. 閱讀狀態控制
3. 章內分頁
4. scroll / slide 閱讀模式
5. 進度保存與還原
6. 章節切換
7. 基本閱讀設定影響排版

## 範圍邊界

### In Scope

- `features/reader` 內與正文閱讀直接相關的 UI、runtime、engine、view
- 現有 `slide` / `scroll` 兩條主線的穩定性、流暢度、可預測性
- 排版參數改變後的重排與位置保持
- 進度保存、退出還原、切章、跳章、章節預載
- 既有功能的 bug fix 與結構收斂
- 與 `legado` 的行為對照，只限於閱讀器成熟度，不包含額外功能照抄

### Out Of Scope

- 新增 `legado` 才有的額外翻頁模式
- 為了對齊 `legado` 而補 `RSS`、工具頁、Android-only 互動
- 書架、搜尋、探索、書源管理的大範圍重寫
- 新增閱讀器外的產品功能
- 重新發明一套新的 state management 或資料層

### 非本輪主線，但不得被破壞

- 現有 TTS / auto page / change source 入口
- 本地書 TXT / EPUB / UMD 的基本閱讀路徑
- 現有測試可覆蓋的 reader runtime 行為

## 和 legado 的對照策略

`legado` 在這份任務裡只能扮演兩種角色：

- 閱讀行為成熟度的參考
- 邊界情況與互動預期的對照樣本

不要把 `legado` 當成：

- 功能清單來源
- 需要逐頁複製的 Android 模板

要借的，是它的成熟度：

- 切章順
- 翻頁穩
- 還原準
- 設定改變後不亂跳
- 鄰章載入與內容顯示的時序直覺

不要借的，是它的產品膨脹：

- 更多動畫模式
- 更多工具對話框
- 更多 Android 系統整合

## 目前應視為真源的檔案

### reader 側

- [lib/features/reader/runtime/read_book_controller.dart](/home/benny/projects/reader/lib/features/reader/runtime/read_book_controller.dart:44)
- [lib/features/reader/runtime/models/reader_location.dart](/home/benny/projects/reader/lib/features/reader/runtime/models/reader_location.dart:1)
- [lib/features/reader/runtime/models/reader_chapter.dart](/home/benny/projects/reader/lib/features/reader/runtime/models/reader_chapter.dart:6)
- [lib/features/reader/runtime/reader_progress_coordinator.dart](/home/benny/projects/reader/lib/features/reader/runtime/reader_progress_coordinator.dart:1)
- [lib/features/reader/runtime/reader_restore_coordinator.dart](/home/benny/projects/reader/lib/features/reader/runtime/reader_restore_coordinator.dart:1)
- [lib/features/reader/provider/reader_content_facade_mixin.dart](/home/benny/projects/reader/lib/features/reader/provider/reader_content_facade_mixin.dart:22)
- [lib/features/reader/provider/reader_settings_mixin.dart](/home/benny/projects/reader/lib/features/reader/provider/reader_settings_mixin.dart:10)
- [lib/features/reader/engine/chapter_content_manager.dart](/home/benny/projects/reader/lib/features/reader/engine/chapter_content_manager.dart:1)
- [lib/features/reader/view/read_view_runtime.dart](/home/benny/projects/reader/lib/features/reader/view/read_view_runtime.dart:18)
- [lib/features/reader/view/delegate/page_mode_delegate.dart](/home/benny/projects/reader/lib/features/reader/view/delegate/page_mode_delegate.dart:1)
- [lib/features/reader/view/delegate/scroll_mode_delegate.dart](/home/benny/projects/reader/lib/features/reader/view/delegate/scroll_mode_delegate.dart:1)

### legado 對照檔案

- [../legado/app/src/main/java/io/legado/app/model/ReadBook.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/model/ReadBook.kt:61)
- [../legado/app/src/main/java/io/legado/app/ui/book/read/ReadBookViewModel.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/ui/book/read/ReadBookViewModel.kt:60)
- [../legado/app/src/main/java/io/legado/app/ui/book/read/page/ReadView.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/ui/book/read/page/ReadView.kt:51)
- [../legado/app/src/main/java/io/legado/app/ui/book/read/page/provider/ChapterProvider.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/ui/book/read/page/provider/ChapterProvider.kt:47)
- [../legado/app/src/main/java/io/legado/app/ui/book/read/page/entities/TextChapter.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/ui/book/read/page/entities/TextChapter.kt:21)
- [../legado/app/src/main/java/io/legado/app/help/config/ReadBookConfig.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/help/config/ReadBookConfig.kt:42)

## 核心設計原則

### 1. 位置語義只能有一套真源

`chapterIndex / charOffset / localOffset / pageIndex` 必須可互相推導，但不能各自為政。

本輪以 `ReaderLocation(chapterIndex, charOffset)` 為 durable 真源，其他位置只作 runtime 投影。

### 2. slide 與 scroll 不是兩套閱讀器

它們可以有不同 executor，但不能有不同的真實閱讀位置語義。

### 3. 設定改變一定走固定重排流程

字級、行距、段距、縮排、主題、翻頁模式改變後，必須：

- 更新 config
- 重建分頁
- 重新定位
- 只在必要時 reset controller

不能靠零散 patch 補救。

### 4. 切章、預載、restore 要有可推理的先後順序

不要讓 UI rebuild、內容載入、scroll restore、preload 互相踩時序。

### 5. 先修正確性，再談局部效能

只有在閱讀位置正確、restore 正確、章節切換穩定後，才處理多餘 rebuild、閃爍、抖動。

## 明確交付目標

下一位 agent 的任務不是提出方案，而是把下列內容實作到可驗證：

### A. 閱讀位置穩定

- 首次打開書籍，位置正確
- 關閉後重進，位置正確
- scroll 模式中途退出再進，位置接近退出時可見位置
- slide 模式切頁後保存位置，重進不跳回前一頁
- 切章後頁碼、章名、進度顯示同步更新

### B. 章內分頁穩定

- 改字級、行距、段距、縮排後不會明顯跳錯章
- 重排後能回到合理的章內位置
- 本地書在常見情況下不出現空白頁、重複頁、卡住不翻

### C. scroll / slide 體感一致

- 同一個章節位置在兩種模式間切換時，不出現大幅錯位
- scroll 模式的 visible tracking 能正確驅動進度保存
- slide 模式的 page index、global page、chapter page 映射穩定

### D. 內容生命週期穩定

- 當前章、前後章的載入與預載順序可預測
- 切章邊界不出現明顯閃爍或佔位卡死
- 設定改變、尺寸改變、重新進頁後，不會殘留過期 cache 導致位置錯亂

### E. UI 殼只做殼的工作

- 閱讀頁 UI 保留現有功能，但不再承擔隱性 runtime 修正責任
- 不以新增大量 UI 功能作為本輪成果

## 推薦實作順序

### Phase 0：建立基線

- 先讀 `docs/reader_architecture_current.md`
- 先確認目前 dirty worktree，避免覆蓋既有修改
- 先跑一次與 reader 直接相關的 targeted tests
- 如果本輪有 code change，結尾必須跑 `flutter analyze`

### Phase 1：位置語義收斂

主要目標：

- 收斂 `sessionLocation / visibleLocation / durableLocation`
- 清理 `currentChapterIndex / visibleChapterIndex / currentPageIndex` 的責任邊界
- 檢查 scroll 模式 `visible localOffset -> charOffset` 的正確性
- 檢查 slide 模式 `pageIndex -> charOffset` 的正確性

重點檔案：

- `runtime/models/reader_location.dart`
- `runtime/models/reader_chapter.dart`
- `runtime/reader_progress_coordinator.dart`
- `runtime/reader_restore_coordinator.dart`
- `runtime/read_book_controller.dart`

### Phase 2：內容生命週期收斂

主要目標：

- 把內容載入、silent preload、window warmup、recenter 的責任切清楚
- 排除章節 ready、controller reset、deferred warmup 之間的時序競態
- 確保 scroll 與 slide 對 content manager 的使用規則一致

重點檔案：

- `provider/reader_content_facade_mixin.dart`
- `engine/chapter_content_manager.dart`
- `engine/reader_chapter_content_loader.dart`

### Phase 3：模式執行器收斂

主要目標：

- 讓 `ReadViewRuntime` 只做協調，不做過多隱性補償
- 降低 mode switch 後的抖動、重複 restore、重複 rebuild
- 檢查 scroll executor、scroll restore、slide page change 的時序

重點檔案：

- `view/read_view_runtime.dart`
- `view/scroll_runtime_executor.dart`
- `view/scroll_restore_runner.dart`
- `view/delegate/page_mode_delegate.dart`
- `view/delegate/scroll_mode_delegate.dart`

### Phase 4：設定與重排穩定性

主要目標：

- 所有基本閱讀設定都走一致的 repaginate 流程
- 設定改變後，位置保持以 durable 語義回推
- 避免字級或行距調整後掉到錯章、頁碼錯、可見位置錯

重點檔案：

- `provider/reader_settings_mixin.dart`
- `runtime/read_book_controller.dart`
- `provider/reader_content_facade_mixin.dart`

### Phase 5：UI 殼收尾

主要目標：

- 清掉閱讀頁內為了掩蓋 runtime 問題而存在的 UI 層 workaround
- 保持現有 menu、drawer、settings sheet 可用
- 不新增本輪 scope 外的 UI 功能

重點檔案：

- `reader_page.dart`
- `reader_layout.dart`
- `widgets/reader/*`
- `widgets/reader_chapters_drawer.dart`

### Phase 6：回歸測試補齊

必補情境：

- 首次打開閱讀器
- 重進閱讀器 restore
- scroll 模式退出再進
- slide / scroll 切換
- 字級調整
- 行距調整
- 章節切換
- 章尾進下一章
- 章首回上一章
- 本地書常見路徑

## 驗收標準

### 功能驗收

- `slide` 與 `scroll` 都能完成閱讀主線，不依賴 scope 外功能
- 同一本書在兩種模式間切換，不發生明顯錯章或大幅跳位
- 設定改變後可持續閱讀，不必手動重新找位置
- 章節切換、退出還原、重進還原都符合預期

### 體感驗收

- 不應頻繁出現空白頁、閃一下又跳位、頁碼延遲更新、章名延遲更新
- 本地書閱讀不應因預載或重排而明顯卡住
- scroll 模式下可見位置更新應足夠即時

### 工程驗收

- `flutter analyze` 需在最終 worktree 上執行一次
- 新增或修正對應的 reader targeted tests
- 不接受只修 UI 表面症狀、不修 runtime 真因

## 測試建議

優先跑 reader targeted tests，不要一開始就 full suite。

建議至少覆蓋：

- [test/features/reader/read_book_controller_test.dart](/home/benny/projects/reader/test/features/reader/read_book_controller_test.dart:1)
- [test/features/reader/reader_progress_coordinator_test.dart](/home/benny/projects/reader/test/features/reader/reader_progress_coordinator_test.dart:1)
- [test/features/reader/reader_restore_coordinator_test.dart](/home/benny/projects/reader/test/features/reader/reader_restore_coordinator_test.dart:1)
- [test/features/reader/reader_runtime_flow_test.dart](/home/benny/projects/reader/test/features/reader/reader_runtime_flow_test.dart:1)
- [test/features/reader/chapter_content_manager_test.dart](/home/benny/projects/reader/test/features/reader/chapter_content_manager_test.dart:1)
- [test/features/reader/chapter_content_manager_lifecycle_test.dart](/home/benny/projects/reader/test/features/reader/chapter_content_manager_lifecycle_test.dart:1)
- [test/features/reader/reader_chapter_runtime_test.dart](/home/benny/projects/reader/test/features/reader/reader_chapter_runtime_test.dart:1)
- [test/features/reader/reader_position_resolver_test.dart](/home/benny/projects/reader/test/features/reader/reader_position_resolver_test.dart:1)
- [test/features/reader/reader_page_compile_test.dart](/home/benny/projects/reader/test/features/reader/reader_page_compile_test.dart:1)

## 明確禁止事項

- 不要把本輪任務變成 `legado` 功能補完計畫
- 不要順手擴 scope 到書架、搜尋、探索、書源系統
- 不要一次大改多個子域卻沒有補測試
- 不要用 UI workaround 掩蓋 runtime 錯誤
- 不要在未確認責任邊界前，重寫整個 reader

## Subagent 協作說明

如果執行環境支援 subagent，本任務允許使用 subagent，但必須遵守下列原則：

- 主 agent 必須先決定整體策略，再分派子任務
- `read_book_controller.dart` 由主 agent 持有，不建議平行改寫
- subagent 只處理明確、可界定、低衝突的子域
- 每個 subagent 都要有清楚的檔案 ownership
- 主 agent 負責最後整合、驗證、補測試、跑 `flutter analyze`

建議拆法：

- Explorer A：只讀 `reader` runtime 與 tests，整理不變條件與已知缺口
- Explorer B：只讀 `legado` 閱讀器主線，列出可借的成熟行為，不列功能 wishlist
- Worker A：`runtime/models/*`、`reader_progress_coordinator.dart`、`reader_restore_coordinator.dart`
- Worker B：`provider/reader_content_facade_mixin.dart`、`engine/*`
- Worker C：`view/*`、`reader_page.dart` 內與模式切換直接相關的行為

如果要平行寫入，務必先避免 write scope 重疊。

## 最終交付應包含

- 完成後的 code change
- 補上的 targeted tests
- 實際跑過的驗證命令與結果摘要
- 仍存在的已知風險
- 若有刻意延後處理的項目，必須明列原因

## 完成定義

當下一位 agent 完成這份文檔後，應能合理聲稱：

- `reader` 的基本閱讀器已經比目前明顯更穩
- 體感更接近 `legado`
- 沒有為了對齊 `legado` 而新增大量非必要功能
- 閱讀器核心更可推理，而不是更混亂
