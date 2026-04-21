# Reader 基本閱讀器重構授權任務書

更新日期：2026-04-21

這份文檔是 `docs/reader_core_optimization_handoff.md` 的強授權版本。

只有在明確允許「大範圍重設計」時，才應使用這份任務書。

## 一句話目標

允許下一位 agent 對 `reader` 的基本閱讀器做大範圍重設計，必要時可明確參考 `legado` 的閱讀器結構與成熟行為作為模板，但最終產物必須：

- 仍然只覆蓋基本閱讀器範圍
- 在 Flutter / Dart 環境下穩定運行
- 不因為重構而把產品邊界擴大
- 不把 Android 專屬設計硬搬進 Flutter

## 本任務書取代了哪些限制

相對於保守優化版，這份文檔明確解除以下限制：

- 允許大範圍重構 `features/reader`
- 允許重切 `runtime / provider / engine / view` 的責任邊界
- 允許用 `legado` 作為結構模板與行為規格參考
- 允許刪除、替換、遷移目前不理想的設計
- 允許 staged migration，而不是只做小修小補

但它沒有解除這些限制：

- 不得把產品範圍擴到基本閱讀器以外
- 不得為了「像 `legado`」而新增多餘功能
- 不得犧牲 Flutter 端穩定性

## 產品範圍仍然固定

本輪仍然只處理以下範圍：

1. 閱讀頁 UI 殼
2. 閱讀狀態控制
3. 章內分頁
4. scroll / slide 閱讀模式
5. 進度保存與還原
6. 章節切換
7. 基本閱讀設定影響排版

### 明確不在範圍內

- 書架
- 搜尋
- 探索
- 書源管理的大改
- RSS
- Android-only 工具頁
- 額外翻頁模式
- 與基本閱讀器無直接關係的新產品功能

## 允許做什麼

### 結構層面

- 允許重寫 `ReadBookController` 及其周邊協調鏈
- 允許淘汰不合理的 mixin 鏈
- 允許重做 scroll / slide executor 與 delegate 分工
- 允許重做章節 runtime model、頁面 model、restore model
- 允許重做內容管理與預載模型
- 允許重設閱讀設定對排版與 restore 的回推流程

### 對 legado 的使用方式

允許直接把 `legado` 當成：

- 閱讀器成熟行為 spec
- 結構模板參考
- 邊界情況與互動設計樣本

允許借的結構思想包括：

- `ReadBook + ViewModel + ReadView + ChapterProvider + TextChapter` 這種角色分離方式
- 三槽位或閱讀窗口的章節持有思路
- 章內位置與頁面映射模型
- 設定變更後固定重排流程
- 切章與相鄰章預載的直覺時序

### 明確允許的重構風格

- 先建立新結構，再逐步遷移舊邏輯
- 新舊路徑短期並存，只要最後能收斂
- 以 compatibility layer 過渡
- 以測試驅動的結構替換

## 不允許做什麼

### 不允許盲目照搬

雖然允許參考 `legado` 模板，但不允許：

- 逐檔照抄 Kotlin / Android View 實作
- 直接把 Android `View` 邏輯翻譯成不自然的 Flutter code
- 把 `legado` 的產品膨脹一起搬過來

### 不允許犧牲 Flutter 穩定性

只要造成下列任一情況，就算重構方向失敗：

- Flutter 端出現明顯 rebuild loop
- `PageController` / scroll 控制器頻繁 assert
- 頁面切換或 restore 在 Flutter widget lifecycle 下不穩
- `flutter analyze` 無法收斂
- 閱讀頁在 Flutter 上的互動體感變差

### 不允許失去閱讀器邊界

本輪不是「把 app 重做成另一個 `legado`」，而是：

- 把 Flutter 版基本閱讀器做成成熟內核

## Flutter 工程穩定性仍需維持

即使進行大範圍重設計，最後也必須至少滿足：

### 1. Flutter 架構上可維持

