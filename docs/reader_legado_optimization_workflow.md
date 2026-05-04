# Reader x Legado 優化工作流程

## 目的

- 用於改善既有行為、可靠性、清晰度、可維護性或效能，不夾帶 unrelated feature。
- 一般優化不要重新執行 Codebase Atlas；先用 `reader_legado_index.md` 選定模組，再依模組文檔進入程式碼。
- `legado` 可協助判斷流程切法、失敗處理與穩定化方式，但不是功能對齊清單。

## 工作流程

1. 打開 [reader_legado_index.md](reader_legado_index.md)，選一個這次要優化的主模組。
2. 閱讀主模組文檔的目前狀態、上下游、可參考模式、變更入口與已知風險。
3. 依模組文檔查看最相關的 `legado` 對應區域，比較責任邊界、資料流、狀態生命週期、錯誤處理、診斷與測試策略。
4. 找出最小變更層：UI、provider/controller、runtime、service、data、integration 或 tooling。
5. 列出 2-3 個具體優化方向，然後只選一個方向執行。
6. 除非使用者要求，保持使用者可見行為不變。
7. 驗證上游輸入與下游行為仍可用。
8. 若結構、責任或風險改變，更新受影響的 Atlas 模組文檔。
9. 依交付政策完成：提交並推送。完成驗證後建立聚焦 commit，確認目標 remote/branch 後推送；若 remote 或 branch 不清楚，推送前必須先詢問。

## 編輯前摘要

當使用者或專案規則期待確認時，先摘要並等待確認：

- 目標模組
- 目前問題或優化動機
- 候選方向與本次選定方向
- 優化前後行為，包含使用者可見行為與內部責任切分
- 明確非目標
- 要執行的測試或檢查

## 交付政策

提交並推送。完成驗證後建立聚焦 commit，確認目標 remote/branch 後推送；若 remote 或 branch 不清楚，推送前必須先詢問。
