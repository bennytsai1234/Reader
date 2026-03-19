# Legado Reader (Flutter) - 深度技術審計與功能全圖譜

本文件為專案深度審計報告，涵蓋目前已實作的所有核心模組、依賴技術及系統架構。

---

## 🛠️ 1. 核心技術與狀態管理
本專案採用 **Flutter 3.29.1+** 開發，主要核心技術與依賴包含：
*   **依賴注入 (DI)**：基於 `get_it` 提供核心服務 (如 `NetworkService`, `TTSService`) 與各實體 DAO 單例全域管理。
*   **狀態管理**：基於 `provider` 與 `event_bus`，負責跨元件狀態的響應式同步。
*   **背景任務**：整合 `workmanager` 執行非同步定時任務 (例如：在背景自動檢查書架上的書籍更新)。
*   **異常防護**：全域佈署 `ErrorWidget` 與 `runZonedGuarded`，從根源保證系統穩定執行並捕捉孤立的執行緒例外。

---

## 📂 2. 核心底層 (Core Layer)
位於 `lib/core` 的核心大腦，負責底層邏輯驅動與資料來源整合：

### 🧩 規則解析引擎 (`core/engine`)
負責將非結構化的網頁 DOM 或 API 數據轉譯為結構化書籍資訊：
*   **多協議支持**：原生相容 **HTML (csslib/xml)**、**JSONPath (json_path)** 與 **XPath (xpath_selector)** 雙解析引擎。
*   **JS 沙盒 (flutter_js)**：具備完整的獨立 JavaScript 執行環境，用以處理困難的書源加解密、自定義簽名計算及特殊的 `eval` 回呼。
*   **Web 穿透技術**：整合 `webview_flutter` 實作 Headless Browser 狀態隱藏連線，自動化繞過 Cloudflare 等反爬蟲機制並靜默提取核心 Cookie (`dio_cookie_manager`)。

### 🗄️ 數據庫叢集 (`core/database`)
基於 **Drift (SQLite)** 打造的高效能單機資料中心：
*   **全方位 DAO 矩陣**：細分為 20 個以上具體業務 DAO (如 `BookDao`, `ChapterDao`, `CookieDao`, `ReplaceRuleDao`) 降低關聯耦合度。
*   **底層狀態持久化**：不僅儲存書籍與章節，全域網路快取 (`CacheDao`) 與閱讀紀錄 (`ReadRecordDao`) 均實現了本地持久化儲存。

### 📡 網路與請求 (`core/network`)
*   高度封裝的 **Dio** 客戶端庫。
*   維護全局代理探測與會話保持策略，支援複雜書源的高效且安全的資料抓取。

---

## 📖 3. 閱讀體驗 (Reader Layer)
模組位於 `lib/features/reader`，專注於提供極致流暢與高度客製化的閱讀沉浸感：

### 🚀 翻頁引擎與導航
*   **雙重原生翻頁模式**：
    1.  **捲動模式 (Scroll)**：最新優化的無接縫向下連續閱讀，確保章節過渡 (Chapter Transitions) 的像素級精確鎖定，滑動如絲般順滑。
    2.  **平移模式 (Slide)**：經典橫向無縫滑動翻頁，基於頁面偏移值精確渲染，耗能低且效能優異。
*   **精準記憶 (Position Memory)**：全域進度定位，記住至具體段落長度，無論何時返回閱讀器皆能還原上一秒的視覺定位。

### 🎨 排版與渲染
*   **全自訂排版引擎**：針對中文特製的排版標記法，支援內嵌插圖與進階間距控制。
*   **EPUB 強力支援**：深度整合 `epubx` 機制完成標準 EPUB 文件解構渲染。
*   **內容淨化**：讀取前即時套用正則替換 (`replace_rule`)，無感過濾內文與站點廣告。

### 🎧 智能 TTS 聽書
串聯 `just_audio` 與原生 `flutter_tts`：
*   支援背景播放 (`audio_service`) 以及自動智慧斷頁/斷行算法。
*   精確校正了「跨段落定位」問題，實現最流暢的有聲書體驗，閱讀期間行級渲染進度完全同步提示。

---

## 📚 4. 特色功能模組 (Feature Groups)
位於 `lib/features`，具備純粹解耦與熱插拔特徵的高階模組：
*   `source_manager` (書源管理)：允許全通道匯入 (剪貼簿、網址、本機 QR 碼)，內建 JSON 語法分析除錯。
*   `bookshelf` / `book_detail` (書庫與維度)：智慧書架擁有自適應書封展示、進度環以及精細書籍分組。
*   `browser` / `explore` / `search` (發現與站點搜尋)：內嵌網頁瀏覽器，實現全域廣度搜尋與分類引流。
*   `dict` (自定義字典)：支援多國語意轉換或自訂特殊名詞解析字典。
*   `local_book` (本機庫存)：強力解析本地端存放之重量級 TXT，生成章節目錄結構 (`txt_toc_rule`)。

---

## 🚀 5. 開發與維護動態 (Maintenance Summary)
專案持續往模組現代化推進，並於近期取得下列技術債清理突破：
*   **[✅ 已優化] 架構去冗餘化**：徹底拔除過時的 Jsoup/Rhino (替換為 Html/JS 庫)、清理早期複雜的 NanoHTTPD。
*   **[✅ 已修復] 捲動與定位問題**：重構 Scroll 引擎，根絕因章節高度跨度差異所引發的頁面閃現與飛焦問題。
*   **[✅ 已增強] 惡意反爬跳脫**：導入自動化 InAppWebView 協同 Dio 驗證繞過邏輯。
*   **[⏳ 進行中] 特大文本渲染**：計畫將破百 MB 之純文本解碼、目錄擷取與分段推移至背景 Isolate，實現 UI 的「零」掉幀表現。

---
*文件更新日期：2026-03-19*
*當前狀態：Flutter 模組精煉版 - 架構同步更新版*
