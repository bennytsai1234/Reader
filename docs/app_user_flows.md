# App 使用流程圖

這份文件只描述使用者從 app 入口開始會走到的產品流程。架構與資料層圖請看 [app_flow_architecture.md](app_flow_architecture.md)。

## A. 啟動與主入口

### A1 + A2. 打開 app、初始化、進入主頁

這張圖把使用者看到的流程與系統背後的初始化合在同一張圖。使用者只會看到 Splash 與主頁；系統會在同一段時間完成 DI、Provider、預設資料與啟動後維護。

```mermaid
flowchart TB
  subgraph User["使用者視角"]
    U1["打開 app"]
    U2["看到 Splash / 歡迎畫面"]
    U3["進入 MainPage"]
    U4["預設顯示書架 tab"]
  end

  subgraph System["系統視角"]
    S1["main()"]
    S2["WidgetsFlutterBinding.ensureInitialized"]
    S3["註冊錯誤處理\nErrorWidget / FlutterError / runZonedGuarded"]
    S4["configureDependencies()"]
    S5["註冊 AppDatabase 與 DAOs"]
    S6["註冊 NetworkService / TTSService / Logger"]
    S7["初始化 CrashHandler / NetworkService / TTSService"]
    S8["runApp(MultiProvider)"]
    S9["LegadoReaderApp 建立 MaterialApp"]
    S10["SplashPage._initApp()"]
    S11["DefaultData.initEssential()\n初始化 AppTheme"]
    S12["Navigator.pushReplacement(MainPage)"]
    S13["第一幀後執行 deferred startup"]
    S14["DefaultData.initDeferred()\n匯入預設書源、TXT 目錄規則、HTTP TTS、字典規則"]
    S15["維護任務\n校正書源排序、清理過期搜尋歷史、清理過期 cache"]
    S16["初始化 Workmanager"]
  end

  U1 --> U2 --> U3 --> U4

  U1 -. triggers .-> S1
  S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7 --> S8 --> S9 --> S10 --> S11 --> S12
  S12 -. updates UI .-> U3
  S12 --> S13
  S13 --> S14
  S13 --> S15
  S13 --> S16
```

### A3. 底部 tab 切換

`MainPage` 使用 `NavigationBar` 與 `IndexedStack` 保留各 tab 狀態。預設進入書架；主頁固定提供書架、發現、我的三個 tab。

```mermaid
flowchart LR
  Main["MainPage\nIndexedStack + NavigationBar"] --> Bookshelf["書架 tab\nBookshelfPage"]
  Main --> Explore["發現 tab\nExplorePage"]
  Main --> Mine["我的 tab\nSettingsPage"]

  Bookshelf --> BookshelfActions["書架動作\n打開書籍 / 搜尋 / 匯入本地 / 分組管理"]
  Explore --> ExploreActions["發現動作\n分類 / 書籍列表 / 書籍詳情"]
  Mine --> MineActions["我的動作\n書源管理 / 閱讀設定 / 備份還原 / 工具"]

  Bookshelf -. double tap current tab .-> Refresh["重新載入書架\nBookshelfProvider.loadBooks()"]
```

## A 類流程摘要

| 編號 | 使用者動作 | 使用者看到 | 系統主要動作 |
| --- | --- | --- | --- |
| A1 | 打開 app | Splash，然後進入主頁 | 建立 `MaterialApp`，進入 `SplashPage` |
| A2 | 等待初始化完成 | 自動進入 `MainPage` | DI、Provider、DefaultData essential/deferred、Workmanager |
| A3 | 點底部 tab | 書架 / 發現 / 我的切換 | `NavigationBar` 改變 index，`IndexedStack` 保留 tab 狀態 |

## B. 書架

書架入口是 `BookshelfPage`。使用者可從書架直接開書、匯入本地書、從 URL 或檔案匯入書架、切換視圖、多選管理與管理分組。

### B1. 打開書架上的一本書

```mermaid
flowchart TD
  B1["使用者在書架點一本書"] --> CheckMode{"目前是多選模式?"}
  CheckMode -- 是 --> ToggleSelect["切換該書選取狀態"]
  CheckMode -- 否 --> CheckType{"book.type == 2?"}
  CheckType -- 是 --> RemovedAudio["顯示提示\n有聲書播放功能已移除"]
  CheckType -- 否 --> OpenReader["Navigator.push(ReaderPage)"]
  OpenReader --> ResumeTarget["ReaderOpenTarget.resume(book)"]
  ResumeTarget --> ReaderInit["ReaderPage 初始化閱讀器"]
  ReaderInit --> Runtime["ReaderRuntime.openBook()"]
  Runtime --> Restore["依 book.chapterIndex + book.charOffset 恢復進度"]
```

