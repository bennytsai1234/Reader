# E 系列閱讀器功能驗證手冊

這份文件用來驗證「E 系列：閱讀器」功能。閱讀器文件只以目前接進 `ReaderPage -> ReaderRuntime` 的主線為準；有程式碼或測試但沒有接進 `ReaderPage` 的旁支，必須標成「旁支 / 未接主線」。

## 適用範圍

- 閱讀器入口：`lib/features/reader/reader_page.dart`
- 閱讀器 runtime：`lib/features/reader/runtime/reader_runtime.dart`
- 章節與正文載入：`lib/features/reader/engine/chapter_repository.dart`
- 分頁與定位：`lib/features/reader/engine/layout_engine.dart`、`lib/features/reader/engine/page_resolver.dart`
- 畫面呈現：`lib/features/reader/viewport/reader_screen.dart`
- slide / scroll viewport：`lib/features/reader/viewport/slide_reader_viewport.dart`、`lib/features/reader/viewport/scroll_reader_viewport.dart`
- 閱讀器選單與抽屜：`lib/features/reader/widgets/reader_page_shell.dart`、`lib/features/reader/widgets/reader/reader_bottom_menu.dart`、`lib/features/reader/widgets/reader_chapters_drawer.dart`
- 閱讀器設定、TTS、自動翻頁、書籤：`lib/features/reader/controllers/`
- 閱讀進度、退出、加入書架：`lib/features/reader/runtime/reader_progress_controller.dart`、`lib/features/reader/runtime/reader_page_exit_coordinator.dart`、`lib/features/reader/runtime/reader_session_facade.dart`

## 快速驗證命令

```bash
flutter analyze
flutter test test/features/reader
```

全量回歸：

```bash
flutter test
```

閱讀器移除項檢查：

```bash
rg "volumeKeyPage|volumeKeyPageOnPlay" lib test
```

預期 `lib` 與 `test` 無結果。

## 功能表

| 編號 | 功能 | 現況 | 主要驗證點 |
| --- | --- | --- | --- |
| E1 | 閱讀器初始化、載入章節、正文、分頁、顯示 | 保留 | `ReaderPage` 建立 runtime，`openBook()` 後可看到正文 |
| E2 | slide 翻頁 | 保留 | 左右滑動 / 點擊區域能前後翻頁 |
| E3 | scroll 滾動閱讀 | 保留 | 切到 scroll 模式後上下拖動可閱讀並保存可見位置 |
| E4 | 閱讀器內目錄面板 | 保留 | 可開目錄 drawer，點章節跳轉 |
| E5 | 上一章 / 下一章 / 章節滑桿 | 保留 | 底部選單可前後章與滑桿跳章 |
| E6 | 保存閱讀進度、下次恢復 | 保留 | 章節 index 與 charOffset 會寫回書籍 |
| E7 | TTS 朗讀 | 部分保留 | 系統 TTS 已接；HTTP TTS engine 仍屬旁支 |
| E8 | 自動翻頁 | 部分保留 | 可啟停；速度仍是固定 timer，尚未有完整速度模式 |
| E9 | 新增書籤 | 部分保留 | 可透過自訂點擊動作新增目前位置書籤 |
| E10 | 日夜模式 / 閱讀介面設定 / 高級設定 | 部分保留 | 主題、字號、行距、段距、縮排、字距、兩端對齊、slide/scroll 已接 |
| E11 | 閱讀中搜尋 | 未接 | 目前開的是全域搜尋，不是本書 / 本章搜尋 |
| E12 | 閱讀中替換規則 | 部分保留 | 閱讀器內輕量面板可切換本書套用與刷新章節，不跳完整管理頁 |
| E13 | 退出保存 / 未入書架提示 | 保留 | 未加入書架退出時提示；加入則保存，不加入則清掉暫存資料 |
| E14 | 當前章節高亮 | 保留 | 目錄 drawer 中目前章節藍色 / 粗體 |
| E15 | 章節載入狀態顯示 | 部分保留 | 底層有 ready / failed 與 placeholder，目錄狀態標籤未完整接 |
| E16 | 全書閱讀進度顯示 | 部分保留 | 全書百分比已帶入總章節；目前章 / 總章與本章百分比仍未完整獨立顯示 |
| E17 | 剩餘閱讀時間估算 | 未接 | 無本章 / 全書剩餘時間 |
| E18 | 閱讀時間統計 | 未接主線 | read record 結構存在，但閱讀器未穩定寫入 |
| E19 | 音量鍵翻頁 | 已移除 | 不保留設定項，也不接事件處理 |
| E20 | 長按選字 / 複製 / 搜尋 / 字典 | 未接 | CustomPainter 文字目前不支援選取 |
| E21 | 手勢自訂 | 部分保留 | 九宮格點擊動作已接；滑動、雙擊、長按自訂未完整 |
| E22 | 章節載入失敗提示 / 重試 | 部分保留 | 有錯誤態與 placeholder，尚缺完整操作面板 |
| E23 | 正文為空時快速換源 | 延後 | 不在閱讀器內偷偷換源 |
| E24 | 章節內容異常回報 / 調試入口 | 未接 | 沒有從閱讀器直接進正文解析調試 |
| E25 | 預載前後章節 | 部分保留 | 目前以鄰近章節預載為主，尚未做可配置多章策略 |
| E26 | 閱讀器錯誤恢復 | 部分保留 | 有 error phase；重建排版、回穩定位置等操作未完整 |
| E27 | 橫豎屏 / 螢幕方向設定 | 未接 | 沒有閱讀器主線方向鎖定 |
| E28 | 防誤觸 / 保持螢幕常亮 | 未接 | 沒有閱讀器主線防誤觸與 wakelock 操作 |
| E29 | 繁簡轉換 | 保留 | 設定變更後會重新載入正文 |
| E30 | 首行縮排、兩端對齊、字距 | 保留 | `ReadStyle` 進入 `LayoutEngine` |
| E31 | 選單配色跟隨閱讀頁 | 保留 | 可在介面設定切換 |
| E32 | 常駐底部資訊列 | 保留 | 顯示書名、頁碼、百分比等底部資訊 |
| E33 | 單章 / 整書換源 | 延後 / 旁支 | 不作為閱讀器內快速換源；換源應走明確選書流程 |
| E34 | HTTP TTS 引擎 | 旁支 | engine / factory 存在，尚未接目前 `ReaderPage` TTS 主線 |
| E35 | 更完整朗讀控制 / 跟讀協調 | 旁支 | 相關 controller 有測試，尚未取代目前主線 TTS controller |
| E36 | Session / source switch runtime 旁支 | 旁支 | 測試存在，但不是目前 `ReaderPage` 主流程 |

