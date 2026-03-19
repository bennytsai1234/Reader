# Legado Reader (Flutter)

基於 Flutter 開發的高自訂化跨平台網文/電子書閱讀器，靈感來自於開源專案 Legado (閱讀)。專案支援網頁書源解析、本地書籍導入、智慧 TTS 聽書等功能，致力於提供純粹、流暢且具備高度擴充性的閱讀體驗。

---

## ✨ 核心特色 (Features)

*   **📖 豐富的閱讀體驗**
    *   提供「無縫捲動 (Scroll)」與「經典平移 (Slide)」雙重原生翻頁模式，極致絲滑無掉幀。
    *   高度客製化排版：支援自訂字體、行距、段距、背景顏色與 EPUB 等多樣式渲染。
    *   全域精準記憶：自動保存閱讀進度到特定段落，重新開啟時瞬間還原。
*   **🕷️ 強大的規則解析引擎**
    *   內建 HTML (csslib)、JSONPath 與 XPath 多重解析支援。
    *   搭載完整 JavaScript 沙盒 (`flutter_js`)，輕鬆應對書源平台的動態加解密與簽名演算法。
*   **🛡️ 反爬蟲防護穿透**
    *   整合 Headless WebView 隱藏連線，自動靜默運算驗證碼並繞過 Cloudflare 防護。
    *   全局 Cookie 與 HTTP 代理接管 (`dio_cookie_manager`)，長效維持登入工作階段。
*   **🎧 智能 TTS 有聲書**
    *   支援背景播放 (`audio_service`) 與系統級 Media Session 控制。
    *   智慧化段落切分與背景提前預取，保證跨章節朗讀與文字高亮完美同步，不中斷。
*   **🗂️ 全方位內容管理**
    *   多元匯入方式：剪貼簿、網址連結、QR 碼，與本機端 JSON 規則。
    *   強大本機解析：支援匯入大型本地 TXT（搭載自動目錄正則分析）與 EPUB 電子書。
    *   自動更新與分組：書架具備進階分類，利用 `workmanager` 執行後台靜默檢查最新章節。
*   **🧹 內容淨化與管理**
    *   即時生效的正則替換與過濾引擎，無感消除站點牛皮癬與錯別字廣告。
    *   全字典支援，可實現繁簡智能轉換與特殊名詞自訂。

---

## 🛠️ 技術棧 (Tech Stack)

專案採用時下最新的 Flutter 開發規範與生態構建：
*   **框架**: Flutter 3.29.1+
*   **架構設計**: 採用高度解耦的模組化結構 (`core` 底層邏輯 + `features` 業務模組)
*   **狀態與路由**: `provider` (響應式狀態), `event_bus` (事件驅動)
*   **依賴注入 (DI)**: `get_it` 全域單例配置
*   **資料持久化**: `drift` (建置高效能 SQLite 叢集，包含 20+ 個 DAO), `shared_preferences`
*   **網路與抓取**: `dio`, `webview_flutter`

---

## 🚀 快速開始 (Getting Started)

### 準備環境
請確保你的開發環境已經正確安裝 [Flutter SDK](https://flutter.dev/docs/get-started/install)。

### 安裝與運行
```bash
# 1. 取得專案檔案 (請先確保在專案根目錄下)
# git clone https://github.com/your-repo/legado_reader_flutter.git
# cd legado_reader_flutter

# 2. 下載依賴套件
flutter pub get

# 3. 執行程式 (需連接實體裝置或是啟動模擬器)
flutter run
```

---

## 📦 專案目錄結構 (Project Structure)

```text
lib/
├── core/                  # 核心底層封裝
│   ├── constant/          # 全域常數與列舉
│   ├── database/          # Drift 資料庫與所有 DAO 介面
│   ├── di/                # GetIt 依賴注入註冊中心
│   ├── engine/            # HTML/JSON 等書源規則解析器與 JS 沙盒
│   ├── network/           # Dio 封裝與請求攔截器
│   └── services/          # TTS、日誌與崩潰處理等背景服務
├── features/              # 獨立的模組化業務功能
│   ├── bookshelf/         # 書架與書籍分類管理
│   ├── reader/            # 核心閱讀器 (排版渲染、翻頁動畫、TTS 面板)
│   ├── source_manager/    # 書源探索與本地除錯編輯器
│   ├── settings/          # App 偏好設定
│   └── search/            # 全域搜尋與發現頁面
├── shared/                # 共用元件 (客製化 Widget、主題樣式)
├── app_providers.dart     # 全域 Provider 狀態樹佈署
└── main.dart              # App 進入點與全域初始化
```

---

## 📄 授權協議 (License)
目前版本屬於私人/開源專案維護，具體開源協議請參閱專案授權文件。