### B2. 匯入本地書 TXT / EPUB / UMD，再打開閱讀

```mermaid
flowchart TD
  Menu["書架右上選單"] --> AddLocal["添加本地"]
  AddLocal --> FilePicker["FilePicker\n選擇 TXT / EPUB / UMD"]
  FilePicker --> HasFile{"有選到檔案?"}
  HasFile -- 否 --> Cancel["結束"]
  HasFile -- 是 --> ImportPath["BookshelfProvider.importLocalBookPath(path)"]
  ImportPath --> Existing{"local://path 已在書架?"}
  Existing -- 是 --> SuccessExisting["回傳成功"]
  Existing -- 否 --> LocalBookService["LocalBookService.importBook(path)"]
  LocalBookService --> Parse["依格式解析\nTxtParser / EpubParser / UmdParser"]
  Parse --> Cover["BookCoverStorageService.ensureBookCoverStored"]
  Cover --> SaveBook["BookDao.upsert(book)"]
  SaveBook --> SaveChapters["ChapterDao.insertChapters(chapters)"]
  SaveChapters --> Reload["BookshelfProvider.loadBooks()"]
  Reload --> Snack["顯示匯入成功 / 失敗"]
  Snack --> OpenImported["使用者在書架點新書"]
  OpenImported --> Reader["ReaderPage"]
```

### B3. 添加網址

目前「添加網址」實作是從 URL 匯入書架資料，URL 內容需要是 Inkpage/相容格式的書架 JSON。它不是直接輸入任意小說網頁 URL 後解析單本小說。

```mermaid
flowchart TD
  Menu["書架右上選單"] --> AddUrl["添加網址"]
  AddUrl --> Dialog["輸入匯入網址"]
  Dialog --> UrlProvided{"URL 非空?"}
  UrlProvided -- 否 --> Cancel["結束"]
  UrlProvided -- 是 --> ImportUrl["BookshelfProvider.importBookshelfFromUrl(url)"]
  ImportUrl --> Exchange["BookshelfExchangeService.importFromUrl"]
  Exchange --> DownloadJson["NetworkService.dio GET URL"]
  DownloadJson --> ParseJson["importFromText(json)"]
  ParseJson --> UpsertSources["BookSourceDao.upsert(sources)"]
  ParseJson --> UpsertBooks["BookDao.upsert(books as isInBookshelf=true)"]
  ParseJson --> InsertChapters["ChapterDao.insertChapters(chapters)"]
  UpsertSources --> Done["顯示網址匯入完成"]
  UpsertBooks --> Done
  InsertChapters --> Done
```

### B4. 書架搜尋入口

```mermaid
flowchart TD
  Bookshelf["BookshelfPage"] --> SearchIcon["點搜尋 icon"]
  SearchIcon --> SearchPage["Navigator.push(SearchPage)"]
  SearchPage --> Keyword["輸入關鍵字"]
  Keyword --> SearchFlow["進入搜尋流程\nSearchProvider + SearchModel"]
  SearchFlow --> Results["搜尋結果"]
  Results --> BookDetail["點結果進入 BookDetailPage"]
```

### B5. 書架切換列表 / 網格

```mermaid
flowchart TD
  Menu["書架右上選單"] --> ToggleView["列表視圖 / 網格視圖"]
  ToggleView --> SetGrid["BookshelfProvider.setGridView(!isGridView)"]
  SetGrid --> SavePref["SharedPreferences\nbookshelf_is_grid"]
  SavePref --> Rebuild["notifyListeners()"]
  Rebuild --> Display{"isGridView?"}
  Display -- true --> Grid["GridView 書架"]
  Display -- false --> List["ListView 書架"]
```

### B6. 書架多選、移入分組、刪除、全選

```mermaid
flowchart TD
  Enter["長按書籍\n或選單 > 書架管理"] --> Multi["進入多選模式"]
  Multi --> TapBook["點書籍"]
  TapBook --> Toggle["加入 / 移除 selectedUrls"]
  Multi --> SelectAll["點全選"]
  SelectAll --> AllState{"已全選?"}
  AllState -- 是 --> ClearSelection["清空選取"]
  AllState -- 否 --> AddAll["選取所有書籍"]

  Multi --> MoveGroup["點移入分組"]
  MoveGroup --> GroupDialog["GroupSelectDialog"]
  GroupDialog --> PickGroup["選擇分組 / 未分組"]
  PickGroup --> BatchGroup["BookshelfProvider.batchUpdateGroup"]
  BatchGroup --> UpsertBooks["BookDao.upsert(updated books)"]
  UpsertBooks --> ExitMulti["退出多選並 reload 書架"]

  Multi --> Delete["點刪除"]
  Delete --> Confirm["確認刪除 dialog"]
  Confirm --> Remove["BookshelfProvider.removeFromBookshelf(url)"]
  Remove --> DeleteBook["BookDao.deleteByUrl"]
  DeleteBook --> ExitMulti
```

