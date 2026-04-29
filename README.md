<p align="center">
  <img src="assets/readme/inkpage-hero.svg" alt="Inkpage Reader hero" width="100%" />
</p>

<p align="center">
  <a href="https://github.com/bennytsai1234/reader/actions/workflows/dart.yml"><img src="https://github.com/bennytsai1234/reader/actions/workflows/dart.yml/badge.svg" alt="Flutter CI"></a>
  <a href="https://github.com/bennytsai1234/reader/releases"><img src="https://img.shields.io/github/v/release/bennytsai1234/reader" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/bennytsai1234/reader" alt="License"></a>
</p>

<p align="center">
  <strong>墨頁 Inkpage</strong><br>
  一個以中文閱讀體驗為核心的開源小說閱讀器
</p>

<p align="center">
  自己管理書源與本地書，把書架、進度、設定和閱讀節奏留在自己手上。
</p>

<p align="center">
  <a href="https://github.com/bennytsai1234/reader/releases">下載最新版本</a>
  ·
  <a href="https://github.com/bennytsai1234/reader/issues">回報問題</a>
  ·
  <a href="docs/README.md">查看文件</a>
</p>

## 這是什麼

墨頁 Inkpage 是一個面向中文小說閱讀場景的閱讀器本體。它支援書架管理、搜尋、發現、閱讀器、書源管理、備份還原與朗讀，也能匯入本地 TXT / EPUB / UMD 書籍。

這個專案只提供閱讀器，不提供小說內容、站點資料或第三方帳號服務。

## 為什麼用墨頁

| 特點 | 說明 |
| --- | --- |
| 閱讀器優先 | 重點不是做一個書源展示工具，而是把閱讀本身做好，包含進度保存、翻頁模式、閱讀外觀與朗讀。 |
| 本地資料優先 | 書架、閱讀進度、設定、書籤與大部分資料都保存在本機，不依賴中心化帳號。 |
| 本地書與書源都能用 | 你可以匯入自己的 TXT / EPUB / UMD，也可以自行加入可用書源。 |
| 為中文閱讀調整 | 針對中文小說閱讀流程設計，包括章節閱讀、替換規則、字典規則與 TXT 目錄規則。 |
| 開源且可持續維護 | 專案以 Flutter / Dart 維護，並有 CI、版本釋出與公開 issue 流程。 |

## 你可以用它做什麼

- 管理自己的書架、閱讀紀錄與分組
- 用多個書源搜尋作品，或只查單一書源
- 透過發現頁找書，查看詳情、目錄與換源
- 在 `slide` / `scroll` 兩種閱讀模式間切換
- 保存並還原閱讀進度
- 使用 TTS 朗讀、自動翻頁、書籤與閱讀設定
- 匯入本地 TXT / EPUB / UMD 書籍
- 管理書源、檢查書源狀態，必要時透過 WebView 登入
- 備份與還原書架、進度、設定與其他使用資料

## 下載與安裝

| 平台 | 取得方式 | 備註 |
| --- | --- | --- |
| Android | [GitHub Releases](https://github.com/bennytsai1234/reader/releases) | 提供依裝置架構分開的 APK 安裝檔 |
| iOS | [GitHub Releases](https://github.com/bennytsai1234/reader/releases) | 提供未簽名 IPA，需自行透過 AltStore 或其他 sideload 方式安裝 |

目前沒有 Play Store 或 App Store 上架版本。

## 快速開始

1. 到 [Releases](https://github.com/bennytsai1234/reader/releases) 下載並安裝最新版。
2. 第一次使用時，先匯入本地書，或自行加入可用書源。
3. 用搜尋或發現功能找書，加入書架後開始閱讀。
4. 在閱讀器裡調整字型、主題、翻頁模式、朗讀與其他偏好設定。
5. 需要換機或保留資料時，用備份與還原保存你的書架與進度。

如果某些書源需要登入，app 內提供 WebView 登入流程。

## 適合誰

- 想自己管理書源、本地書與閱讀資料的人
- 需要細緻閱讀設定、書籤與進度保存的人
- 習慣中文小說閱讀流程，且希望使用開源工具的人
- 不想把閱讀資料綁在特定平台帳號上的人

## 產品邊界

- 不內建小說內容
- 不保證第三方書源長期可用
- 不代管使用者帳號、Cookie 或站點權限
- 不承諾所有來源站點都能穩定抓取

書源是否可用，會受到來源站點、規則品質、登入狀態與站方限制影響。

## 資料與隱私

- 書架、閱讀進度、設定、書籤與大部分使用資料會保存在本機
- 部分功能可能使用網路請求、Cookie 與 WebView
- 備份檔目前是 ZIP，不是加密備份，請自行妥善保管

## 問題回報

問題或建議請到 [Issues](https://github.com/bennytsai1234/reader/issues)。

回報時建議附上：

- 裝置型號與系統版本
- app 版本
- 重現步驟
- 錯誤訊息或畫面截圖
- 若是書源問題，附上書源名稱與書名

## 開發與文件

如果你是來看架構、開發流程或 release 說明，請從 [docs/README.md](docs/README.md) 開始。

常用文件：

- [docs/reader_current_state.md](docs/reader_current_state.md)
- [docs/reader_mobile_test_plan.md](docs/reader_mobile_test_plan.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CHANGELOG.md](CHANGELOG.md)
- [release-notes/](release-notes/)

## 授權

Apache License 2.0。詳見 [LICENSE](LICENSE)。
