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
- [a_startup_validation.md](a_startup_validation.md)
  - A 系列啟動與主入口功能驗證手冊；包含功能表、手動驗證步驟、故障定位與已移除項目。
- [c_search_discovery_validation.md](c_search_discovery_validation.md)
  - C 系列搜尋與發現功能驗證手冊；包含功能表、驗證步驟、相關檔案與常見故障定位。
- [g_settings_tools_validation.md](g_settings_tools_validation.md)
  - G 系列設定與工具功能驗證手冊；包含功能表、驗證步驟、相關檔案與常見故障定位。
- [h_background_download_validation.md](h_background_download_validation.md)
  - H 系列背景與下載功能驗證手冊；包含功能表、驗證步驟、相關檔案與常見故障定位。
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
5. [a_startup_validation.md](a_startup_validation.md)
6. [c_search_discovery_validation.md](c_search_discovery_validation.md)
7. [g_settings_tools_validation.md](g_settings_tools_validation.md)
8. [h_background_download_validation.md](h_background_download_validation.md)
9. [DATABASE.md](DATABASE.md)
10. [reader_runtime.md](reader_runtime.md)
11. [reader_spec.md](reader_spec.md)
12. [release.md](release.md)