## 驗證步驟

### E1 / E6 / E16：打開閱讀器、恢復進度、顯示百分比

手動驗證：

1. 從書架或書籍詳情打開一本有多章正文的書。
2. 預期進入閱讀器後會載入目前章節並顯示正文。
3. 翻到非第一頁或非第一章。
4. 退出閱讀器，再重新打開同一本書。
5. 預期恢復到前次章節與位置附近。
6. 預期底部資訊列的全書百分比不是固定 `0.0%`，且會隨章節 / 頁面變動。

程式驗證：

```bash
flutter test test/features/reader/reader_engine_replacement_test.dart \
  test/features/reader/text_page_test.dart
```

故障定位：

- 無法載入正文：查 `ChapterRepository.ensureChapters()` 與 `ChapterRepository.loadContent()`。
- 分頁後百分比固定 `0.0%`：查 `LayoutEngine.layout(... chapterSize:)` 是否由 `PageResolver` 傳入 `repository.chapterCount`。
- 退出後位置沒保存：查 `ReaderProgressController.flush()` 與 `BookDao.updateProgress()`。

### E2 / E3 / E4 / E5 / E14：翻頁、滾動、目錄與跳章

手動驗證：

1. 在閱讀器底部選單切換 slide / scroll 模式。
2. slide 模式左右滑動或點擊下一頁區域，預期頁面前後切換。
3. scroll 模式上下拖動，預期可跨頁 / 跨章滾動。
4. 打開目錄 drawer，預期目前章節被高亮。
5. 點其他章節，預期跳轉並關閉 drawer。
6. 使用上一章、下一章、章節滑桿，預期跳到正確章節。

故障定位：

- slide 卡在載入頁：查 `SlideReaderViewport` 的 `PageWindow.prev/current/next`。
- scroll 位置保存不準：查 `ScrollReaderViewport._commitVisibleLocation()` 與 `ReaderRuntime.resolveVisibleLocation()`。
- 目錄不高亮：查 `ReaderChaptersDrawer.currentChapterIndex` 與 `ReaderRuntime.state.visibleLocation`。

### E7 / E8 / E9：TTS、自動翻頁、書籤

手動驗證：

