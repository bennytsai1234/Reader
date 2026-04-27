# 文檔索引

這個目錄只保留能從目前 `main` 程式碼、CI、資料表或專案檔驗證的文件。

## 維護原則

- 文件描述現況，不保存已完成或已失效的 handoff、roadmap、階段執行稿。
- 架構文件以 `lib/`、`.github/workflows/`、`pubspec.yaml` 的實作為準。
- 資料庫文件以 `lib/core/database/app_database.dart` 與 `lib/core/database/tables/app_tables.dart` 為準。
- 閱讀器文件以目前接進 `ReaderPage` 的主線為準；未接線的 runtime 旁支必須明確標示。

## 目前文件

- [architecture.md](architecture.md)
  - app 啟動、技術棧、分層、主要資料流與模組邊界。
- [app_flow_architecture.md](app_flow_architecture.md)
  - 整個 app 的 Mermaid 架構圖、啟動流程、主導航、找書到閱讀、閱讀器、書源管理、備份還原與背景任務流程。
- [app_user_flows.md](app_user_flows.md)
  - 從使用者操作角度整理 app 流程圖；目前包含 A 類啟動與主入口流程。
- [reader_runtime.md](reader_runtime.md)
  - 閱讀器目前真正接線的 runtime、內容載入、分頁、viewport、進度與 TTS。
- [reader_spec.md](reader_spec.md)
  - 閱讀器目前可驗證的功能規格與非目標。
- [DATABASE.md](DATABASE.md)
  - Drift schema version 1、資料表、DAO、migration、備份與還原。
- [release.md](release.md)
  - CI、tag release、Android/iOS artifacts 與版本同步流程。

## 建議閱讀順序

1. [../README.md](../README.md)
2. [architecture.md](architecture.md)
3. [app_flow_architecture.md](app_flow_architecture.md)
4. [app_user_flows.md](app_user_flows.md)
5. [DATABASE.md](DATABASE.md)
6. [reader_runtime.md](reader_runtime.md)
7. [reader_spec.md](reader_spec.md)
8. [release.md](release.md)
