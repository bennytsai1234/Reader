# 接手說明

更新日期：2026-04-20

這份 handoff 不假設舊文檔可靠，只以目前 repo 實際狀態整理。

## 先講結論

如果今天要接手 `reader`，最合理的策略不是先加功能，而是先把三件事吃透：

1. `features/reader` runtime
2. `core/engine` 書源解析鏈
3. `core/database` 與 `core/services/check_source_service.dart`

## 現在的產品邊界

`reader` 目前是一個聚焦在小說閱讀主線的 Flutter app。

已存在的主線：

- 書架
- 書籍詳情
- 搜尋
- 探索
- 書源管理
- 閱讀器
- 備份還原
- 本地書匯入

明確不應假設存在的線：

- RSS
- 多媒體閱讀
- 完整對齊 `legado` 的所有 Android-only 能力

## 先讀哪些檔

### 第一輪

1. [main.dart](/home/benny/projects/reader/lib/main.dart:1)
2. [app_providers.dart](/home/benny/projects/reader/lib/app_providers.dart:1)
3. [architecture.md](architecture.md)
4. [DATABASE.md](DATABASE.md)
5. [source_audit_backlog.md](source_audit_backlog.md)

### 第二輪

1. [read_book_controller.dart](/home/benny/projects/reader/lib/features/reader/runtime/read_book_controller.dart:1)
2. [reader_content_facade_mixin.dart](/home/benny/projects/reader/lib/features/reader/provider/reader_content_facade_mixin.dart:1)
3. [chapter_content_manager.dart](/home/benny/projects/reader/lib/features/reader/engine/chapter_content_manager.dart:1)
4. [js_engine.dart](/home/benny/projects/reader/lib/core/engine/js/js_engine.dart:1)
5. [check_source_service.dart](/home/benny/projects/reader/lib/core/services/check_source_service.dart:1)

### 第三輪

1. [source_manager_page.dart](/home/benny/projects/reader/lib/features/source_manager/source_manager_page.dart:1)
2. [search_page.dart](/home/benny/projects/reader/lib/features/search/search_page.dart:1)
3. [explore_page.dart](/home/benny/projects/reader/lib/features/explore/explore_page.dart:1)
4. [book_detail_provider.dart](/home/benny/projects/reader/lib/features/book_detail/book_detail_provider.dart:1)
5. [bookshelf_provider.dart](/home/benny/projects/reader/lib/features/bookshelf/bookshelf_provider.dart:1)

## 接手時不要被哪些舊印象誤導

### 不要假設文件裡說「已完成」就真的完成

目前實際程式碼裡仍可直接看到：

- 過渡性的書源狀態實作
- provider 中的簡化註解式邏輯
- 未接線 widget
- lint 與舊 API 殘留

### 不要假設 `reader` 是一個完整複刻的 `legado`

它更接近：

- 以 `legado` 書源能力為規格參考
- 但產品邊界刻意縮成小說閱讀器

### 不要假設本地書已全面支持

目前可直接驗證的本地格式只有：

- TXT
- EPUB
- UMD

## 目前最實際的風險

### 1. 測試可信度不是無條件成立

`flutter test` 可過，但有 QuickJS 相關 skip，代表：

- 綠燈不完全等於完整覆蓋
- JS compatibility 仍有環境依賴

### 2. 書源治理還停在過渡態

核心症狀：

- health 沒正式欄位
- `lastReport` 只有記憶體版本
- group/comment 同時扮演使用者語義與系統語義

### 3. 閱讀器已進入重構後期，但還沒完全收口

核心症狀：

- mixin 鏈還在
- controller 還大
- 交互邊角還有待清理項

## 建議實作順序

### 第一步

先清 `flutter analyze`。

理由：

- 這是最便宜、也最能快速摸清全域代碼氣味的方法
- 可以順便收掉 deprecated 與死碼

### 第二步

把 source health 與 last check state 正規化。

理由：

- 這會同時改善 source manager、search、explore、reader fallback
- 是目前最明顯的結構缺口

### 第三步

補 engine 錯誤訊息與 WebView/login recovery。

理由：

- 這是 `reader` 和 `legado` 真正仍有成熟度差距的地方

### 第四步

回頭收閱讀器產品層邊角。

理由：

- 閱讀器主幹已經存在，不需要先重寫
- 先修邊角比再做一輪大改更划算

## 驗證方式

建議順序：

1. `flutter analyze`
2. targeted `flutter test`
3. `tool/flutter_test_with_quickjs.sh`
4. 有需要才跑 full suite

不要一開始就：

- 同時跑多個 heavy command
- 重新做大規模 source batch audit
- 直接改動閱讀器多個子域再一起驗證

## 和 legado 的相處方式

接手時最好把 `legado` 當作三種東西：

1. 產品流對照
2. parser / JS / source 行為 spec
3. 缺口確認工具

不要把它當成：

- 每個頁面都要照抄的模板
- 評價 `reader` 好壞的唯一標準

## 當前最有價值的交付

如果下一位接手者只做一輪高價值整理，最值得交付的是：

1. `flutter analyze` 全綠
2. source health 正式欄位或正式表
3. 最後一次 source check 落地
4. rule 級錯誤訊息
5. 閱讀器返回與交互收尾
