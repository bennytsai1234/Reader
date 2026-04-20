# 墨頁 Inkpage — 文檔索引

更新日期：2026-04-20

這份索引只收錄目前仍應被維護、且能直接對照現有代碼的文檔。閱讀順序建議由總覽到細節。

## 建議閱讀順序

1. [../README.md](../README.md) — 專案總覽、功能範圍、開發入口與版本資訊
2. [architecture.md](architecture.md) — 專案目標架構、模組邊界與分層原則
3. [reader_architecture_current.md](reader_architecture_current.md) — 閱讀器 runtime 目前實際如何運作
4. [DATABASE.md](DATABASE.md) — Drift schema、DAO、migration 與持久化邊界
5. [roadmap.md](roadmap.md) — 當前風險、優先級與下一階段整理方向
6. [next_stage_handoff.md](next_stage_handoff.md) — 下一階段交接、已知風險與建議執行順序

## 文檔分工

| 文件 | 回答 |
|------|------|
| `README.md`（根目錄） | 這個專案是什麼、怎麼跑起來、現在做到哪裡 |
| `architecture.md` | 專案應如何分層、各模組責任邊界 |
| `reader_architecture_current.md` | 目前閱讀器 runtime 的真實責任鏈 |
| `DATABASE.md` | 資料真源在哪、schema 與 DAO 如何分工 |
| `roadmap.md` | 接下來先修什麼、哪些能力不做 |
| `next_stage_handoff.md` | 現在可以接著做什麼、有哪些已知坑要避開 |

## 維護原則

- 只保留能由代碼驗證的描述
- 同一個問題只由一份主文檔負責
- 過時內容必須修正或刪除，不保留半失效說明
- 歷史 plan / audit 文檔若仍保留，必須明確標示「歷史 / 專項記錄」，不能偽裝成當前主線
- 文檔與代碼不一致時，改文檔，不改代碼（除非代碼本身有錯）

## 歷史 / 專項文檔

- [source_audit_backlog.md](source_audit_backlog.md) — 書源相容性審計的歷史記錄，現在主要作為 parser parity 考古資料
- [slide-chapter-preload-plan.md](slide-chapter-preload-plan.md) — 平移翻頁預載優化的專項說明，不代表當前整體主線
