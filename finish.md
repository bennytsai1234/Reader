# ✅ Project Alignment Progress (Finished)

## 1. 核心邏輯與引擎層 (Core Engine & Logic)

- [x] **數據模型** (`lib/core/models/`)
  - [x] `BookType` 常量對齊 Android 3.0+ 位元標記
  - [x] `Book` 模型核心屬性與業務邏輯對齊
  - [x] `BookSource` 與所有子規則 (`SearchRule`, `TocRule`, etc.) 對齊
  - [x] `BookSourcePart` 輕量化模型擴展 (v2026.03.16)

- [x] **資料庫接口 (DAOs)** (`lib/core/database/dao/`)
  - [x] `BookDao`: 補全位運算過濾、特殊分組處理、`hasFile` 等方法
  - [x] `BookSourceDao`: 實現 `BookSourcePart` 視圖與 SQL 預計算標記，補全高級搜尋與分組管理
  - [x] `ChapterDao`: 實現章節範圍查詢、標題搜尋與字數更新
  - [x] `BookmarkDao`: 實現批量刪除與事件廣播修正
  - [x] `ReplaceRuleDao`: 實現精確的 `scope` 與 `excludeScope` 範圍過濾邏輯

- [x] **UI/Logic 同步優化**
  - [x] `SourceManager` 模組全鏈條適配 `BookSourcePart`，兼顧列表滾動流暢度與功能完整性
  - [x] 修正全域 `SharePlus` 棄用警告與 iPad 相容性

---
*Last update: 2026-03-16*
