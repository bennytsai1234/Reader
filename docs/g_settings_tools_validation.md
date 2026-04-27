# G 系列設定與工具功能驗證手冊

這份文件用來驗證「G 系列：設定與工具」功能。當備份還原、閱讀設定、TTS、規則管理、書籤紀錄、Log、Cookie / WebView 資料清理、隱私與權限說明出問題時，先照這份文件查。

## 適用範圍

- 設定首頁：`lib/features/settings/settings_page.dart`
- 其他設定與資料隱私：`lib/features/settings/other_settings_page.dart`、`lib/features/settings/data_privacy_settings_page.dart`
- 備份還原：`lib/features/settings/backup_settings_page.dart`、`lib/core/services/backup_service.dart`、`lib/core/services/restore_service.dart`
- 閱讀設定與打點區：`lib/features/settings/reading_settings_page.dart`、`lib/features/settings/click_action_config_page.dart`
- 系統 TTS：`lib/features/settings/tts_settings_page.dart`、`lib/core/services/tts_service.dart`
- 外觀與歡迎頁：`lib/features/settings/appearance_settings_page.dart`、`lib/features/settings/welcome_settings_page.dart`
- 替換 / 字典 / TXT 目錄規則：`lib/features/replace_rule/`、`lib/features/dict/`、`lib/features/txt_toc_rule/`
- 書籤與閱讀紀錄：`lib/features/bookmark/`、`lib/features/read_record/`
- About / Log：`lib/features/about/`、`lib/core/services/app_log_service.dart`、`lib/core/services/crash_handler.dart`
- Cookie / WebView 資料：`lib/core/services/cookie_store.dart`、`lib/core/services/network_service.dart`、`lib/core/services/webview_data_service.dart`
- 書源調試：`lib/core/services/source_debug_service.dart`、`lib/features/source_debug/`

## 快速驗證命令

```bash
flutter analyze lib/core/services/webview_data_service.dart \
  lib/features/settings/data_privacy_settings_page.dart \
  lib/features/settings/tts_settings_page.dart \
  lib/features/settings/other_settings_page.dart \
  lib/features/settings/settings_page.dart \
  lib/features/settings/settings_provider.dart

flutter test test/features/settings/other_settings_page_test.dart

flutter test test/features/reader/reader_tts_engine_factory_test.dart \
  test/features/reader/reader_tts_source_test.dart
```

修改備份、還原、規則或 Cookie 清理後，還需要至少跑一次實機或模擬器手動驗證。WebView cache、localStorage 與系統 Cookie 是平台能力，單元測試無法完整覆蓋。

## 功能表

| 編號 | 功能 | 現況 | 主要驗證點 |
| --- | --- | --- | --- |
| G1 | 備份資料 | 保留 | ZIP 內包含書架、書源、書籤、閱讀進度、設定、替換規則、字典規則、TXT 規則、HTTP TTS 舊資料、正文快取等 |
| G2 | 還原備份 | 保留 | 選 ZIP 後依 manifest 匯入資料表與 config |
| G3 | 閱讀設定 | 保留 | 排版、翻頁、繁簡轉換、自動換源等設定可保存並影響閱讀器 |
| G4 | 打點區設定 | 保留 | 3x3 點擊區可修改、保存與重置 |
| G5 | TTS 設定 | 收斂 | 只保留系統 TTS；語速、音調、音量、系統語音引擎、音色可設定 |
| G6 | 外觀與主題 / 歡迎頁 | 部分保留 | 主題模式與歡迎頁設定保留；顏色與首頁樣式不作為目前驗證目標 |
| G7 | 替換規則 | 保留 | 新增、編輯、刪除、匯入、匯出、測試、啟用與排序 |
| G8 | 字典規則 | 保留 | 新增、編輯、刪除、啟用與 JSON 複製/貼上 |
| G9 | TXT 目錄規則 | 保留 | 新增、編輯、刪除、啟用 |
| G10 | 書籤管理跳回書籍 | 保留 | 書籤列表可搜尋，點擊跳回對應書籍與位置 |
| G11 | 閱讀紀錄 | 部分保留 | 顯示打開過的書籍與閱讀時間；不做完整進度跳轉入口 |
| G12 | App log / crash log / 關於頁 | 保留 | About、版本、授權、App log、crash log 可查看 |
| G13 | 匯出 App log | 不做 | 目前不提供匯出檔案 |
| G14 | 匯出 crash log | 不做 | 目前保留複製與清除，不做分享匯出 |
| G15 | 書源調試 log | 部分保留 | 可看 URL、解析結果、錯誤；Headers、完整 Response 與耗時統計不作為目前目標 |
| G16 | 慢請求 / 慢解析統計 | 不做 | 不做獨立統計頁 |
| G17 | 清除快取 | 不做全域入口 | 單本書快取清理保留；全域圖片/正文/搜尋/暫存清理不做 |
| G18 | 清 Cookie / WebView 資料 | 保留 | 清全部 Cookie、指定書源 Cookie、WebView localStorage、WebView cache |
| G19 | 重置 App 資料 | 不做 | 不提供危險重置入口 |
| G20 | 備份檔加密 | 不做 | 備份 ZIP 目前不加密 |
| G21 | 隱私說明 | 保留 | 說明本地資料、Cookie、WebView、備份資料、網路請求與 log |
| G22 | 權限管理與說明 | 保留 | 說明檔案、網路、通知/背景任務、WebView 權限用途 |
| G23 | 操作撤銷與確認設定 | 不做 | 保留必要確認框，不提供全域撤銷/確認設定 |

