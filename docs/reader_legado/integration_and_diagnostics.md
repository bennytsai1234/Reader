# Integration And Diagnostics

## 目標專案目前狀態

- 外部連結與分享匯入在 `lib/features/association`，`AssociationHandlerService` 是 singleton，混入 URI、檔案與對話框 helper。
- `UriAssociationHandler` 支援 `legado://` 與 `yuedu://`，依 type 映射書源、替換規則與加入書架入口。
- `FileAssociationHandler` 處理分享進來的 JSON 與本地書格式；本地書會複製到 app document 目錄的 `LegadoBooks` 後呼叫 `BookshelfProvider.importLocalBookPath()`。
- 關於與診斷在 `lib/features/about`，crash log UI 是 `crash_log_page.dart`。
- `CrashHandler` 會接管 Flutter/Platform error，寫入 crash log；`AppLog` 保留記憶體內近期 log 並支援 toast stream。

## 目標專案上下游

- 上游依賴：`app_links`、`receive_sharing_intent`、`path_provider`、`BookshelfProvider`、`SourceImportService`、`ReplaceRuleProvider`、`CrashHandler`、`AppLog`、`AppVersion`。
- 下游影響：書源匯入、替換規則匯入、本地書匯入、書架刷新、關於頁、錯誤回報與 crash log 檢查。
- 外部入口通常在 app 已啟動但 navigator/provider 狀態可能尚未穩定時發生，要先確認 `context.mounted` 與 provider 可用。

## 參考對應

- `legado/app/src/main/java/io/legado/app/ui/association`
- `legado/app/src/main/java/io/legado/app/ui/about`
- `legado/app/src/main/java/io/legado/app/help/IntentHelp.kt`
- `legado/app/src/main/java/io/legado/app/help/IntentData.kt`
- `legado/app/src/main/java/io/legado/app/help/CrashHandler.kt`
- `legado/api.md`

## 可參考模式

- 外部入口要先判斷資料類型，再交給 app 內對應匯入流程，不要在 intent handler 內直接做完整業務邏輯。
- 匯入對話與實際匯入應分離，讓失敗時可以提供 fallback 或強制匯入。
- 診斷資訊應集中提供 app 版本、平台、錯誤與 stack，便於後續 bug workflow 定位。

## 目標專案變更入口

- 外部服務：`lib/features/association/association_handler_service.dart`。
- URI：`lib/features/association/handlers/uri_association_handler.dart`。
- 檔案分享：`lib/features/association/handlers/file_association_handler.dart`。
- 匯入對話：`lib/features/association/handlers/association_dialog_helper.dart`。
- 診斷：`lib/features/about/crash_log_page.dart`、`lib/core/services/crash_handler.dart`、`lib/core/services/app_log_service.dart`。
- 測試：`flutter test test/import_logic_test.dart test/local_txt_test.dart test/core/local_book`；外部 intent 行為通常需要手動 smoke 或 widget-level 補測。

## 已知風險

- Android/iOS intent 與分享 callback 可能早於目標 page ready；使用 `BuildContext` 前要檢查 `mounted`。
- JSON 類型判斷目前靠第一筆欄位推斷；新增匯入類型要避免誤判書源、替換規則或 theme。
- 本地書分享會複製檔案；同名檔案已存在時目前不覆蓋，可能造成使用者以為匯入了新版本但實際讀舊檔。
- Crash log 寫入外部或 app document 目錄，平台權限與檔案位置差異會影響可讀性。
- `AppLog` 只保留記憶體內最近 100 筆，不能當成完整持久診斷資料。

## 不要做

- 不把外部 API 擴張成完整遠端控制平台。
- 不在 association handler 裡直接改 source manager、replace rule 或 reader runtime 的內部狀態。
- 不把診斷頁做成新的進階產品面；它只應協助定位問題。
