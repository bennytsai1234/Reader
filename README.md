# 保安專用閱讀器

保安專用閱讀器是一個以中文閱讀體驗為主的 Flutter 閱讀器，支援本地文本閱讀、章節切換、捲動/平移兩種模式，以及朗讀與閱讀進度管理。

目前這個倉庫以「可自行部署、可自行側載」為主，不走 App Store，也沒有 TestFlight。  
如果你是 iPhone / iPad 使用者，建議走 AltStore 安裝路線。

目前倉庫也已配置 GitHub Actions，可自動建置 Android 與 iOS artifact。之後可直接從 `Actions` 或 `Releases` 下載產物。

## 目前提供什麼

- Flutter 原始碼
- Android 可自行打包的 release 專案
- iOS 可自行建置與側載的專案

## iOS 安裝方式

目前推薦使用 `AltStore Classic`。

適合對象：

- 有 iPhone / iPad
- 可以接受側載安裝
- 可以每 7 天重新整理一次 app
- 手邊有 Windows 或 macOS 電腦

基本流程：

1. 在電腦上安裝 `AltServer`
2. 在 iPhone / iPad 上安裝 `AltStore`
3. 取得本專案對應的 `.ipa`
4. 使用 AltStore 匯入 `.ipa` 安裝
5. 後續定期透過 AltStore / AltServer 重新整理 app

注意事項：

- `AltStore Classic` 需要 Apple ID
- 免費帳號安裝的 app 一般需要每 7 天 refresh 一次
- Apple 對側載 app 數量有限制
- 如果你不熟 iOS 側載，請先看 AltStore 官方教學再安裝

如果你位於歐盟地區，也可以自行評估是否改用 `AltStore PAL`。但這個倉庫目前仍以一般側載流程為主。

## Android 安裝方式

Android 使用者可直接安裝 release APK，或自行從原始碼建置：

```bash
flutter pub get
flutter build apk --release
```

輸出檔案通常會在：

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 開發環境

```bash
flutter pub get
flutter analyze
flutter run
```

## 專案現況

目前閱讀器核心已完成一輪重構，主鏈重點如下：

- 閱讀狀態與協調：`ReadBookController`
- 內容載入與章節生命週期：`ReaderContentMixin`、`ChapterContentManager`
- 視圖執行層：`ReadViewRuntime`
- 朗讀：`ReadAloudController`

## 文檔

- [docs/README.md](docs/README.md)
- [docs/roadmap.md](docs/roadmap.md)
- [docs/architecture.md](docs/architecture.md)
- [docs/reader_architecture_current.md](docs/reader_architecture_current.md)
- [docs/DATABASE.md](docs/DATABASE.md)

## 授權與使用說明

本專案僅提供閱讀器程式本體，不提供任何書籍內容。  
請自行確認你匯入、側載、分享與使用的內容符合所在地法律與平台規範。
