# 下一階段交接

更新日期：2026-04-20

這份文檔是 `v0.2.4` 發版後的正式交接稿，目的是讓下一位接手的人不需要重新考古整個書源審計與產品整合過程，就能直接進入下一階段。

## 一句話結論

`v0.2.4` 已經把「書源相容層補強 + 書源狀態系統 + 執行期隔離策略 + 閱讀失敗換源」正式接進 app。下一階段不應再以大範圍書源掃描為主，而應改做：

1. JS / QuickJS 測試環境與 full suite 可信度
2. 書源健康狀態與校驗結果資料正規化
3. rule 級診斷、WebView / login recovery 與閱讀器 runtime 收尾

## 目前已完成的事情

### 書源相容層

- 大量對齊 `legado` 的 URL、Regex、CSS、JsonPath、JS bridge、TOC / 正文解析行為
- 前 `1-300` 個純小說源已完成主窗口收斂
- 非小說源、下載站、登入牆來源已有清理與隔離策略

### 書源狀態系統

- 校驗結果已接入 app，不再只是工具輸出
- `搜尋失效 / 詳情失效 / 目錄失效 / 正文失效 / 上游異常 / 非小說源 / 下載站 / 需要登入` 等狀態會影響：
  - 搜尋池
  - 閱讀可用性
  - 建議清理來源

### 閱讀器恢復能力

- 正文或章節失敗時，頁面內會直接顯示恢復卡片
- 已支援：
  - 自動換源
  - 手動換源
  - 保留閱讀進度切換來源

### UI / 產品策略

- 已移除 `ms` 響應時間顯示與排序
- 已確立「純小說閱讀器」方向，不再比照 `legado` 全收音頻 / 漫畫 / 影片源

## 目前不要再做的事情

- 不要再把主線目標設成「繼續掃更多書源」
- 不要再做大範圍 `50+` 書源 batch 驗證
- 不要再引入新功能線，特別是非核心工具頁或新平台能力
- 不要把書源健康狀態繼續綁死在 group/comment 模式上擴寫更多規則

## 已知問題

### 1. `flutter test` 尚未完全可信

本地 full suite 目前不是全綠，主要是兩類問題：

- 某些 VM / WSL 環境缺 `libquickjs_c_bridge_plugin.so`
- 少數既有 compatibility 測試仍紅

這意味著：

- `flutter analyze` 已可作為穩定護欄
- `flutter test` 目前還不能在所有本機環境上直接視為可靠綠燈

### 2. 書源健康狀態是過渡實作

目前 health 是透過：

- `bookSourceGroup` 的系統 tag
- `bookSourceComment` 的錯誤註解

推導而來，而不是獨立欄位或獨立表。這已經能用，但不夠乾淨。

### 3. 校驗結果沒有正式歷史

`CheckSourceService` 現在只有記憶體內的 `lastReport`，來源管理頁顯示的是這份最近結果，沒有真正的：

- 上次校驗時間
- 最後失敗階段
- 歷史摘要
- 來源級別的審計追蹤

### 4. WebView / login recovery 仍然偏弱

parser parity 已補很多，但：

- WebView 書源仍偏黑盒
- login 只有基礎可用
- headless recovery 的測試覆蓋還不夠

### 5. 換源仍偏「失敗後補救」

目前換源體驗已經可用，但仍主要發生在正文失敗之後。它還沒完全前移到：

- 詳情失敗
- 目錄失敗
- 來源預測性評分

這種更無感的執行期自癒層。

## 下一階段建議順序

### P0：先修測試環境與 full suite 可信度

目標：

- 讓 QuickJS 缺件時有明確的測試策略
- 收斂目前 compatibility 紅燈

完成標準：

- `flutter analyze` 全綠
- `flutter test` 不再被大量 `JS_ERROR: Library not available` 汙染
- 剩餘失敗能被明確歸類成真 regression

### P1：把書源健康狀態正規化

目標：

- 不再只靠 `group/comment` 推導健康狀態
- 讓來源管理、搜尋池、閱讀策略共用正式資料

建議落點：

- `BookSources` 新增正式欄位，或
- 建一張獨立的 `SourceHealth` / `SourceCheckState` 表

至少要有：

- `healthCategory`
- `lastCheckedAt`
- `lastStage`
- `lastMessage`
- `quarantined`
- `cleanupCandidate`

### P2：把校驗結果做成正式歷史

目標：

- app 重啟後仍看得到上次校驗資訊
- 來源管理頁可以按狀態、時間、建議清理與隔離做篩選

建議不要一開始就做完整歷史表；先把最後一次結果落地即可。

### P3：補 engine 的 rule 級診斷與 WebView / login recovery

目標：

- 錯誤能追到：
  - 哪個階段
  - 哪條 rule
  - 哪個 URL
- WebView / login 類失敗不再只是 timeout 或黑盒錯誤

### P4：閱讀器 runtime 與換源流程收尾

目標：

- 讓換源從「正文失敗後補救」往前推
- 繼續收斂 `ReadBookController` / `ReaderContentMixin`

## 建議先讀哪些檔

如果是要直接開始下一階段，建議閱讀順序：

1. [roadmap.md](roadmap.md)
2. [reader_architecture_current.md](reader_architecture_current.md)
3. [DATABASE.md](DATABASE.md)
4. [source_audit_backlog.md](source_audit_backlog.md)

之後直接看這些程式檔：

- [js_engine.dart](/home/benny/projects/reader/lib/core/engine/js/js_engine.dart)
- [check_source_service.dart](/home/benny/projects/reader/lib/core/services/check_source_service.dart)
- [book_source_logic.dart](/home/benny/projects/reader/lib/core/models/source/book_source_logic.dart)
- [headless_webview_service.dart](/home/benny/projects/reader/lib/core/engine/web_book/headless_webview_service.dart)
- [read_book_controller.dart](/home/benny/projects/reader/lib/features/reader/runtime/read_book_controller.dart)

## 執行與驗證注意事項

這個 repo 在 WSL 下容易被重型 Dart / Flutter 命令頂爆，請遵守：

- 一次只跑一個 heavy command
- 不要同時跑 `analyze` 和 `test`
- 不要再做大型 batch source validation
- 優先 targeted test

建議順序：

1. 先改資料模型 / 文檔
2. `flutter analyze`
3. targeted `flutter test`
4. 只有真的需要時才跑 full `flutter test`

## 當前完成判斷

下一階段如果做到以下幾件事，就算真的往前跨一大步：

- full suite 的可信度恢復
- 書源健康狀態脫離 `group/comment` 過渡實作
- 校驗結果能持久化
- WebView / login 類來源不再是黑盒
- 換源從「補救」走向更主動的執行期恢復