- 結構符合 Flutter / Dart 的 idiom
- 不依賴 Android 專屬生命周期假設
- 不建立過於脆弱的 widget 與 runtime 相互依賴

### 2. Flutter 工具鏈上可維持

- `flutter analyze` 必須通過
- Reader 相關 targeted tests 必須通過
- 至少要有 compile / widget / runtime flow 級別的驗證

### 3. Flutter 執行期設計不可失控

- 不應引入明顯脆弱的 widget / controller / runtime 耦合
- 不應讓 scroll / slide 切換、切章、restore、repaginate 的既有語義退化
- 不應把閱讀器推向明顯易崩潰或難以維護的結構

### 4. 不要求 Flutter 啟動 smoke

本任務書不再要求：

- `flutter run` 到可用裝置或桌面 target
- 進閱讀頁 smoke test

可接受的最低驗證基線是：

- `flutter analyze`
- reader 相關 targeted tests
- 至少一輪 runtime / compile 驗證

## 推薦重構策略

### Phase 0：先定合約，再動結構

先明確定義以下 contract：

- durable location contract
- visible location contract
- slide / scroll 共用的位置語義 contract
- 設定改變後的 repaginate contract
- 切章 contract
- restore contract

沒有這份 contract，不允許直接大改。

### Phase 1：抽新內核，不先追 UI

先重構：

- 閱讀位置模型
- 章內 runtime model
- content lifecycle
- scroll / slide executor

不要一開始就先做 menu、sheet、toolbar 重畫。

### Phase 2：建立新舊橋接層

允許短期保留舊 page shell、舊 settings sheet、舊 menu，只要：

- 新內核能接入
- 可逐步淘汰舊 runtime workaround

### Phase 3：遷移完成後再刪舊碼

禁止在沒有替代方案前先暴力刪大段舊邏輯。

正確順序是：

1. 建新內核
2. 接線
3. 補測試
4. 驗證穩定
5. 移除舊碼

### Phase 4：以 Flutter 體感做最後修正

最終以 Flutter 端實際體感驗收，而不是以「和 `legado` 長得像」驗收。

## 可直接重點參考的檔案

### reader 現況真源

- [lib/features/reader/runtime/read_book_controller.dart](/home/benny/projects/reader/lib/features/reader/runtime/read_book_controller.dart:44)
- [lib/features/reader/provider/reader_content_facade_mixin.dart](/home/benny/projects/reader/lib/features/reader/provider/reader_content_facade_mixin.dart:22)
- [lib/features/reader/view/read_view_runtime.dart](/home/benny/projects/reader/lib/features/reader/view/read_view_runtime.dart:18)
- [lib/features/reader/runtime/models/reader_location.dart](/home/benny/projects/reader/lib/features/reader/runtime/models/reader_location.dart:1)
- [lib/features/reader/runtime/models/reader_chapter.dart](/home/benny/projects/reader/lib/features/reader/runtime/models/reader_chapter.dart:6)

### legado 參考真源

- [../legado/app/src/main/java/io/legado/app/model/ReadBook.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/model/ReadBook.kt:61)
- [../legado/app/src/main/java/io/legado/app/ui/book/read/ReadBookViewModel.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/ui/book/read/ReadBookViewModel.kt:60)
- [../legado/app/src/main/java/io/legado/app/ui/book/read/page/ReadView.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/ui/book/read/page/ReadView.kt:51)
- [../legado/app/src/main/java/io/legado/app/ui/book/read/page/provider/ChapterProvider.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/ui/book/read/page/provider/ChapterProvider.kt:47)
- [../legado/app/src/main/java/io/legado/app/ui/book/read/page/entities/TextChapter.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/ui/book/read/page/entities/TextChapter.kt:21)
- [../legado/app/src/main/java/io/legado/app/help/config/ReadBookConfig.kt](/home/benny/projects/legado/app/src/main/java/io/legado/app/help/config/ReadBookConfig.kt:42)

## 建議的新結構方向

