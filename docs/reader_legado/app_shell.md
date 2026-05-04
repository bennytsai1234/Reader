# App Shell

## 目標專案目前狀態

- `reader` 是 Flutter/Dart 專案，app 顯示名稱是 `墨頁`，`pubspec.yaml` 專案名是 `inkpage_reader`。
- 主入口在 `lib/main.dart`：設定 `runZonedGuarded`、Flutter error widget、`configureDependencies()`、`MultiProvider`、`MaterialApp`、`SourceVerificationCoordinator` 與 `SplashPage`。
- 全域服務註冊在 `lib/core/di/injection.dart`，目前註冊 Drift `AppDatabase`、DAO、`NetworkService`、`TTSService`、`CrashHandler` 與 logger。
- 全域 Provider 組裝在 `lib/app_providers.dart`，主要包含 `BookshelfProvider`、`SettingsProvider`、`ChangeCoverProvider`、`DownloadService` 與 get_it 的 `TTSService`。
- 主導航在 `lib/features/welcome/main_page.dart`，使用 `NavigationBar` 與 `IndexedStack` 維持書架、發現、我的三個分頁狀態；啟動畫面與必要初始化在 `lib/features/welcome/splash_page.dart`。

## 目標專案上下游

- 上游依賴：`lib/core/di/injection.dart`、`lib/core/database`、`lib/core/services/default_data.dart`、`lib/features/settings/settings_provider.dart`、`lib/shared/theme/app_theme.dart`。
- 下游影響：所有功能頁、全域 provider、`Workmanager` 後台任務、Source verification 全域路由、主題與語系設定。
- 新增全域服務、DAO 或 UI 狀態時，通常要同時檢查 `configureDependencies()` 與 `AppProviders.providers`。

## 參考對應

- `legado/app/src/main/java/io/legado/app/ui/main/MainActivity.kt`
- `legado/app/src/main/java/io/legado/app/ui/main/MainViewModel.kt`
- `legado/app/src/main/java/io/legado/app/ui/welcome/WelcomeActivity.kt`
- `legado/app/src/main/java/io/legado/app/help/DefaultData.kt`
- `legado/app/src/main/java/io/legado/app/help/CrashHandler.kt`

## 可參考模式

- 把必要啟動與延後初始化分開，避免首頁因非必要資料卡住。
- 啟動錯誤要落在可恢復的 UI，而不是讓 app 黑屏或無法重試。
- 主導航只負責分頁與全域殼層，不直接承擔 feature-specific 邏輯。

## 目標專案變更入口

- 啟動與 crash：`lib/main.dart`、`lib/features/welcome/splash_page.dart`、`lib/features/welcome/startup_failure_panel.dart`。
- 導航：`lib/features/welcome/main_page.dart`。
- DI：`lib/core/di/injection.dart`、`lib/core/database/app_database.dart`。
- Provider：`lib/app_providers.dart`。
- 基礎檢查：`flutter analyze lib/main.dart lib/app_providers.dart lib/features/welcome`，必要時加上 `flutter test test/features/settings/settings_pages_compile_test.dart`。

## 已知風險

- `configureDependencies()` 使用 get_it 註冊單例；重試啟動前若沒有 reset，重複註冊會造成狀態污染。
- `Workmanager` callback 在背景 isolate 重新初始化 DI；新增服務時要確認背景任務可用，不能依賴主 isolate 的 provider 狀態。
- `MaterialApp.builder` 包住 `SourceVerificationCoordinator`；修改 navigation key 或 route 行為會影響驗證流程。
- `SplashPage` 會在必要初始化完成後進入 `MainPage`，延後初始化失敗目前只寫 log，不能假設所有 default data 都已經存在。

## 不要做

- 不為了對齊 `legado` 重寫整個首頁資訊架構或導入 RSS 等未要求入口。
- 不把 feature-specific provider 或頁面流程塞進 app 啟動層。
- 不在這個模組直接改書源解析、閱讀器 runtime 或資料 schema；只保留殼層與全域組裝責任。