1. 在閱讀器開啟 TTS 面板，點播放。
2. 預期從目前可見位置往後朗讀。
3. 調整語速 / 音調後再播放，確認系統 TTS 參數生效。
4. 點自動翻頁，預期選單收起並按固定 timer 往後翻。
5. 在高級設定把某個點擊區域設為「書籤」，返回正文後點該區域。
6. 到書籤管理頁確認新增書籤包含目前章節與位置。

故障定位：

- TTS 不從目前位置開始：查 `ReaderTtsController.toggle()` 與 `ReaderRuntime.textFromVisibleLocation()`。
- 自動翻頁不動：查 `ReaderAutoPageController` 是否拿到 `runtime.moveToNextPage()`。
- 書籤沒有寫入：查 `ReaderBookmarkController.addVisibleLocationBookmark()` 與 `BookmarkDao.upsert()`。

### E10 / E12 / E29 / E30 / E31 / E32：閱讀設定與替換規則

手動驗證：

1. 打開介面設定，修改字號、行距、段距、縮排、字距或兩端對齊。
2. 預期正文重新排版，位置盡量保留。
3. 切換日夜模式，預期背景與文字顏色改變。
4. 開啟更多操作或底部替換規則入口。
5. 預期出現閱讀器內輕量替換規則面板，而不是跳完整 `ReplaceRulePage`。
6. 切換「本書套用替換規則」或點「重新套用並刷新目前章節」。
7. 預期目前章節重新處理並重建排版。

故障定位：

- 設定改了但版面不變：查 `ReaderSettingsController.contentSettingsGeneration` 與 `ReaderRuntime.reloadContentPreservingLocation()`。
- 替換規則改了但正文沒刷新：查 `ReaderPage._openReplaceRule()` 的 reload 呼叫。
- 繁簡轉換不生效：查 `ChapterRepository.currentChineseConvert` 與 `ReaderChapterContentLoader.currentChineseConvert()`。

### E13：退出時加入書架或清理暫存資料

手動驗證：

1. 從搜尋結果或書籍詳情直接閱讀一本尚未加入書架的書。
2. 閱讀幾頁後按返回。
3. 預期出現「加入書架？」提示。
4. 選「加入書架」：預期回到上一頁後，該書出現在書架，閱讀進度保留。
5. 再找一本未入書架書籍重複測試，這次選「直接退出」。
6. 預期該書不在書架，這次閱讀產生的書籍、章節、正文快取、書籤與下載任務被清理。

故障定位：

- 未入書架退出沒有提示：查 `ReaderSettingsController.showAddToShelfAlert` 與 `ReaderPage.shouldPromptAddToBookshelfOnExit()`。
- 選加入後書架不刷新：查 `ReaderSessionFacade.addCurrentBookToBookshelf()` 是否發送 `AppEventBus.upBookshelf`。
- 選不加入後資料殘留：查 `BookStorageService.discardBook()` 與 `BookmarkDao.deleteByBook()`。

### E15 / E22 / E25 / E26：載入狀態、預載與錯誤恢復

手動驗證：

1. 使用網路書源打開一本書。
2. 快速翻到前後章，預期鄰近章節可預載，跨章時不應長時間白屏。
3. 斷網或使用會失敗的章節測試，預期畫面至少顯示載入失敗或錯誤文字。
4. 回目錄再切回章節，確認不會卡死。

目前限制：

- 目錄尚未完整顯示「已載入 / 未載入 / 載入中 / 載入失敗 / 已快取」。
- 載入失敗尚未有完整操作面板。
- 下一批建議補：重試、查看錯誤、返回目錄、重新載入章節。

故障定位：

- 預載沒生效：查 `ReaderPreloadScheduler.scheduleJump()` 與 `scheduleScrollSettled()`。
- 失敗章節一直重試：查 `ReaderChapterContentStorage` 與 `ReaderChapterContentStatus.failed`。
- error phase 後畫面卡死：查 `ReaderRuntime.jumpToLocation()` catch 與 viewport error UI。

### E11 / E19 / E20 / E23 / E24 / E27 / E28 / E33：未接、移除或延後項

驗證目標：

- E11：閱讀器搜尋不應被誤認為已完成；目前仍是全域搜尋入口。
- E19：音量鍵翻頁已移除，不應再有設定欄位或事件處理。
- E20：長按選字未接，不應標成可用。
- E23 / E33：閱讀器內快速換源延後，不應在空正文時偷偷替換目前書。
- E24：正文解析調試入口未接閱讀器。
- E27 / E28：方向鎖定、保持螢幕常亮、防誤觸未接主線。

檢查命令：

```bash
rg "volumeKeyPage|volumeKeyPageOnPlay" lib test
rg "ChangeChapterSourceSheet.show|ReaderSourceFallbackSheet.show" lib/features/reader
```

