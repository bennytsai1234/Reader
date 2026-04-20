# CHANGELOG

所有版本變更記錄。格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/)，版號遵循 [語意化版本](https://semver.org/lang/zh-TW/)。

---

## [0.2.8] — 2026-04-20

### 新功能 / 發版基礎設施

- **固定 Android release signing**：release APK 改為讀取正式 keystore，不再沿用每次 runner 都不同的 debug 簽名
- **GitHub Actions release workflow 補齊 signing secrets 流程**：CI 會從 repo secrets 還原 keystore 並用固定 release key 產生 APK

### 修復

- 修正 QuickJS 啟用後在 CI 上暴露出的 6 個測試回歸
- 補 `TestWidgetsFlutterBinding.ensureInitialized()` 到相關 integration tests，避免 `flutter_js` 在 CI 上因 asset binding 未初始化而失敗
- 修正 CSS attribute selector compat，避免把 `^=` 這類 selector 誤判成 exact match
- 修正 nested async JS rewrite，讓 `java.ajax(java.ajax(...))` 這類巢狀呼叫正確等待內層結果
- 修正 Promise bridge 測試上下文，避免 `result/baseUrl` 未定義造成假失敗

## [0.2.7] — 2026-04-20

### 修復

- 修正 `ReadAloudController` 的 flow-control braces lint
- 修正 `test_helper.dart` 的 `prefer_const_declarations` lint
- 補一個 patch release，讓最新遠端版本和 analyzer 狀態一致

## [0.2.6] — 2026-04-20

### 新功能 / 整合

- **發現頁對齊 Legado**：收斂成頂部搜尋列、緊湊書源標題列、框線分類容器與精簡長按選單，操作流更接近 Legado
- **發現規則 JS 快取與回退**：`exploreUrl` 的 JS 結果現在會持久化快取，重新整理時可同步清空；JS 執行失敗時改為顯式 `ERROR:*` 分類，而不是靜默空白
- **QuickJS 測試環境收口**：新增 `tool/flutter_test_with_quickjs.sh` 與通用 QuickJS wrapper，CI 與 source validation 共用同一套本地/CI QuickJS 測試入口

### 修復

- 修正部分書源目錄順序與 Legado 不一致，導致「開始閱讀」從最新章節而非第一章開始的問題
- 修正發現頁展開、分類與 JS 探索錯誤回顯的穩定性
- 修正 TTS 跟讀、閱讀頁上下邊界與閱讀控制層的若干行為細節，減少誤觸與跟隨不準確
- 修正 QuickJS 測試探測邏輯，避免在 test zone 外誤啟動 runtime 導致 JS 測試自身失敗

### 體驗優化

- 發現頁分類空狀態、錯誤狀態與長按操作更直接，出錯時可直接看到規則訊息
- README 與交接文檔補齊 Linux / WSL 下 QuickJS 測試正確用法

## [0.2.5] — 2026-04-20

### 新功能 / 整合

- **書源管理頁對齊 Legado 操作流**：主頁收斂為 `排序 / 分組 / 更多` 三個入口，單列補齊 `編輯 / 更多 / 啟用開關`，批量操作新增發現開關與連續選取
- **單書源搜尋入口補齊**：從書源管理頁可直接在指定書源內搜尋，並帶正確 scope 進搜尋頁
- **交接與架構文檔刷新**：補齊下一階段交接稿，更新 README、roadmap、database 與 reader/current architecture 文檔

### 修復

- 修正從搜尋結果進入書籍詳情後，點擊「開始閱讀」直接顯示「暫無章節」的鏈路問題，詳情頁已載入的目錄會正確交給閱讀器
- 修正部分 CSS self-match、attribute selector 與章節標題重複問題，補齊對應 targeted tests
- 將 QuickJS 依賴測試改成 CI-safe，在缺少 native library 的 runner 上自動跳過，避免把 CI 誤打紅

### 體驗優化

- 書源管理頁移除過多入口，列表改為更貼近 Legado 的平鋪式管理介面
- 域名分組改為清晰的 host header 顯示，不再使用展開群組卡片
- 校驗選中書源時不再顯示沒有實際作用的手動關鍵字輸入

## [0.2.4] — 2026-04-20

### 新功能 / 整合

- **書源相容層大幅補強（對標 Legado）**：補齊大量 URL、Regex、CSS、JsonPath、JS bridge 與章節解析差異，前 `1-300` 個純小說源的主要共性缺口已大幅收斂
- **書源狀態系統接入 App**：校驗結果不再只停留在工具輸出，現在會直接落成書源狀態、標籤與註解，並反映在書源管理頁
- **執行期隔離策略上線**：搜尋失效、詳情失效、目錄失效、正文失效、上游異常、下載站、需要登入、非小說源等狀態，現在會影響搜尋池、閱讀可用性與清理建議
- **閱讀失敗換源流程**：正文或章節失敗時，閱讀器可直接自動換源或手動換源，並保留閱讀進度

### 體驗優化

- **移除回應時間 UI**：書源管理、書籍詳情換源與相關選單不再顯示 `ms` 響應時間，也移除依響應時間排序
- **純小說產品策略落地**：非小說源、下載站與需要登入的來源會被明確標示，並可在校驗結果中集中清理
- **書源管理頁強化**：新增校驗結果摘要、結果對話框與批次刪除建議來源流程

### 修復

- 修正多種 `POST redirect`、JSONP、async JS、舊式 Regex、`Map` 動態 URL、Jsoup/CSS selector 與 `chapter.putVariable(...)` 相關解析差異
- 修正搜尋、詳情、目錄、正文之間的資料傳遞斷點，減少「搜尋能進、閱讀失敗」的鏈路落差
- 修正 cookie 容錯與部分慢源 / 壞源分類，讓校驗結果更接近實際可用性

---

## [0.2.1] — 2026-04-10

### 增強

- **書源管理體驗升級（對標 Legado）**
  - 移除冗餘的「多選模式」開關，改為預設顯示核取方塊，可直接多選
  - 列表新增分組資訊、書源 URL 與回應狀態標籤，排版更緊湊
  - 操作按鈕（啟用、禁用、加入分組、匯出等）整合至溢出選單（⋮）
  - 拖曳排序觸發區域與視覺調整，手動排序模式體驗更順暢

---

## [0.2.0] — 2026-04-10

### 新功能 / 重構

- **搜尋架構重構（對標 Legado）**：`SearchProvider` → `SearchProvider (UI State)` + `SearchModel (Engine)` 三層架構
- 新增 `SearchScope` 機制，支援全部書源、分類書源、單一書源的細粒度搜尋
- 新增 `SearchScopeSheet` UI 元件
- 搜尋歷史長期持久化與長按刪除單條記錄
- **發現頁面重構**：對齊 Legado 雙層書源架構，移除舊版年齡驗證，改為書源分類設計
- 書源管理介面與功能全面優化

### 修復

- 切換章節（Slide 機制）時，未正確延遲重置動畫導致的畫面跳動
- 滑動換頁進度在模式切換後未正確重置
- 清除 `SearchService` 與多個廢棄代碼段
- 修復所有遺留的 `flutter analyze` deprecation warnings

---

## [0.1.9]

### 重構

- 閱讀器 runtime 鏈重構：拆出 `ReaderContentCoordinator`、`ReaderDisplayCoordinator`、`ReaderSessionCoordinator`、`ReadViewRuntimeCoordinator`、`ReaderPositionResolver` 五個協調器
- 新增 `ReaderLocation`、`ReaderSessionState`、`ReaderViewportState` 資料模型，統一 runtime 狀態傳遞
- `ReadBookController` 大幅瘦身，控制流程移至對應 coordinator

### 修復

- 還原跳轉後清除 `initialCharOffset`，避免 `_init()` 重複定位
- 空內容章節不再進入預載佇列，並加入無限重試迴圈防護
- config 更新後丟棄舊分頁結果；`configVersion` 正確傳入靜默預載路徑；補齊 progressive 路徑的剩餘缺口
- 進度寫入失敗改為 catch 並記錄，不再向上拋出
- TTS 跟隨捲動時 `localOffset` 鉗制於章節高度內；章節朗讀完成時立即清除高亮
- 切換翻頁模式時自動翻頁進度指示器重置為 0
- 空章節 handoff 後 TTS 正確回到 idle 狀態

---

## [0.1.8]

### 重構

- M5：消除所有 widget 層直接呼叫 DAO 的情況，改由 Provider / Service 代理
- 刪除兩個死碼檔（`bookmark_list_page.dart`、`local_book_provider.dart`）
- 廢棄的 settings 擴展 mixin 合併進 `SettingsProvider`
- `HttpTtsProvider` 提取為獨立 provider

---

## [0.1.7]

### 重構

- M5：消除所有 widget 層直接呼叫 DAO 的情況，改由 Provider / Service 代理（初步）
- 廢棄 settings 擴展 mixin，合併進 `SettingsProvider`
- `HttpTtsProvider` 提取為獨立 provider

---

## [0.1.6]

### 整體

- 收攏 parser、storage、reader service 精修成果
- 對齊專案文件（README、architecture、reader architecture、database、roadmap）與現有程式碼
- 更新備份 manifest 常數與 schema，對應實際 app 版本
- App 版本升至 `0.1.6` / build `6`

---

[0.2.8]: https://github.com/bennytsai1234/reader/releases/tag/v0.2.8
[0.2.7]: https://github.com/bennytsai1234/reader/releases/tag/v0.2.7
[0.2.6]: https://github.com/bennytsai1234/reader/releases/tag/v0.2.6
[0.2.1]: https://github.com/bennytsai1234/reader/releases/tag/v0.2.1
[0.2.5]: https://github.com/bennytsai1234/reader/releases/tag/v0.2.5
[0.2.4]: https://github.com/bennytsai1234/reader/releases/tag/v0.2.4
[0.2.0]: https://github.com/bennytsai1234/reader/releases/tag/v0.2.0
[0.1.9]: https://github.com/bennytsai1234/reader/releases/tag/v0.1.9
[0.1.8]: https://github.com/bennytsai1234/reader/releases/tag/v0.1.8
[0.1.7]: https://github.com/bennytsai1234/reader/releases/tag/v0.1.7
[0.1.6]: https://github.com/bennytsai1234/reader/releases/tag/v0.1.6
