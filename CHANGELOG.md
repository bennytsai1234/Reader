# CHANGELOG

所有版本變更記錄。格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/)，版號遵循 [語意化版本](https://semver.org/lang/zh-TW/)。

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

[0.2.1]: https://github.com/bennytsai1234/reader/releases/tag/v0.2.1
[0.2.0]: https://github.com/bennytsai1234/reader/releases/tag/v0.2.0
[0.1.9]: https://github.com/bennytsai1234/reader/releases/tag/v0.1.9
[0.1.8]: https://github.com/bennytsai1234/reader/releases/tag/v0.1.8
[0.1.7]: https://github.com/bennytsai1234/reader/releases/tag/v0.1.7
[0.1.6]: https://github.com/bennytsai1234/reader/releases/tag/v0.1.6