## 驗證步驟

### G1 / G2 備份與還原

入口鏈路：

```text
SettingsPage
  -> 備份與還原
  -> BackupSettingsPage
  -> BackupService.createBackupZip()
  -> RestoreService.restoreFromZip(file)
```

手動驗證：

1. 在書架準備至少一本書、一個書籤、一筆閱讀紀錄與一條替換規則。
2. 進入 `我的` -> `備份與還原`。
3. 執行本地備份，預期產生 ZIP 並進入分享流程。
4. 解開 ZIP，確認至少包含 `manifest.json`、`bookshelf.json`、`bookSource.json`、`bookmark.json`、`readRecord.json`、`replaceRule.json`、`txtTocRule.json`、`dictRule.json`、`config.json`、`readerChapterContent.json`。
5. 使用同一 ZIP 執行還原。
6. 預期書架、規則、書籤、閱讀紀錄與設定可回復。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 備份頁 | `features/settings/backup_settings_page.dart` |
| 建立 ZIP | `core/services/backup_service.dart` / `createBackupZip()` |
| 還原 ZIP | `core/services/restore_service.dart` / `restoreFromZip()` |
| 設定備份 | `SharedPreferences` -> `config.json` |

常見故障定位：

- ZIP 內缺資料：先看 `BackupService.createBackupZip()` 的 export 清單。
- 還原後書架空白：檢查 `RestoreService.restoreFromZip()` 是否有讀到 `bookshelf.json`。
- 設定沒回復：檢查 `config.json` 是否存在，以及 restore 是否寫回 SharedPreferences。

### G3 / G4 閱讀設定與打點區

手動驗證：

1. 進入 `我的` -> `閱讀設定`。
2. 修改字號、行高、字距、段距、縮排、翻頁模式或繁簡轉換。
3. 打開任一本書，確認閱讀器使用新設定。
4. 在閱讀設定進入 `打點區設定`。
5. 修改任一格點擊行為，保存後回閱讀器測試對應區域。
6. 點重置預設，確認九宮格回到預設行為。

相關檔案：

| 項目 | 檔案 |
| --- | --- |
| 閱讀設定頁 | `features/settings/reading_settings_page.dart` |
| 打點區設定 | `features/settings/click_action_config_page.dart` |
| 閱讀偏好 | `features/reader/settings/reader_prefs_repository.dart` |
| 閱讀器消費設定 | `features/reader/controllers/reader_settings_controller.dart` |

常見故障定位：

- 設定頁顯示已變但閱讀器沒變：檢查 `ReaderPrefsRepository` 是否有保存，以及 `ReaderSettingsController` 是否載入最新 snapshot。
- 點擊區無效：檢查 `ReaderTapAction` code 是否保存到偏好設定。

### G5 系統 TTS

產品決策：

- 設定頁只保留系統 TTS。
- HTTP TTS 管理入口不再顯示。
- 舊的 `readerTtsSource=httpTts:*` 會在 `SettingsProvider` 載入時回退為 `system`。

手動驗證：

1. 進入 `我的` -> `朗讀與語音`。
2. 預期頁面只顯示 `語速`、`音調`、`音量`、`語音引擎`、`音色`。
3. 預期不再看到 `HTTP TTS 管理` 或 `HTTP TTS` 來源下拉選項。
4. 修改語速、音調、音量後打開閱讀器朗讀，確認系統 TTS 使用新參數。
5. 若裝置提供多個系統 TTS engine 或 voice，切換後確認朗讀音色變更。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| TTS 設定頁 | `features/settings/tts_settings_page.dart` |
| TTS 狀態 | `features/settings/settings_provider.dart` |
| 系統 TTS | `core/services/tts_service.dart` |
| 閱讀器朗讀控制 | `features/reader/controllers/reader_tts_controller.dart` |

常見故障定位：

