# 保安專用閱讀器

更新日期：2026-04-02

保安專用閱讀器是一個以中文閱讀體驗為核心的 Flutter 閱讀器，目標是提供一個可自行建置、可自行側載、可長期維護的閱讀器專案。它同時覆蓋本地書閱讀、網路書源解析、閱讀器 runtime、朗讀、備份還原與基礎平台整合。

目前專案已經不是單純的 UI 殼，而是一個由四個主要子系統構成的完整 app：

- 閱讀器 runtime：以 `ReadBookController` 為主控，負責 restore、progress、TTS follow、scroll/slide 模式切換與章節生命週期
- 書源引擎：集中在 `lib/core/engine`，涵蓋 URL 分析、規則解析、JS 擴充、WebView 書源與登入流程
- 資料層：`Drift` + DAO，保存書架、章節快取、規則、書源、書籤、下載與偏好設定
- 產品模組：`features/` 下的書架、搜尋、探索、書源管理、設定、本地書、閱讀器與工具頁

## 目前版本

- App version: `0.1.6`
- Build number: `6`
- 開發主線：`main`

## 專案結構

```text
lib/
  core/      基礎能力、資料層、服務、書源引擎
  features/  產品功能模組
  shared/    共用主題與 widgets
docs/        維護中的設計與架構文檔
test/        單元測試與整合測試
```

目前最重要的代碼入口：

- App 啟動：`lib/main.dart`
- 依賴注入：`lib/core/di/injection.dart`
- 資料庫：`lib/core/database/app_database.dart`
- 閱讀器主控：`lib/features/reader/runtime/read_book_controller.dart`
- 書源引擎：`lib/core/engine/`

## 功能覆蓋

- 書架管理、分組、書籍詳情、章節列表
- 搜尋與探索頁
- 本地 TXT / EPUB 匯入
- 網路書源解析、登入、內容抓取
- Scroll / Slide 兩種閱讀模式
- 閱讀進度保存與還原
- 朗讀、TTS 跟隨與基礎自動翻頁
- 備份 / 還原、匯出、分享導入、桌面小工具、背景檢查基礎掛鉤

## 開發環境

需求：

- Flutter SDK
- Dart SDK `^3.7.0`
- Xcode / Android Studio 對應本機平台

常用命令：

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Android release：

```bash
flutter build apk --release
```

iOS 側載建議：

- 使用 Xcode 自行簽名建置，或
- 使用 AltStore 匯入已建好的 `.ipa`

本倉庫不走 App Store，也沒有 TestFlight 流程。

## 發版流程

1. 撰寫 `release-notes/vX.Y.Z.md`
2. `git add . && git commit -m "chore: prepare vX.Y.Z"`
3. `git tag vX.Y.Z`
4. `git push && git push --tags`

CI 自動觸發，約 25 分鐘後 GitHub Releases 頁面出現 Android APK 與 iOS IPA。

## 文檔

- [docs/README.md](docs/README.md)：文檔索引與閱讀順序
- [docs/architecture.md](docs/architecture.md)：專案目標架構與責任邊界
- [docs/reader_architecture_current.md](docs/reader_architecture_current.md)：目前閱讀器 runtime 實際設計
- [docs/DATABASE.md](docs/DATABASE.md)：Drift schema、DAO 與 migration 現況
- [docs/roadmap.md](docs/roadmap.md)：現階段主線、風險與後續優先級

## 測試與品質

目前測試已覆蓋的重點集中在：

- 閱讀器 runtime 與 restore / progress / command guard
- 書源解析器與 parser integration
- JS extensions
- 備份、下載與部分工具服務

建議提交前至少執行：

```bash
flutter analyze
flutter test
```

## 授權與使用說明

本專案只提供閱讀器程式本體，不提供任何書籍內容或站點資料。請自行確認匯入、抓取、分享、側載與使用行為符合所在地法律、站點條款與平台規範。
