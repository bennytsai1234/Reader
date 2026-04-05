# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概述

Flutter 跨平台小說閱讀 App，移植自 Android 的 Legado（閱讀 3.0）。

## 常用指令

```bash
flutter pub get              # 安裝依賴
flutter pub run build_runner build --delete-conflicting-outputs  # 重新生成 Drift DB 程式碼
flutter analyze              # 靜態分析
flutter test                 # 執行全部測試
flutter test test/some_test.dart  # 執行單一測試
flutter run                  # 啟動 App
flutter build ios            # 建置 iOS
flutter build apk            # 建置 Android APK
```

> 修改 `core/database/` 中的 Drift table 定義後，必須重新執行 `build_runner`。

## 技術棧

- **語言**：Dart / Flutter（SDK ^3.7.0）
- **狀態管理**：Provider + ChangeNotifier
- **依賴注入**：get_it
- **資料庫**：Drift (SQLite ORM，v8 schema)
- **網路**：Dio + CookieJar
- **JS 引擎**：flutter_js（替代 Android Rhino）
- **WebView**：webview_flutter
- **音訊/TTS**：just_audio、audio_service、flutter_tts
- **本機書籍解析**：TXT、EPUB (epubx)、MOBI、PDF、UMD

## 目錄結構

```
lib/
├── main.dart                 # 進入點，初始化 DI、TTSService、Workmanager
├── app_providers.dart        # 全域 Provider 集中註冊
├── core/
│   ├── base/                 # BaseProvider：統一 loading/error 處理
│   ├── config/               # 常數、PreferenceKey、預設資料
│   ├── constant/             # 列舉與常數（PageAnim、BookType…）
│   ├── database/             # Drift schema (v8) / DAO / 遷移
│   ├── di/                   # GetIt 依賴注入 (injection.dart)
│   ├── engine/               # 書源解析引擎（CSS/JSON/XPath/JS/URL）
│   │   ├── analyze_rule/     # 規則解析核心
│   │   ├── analyze_url/      # URL 建構與請求發送
│   │   ├── parsers/          # 格式解析器（CSS、XPath、JSON、Regex）
│   │   ├── rule_analyzer/    # 範圍/匹配/分割分析
│   │   ├── web_book/         # 書源抓取服務（搜尋、書籍資訊、章節、內容）
│   │   ├── reader/           # 內容後處理（content_processor.dart）
│   │   └── js/               # flutter_js 沙盒與擴展
│   ├── local_book/           # 本機格式解析器
│   ├── models/               # 資料模型（Book、Chapter、BookSource…）
│   ├── network/              # HTTP / Cookie
│   ├── services/             # 各種 Service（TTS、音訊、下載…）
│   ├── storage/              # 路徑註冊、快取、儲存指標
│   └── utils/                # 工具類（LRU 快取等）
├── features/                 # UI 功能模組
│   ├── reader/               # 閱讀器（核心，見下方詳述）
│   ├── bookshelf/            # 書架
│   ├── book_detail/          # 書籍詳情
│   ├── search/               # 搜尋
│   ├── source_manager/       # 書源管理
│   ├── explore/              # 發現
│   ├── local_book/           # 本機書籍匯入
│   ├── settings/             # 設定
│   └── association/          # 深連結與檔案關聯處理
└── shared/
    ├── theme/app_theme.dart  # 亮/暗主題、閱讀主題色表
    └── widgets/              # 跨功能共用 Widget
```

## 閱讀器架構（重點）

閱讀器是最複雜的模組，以 `ReadBookController` 為中心的 runtime 內核，搭配 mixin 鏈與 coordinator 模式：

### 主控與 Coordinator

`ReadBookController` 是閱讀生命週期的主控（`loading -> restoring -> ready`），內部拆出五個子域：

- `ReaderNavigationController` — 跳轉命令、頁面切換原因、command guard
- `ReaderRestoreCoordinator` — 進度還原的 token/target 管理
- `ReaderProgressStore` — 持久化進度寫回（`book.durChapter*` 同步）
- `ReaderScrollVisibilityCoordinator` — 捲動可見章節追蹤與預載判斷
- `ReaderTtsFollowCoordinator` — TTS 朗讀時的畫面跟隨
- `ReaderProgressCoordinator` — 閱讀進度更新與持久化（含 debounce）

### Mixin 鏈

```
ReaderProviderBase → ReaderSettingsMixin → ReaderContentMixin
  → ReaderAutoPageMixin → ReadBookController
```

Mixin 負責設定投影、內容載入等，但控制權已大幅回收到 controller 與 coordinator。進度相關邏輯已提取為 `ReaderProgressCoordinator`。

### 章節 Runtime

`ReaderChapter` 是核心共用 runtime 物件，統一提供：
- `charOffset ↔ localOffset ↔ pageIndex` 互轉
- highlight range、restore target、scroll anchor 解析
- read aloud data 組裝

### 內容生命週期

`ChapterContentManager` 負責章節內容的完整生命週期：
- 正文抓取協調與靜默預載去重
- 分頁快取與 progressive paginate
- 視窗內外快取驅逐

### View Runtime

- `ReadViewRuntime` — 主視圖控制器
- `PageModeDelegate` / `ScrollModeDelegate` / `SlideModeDelegate` — 三種閱讀模式
- `ScrollExecutionAdapter` / `ScrollRestoreRunner` — 捲動執行與還原

### TTS 設計

`TTSService` 是全域單例，在 `main()` 中初始化，與 `audio_service` 整合以提供系統通知欄控制。

`ReadAloudController` 是實際朗讀流程的主控，負責：
- TTS session 建立與 offset map
- progress → chapter offset 映射
- highlight 同步、章節預取與無縫銜接

底層仍使用錨點游標模式（`_ttsAnchorChapterIdx` / `_ttsAnchorEndCharPos`），朗讀以整章為單位。

## 開發規範

- 不引入其他狀態管理套件（已統一使用 Provider）
- 繼承 `BaseProvider` 的類別請用 `runTask()` 處理非同步，不要手動維護 loading/error 狀態
  （`BookshelfProviderBase` 繼承 `ChangeNotifier` 而非 `BaseProvider`，是例外）
- 資料庫操作統一走 DAO 類別；公用邏輯放在 `DatabaseBase`，不直接呼叫底層 Drift API
- 新的解析邏輯放在 `core/engine/` 對應子目錄
- 保持 Dart null-safety；在 `await` 後使用 context 前必須加 `if (!mounted) return;`

## 注意事項

- `assets/` 目錄包含字型、預設書源，不要刪除或重新命名
- `analysis_options.yaml` 定義嚴格 lint 規則，所有新程式碼必須通過
- 測試放在 `test/` 目錄
- Android 原版參考實作在 `../legado/`，書源規則邏輯可對照 `legado/app/src/main/java/io/legado/app/model/analyzeRule/`
