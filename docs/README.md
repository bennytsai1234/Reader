# Docs Index

更新日期：2026-03-29

這份索引只列出目前仍符合代碼事實、且對開發決策有直接價值的文檔。

## 核心文檔

- [roadmap.md](roadmap.md)
  - 專案接下來應如何完成、優先級、milestones 與完成標準
- [architecture.md](architecture.md)
  - 專案總體目標架構、模組分層、責任邊界與遷移方向
- [reader_architecture_current.md](reader_architecture_current.md)
  - 目前閱讀器 runtime 的實際架構、主鏈、分層與責任邊界
- [DATABASE.md](DATABASE.md)
  - 資料庫實際 schema、DAO 組成與目前版本資訊

## 文檔分工

- `roadmap.md`
  - 回答「接下來應該先做什麼、按什麼順序完成專案」
- `architecture.md`
  - 回答「整個專案應該怎麼分層、怎麼切模組」
- `reader_architecture_current.md`
  - 回答「現在系統實際怎麼運作」
- `DATABASE.md`
  - 回答「資料層目前長什麼樣」

## 編寫原則

- 只描述目前代碼可驗證的事實
- 不保留已過期的臨時分析稿
- 不同文檔不重複承擔同一個問題
- 如果某份文檔無法持續維護，就應刪除，而不是任其過時