這不是唯一答案，但下一位 agent 可以大膽往這個方向靠：

- `ReaderSession` 或等價物：持有 durable / visible / transient state
- `ReaderRuntimeController`：接收命令，協調 restore、progress、navigation
- `ReaderContentPipeline`：負責章節內容載入、分頁、預載、cache
- `ReaderViewportRuntime`：專責 scroll / slide 執行
- `ReaderUiShell`：只保留頁面殼與 menu / sheet 接線

也就是說，允許把現在的：

- mixin 鏈
- 巨型 controller
- UI/runtime 交互補丁

往更乾淨的核心結構重切。

## 強制驗收項目

### A. 正確性

- 首次打開位置正確
- 關閉再進位置正確
- scroll 中途退出再進位置合理
- slide 翻頁後重進不回退
- 切章不錯章
- 章尾進下一章、章首回上一章行為穩定

### B. 排版與設定

- 字級調整後位置合理
- 行距調整後位置合理
- 段距、縮排調整後不亂跳
- 主題與模式切換後不破壞閱讀位置

### C. 體感

- scroll / slide 切換時不大幅跳位
- 沒有顯著白屏、空頁、頁碼不同步
- 預載與重排不造成明顯卡死

### D. Flutter 工程穩定性

- `flutter analyze`
- reader targeted tests
- 至少一輪 runtime / compile 驗證

## 測試與驗證要求

至少應覆蓋：

- [test/features/reader/read_book_controller_test.dart](/home/benny/projects/reader/test/features/reader/read_book_controller_test.dart:1)
- [test/features/reader/reader_progress_coordinator_test.dart](/home/benny/projects/reader/test/features/reader/reader_progress_coordinator_test.dart:1)
- [test/features/reader/reader_restore_coordinator_test.dart](/home/benny/projects/reader/test/features/reader/reader_restore_coordinator_test.dart:1)
- [test/features/reader/reader_runtime_flow_test.dart](/home/benny/projects/reader/test/features/reader/reader_runtime_flow_test.dart:1)
- [test/features/reader/chapter_content_manager_test.dart](/home/benny/projects/reader/test/features/reader/chapter_content_manager_test.dart:1)
- [test/features/reader/chapter_content_manager_lifecycle_test.dart](/home/benny/projects/reader/test/features/reader/chapter_content_manager_lifecycle_test.dart:1)
- [test/features/reader/reader_page_compile_test.dart](/home/benny/projects/reader/test/features/reader/reader_page_compile_test.dart:1)

必要時可新增：

- scroll / slide parity tests
- repaginate restore tests
- mode switch restore tests
- chapter boundary regression tests

## 授權下的 subagent 規則

這份任務書明確允許使用 subagent，而且可以比保守版更積極。

### 建議分工

- Explorer A：現有 `reader` runtime 與 tests 的契約整理
- Explorer B：`legado` 閱讀器結構模板抽取，只提取可遷移設計，不做 wish list
- Worker A：新位置語義與 session runtime
- Worker B：新 content pipeline 與 cache / preload
- Worker C：scroll / slide viewport runtime
- Worker D：UI shell 接線與舊碼清理
- Worker E：回歸測試補齊

### 協作規則

- 主 agent 必須保留總體架構決策權
- write scope 必須先切乾淨
- 不允許多個 worker 同時亂改同一批核心檔案
- 最終整合、測試與 analyze 由主 agent 負責

## 交付要求

下一位 agent 最終必須提交：

- 重構後的 code
- 清楚的結構說明
- 主要變更檔案清單
- 測試清單
- 實際執行的驗證命令
- `flutter analyze` 結果
- 剩餘風險與未完成項目

## 完成定義

只有在同時滿足下面條件時，才算完成：

- `reader` 的基本閱讀器已被大幅收斂或重構
- 體感更接近 `legado`
- 沒有超出基本閱讀器產品邊界
- Flutter 端仍然穩定運行
- 重構後比現在更可維護，而不是更脆弱
