# Docs Index

更新日期：2026-03-30

這份索引只收錄目前仍應被維護、且能直接對照現有代碼的文檔。閱讀順序建議由總覽到細節。

## 建議閱讀順序

1. [../README.md](../README.md)
   專案總覽、功能範圍、開發入口與版本資訊
2. [architecture.md](architecture.md)
   專案應收斂到的目標架構、模組邊界與分層原則
3. [reader_architecture_current.md](reader_architecture_current.md)
   閱讀器 runtime 目前實際如何運作
4. [DATABASE.md](DATABASE.md)
   資料庫 schema、DAO、migration 與持久化邊界
5. [roadmap.md](roadmap.md)
   當前風險、優先級與下一階段整理方向

## 文檔分工

- `README.md`
  對外總覽，回答「這個專案是什麼、現在做到哪裡、怎麼跑起來」
- `architecture.md`
  對內目標架構，回答「專案應該如何分層與收斂」
- `reader_architecture_current.md`
  閱讀器現況，回答「現在這套 runtime 的真實責任鏈是什麼」
- `DATABASE.md`
  資料層現況，回答「資料真源在哪裡、schema 長什麼樣」
- `roadmap.md`
  近期路線圖，回答「接下來先修什麼、哪些風險要優先消化」

## 歷史文檔

以下文檔保留為歷史分析與設計上下文，不應當成最新真相來源：

- `superpowers/plans/`
- `superpowers/specs/`

這些文件仍有參考價值，但如果與主文檔或代碼衝突，應以代碼與本層主文檔為準。

## 維護原則

- 只保留能由代碼驗證的描述
- 同一個問題只由一份主文檔負責
- 過時內容要修正或刪除，不保留半失效說明
- 任何包含舊機器絕對路徑、舊版本號或舊架構名詞的說明都應視為待修
