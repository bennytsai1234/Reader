# Docs Index

更新日期：2026-03-20

這份索引只列出目前仍符合代碼事實、且對開發決策有直接價值的文檔。

## 核心文檔

- [reader_architecture_current.md](/C:/Users/benny/Desktop/Folder/Project/reader/ios/docs/reader_architecture_current.md)
  - 目前閱讀器 runtime 的實際架構、主鏈、分層與責任邊界
- [next_refactor_roadmap.md](/C:/Users/benny/Desktop/Folder/Project/reader/ios/next_refactor_roadmap.md)
  - 在本輪大重構完成後，接下來仍值得做的優化方向
- [DATABASE.md](/C:/Users/benny/Desktop/Folder/Project/reader/ios/docs/DATABASE.md)
  - 資料庫實際 schema、DAO 組成與目前版本資訊

## 文檔分工

- `reader_architecture_current.md`
  - 回答「現在系統實際怎麼運作」
- `next_refactor_roadmap.md`
  - 回答「下一步還要做什麼」
- `DATABASE.md`
  - 回答「資料層目前長什麼樣」

## 編寫原則

- 只描述目前代碼可驗證的事實
- 不保留已過期的臨時分析稿
- 不同文檔不重複承擔同一個問題
- 如果某份文檔無法持續維護，就應刪除，而不是任其過時
