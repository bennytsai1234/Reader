# Inkpage Reader

墨頁 Inkpage 是一個以 Flutter 實作的中文小說閱讀器。這個 repo 目前聚焦在：

- 書架、搜尋、發現、書籍詳情、書源管理、閱讀器、設定
- TXT / EPUB / UMD 本地書匯入
- 備份還原、下載任務、TTS、替換規則、字典規則
- Legado 風格書源解析，但以 Flutter / Dart 架構維護

本專案只提供閱讀器程式本體，不提供書籍內容或站點資料。

## 當前狀態

- package：`inkpage_reader`
- app 顯示名：`墨頁`
- 版本來源：`pubspec.yaml`；正式 release 由 tag `vX.Y.Z` 回寫成 `X.Y.Z+<github.run_number>`
- Dart SDK：`^3.7.0`
- Flutter channel：stable
- 資料庫：Drift / SQLite
- Drift schema version：`1`
- 狀態管理：`provider` + `ChangeNotifier`
- DI：`get_it`
- 路由：`Navigator` + `MaterialPageRoute`
- 書源 JS：`flutter_js`

目前不是 Riverpod / GoRouter 架構。

## 現有功能

- 書架、書籍分組、閱讀紀錄
- 全域搜尋、單一書源搜尋、發現頁
- 書籍詳情、章節列表、換源
- 閱讀器：`slide` / `scroll`
- `chapterIndex + charOffset` 閱讀進度保存與還原
- TTS、自動翻頁、書籤、閱讀設定
- 替換規則、字典規則、TXT 目錄規則
- TXT / EPUB / UMD 本地書
- 書源匯入、編輯、檢查、除錯、登入 WebView
- 備份還原與下載任務

## 程式結構

```text
lib/
  main.dart          app composition root
  app_providers.dart global Provider registration
  core/
    database/        Drift tables, DAOs, AppDatabase
    di/              get_it registration
    engine/          書源規則、JS bridge、WebBook parser
    local_book/      TXT / EPUB / UMD parser
    models/          domain models
    services/        書源、備份、還原、TTS、下載等服務
    storage/         app-owned filesystem paths
  features/
    bookshelf/
    book_detail/
    explore/
    reader/
    search/
    settings/
    source_manager/
    ...
  shared/
    theme/
    widgets/
docs/
test/
release-notes/
```

## 閱讀器主線

目前閱讀器主線不是舊的 `ReadBookController` 架構。實際接線是：

- 頁面組裝：`lib/features/reader/reader_page.dart`
- 核心 runtime：`lib/features/reader/runtime/reader_runtime.dart`
- 依賴組裝：`lib/features/reader/controllers/reader_dependencies.dart`
- 章節 repository：`lib/features/reader/engine/chapter_repository.dart`
- 分頁 resolver：`lib/features/reader/engine/page_resolver.dart`
- viewport：`lib/features/reader/viewport/reader_screen.dart`

長期閱讀位置以 `ReaderLocation(chapterIndex, charOffset)` 表示。頁碼、PageView index、scroll offset 都只是執行期投影。

細節見 [docs/reader_runtime.md](docs/reader_runtime.md)。

## 開發環境

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

如果 Linux 測試需要 QuickJS shared library，可用：

```bash
tool/flutter_test_with_quickjs.sh
```

只改閱讀器時，通常先跑：

```bash
flutter analyze
flutter test test/features/reader
```

修改 Drift table、DAO 或 `AppDatabase` 後必須重新生成：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## CI 與釋出

CI：

- `.github/workflows/dart.yml`
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test --reporter compact`

Release：

- `.github/workflows/build-release.yml`
  - tag `vX.Y.Z` 觸發
  - 回寫 `pubspec.yaml` 為 `X.Y.Z+<github.run_number>`
  - 建 Android split APK
  - 建 iOS unsigned IPA
  - 發佈 GitHub Release

完整流程見 [docs/release.md](docs/release.md)。

## 文檔

- [docs/README.md](docs/README.md) - 文檔索引
- [docs/architecture.md](docs/architecture.md) - 專案架構與資料流
- [docs/app_flow_architecture.md](docs/app_flow_architecture.md) - 整個 app 的流程圖與架構圖
- [docs/app_user_flows.md](docs/app_user_flows.md) - 使用者操作流程圖
- [docs/DATABASE.md](docs/DATABASE.md) - Drift schema version 1 與資料表
- [docs/reader_runtime.md](docs/reader_runtime.md) - 閱讀器 runtime 主線
- [docs/reader_spec.md](docs/reader_spec.md) - 閱讀器可驗證規格
- [docs/release.md](docs/release.md) - CI / tag / release 流程

## 授權

- License：Apache License 2.0
- Releases：<https://github.com/bennytsai1234/reader/releases>
- Issues：<https://github.com/bennytsai1234/reader/issues>
