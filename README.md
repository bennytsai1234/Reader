# 墨頁 Inkpage

更新日期：2026-04-20

**墨頁（Inkpage）** 是一個以中文閱讀體驗為核心的 Flutter 跨平台小說閱讀器，移植並延伸自 Android 的 Legado（閱讀 3.0）。目標是做一個可自行建置、可側載、可長期維護的閱讀器本體，覆蓋本地書、網路書源、閱讀器 runtime、朗讀、備份還原與基礎平台整合。

墨頁不是單純的 UI 殼，而是由四個子系統組成：

- **閱讀器 runtime** — 以 `ReadBookController` 為主控，統籌 restore、progress、TTS follow、scroll/slide 切換與章節生命週期
- **書源引擎** — `lib/core/engine/` 提供 URL 分析、規則解析、JS 擴充、WebView 書源、登入流程
- **資料層** — Drift (SQLite) + DAO，保存書架、章節、規則、書源、書籤、下載與偏好
- **產品模組** — `features/` 下的書架、搜尋、探索、書源管理、設定、本地書、閱讀器與工具頁

## 版本資訊

- App version：`0.2.6` (build `21`)
- Dart SDK：`^3.7.0`
- 資料庫 schema：v8
- 開發主線：`main`

## 目錄結構

```text
lib/
  core/      資料層、書源引擎、網路、服務、儲存與工具
  features/  產品功能模組（閱讀器、書架、搜尋、書源管理…）
  shared/    共用主題與 widgets
docs/        設計與架構文檔
test/        單元與整合測試
release-notes/  各版本 release note
```

主要入口：

- 啟動：`lib/main.dart`
- 依賴注入：`lib/core/di/injection.dart`
- 資料庫：`lib/core/database/app_database.dart`
- 閱讀器主控：`lib/features/reader/runtime/read_book_controller.dart`
- 書源引擎：`lib/core/engine/`

## 功能覆蓋

- 書架管理、分組、書籍詳情、章節列表
- 搜尋（支援全部 / 分類 / 單一書源）與探索頁
- 本地 TXT / EPUB 匯入
- 網路書源解析、登入、WebView 抓取
- 書源校驗結果、隔離與建議清理
- 兩種閱讀模式：平移 / 捲動
- 閱讀進度保存與還原
- 閱讀失敗時的自動換源 / 手動換源
- TTS 朗讀、章節跟隨、自動翻頁
- 本地備份 / 還原、匯出、分享導入

> 桌面小工具、背景任務、深連結 / 檔案關聯等能力雖有現成實作，但已列入 `docs/roadmap.md` 的「明確不做」清單，不會再投入優化，保留現況。

其他主動排除的能力見 `docs/roadmap.md`。

## 開發環境

- Flutter SDK（建議 `stable` channel，配 Dart ^3.7.0）
- Xcode / Android Studio 對應本機平台
- 建議：`~/flutter/bin/flutter doctor` 確認環境

常用指令：

```bash
flutter pub get              # 安裝依賴
flutter pub run build_runner build --delete-conflicting-outputs  # 重新生成 Drift 程式碼
flutter analyze              # 靜態分析
tool/flutter_test_with_quickjs.sh                 # 跑全部測試（自動補 QuickJS 測試環境）
flutter test test/features/reader/read_book_controller_test.dart  # 跑單一檔
flutter run                  # 啟動
flutter build apk --release  # Android release
flutter build ios --release --no-codesign  # iOS release
```

修改 `lib/core/database/tables/` 後必須重新跑 `build_runner`。

## 發版流程

1. 撰寫 `release-notes/vX.Y.Z.md`
2. 更新 `pubspec.yaml` version
3. 跑 `flutter analyze` + `flutter test` 並確認全通過
4. `git commit` + `git tag vX.Y.Z`
5. `git push && git push --tags`

CI 自動觸發 build-release workflow，約 25 分鐘後 GitHub Releases 頁面出現 Android APK 與 iOS 未簽名 IPA。

## iOS 側載建議

- 用 Xcode 自行簽名建置，或
- 用 AltStore 匯入 CI 產出的 `inkpage-ios-unsigned.ipa`

本倉庫不走 App Store，也沒有 TestFlight 流程。

## 文檔

- [docs/README.md](docs/README.md) — 文檔索引與閱讀順序
- [docs/architecture.md](docs/architecture.md) — 目標架構與責任邊界
- [docs/reader_architecture_current.md](docs/reader_architecture_current.md) — 閱讀器 runtime 現況
- [docs/DATABASE.md](docs/DATABASE.md) — Drift schema、DAO 與 migration
- [docs/roadmap.md](docs/roadmap.md) — 當前主線、不做清單與下一階段
- [docs/next_stage_handoff.md](docs/next_stage_handoff.md) — 下一階段交接、風險與執行順序

## 測試

目前有 82 個測試檔覆蓋：

- 閱讀器 runtime：lifecycle、restore、progress、navigation、scroll/slide、TTS follow
- 書源引擎：parser、URL 分析、JS extensions、JS promise bridge、integration
- 本地書解析、備份、下載與工具服務

注意：

- Linux / WSL 的 `flutter test` 需要 `flutter_js` 提供的 `libquickjs_c_bridge_plugin.so`。
- repo 已提供 `tool/flutter_test_with_quickjs.sh`，會自動從 `~/.pub-cache` 尋找這顆 `.so`，並設定 `LIBQUICKJSC_TEST_PATH` / `LD_LIBRARY_PATH`。
- 如果要跑 source validation，也請使用 repo 內的 script，例如 `tool/run_source_validation.sh`，不要自己裸跑 `flutter test tool/...`。

提交前最低要求：

```bash
flutter analyze
tool/flutter_test_with_quickjs.sh
```

## 授權與使用說明

本專案只提供閱讀器程式本體，不提供任何書籍內容或站點資料。請自行確認匯入、抓取、分享、側載與使用行為符合所在地法律、站點條款與平台規範。
