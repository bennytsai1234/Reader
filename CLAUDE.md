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
- **資料庫**：Drift (SQLite ORM，v7 schema)
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
│   ├── database/             # Drift schema (v7) / DAO / 遷移
│   ├── di/                   # GetIt 依賴注入 (injection.dart)
│   ├── engine/               # 書源解析引擎（CSS/JSON/XPath/JS/URL）
│   │   ├── analyze_rule/     # 規則解析核心
│   │   ├── analyze_url/      # URL 建構與請求發送
│   │   ├── reader/           # 內容後處理（content_processor.dart）
│   │   └── js/               # flutter_js 沙盒
│   ├── local_book/           # 本機格式解析器
│   ├── models/               # 資料模型（Book、Chapter、BookSource…）
│   ├── network/              # HTTP / Cookie
│   └── services/             # 各種 Service（TTS、音訊、下載…）
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

閱讀器是最複雜的模組，`ReaderProvider` 由一條 mixin 鏈組合而成：

```
ReaderProviderBase          ← DAO、基礎狀態（currentPageIndex、pages、chapterCache…）
  └── ReaderSettingsMixin   ← 字體/行距/主題等使用者設定（從 SharedPreferences 讀寫）
        └── ReaderContentMixin  ← 章節加載、ChapterProvider.paginate()、靜默預載
              └── ReaderProgressMixin  ← 進度儲存/恢復、捲動位置計算
                    └── ReaderTtsMixin  ← TTS 朗讀、高亮追蹤、章節預取
                          └── ReaderAutoPageMixin  ← 自動翻頁計時
                                └── ReaderProvider  ← 組合入口，_init() 串接所有初始化
```

### 核心資料流

- **TextPage / TextLine**：`engine/text_page.dart`。每行有 `chapterPosition`（在章節原始文字中的字元偏移），是 TTS 高亮與進度恢復的共同基礎。
- **chapterCache**：`Map<int, List<TextPage>>`，以章節索引為鍵，存放分頁結果；載入新章節後更新，是多章節捲動模式的頁面來源。
- **事件通訊**：`ReaderProviderBase` 暴露三個 `StreamController`：
  - `jumpPageController` — 命令 PageView 跳到指定頁（平移/覆蓋模式）
  - `scrollOffsetController` — 命令 ScrollView 跳到指定偏移（捲動模式）
  - `scrollTrimAdjustController` — trim 前方頁面後補償捲動位置

### TTS 設計

`TTSService` 是全域單例（`TTSService()` 工廠），在 `main()` 中初始化，與 `audio_service` 整合以提供系統通知欄控制。

`ReaderTtsMixin` 使用**錨點游標**而非 `currentPageIndex`：
- `_ttsAnchorChapterIdx` / `_ttsAnchorEndCharPos` — 記錄「目前正在讀到哪個章節的哪個字元」
- `_ttsChapterIndex` — 目前朗讀所在章節，用於過濾高亮避免跨章節誤標

TTS 朗讀以**整章**為單位：`_startTts()` 從目前位置收集到章末的所有行，呼叫一次 `TTSService().speak()`；章節邊界由 `_onTtsComplete()` 處理，利用 `_prefetchedChapterTtsText` 實現無縫銜接。

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