- 設定頁還有 HTTP TTS：檢查 `tts_settings_page.dart` 是否又引入 `HttpTtsProvider` 或 `HttpTtsManagerPage`。
- 音色清單空白：可能是平台 TTS engine 沒提供 voices；先在系統設定安裝或啟用 TTS 語音。
- 舊 HTTP TTS 仍被使用：檢查 `PreferKey.ttsSource` 是否在 `SettingsProvider._loadSettings()` 被重設為 `system`。

### G6 外觀與歡迎頁

手動驗證：

1. 進入 `我的` -> `外觀與主題`。
2. 切換系統 / 淺色 / 深色模式，確認 app theme 改變並保存。
3. 進入歡迎頁設定。
4. 修改日間/夜間歡迎圖片、文字與圖示開關。
5. 冷啟 app，確認 Splash / Welcome 使用新設定。

相關檔案：

| 項目 | 檔案 |
| --- | --- |
| 外觀設定 | `features/settings/appearance_settings_page.dart` |
| 歡迎頁設定 | `features/settings/welcome_settings_page.dart` |
| 設定狀態 | `features/settings/settings_provider.dart` |
| 啟動畫面 | `features/welcome/splash_page.dart` |

常見故障定位：

- Theme 沒變：檢查 `MaterialApp.themeMode` 是否仍綁定 `settings.themeMode`。
- 歡迎圖片不顯示：檢查本機檔案路徑是否仍存在。

### G7 / G8 / G9 規則管理

手動驗證：

1. 進入 `我的` -> `替換淨化`。
2. 新增替換規則，測試輸入文字，確認輸出符合預期。
3. 匯出規則到剪貼簿，再刪除後從剪貼簿匯入。
4. 進入 `字典規則`，新增、編輯、刪除並切換啟用狀態。
5. 進入 `本地目錄規則`，新增 regex 規則並切換啟用狀態。

相關檔案：

| 功能 | 檔案 |
| --- | --- |
| 替換規則 | `features/replace_rule/replace_rule_page.dart`、`features/replace_rule/replace_rule_provider.dart` |
| 字典規則 | `features/dict/dict_rule_page.dart`、`features/dict/dict_provider.dart` |
| TXT 目錄規則 | `features/txt_toc_rule/txt_toc_rule_page.dart`、`features/txt_toc_rule/txt_toc_rule_provider.dart` |

常見故障定位：

- 替換測試無效：檢查規則是否啟用、scope 是否限制 title/content。
- 字典查不到：檢查 `DictService` 是否能讀到啟用規則。
- TXT 章節切分錯誤：先測 regex，再看本地書匯入時使用的章節解析規則。

### G10 / G11 書籤與閱讀紀錄

手動驗證：

1. 在閱讀器新增書籤。
2. 進入 `我的` -> `書籤管理`。
3. 搜尋剛建立的書籤，點擊後預期回到對應書籍與位置。
4. 閱讀任一本書一段時間。
5. 進入 `我的` -> `閱讀紀錄`。
6. 預期列表顯示書名、閱讀時間與最後閱讀時間。

相關檔案：

| 功能 | 檔案 |
| --- | --- |
| 書籤頁 | `features/bookmark/bookmark_page.dart` |
| 書籤狀態 | `features/bookmark/bookmark_provider.dart` |
| 閱讀紀錄頁 | `features/read_record/read_record_page.dart` |
| 閱讀紀錄狀態 | `features/read_record/read_record_provider.dart` |

常見故障定位：

- 書籤點擊失敗：檢查書籍是否仍存在於書架，`BookmarkProvider.lookupBook()` 找不到書會提示。
- 閱讀紀錄不更新：檢查閱讀器退出或進度保存時是否寫入 `ReadRecordDao`。

### G12 / G15 About、Log 與書源調試

手動驗證：

1. 進入 `我的` -> `關於墨頁`。
2. 確認可查看版本資訊、開源授權、App log、crash log。
3. 到書源管理或書籍詳情頁進入書源調試。
4. 執行搜尋、詳情、目錄或正文調試。
5. 預期可看到 URL、解析摘要、錯誤訊息與解析結果。

相關檔案：

| 功能 | 檔案 |
| --- | --- |
| About | `features/about/about_page.dart` |
| App log | `features/about/app_log_page.dart`、`core/services/app_log_service.dart` |
| Crash log | `features/about/crash_log_page.dart`、`core/services/crash_handler.dart` |
| 書源調試 | `features/source_debug/`、`core/services/source_debug_service.dart` |

常見故障定位：

- App log 空白：`AppLog` 是記憶體 queue，冷啟後只會看到本次執行產生的 log。
- Crash log 空白：需要實際有 crash log 檔案，或 `CrashHandler` 成功初始化。
- 書源調試沒有結果：先確認書源已啟用，且調試 key 不為空。

