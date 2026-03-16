# 🗺️ Legado (Android) vs. Reader (iOS) 真實物理路徑映射地圖 (Verified v2)

本報告根據 2026-03-16 實際目錄掃描結果產出，確保 1:1 的邏輯對位與物理路徑對位。

---

## 1. 核心邏輯與引擎層 (Core Engine & Logic)

| 功能分類 | Android (Legado) 真實路徑 | iOS (Flutter) 對應路徑 | 說明 |
| :--- | :--- | :--- | :--- |
| **數據模型** | `app/src/main/java/io/legado/app/data/entities/` | `lib/core/models/` | Book, BookSource, Chapter 等 |
| **資料庫接口** | `app/src/main/java/io/legado/app/data/dao/` | `lib/core/database/dao/` | SQLite DAO 層 |
| **爬蟲調度** | `app/src/main/java/io/legado/app/model/webBook/` | `lib/core/engine/web_book/` | WebBook.kt 核心爬蟲 |
| **解析引擎** | `app/src/main/java/io/legado/app/model/analyzeRule/` | `lib/core/engine/` | AnalyzeRule.kt 核心解析邏輯 |
| **核心幫助類** | `app/src/main/java/io/legado/app/help/` | `lib/core/services/` | DefaultData, IntentData, CookieHelp |
| **網路請求** | `app/src/main/java/io/legado/app/help/coroutine/` | `lib/core/network/` | Dio 請求與 OKHttp 對位 |
| **JS 引擎實作** | `modules/rhino/` (Android 外掛) | `lib/core/engine/` | FlutterJS 封裝 |
| **同步服務** | `app/src/main/java/io/legado/app/model/` | `lib/core/services/` | WebDav, AppWebDav 對位 |

## 2. 使用者介面層 (UI / Features)

| UI 模組 | Android (Legado) UI 目錄 | iOS (Flutter) Features 目錄 | 說明 |
| :--- | :--- | :--- | :--- |
| **書架主頁** | `app/src/main/java/io/legado/app/ui/main/bookshelf/` | `lib/features/bookshelf/` | 書架列表、分組 |
| **全域搜尋** | `app/src/main/java/io/legado/app/ui/book/search/` | `lib/features/search/` | 搜尋頁、聚合結果 |
| **閱讀器介面** | `app/src/main/java/io/legado/app/ui/book/read/` | `lib/features/reader/` | 閱讀頁、菜單、翻頁 |
| **書籍詳情** | `app/src/main/java/io/legado/app/ui/book/info/` | `lib/features/book_detail/` | 詳情、目錄、換源介面 |
| **書源管理** | `app/src/main/java/io/legado/app/ui/book/source/` | `lib/features/source_manager/` | 書源列表、編輯、校驗 |
| **探索模組** | `app/src/main/java/io/legado/app/ui/book/explore/` | `lib/features/explore/` | 發現分類導航 |
| **RSS 訂閱** | `app/src/main/java/io/legado/app/ui/rss/` | `lib/features/rss/` | RSS 列表與閱讀 |
| **關於/日誌** | `app/src/main/java/io/legado/app/ui/about/` | `lib/features/about/` | 關於、APP 日誌 |
| **設定/我的** | `app/src/main/java/io/legado/app/ui/main/my/` | `lib/features/settings/` | 配置與個人化 |

## 3. 資源與設定 (Resources & Config)

| 資源類型 | Android (Legado) 路徑 | iOS (Flutter) 路徑 | 說明 |
| :--- | :--- | :--- | :--- |
| **靜態資源** | `app/src/main/assets/` | `assets/` | 預設 JSON, 18+ List |
| **全域配置** | `app/src/main/java/io/legado/app/constant/PreferKey.kt` | `lib/core/constant/prefer_key.dart` | 設定鍵名對應 |

---
📅 **最後更新日期**: 2026-03-16
