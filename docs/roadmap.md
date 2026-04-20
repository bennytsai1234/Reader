# 路線圖

更新日期：2026-04-20

這份 roadmap 不是零碎待辦清單，而是墨頁在 `v0.2.4` 之後的優先級約束。原則只有一個：**不再擴充新功能，持續優化既有的核心能力**。

## 專案目標

墨頁要完成的不是短期 demo，而是一個：

- 可長期維護的 Flutter 閱讀器
- 以中文閱讀體驗為核心
- 同時支援本地書與網路書源
- 有穩定閱讀器 runtime、可預測書源引擎、可追蹤資料層
- 可自行建置、側載、測試、持續發版的 app

## 到 0.2.4 為止的進度

**核心架構已落地**：

- 閱讀器 runtime 以 `ReadBookController` 為中心，coordinator 拆分完成
- `core/engine` 有完整 parser + source login + charset 偵測
- Drift + DAO（schema v8）資料層骨架穩定
- 備份、還原、匯出、下載、widget 等平台能力有基礎實作
- 82 個測試檔覆蓋閱讀器主流程、parser、book source、JS extensions、bookshelf exchange、source manager 與 source health

**已完成的主要里程碑**：

| M | 內容 | 狀態 |
|---|------|------|
| M1 | 閱讀器 Lifecycle Refactor（lifecycle 簡化、SlideWindow、ContentCallbacks、SlidePageController） | ✅ |
| M2 | Parser Alignment（CSS / html textNodes / AnalyzeRule @put / XPath 自訂函數 / JS extensions / source login） | ✅ |
| M3 | 儲存一致化（`AppStoragePaths`、`AppVersion`、BackupService 補齊、PreferKey） | ✅ |
| M4 | 書架 / 書籍詳情 / 搜尋資料流整理 | ✅ |
| M5 | 全域 Widget 層 DAO 呼叫消除 | ✅ |
| M6 | 搜尋架構重構（SearchProvider → SearchModel → SearchScope） | ✅ |
| M7 | 發現頁重構（對齊 Legado 雙層書源） | ✅ |
| M8 | 書源管理體驗升級（checkbox 預設、overflow menu、drag handle） | ✅ |
| — | 發現頁亂碼 / 「暫無章節」修復（charset + tocUrl 備援） | ✅ |
| — | JS Promise bridge（async 規則執行） | ✅ |
| M9 | 閱讀器 Runtime 收斂與產品模組清理（TTS mixin 提取、settings 重組、scroll_auto_page_driver 刪除、battery mixin 提取） | ✅ |
| M10 | 備份 / 還原能力補齊（RestoreService 實作、BackupSettingsPage UI、備份一致性優化、下載任務備份擴充） | ✅ |
| M11 | 書架匯入匯出與本地格式管理（BookshelfExchangeService、LocalBookFormats 集中化、UMD parser 重寫） | ✅ |
| M12 | 書源相容層與產品策略收斂（source parity、書源狀態系統、執行期隔離、閱讀失敗換源） | ✅ |

## 長期目標

`v0.2.4` 之後，專案定位仍然是**不再擴充新功能**，而是持續優化既有的 8 項基礎能力。每項基礎走完四個階段才算穩定：

**8 項基礎能力與當前階段**