### B7. 書架分組管理

```mermaid
flowchart TD
  Menu["書架右上選單"] --> GroupManage["分組管理"]
  GroupManage --> Page["GroupManagePage"]

  Page --> Add["新增分組"]
  Add --> AddDialog["輸入名稱\n可選封面圖片"]
  AddDialog --> Create["BookshelfProvider.createGroup"]
  Create --> NewMask["分配下一個 group bit mask"]
  NewMask --> SaveGroup["BookGroupDao.upsert"]
  SaveGroup --> ReloadGroups["loadGroups()"]

  Page --> Rename["編輯分組"]
  Rename --> RenameDialog["修改名稱\n可選封面圖片"]
  RenameDialog --> RenameAction["BookshelfProvider.renameGroup"]
  RenameAction --> SaveGroup

  Page --> Visibility["切換顯示開關"]
  Visibility --> UpdateVisibility["BookshelfProvider.updateGroupVisibility"]
  UpdateVisibility --> SaveGroup

  Page --> Reorder["拖曳排序"]
  Reorder --> UpdateOrder["BookGroupDao.updateOrder"]

  Page --> Delete["刪除分組"]
  Delete --> Confirm["確認刪除"]
  Confirm --> DeleteAction["BookshelfProvider.deleteGroup"]
  DeleteAction --> RemoveMask["從所有書籍移除該 group"]
  RemoveMask --> DeleteGroup["BookGroupDao.deleteById"]
  DeleteGroup --> ReloadGroups
```

### B8. 匯入書架

```mermaid
flowchart TD
  Menu["書架右上選單"] --> Import["匯入書架"]
  Import --> Pick["FilePicker\n選擇 json 或 zip"]
  Pick --> HasFile{"有選到檔案?"}
  HasFile -- 否 --> Cancel["結束"]
  HasFile -- 是 --> Type{"副檔名是 zip?"}
  Type -- 是 --> Restore["RestoreService.restoreFromZip(file)"]
  Restore --> RestoreResult["顯示備份還原完成 / 失敗"]
  Type -- 否 --> ImportFile["BookshelfExchangeService.importFromFile(file)"]
  ImportFile --> Parse["importFromText(json)"]
  Parse --> Sources["BookSourceDao.upsert(sources)"]
  Parse --> Books["BookDao.upsert(books as isInBookshelf=true)"]
  Parse --> Chapters["ChapterDao.insertChapters(chapters)"]
  Sources --> Reload["BookshelfProvider.loadBooks()"]
  Books --> Reload
  Chapters --> Reload
  Reload --> Snack["顯示匯入本數、章節數、書源數"]
```

### B9. 匯出書架

```mermaid
flowchart TD
  Menu["書架右上選單"] --> Export["匯出書架"]
  Export --> Share["BookshelfExchangeService.shareBookshelf(books: provider.books)"]
  Share --> BuildPayload["exportBookshelf()\nbooks + chapters + related sources"]
  BuildPayload --> WriteFile["寫入 bookshelf-export.inkpage.json"]
  WriteFile --> ShareSheet["SharePlus 分享檔案"]
  ShareSheet --> Snack["顯示書架已匯出 / 匯出失敗"]
```

## B 類流程摘要

| 編號 | 使用者動作 | 主要入口 | 系統主要動作 |
| --- | --- | --- | --- |
| B1 | 點書架上的書 | `BookshelfPage._openBook` | 開啟 `ReaderPage` 並用 `ReaderOpenTarget.resume(book)` 恢復進度 |
| B2 | 添加本地 | `importLocalBookPath` | 解析本地檔、保存 book / chapters、刷新書架 |
| B3 | 添加網址 | `importBookshelfFromUrl` | 從 URL 下載書架 JSON，匯入 books / chapters / sources |
| B4 | 書架搜尋 | `SearchPage` | 進入搜尋流程 |
| B5 | 切換列表 / 網格 | `setGridView` | 寫入 `SharedPreferences` 並重建書架 |
| B6 | 多選管理 | 多選 app bar actions | 選取、全選、移入分組、刪除 |
| B7 | 分組管理 | `GroupManagePage` | 新增、改名、顯示/隱藏、排序、刪除分組 |
| B8 | 匯入書架 | `BookshelfExchangeService` / `RestoreService` | 匯入 json 或還原 zip |
| B9 | 匯出書架 | `BookshelfExchangeService.shareBookshelf` | 產生 JSON 並呼叫系統分享 |