### G18 Cookie / WebView 資料清理

入口鏈路：

```text
SettingsPage
  -> 其他設定
  -> 資料與隱私
  -> WebViewDataService
```

手動驗證：

1. 進入 `我的` -> `其他設定` -> `資料與隱私`。
2. 點 `清除全部 Cookie`，確認有二次確認，成功後顯示 snackbar。
3. 點 `清除指定書源 Cookie`，輸入 `https://example.com` 或 `example.com`，確認成功提示。
4. 點 `清除 WebView localStorage`，確認有二次確認與成功提示。
5. 點 `清除 WebView cache`，確認有二次確認與成功提示。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 資料與隱私頁 | `features/settings/data_privacy_settings_page.dart` |
| App Cookie | `core/services/cookie_store.dart` / `clearAll()`、`removeCookie()` |
| Dio Cookie | `core/services/network_service.dart` / `cookieJar` |
| WebView Cookie/cache/storage | `core/services/webview_data_service.dart` |

注意：

- `清除全部 Cookie` 會清 App Cookie、Dio 持久化 Cookie 與 WebView Cookie。
- `清除指定書源 Cookie` 只清 App Cookie 與 Dio Cookie。`webview_flutter` 目前沒有可靠的指定站點 WebView Cookie 刪除 API。

常見故障定位：

- 點清除後報錯：確認 `NetworkService.init()` 已完成，否則 `cookieJar` 尚未初始化。
- 指定書源格式錯誤：輸入完整 URL 或純網域，不要輸入書名。
- WebView 資料仍像沒清：部分平台可能需要關閉既有 WebView 頁面或重啟 app 才能看到效果。

### G21 / G22 隱私與權限說明

手動驗證：

1. 進入 `我的` -> `其他設定` -> `資料與隱私`。
2. 點 `隱私說明`。
3. 預期看到本地資料、Cookie 與 WebView、網路請求、備份資料與 log 說明。
4. 返回後點 `權限說明`。
5. 預期看到檔案、網路、通知與背景任務、WebView 權限用途說明。

相關檔案：

| 項目 | 檔案 |
| --- | --- |
| 隱私說明 | `features/settings/data_privacy_settings_page.dart` / `PrivacyNoticePage` |
| 權限說明 | `features/settings/data_privacy_settings_page.dart` / `PermissionNoticePage` |

常見故障定位：

- 找不到入口：確認 `OtherSettingsPage` 是否有 `資料與隱私` ListTile。
- 文字過舊：直接更新 `PrivacyNoticePage` 或 `PermissionNoticePage` 的段落。

## 已收斂或不做項目

| 項目 | 決策 | 驗證方式 |
| --- | --- | --- |
| 語言設定 | 移除入口 | 目前沒有完整 l10n/ARB/localization delegates，App 文案多為硬編碼中文；`其他設定` 不應再顯示語言選擇 |
| HTTP TTS 管理 | 移除入口 | `朗讀與語音` 不應出現 HTTP TTS 管理；舊偏好會回退系統 TTS |
| App log 匯出 | 不做 | About 只保留查看與清除 |
| Crash log 匯出 | 不做 | 只保留查看、複製與清除 |
| 慢請求統計 | 不做 | 不應出現獨立統計頁 |
| 重置 App 資料 | 不做 | 不提供危險重置入口 |
| 備份加密 | 不做 | 備份 ZIP 不要求密碼 |
| 刪除後撤銷設定 | 不做 | 保留必要確認框，不做全域 undo 設定 |

## 常見故障定位總表

| 現象 | 優先檢查 |
| --- | --- |
| 設定頁進不去 | `SettingsPage` import 與 `Navigator.push` 目標頁 constructor |
| 其他設定頁測試失敗 | `OtherSettingsPage` 的最後一個 `SwitchListTile` 仍應是 `顯示加入書架提示` |
| TTS 設定不生效 | `SettingsProvider.setSpeechRate/setSpeechPitch/setSpeechVolume` 是否呼叫 `TTSService()` |
| 系統音色沒有選項 | 平台 TTS engine 未提供 voices，先檢查系統 TTS 設定 |
| 舊 HTTP TTS 仍生效 | 清查 `PreferKey.ttsSource` 與 `SettingsProvider._loadSettings()` |
| Cookie 沒清乾淨 | 分清 App Cookie、Dio Cookie 與 WebView Cookie；指定書源不會清單站 WebView Cookie |
| WebView cache 清除後仍顯示舊頁 | 關閉現有 WebView、重新進入頁面或重啟 app |
| 備份還原後設定不對 | 檢查 ZIP 內 `config.json` 與 `RestoreService` 寫回 SharedPreferences 流程 |