## 相關檔案

| 功能區 | 相關檔案 |
| --- | --- |
| 閱讀器入口 | `lib/features/reader/reader_page.dart` |
| runtime 狀態 | `lib/features/reader/runtime/reader_runtime.dart`、`lib/features/reader/runtime/reader_state.dart` |
| 進度保存 | `lib/features/reader/runtime/reader_progress_controller.dart`、`lib/features/reader/runtime/reader_progress_store.dart`、`lib/core/database/dao/book_dao.dart` |
| 退出與加入書架 | `lib/features/reader/runtime/reader_page_exit_coordinator.dart`、`lib/features/reader/runtime/reader_session_facade.dart`、`lib/core/services/book_storage_service.dart` |
| 章節列表與正文 | `lib/features/reader/engine/chapter_repository.dart`、`lib/features/reader/engine/reader_chapter_content_loader.dart`、`lib/core/database/dao/reader_chapter_content_dao.dart` |
| 分頁與定位 | `lib/features/reader/engine/layout_engine.dart`、`lib/features/reader/engine/page_resolver.dart`、`lib/features/reader/engine/text_page.dart` |
| slide / scroll | `lib/features/reader/viewport/slide_reader_viewport.dart`、`lib/features/reader/viewport/scroll_reader_viewport.dart` |
| 文字繪製 | `lib/features/reader/viewport/reader_painter.dart` |
| 目錄 | `lib/features/reader/widgets/reader_chapters_drawer.dart` |
| 底部選單 | `lib/features/reader/widgets/reader_page_shell.dart`、`lib/features/reader/widgets/reader/reader_bottom_menu.dart` |
| 閱讀設定 | `lib/features/reader/controllers/reader_settings_controller.dart`、`lib/features/reader/settings/reader_prefs_repository.dart` |
| TTS | `lib/features/reader/controllers/reader_tts_controller.dart`、`lib/core/services/tts_service.dart` |
| 自動翻頁 | `lib/features/reader/controllers/reader_auto_page_controller.dart` |
| 書籤 | `lib/features/reader/controllers/reader_bookmark_controller.dart`、`lib/core/database/dao/bookmark_dao.dart` |
| 替換規則 | `lib/core/database/dao/replace_rule_dao.dart`、`lib/core/engine/reader/content_processor.dart`、`lib/features/replace_rule/replace_rule_page.dart` |
| 旁支 runtime | `lib/features/reader/runtime/reader_session_facade.dart`、`lib/features/reader/source/`、`lib/features/reader/runtime/reader_tts_engine_factory.dart` |

## 常見故障定位

| 現象 | 優先檢查 |
| --- | --- |
| 打開閱讀器空白或一直 loading | `ReaderRuntime.openBook()`、`ChapterRepository.ensureChapters()`、`PageResolver.ensureLayout()` |
| 章節有內容但畫面無字 | `BookContent.fromRaw()`、`LayoutEngine._layoutBlock()`、`ReaderPainter` |
| 翻頁後進度沒保存 | `ReaderRuntime.moveToNextPage()` / `moveToPrevPage()` 是否呼叫 `_progressController.schedule()` |
| scroll 模式返回後位置錯 | `ScrollReaderViewport._commitVisibleLocation()` 與 `ReaderRuntime.resolveVisibleLocation()` |
| 全書百分比固定 0 | `TextPage.chapterSize` 是否在 `LayoutEngine` 分頁時被設定 |
| 未入書架書籍退出後仍殘留 | `ReaderPage.discardUnkeptBookStorage()` 與 `BookStorageService.discardBook()` |
| 加入書架後書架不顯示 | `Book.isInBookshelf`、`BookDao.upsert()`、`AppEventBus.upBookshelf` |
| 替換規則切換後不生效 | `Book.readConfig.useReplaceRule`、`ChapterRepository.clearContentCache()`、`ReaderRuntime.reloadContentPreservingLocation()` |
| TTS 無聲或不啟動 | `TTSService.init()`、系統 TTS engine / voice、`ReaderTtsController.toggle()` |
| 自動翻頁啟動但不翻 | `ReaderAutoPageController._timer` 與 `ReaderRuntime.moveToNextPage()` 回傳值 |
| 目錄章節高亮錯誤 | `ReaderRuntime.state.visibleLocation.chapterIndex` 與 `ReaderChaptersDrawer.currentChapterIndex` |
| 章節失敗沒有操作 | 目前是已知缺口，下一批補 E15 / E22 操作面板 |