| # | 基礎能力 | 設計 | 可用 | 流暢 | UI/UX | 備註 |
|---|---------|------|------|------|-------|------|
| 1 | 書架管理、分組、書籍詳情、章節列表 | ✅ | ✅ | — | — | M11 新增匯入匯出功能 |
| 2 | 搜尋（全部 / 分類 / 單一書源）與探索頁 | ✅ | ✅ | — | — | M6 / M7 完成重構，已接入書源健康過濾 |
| 3 | 本地 TXT / EPUB / MOBI / PDF / UMD 匯入 | ✅ | ⚙️ | — | — | UMD parser 已重寫；LocalBookFormats 集中化 |
| 4 | 網路書源解析、登入、WebView 抓取 | ✅ | ⚙️ | — | — | source parity 與隔離策略已接入，但 rule 級診斷與 WebView recovery 未完成 |
| 5 | 兩種閱讀模式：平移 / 捲動 | ✅ | ✅ | — | — | scroll_auto_page_driver 已刪除、auto-page 統一 |
| 6 | 閱讀進度保存、還原與多點同步 | ✅ | ✅ | — | — | RestoreService 已實作端到端還原 |
| 7 | TTS 朗讀、章節跟隨、自動翻頁 | ✅ | ⚙️ | — | — | ReaderTtsMixin 已提取、TTS settings 獨立頁面 |
| 8 | 備份 / 還原、匯出、分享導入 | ✅ | ✅ | — | — | BackupSettingsPage UI 到位、備份一致性優化完成 |

> ✅ = 已達標 · ⚙️ = 進行中 · — = 尚未開始

**四階段推進**

| 階段 | 判斷標準 |
|------|---------|
| 設計 | 責任邊界清楚、真源明確、測試可保護 |
| 可用 | 主流程可順利跑完、邊緣條件不會當掉 |
| 流暢 | I/O 與排版耗時可預期、無明顯卡頓 |
| UI / UX | 視覺、互動、操作手感對齊產品直覺 |

目前 8 項基礎的「設計」階段全數完成，多數已進入或達到「可用」。下一輪焦點不再是擴大書源審計，而是把 #4 的可預測性、#5/#6 的恢復能力、以及整體測試環境可信度補齊，再整體向「流暢」與「UI/UX」推進。不跳階、不平行擴張。

## 主線優先級

下面是目前（仍在**設計 → 可用**過渡期）的近期焦點。時間有限時永遠先保護前兩項。

### 1. JS 引擎與 full suite 可信度（最高）

`v0.2.4` 已把 source parity 與書源狀態系統接入主線，但完整 `flutter test` 在部分 VM / WSL 環境仍不穩定，主要因為：

- `JsEngine` 在 native QuickJS library 缺失時會落回 mock 路徑
- 一批 JS / compatibility 測試會因此轉成 `JS_ERROR: Library not available`
- 仍有少數 CSS / integration 級紅燈沒有完全收斂

**目標**：

- 讓 full suite 在本地與 CI 都有可預期的執行方式
- 明確區分「環境缺件」與「真 regression」
- 把現存 compatibility 紅燈收斂到可接受的少數 canary

**完成標準**：`flutter analyze` 穩定全綠，`flutter test` 不再被 QuickJS 缺件大面積污染，剩餘失敗能明確指向真實 parser/runtime 問題。

### 2. 書源狀態與校驗資料正規化

目前已做到：

- 書源健康狀態可影響搜尋、閱讀、清理與換源
- 來源管理頁可直接查看校驗結果與批次清理建議來源

但目前 health 仍是依賴 `group/comment` 推導，`SourceCheckReport` 也只有 service 記憶體內的最近一次結果。

**目標**：

- 把書源健康狀態收斂為正式欄位或獨立狀態表
- 保留最後校驗時間、階段、錯誤摘要與必要歷史
- 讓 UI 不再依賴暫時性 tag/comment 技巧推導狀態

**完成標準**：書源健康狀態、校驗摘要與清理建議都能持久化，重啟 app 後不丟失，且與手動分組語義解耦。

### 3. 書源引擎可預測性與 rule 級診斷

當前 source parity 已有大量進展，但還差兩塊：

- 錯誤訊息還沒全面下沉到 rule 級
- WebView / login / anti-bot recovery 的覆蓋還不完整

**目標**：讓 engine 對外 API 進一步語意化，錯誤訊息可追蹤到 rule 層級，WebView 失敗能更像正常 runtime 問題而不是黑盒 timeout。

**完成標準**：書源報錯時，能在 engine 層給出「第幾條 rule、哪個 URL、哪個階段」而不是 UI 層猜測；WebView / login 類失敗有穩定 recovery 與測試護欄。

