# 專案架構

這份文件描述 `main` 分支目前實際存在的架構，不描述過去規劃，也不描述未落地設計。

## 一句話

Inkpage 是一個以 Flutter 實作的小說閱讀器應用，主體由三層組成：

- `core/`：資料庫、書源引擎、服務與共用基礎設施
- `features/`：產品功能模組
- `shared/`：主題與共用 UI 元件

## 目錄邊界

```text
lib/
  core/
    database/
    engine/
    models/
    network/
    services/
    storage/
    utils/
  features/
    about/
    book_detail/
    bookmark/
    bookshelf/
    browser/
    cache_manager/
    dict/
    explore/
    read_record/
    reader/
    replace_rule/
    search/
    settings/
    source_manager/
    txt_toc_rule/
    welcome/
  shared/
    theme/
    widgets/
```

## `core/` 的責任

### `core/database/`

- `AppDatabase`：Drift singleton，schema version `1`
- DAO：所有資料寫入與查詢的唯一正式入口
- tables：資料表與 converter 定義

### `core/engine/`

書源能力集中在這裡，包含：

- URL / rule 分析
- HTML / JSON / XPath / JS 規則解析
- WebView 書源與登入流程
- 網頁與正文抓取

這一層不是 UI 輔助，而是整個「書源系統」的執行核心。

### `core/models/`

定義書籍、章節、書源、書籤、閱讀紀錄、下載任務等核心資料模型。

### `core/services/`

封裝下載、書源切換、TTS、備份、驗證、儲存等服務邏輯。

## `features/` 的責任

### 內容入口

- `bookshelf/`
- `search/`
- `explore/`
- `book_detail/`
- `source_manager/`

這些模組共同組成：

- 找書
- 看書籍詳情
- 換源
- 管理書源
- 回到閱讀器

### 閱讀器

`features/reader/` 是 repo 內最複雜的 feature，拆成四層：

- `engine/`：章節內容載入、分頁、位置轉換
- `provider/`：facade mixin 與相容入口
- `runtime/`：session、restore、progress、viewport、content lifecycle
- `view/`：scroll / slide 執行層與 widget runtime

細節見 [reader_runtime.md](reader_runtime.md)。

## 真實資料流

### 書源到閱讀

1. `source_manager/` 管理書源啟用、分組、校驗與來源狀態
2. `search/` / `explore/` 透過 `core/engine` 執行規則
3. `book_detail/` 載入書籍詳情、目錄與換源資料
4. `reader/` 以 `ReadBookController` 和各 runtime 負責正文載入、分頁、進度與 restore

### 閱讀進度

1. `reader` 以 `ReaderLocation(chapterIndex, charOffset)` 作 durable location
2. `ReaderProgressStore` / `ReaderSessionCoordinator` 寫回 `Book` 與 `ReadRecord`
3. 重新進入時，bootstrap 依 durable location 還原內容與 viewport

## 目前不在架構目標內的東西

- RSS 流程
- 額外閱讀模式實驗
- Android-only 系統整合頁照搬
- 以文檔先行、程式尚未存在的設計稿

## CI 與釋出邊界

目前正式工作流只有兩條：

- `dart.yml`
  - `flutter analyze`
  - `tool/flutter_test_with_quickjs.sh`
- `build-release.yml`
  - tag 觸發 release build
  - 同步版本號到 `main`
  - Android / iOS 產物
  - GitHub Release

完整釋出規則見 [release.md](release.md)。
