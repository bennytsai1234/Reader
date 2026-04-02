# Reader Project Roadmap

更新日期：2026-04-02

這份 roadmap 不是零碎待辦清單，而是專案在 `0.1.6` 之後的優先級約束。原則只有一個：先讓已經存在的核心能力變穩，再決定要不要擴張功能面。

## 專案目標

這個專案要完成的不是一個短期 demo，而是一個：

- 可長期維護的 Flutter 閱讀器
- 以中文閱讀體驗為核心
- 同時支援本地書與網路書源
- 具備穩定閱讀器 runtime、可預測書源引擎與可追蹤資料層
- 可自行建置、側載、測試與持續發版的 app

## 截至 0.1.6 之後的進展（2026-04-02）

M1 與 M2 的主要工作已完成：

- **Parser Alignment（M2）**：CSS exclusion、html/textNodes、AnalyzeRule `@put` timing、SourceRule mode detection、XPath 自訂函數（allText/textNodes/ownText）、JS Extensions 缺失 method 補齊、書源登入流程（source_login_page + BaseSource login methods）—— 均已落地，tests 全通過
- **Reader Lifecycle Refactor（M1）**：`ReaderLifecycle` 簡化（移除 `restoring`）、`batchUpdate`、`SlideWindow`/`SlideSegment`、`ContentCallbacks`（消滅 `this as dynamic`）、`SlidePageController`—— 均已落地
- **Slide mode bugs**：Bug 1（`_handleChapterReady` 漏 notify）與 Bug 2（跨章節邊界閃現 PageController reset）均已修復

目前狀態：324 tests 全通過，`flutter analyze` 零問題。

**下一主線：M3（settings / cache / storage / export 收斂）**

---

## 截至 0.1.6 的專案判讀

整個專案目前已經跨過「只有零散功能」的階段，進入「已有完整主線，但邊界還在收斂」的階段。

相對成熟的部分：

- 閱讀器 runtime 已經形成以 `ReadBookController` 為核心的責任鏈
- `core/engine` 已有完整 parser 與 source login 支撐
- Drift + DAO 的資料層骨架穩定
- 備份、還原、匯出、下載、widget 等平台能力已有基礎實作
- 測試已開始覆蓋閱讀器與解析器主流程

仍需優先處理的問題：

- 某些 feature 的 provider / service / page 邊界仍不夠乾淨
- `core/services` 與 feature 協調層偶爾混責
- 文檔和版本資訊過去曾出現漂移，必須持續收斂
- 平台能力雖然已存在，但一致性與回歸保護還不夠

## 最高優先級

接下來的工作應只按下面順序推進：

1. 閱讀器核心穩定性
2. 書源引擎可預測性
3. 資料層與平台能力一致性
4. UI 與工具頁整理

如果時間有限，永遠先保護前兩項。

## 近期主線

### M1：閱讀器 runtime 收斂

目標：

- 讓 restore、progress、jump、visible tracking、TTS follow 的責任邊界保持穩定
- 繼續降低 widget 層對 runtime 細節的了解
- 確保 scroll / slide 兩條路徑共用同一套章內語義

完成標準：

- 閱讀位置真源清楚
- restore / progress 不再靠多點同步維持
- 閱讀器主流程測試能覆蓋常見回歸

### M2：書源引擎對齊與隔離

目標：

- 讓 parser 行為更穩定、更容易驗證
- 確保 source login、cookie、header、webview 行為可預測
- 讓 `core/engine` 對外呈現更清楚的語意 API

完成標準：

- 常見規則語法有 integration tests 保護
- login source 具最小回歸保護
- 書源解析問題可以在 engine 層定位，而不是 UI 層猜測

### M3：資料與平台能力一致化

目標：

- 收斂備份 / 還原 / 匯出 / 快取 / 儲存空間指標的版本與路徑口徑
- 確保 migration、manifest、DAO、設定項沒有版本漂移
- 繼續把平台與檔案系統能力集中到 `core/storage` + `core/services`

完成標準：

- 版本資訊只由少數可信來源決定
- manifest、資料庫 schema、文檔與實作一致
- 檔案路徑與容量管理不再分散

### M4：產品模組整理

目標：

- 減少 feature 內部平行頁面或平行流程
- 清理書架、設定、快取管理與工具頁的重複責任
- 讓功能入口與實際責任更容易理解

完成標準：

- 同一件事只有一條主要代碼路徑
- 不再出現「新頁面疊在舊頁面上」的擴張方式

## 明確不做的事

在上述主線完成前，不建議：

- 引入新的狀態管理框架
- 引入第二套資料層抽象
- 大量新增細碎工具頁
- 為了短期修 bug 再建立平行的 provider / service / runtime

## 發版原則

從 `0.1.6` 起，建議沿用以下規則：

- 每次發版先統一 `pubspec.yaml`、iOS version metadata、備份 manifest 版本口徑
- 發版前至少跑 `flutter analyze` 與 `flutter test`
- 只有在工作區、文檔與版本資訊一致時才推送
- tag 可以做，但應在版本內容穩定後再建立

## 一句話總結

這個專案目前最需要的不是更多功能，而是繼續把已經存在的核心能力做成一套可推理、可測試、可發版的系統。

責任：

- DAO
- repository
- API / storage / resource service
- database / cache / export / import

原則：

- DAO 只做資料存取
- service / repository 組合多個資料來源
- UI 不直接繞過 application 層碰資料

## 7.4 Engine

責任：

- 書源規則解析
- URL 分析
- CSS / XPath / JsonPath / Regex / JS
- 章節內容抓取與解析

原則：

- engine 不知道具體 UI
- engine 的輸入輸出應可測試
- parser 行為優先追求一致性與可驗證性

## 8. 開發規則

接下來的開發都應遵守：

- 不再新增第二套相同功能頁
- 新功能先決定屬於哪個 module，再開始寫
- UI 不直接碰 DAO、路徑與平台 API
- 路徑統一進 `core/storage`
- 平台能力統一進 `core/services` 或 `core/platform`
- 每個核心模組至少要有一條 integration path 可測
- 大改動完成後必跑 `flutter analyze` 與 `flutter test`

## 9. 最近建議執行順序

最接近現在代碼狀態、最值得優先做的順序：

1. 整理 `settings / cache / storage / export`
2. 繼續收斂 `reader` runtime 邊界
3. 補 `source_manager` 與 `core/engine` 的登入 / parser 對齊
4. 整理 `bookshelf / book_detail / search` 的資料流
5. 最後再擴大做平台能力與發版流程

## 10. 成功判斷標準

這個專案算是走上正軌，不是看功能數量，而是看這些問題是否成立：

- 能清楚說出每個主要模組的責任
- 新功能不會自然長出第二套實作
- 閱讀器與書源引擎有穩定測試護欄
- 發版不需要每次重新摸索流程
- 專案新增功能時，不會再先亂長、後補整理
