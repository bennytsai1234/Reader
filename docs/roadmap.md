# Reader Project Roadmap

更新日期：2026-03-29

本文回答的是「這個閱讀器專案接下來應該怎麼完成」。  
它不是臨時待辦，而是用來約束後續開發順序、範圍與完成標準的主路線圖。

## 1. 專案目標

本專案的最終目標不是做一個功能很多但持續失控的 App，而是做一個：

- 可長期維護的 Flutter 閱讀器
- 以中文閱讀體驗為核心
- 同時支援本地書與網路書源
- 具備穩定的閱讀器 runtime、資料層與書源引擎
- 可自行建置、可自行側載、可持續發版

## 2. 產品主線

專案只圍繞四條主線推進：

1. 閱讀器核心
2. 書源引擎
3. 本地資料與同步
4. UI / 設定 / 平台整合

這四條主線的重要度不同。

優先級排序：

1. 閱讀器核心
2. 書源引擎
3. 本地資料與同步
4. UI / 設定 / 平台整合

如果時間、精力或上下文有限，永遠先保護前兩項。

## 3. MVP 完成線

在擴功能之前，先把最小可用產品定義清楚。

MVP 必須穩定具備：

- 書源搜尋
- 書籍詳情
- 加入書架 / 移出書架
- 章節列表
- 閱讀頁
- 閱讀進度保存與還原
- 本地 TXT / EPUB 匯入
- 基本閱讀設定
- 基本書源管理
- 最小可用的匯出 / 備份能力

不屬於 MVP，但可以後補的項目：

- 背景更新
- 完整 WebDAV 同步策略
- 高階分享 / 關聯導入
- 細碎工具頁
- 過度細化的設定選項

## 4. 目前主要問題

目前專案最大的問題不是缺技術，而是缺少穩定邊界。

主要症狀：

- 功能存在重複實作或平行頁面
- `features/`、`core/`、service、provider 的責任邊界模糊
- UI 有時直接碰 DAO、檔案系統或平台路徑
- 某些功能先堆頁面，再補抽象，造成長期難維護
- 閱讀器、書源、設定、工具頁的重要性沒有被區分

這代表專案需要的不是全面重寫，而是「先止血，再收斂，再擴充」。

## 5. 開發策略

接下來只採用以下策略：

### 5.1 先收斂，再擴功能

新功能只有在以下條件都成立時才新增：

- 它屬於 MVP 或既定 milestone
- 它有明確模組歸屬
- 它不會再產生第二套同類實作

### 5.2 每輪只打一路

每次較大的改動只聚焦一條主線，例如：

- 只整理閱讀器 restore / progress
- 只整理 source login / parser
- 只整理 cache / storage / export

不要一輪同時動閱讀器、書源、設定、同步四塊。

### 5.3 保留技術棧，不再引入新流派

現有技術棧可以支撐完成專案，不需要中途再換：

- `Flutter`
- `Provider + ChangeNotifier`
- `get_it`
- `Drift`
- `Dio`
- `flutter_js`
- `webview_flutter`
- `Workmanager`

原則：

- 不引入新的狀態管理方案
- 不引入第二套資料庫抽象
- 不引入第二套 HTTP client

## 6. Milestones

## M1：架構止血

目標：

- 收斂重複頁面與重複 provider
- 統一路徑、快取、匯出、資源暫存位置
- 明確規定 UI / provider / service / dao 責任
- 補齊總體規劃文檔

完成標準：

- 同類功能只保留單一路徑
- 檔案系統路徑不再散落硬編碼
- `flutter analyze`、`flutter test` 維持可綠

## M2：閱讀器核心可維護化

目標：

- 穩定閱讀生命週期
- 穩定 restore / progress / follow / preload
- 讓閱讀器 runtime 形成清楚內核

重點：

- `ReadBookController`
- `ReaderChapter`
- content lifecycle
- scroll / slide delegate
- read aloud flow

完成標準：

- 閱讀器的核心狀態真源明確
- 章內定位語義統一
- 閱讀器測試覆蓋主流程

## M3：書源引擎對齊

目標：

- 讓 parser 與 legado 邏輯更一致
- 讓 login / webview / header / cookie 行為可預測
- 把書源引擎當成獨立子系統維護

重點：

- `core/engine`
- `AnalyzeUrl`
- CSS / XPath / JsonPath / Regex / JS parser
- source login flow

完成標準：

- 常見解析語法具 integration tests
- login source 有穩定流程與最小回歸測試

## M4：書架與資料層穩定

目標：

- 書架、詳情、搜尋、章節資料流一致
- DAO / DB migration 穩定
- 資料層成為唯一真源

重點：

- `BookDao`
- `ChapterDao`
- `SearchHistoryDao`
- repository / service 邊界

完成標準：

- UI 不直接操作原始資料層
- migration、CRUD、快取清理策略可說明

## M5：平台能力補齊

目標：

- 備份 / 還原
- 分享導入
- 匯出
- crash log
- 背景任務

原則：

- 只有在前四個 milestone 穩定後才大規模補平台能力
- 平台功能必須掛在既有 service / storage / platform 層，不可零散散落

## M6：發版工程化

目標：

- 固定版本管理與發版節奏
- 確保 analyze / test / build / release 可持續
- 把 release 流程文件化

完成標準：

- 有固定版號策略
- 有 release checklist
- CI 能提供 artifact 或 release 基礎流程

## 7. 技術路徑

## 7.1 UI / Presentation

責任：

- 畫面
- 互動
- 導航
- dialog / bottom sheet / page 組裝

不負責：

- SQL
- 檔案系統路徑
- 業務快取策略
- source parser 細節

## 7.2 Application

責任：

- provider / controller / coordinator
- 流程協調
- 狀態聚合
- use case 調度

不負責：

- 直接硬寫本地路徑
- 直接寫 SQL 查詢細節
- 直接知道 widget 細節

## 7.3 Data

責任：

- DAO
- repository
- API / storage / resource service
- database / cache / export / import

原則：

- DAO 只做資料存取
- service / repository 組合多個資料來源
- UI 不直接繞過 application 層碰資料

## 7.4 Engine

責任：

- 書源規則解析
- URL 分析
- CSS / XPath / JsonPath / Regex / JS
- 章節內容抓取與解析

原則：

- engine 不知道具體 UI
- engine 的輸入輸出應可測試
- parser 行為優先追求一致性與可驗證性

## 8. 開發規則

接下來的開發都應遵守：

- 不再新增第二套相同功能頁
- 新功能先決定屬於哪個 module，再開始寫
- UI 不直接碰 DAO、路徑與平台 API
- 路徑統一進 `core/storage`
- 平台能力統一進 `core/services` 或 `core/platform`
- 每個核心模組至少要有一條 integration path 可測
- 大改動完成後必跑 `flutter analyze` 與 `flutter test`

## 9. 最近建議執行順序

最接近現在代碼狀態、最值得優先做的順序：

1. 整理 `settings / cache / storage / export`
2. 繼續收斂 `reader` runtime 邊界
3. 補 `source_manager` 與 `core/engine` 的登入 / parser 對齊
4. 整理 `bookshelf / book_detail / search` 的資料流
5. 最後再擴大做平台能力與發版流程

## 10. 成功判斷標準

這個專案算是走上正軌，不是看功能數量，而是看這些問題是否成立：

- 能清楚說出每個主要模組的責任
- 新功能不會自然長出第二套實作
- 閱讀器與書源引擎有穩定測試護欄
- 發版不需要每次重新摸索流程
- 專案新增功能時，不會再先亂長、後補整理