### 4. 閱讀器 runtime 與換源流程收尾

**近期進展（M9 – M12）**：

- `settings/` 已完成重組：舊的 `theme_settings_page`、`aloud_settings_page` 與三個 `settings_group_*.dart` widget 刪除
- 新增 `appearance_settings_page.dart`（252 行）統一視覺設定、`tts_settings_page.dart`（112 行）獨立 TTS 設定
- `reading_settings_page` 精簡、`settings_page` 入口頁大幅簡化
- `BookshelfExchangeService`（177 行）提供書架匯入 / 匯出，整合至書架頁溢出選單
- `LocalBookFormats` 集中管理所有本地書格式常數
- `UmdParser` 重寫（261 行），新增 UMD 匯入測試
- 閱讀器已接入正文失敗後的自動換源 / 手動換源

**仍待處理**：

- `ReadBookController` 本身仍偏大
- 換源目前偏「正文失敗後補救」，尚未前移到詳情 / 目錄階段
- `cache_manager` 與 `download_manager` 責任仍有重疊，考慮統一入口
- `dict`、`replace_rule`、`txt_toc_rule` 工具頁 UI 風格可對齊
- `storage_management_page` 已初步重構但可進一步精簡

## 明確不做

以下功能確定不納入本專案範圍（對標 Legado 功能清單，逐項評估後排除）：

| 功能 | 不做的理由 |
|------|----------|
| RSS 閱讀器 | 獨立功能線（RssSource/RssArticle/RssStar），與核心閱讀體驗無關，維護成本高、使用率低 |
| Web 遠端服務 | Legado 內建 HTTP/WebSocket 伺服器；屬進階便利功能，不屬閱讀器核心 |
| WebDAV 備份 / 還原 | 本地 ZIP 備份已夠；WebDAV 涉及憑證管理與衝突處理，收益不成比例 |
| 仿真翻頁動畫 | 需自繪貝塞爾翻頁曲線，現有兩模式（平移 / 捲動）已覆蓋主要場景 |
| AES 加密備份 | 使用者可自行加密壓縮，不內建 |
| 應用內更新檢查 | Flutter 發版管道多元（TestFlight / 側載 / GitHub Release），內建檢查各平台行為不一致 |
| 硬體按鍵翻頁 | 音量鍵等為 Android 專屬，跨平台定位下優先級低 |
| Cronet HTTP 引擎 | Dio 已跨平台穩定；Cronet 需 FFI 綁定，成本高收益低 |
| 桌面小工具（home_widget） | 非閱讀器核心；現有 Android widget 實作保留可用，但不再擴充 iOS、不再優化 |
| 背景任務（Workmanager） | 主要僅為支援 widget 更新；不會擴張新使用情境 |
| 深連結 / 檔案關聯 | 現有 `legado://` URL scheme 與本地檔案匯入保留可用，不再擴張新 intent / share target |

**在主線完成前也不建議：**

- 引入新的狀態管理框架
- 引入第二套資料層抽象
- 大量新增細碎工具頁
- 為了短期修 bug 再建立平行的 provider / service / runtime

## 發版原則

從 `v0.2.4` 起沿用：

- 每次發版先統一 `pubspec.yaml`、iOS version metadata、備份 manifest 版本口徑
- 發版前至少跑 `flutter analyze` 與 `flutter test`
- 工作區、文檔與版本資訊一致時才推送
- tag 可以做，但應在版本內容穩定後再建立
- release notes 寫在 `release-notes/vX.Y.Z.md`，CI 會自動抓

## 成功判斷標準

這個專案算走上正軌，不是看功能數量，而是看這些問題是否成立：

- 能清楚說出每個主要模組的責任
- 新功能不會自然長出第二套實作
- 閱讀器與書源引擎有穩定測試護欄
- 發版不需要每次重新摸索流程
- 新增功能時不會再先亂長、後補整理

## 一句話總結

目前最需要的不是更多功能，而是繼續把已存在的核心能力做成一套可推理、可測試、可發版的系統。
