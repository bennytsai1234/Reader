# legado_reader — Claude Code 專案指引

## 專案概述
Flutter iOS 小說閱讀 App，靈感來自 Legado（閱讀 3.0）。

## 技術棧
- **語言**：Dart / Flutter（SDK ^3.7.0）
- **狀態管理**：Provider + ChangeNotifier
- **資料庫**：sqflite（SQLite）
- **網路**：Dio + CookieJar
- **JS 引擎**：flutter_js（替代 Android Rhino）
- **WebView**：webview_flutter
- **本機書籍解析**：TXT、EPUB（epubx）、MOBI、PDF、UMD

## 目錄結構
```
lib/
├── app_providers.dart        # 全域 Provider 註冊
├── core/
│   ├── base/                 # 基礎 Provider 類別
│   ├── constant/             # 常數與 key
│   ├── database/             # DB schema / migrations
│   ├── engine/               # 書源解析引擎（CSS/JSON/XPath/JS/URL）
│   ├── local_book/           # 本機格式解析器
│   ├── models/               # 資料模型
│   ├── network/              # HTTP API
│   └── services/             # 各種服務（音訊、下載、TTS…）
└── features/                 # UI 功能模組（reader、bookshelf…）
```

## 開發規範
- 遵循現有的 Provider 模式，不引入其他狀態管理套件
- 資料庫操作統一走 `DatabaseBase`，不直接呼叫 sqflite
- 新的解析邏輯放在 `core/engine/` 對應子目錄
- 保持 Dart 空安全（null-safety）

## 注意事項
- `assets/` 目錄包含字型、預設書源，不要刪除或重新命名
- `analysis_options.yaml` 定義 lint 規則，請遵守
- 測試放在 `test/` 目錄
