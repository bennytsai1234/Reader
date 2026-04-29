# Project Docs

日期：2026-04-29

這個目錄只放目前對 `main` 有直接幫助的文件。已經完成或過期的 reader 設計討論稿，集中放到 `docs/archive/`，避免後續接手時誤以為那些還是待實作計劃。

## 目前有效文件

- [reader_current_state.md](reader_current_state.md)
  - reader 目前已落地的架構、核心 invariant、主要檔案與測試入口。
- [reader_mobile_test_plan.md](reader_mobile_test_plan.md)
  - 接下來在手機上實測 reader 的檢查清單與回報格式。

## 歷史文件

- [archive/reader-2026-04-design/](archive/reader-2026-04-design/)
  - 2026-04 reader 重構討論期的設計、修復計劃、review 計劃與實作順序。
  - 這些文件保留作為背景資料，不再是目前主入口。

## 根目錄文件

- [../README.md](../README.md)：產品介紹、下載與使用入口。
- [../CONTRIBUTING.md](../CONTRIBUTING.md)：開發與驗證規則。
- [../AGENTS.md](../AGENTS.md)：通用 coding agent 導引。
- [../CLAUDE.md](../CLAUDE.md)：另一份 agent 導引，內容應和 AGENTS 保持同一套事實。
- [../CHANGELOG.md](../CHANGELOG.md)：高可信度里程碑摘要。
- [../release-notes/](../release-notes/)：逐版本 release notes。

## 資料夾歸屬規則

判斷一個檔案該放在哪裡，先問三個問題：

1. 它是不是整個 app 都會用，且不應依賴任何 feature？
   - 是：放 `lib/core/`。
   - 例：資料庫、DAO、全域 model、網路、書源解析、本地書解析、備份還原、全域 service、app config。
2. 它是不是某一個產品功能的流程、狀態或畫面？
   - 是：放 `lib/features/<feature>/`。
   - 例：reader、bookshelf、book_detail、search、settings 各自的 page/controller/widget。
3. 它是不是純 UI 共用元件，沒有特定業務語意？
   - 是：放 `lib/shared/`。
   - 例：跨 feature 共用的 theme、button、layout widget。

### `core`

`core` 是 app 的底層能力。它可以被 feature 使用，但不應該 import `features/...`。

適合放 `core`：

- `core/database/`：Drift table、DAO、database。
- `core/models/`：全 app 共用資料模型，例如 `Book`、`BookChapter`、`BookSource`。
- `core/engine/`：書源規則解析、WebBook、JS bridge、內容處理等跨 UI 的核心能力。
- `core/local_book/`：TXT / EPUB / UMD 等本地書解析。
- `core/network/`：Dio、API、interceptor。
- `core/services/`：跨 feature 的服務，例如備份、還原、TTS、下載、檔案儲存。
- `core/storage/`、`core/utils/`、`core/constant/`、`core/config/`：全域工具與設定。

不適合放 `core`：

- 只服務 reader 的 layout、viewport、progress runtime。
- 某個頁面的 controller、menu、dialog、widget。
- 會 import `features/...` 的東西。

### `features`

`features` 是產品功能。feature 可以 import `core` 和 `shared`，但不同 feature 之間應避免直接糾纏；需要跨功能協作時，優先用 `core/services` 或明確的資料模型承接。

適合放 `features/<feature>`：

- 入口 page。
- 該功能自己的 controller / provider。
- 該功能自己的 UI widget。
- 該功能自己的 runtime 狀態。
- 該功能自己的演算法，只要它離開這個 feature 沒有獨立意義。

reader 的 layout engine 雖然偏底層，但它只服務閱讀器，所以放在 `lib/features/reader/engine/`，不是 `core/engine/`。`core/engine/reader/` 則偏向書源正文處理與轉換，是內容來源層，不是 reader viewport/runtime。

### `shared`

`shared` 只放跨功能的通用 UI。它不應該知道 reader、bookshelf、search 這些業務語意。

適合放 `shared`：

- 共用 theme。
- 通用 widget。
- 不帶 domain 行為的 UI building block。

不適合放 `shared`：

- reader menu。
- 書籍詳情卡片。
- 書架排序邏輯。
- 搜尋結果業務狀態。

### `test`

測試目錄跟 production 目錄對齊：

- `test/core/...` 測 `lib/core/...`。
- `test/features/reader/...` 測 `lib/features/reader/...`。
- `test/features/settings/...` 測 `lib/features/settings/...`。

刪除 production 殘留檔案時，對應只保護殘留模型的測試也要一起刪掉；保留測試會讓已廢棄架構看起來仍然有效。

## 文件規則

- 主文件只描述目前 `main` 上已存在、可被程式碼或測試驗證的事實。
- 討論稿、方案比較、review prompt、階段性實作順序放進 `docs/archive/`。
- reader durable progress 一律寫成 `ReaderLocation(chapterIndex, charOffset, visualOffsetPx)`。
- 如果 reader 的 runtime、progress、layout、viewport 或 DB 欄位改動，優先同步更新 [reader_current_state.md](reader_current_state.md)。
- 如果手機實測流程或回報格式改動，更新 [reader_mobile_test_plan.md](reader_mobile_test_plan.md)。
