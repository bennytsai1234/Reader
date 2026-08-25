---
ROLE: worker
CONTRACT: atlas/v3
TASK_TYPE: implement
MODEL: Claude Sonnet 5
EXECUTION_ROUTE: claude-p
REPORTING_LEVEL: technical
---

## Goal

讓 Hybrid 閱讀器把效能 block 視為載入／排程／admission 單位，而不是排版段落；`ui.Paragraph` 的排版單位必須改成邏輯段落或其他不受 block segmentation 影響的穩定 layout unit。同一個邏輯段落無論以何種 block 邊界切割，最終的換行、總高度、字元幾何與錨點位置都必須等價於連續排版。

## Background

目前閱讀頁面的實際入口是 `lib/features/reader_v2/screen/reader_v2_page.dart:203` 的 `HybridReaderScreen`。舊的 `ReaderV2LayoutEngine` 不會在 Hybrid 開書、跳章、換樣式或內容重載時執行；現有測試 `test/features/reader_v2/hybrid/hybrid_reader_screen_test.dart:587` 已驗證舊引擎執行次數為 0。因此修正必須落在 Hybrid 的文字／排版／度量／視口管線，不應只改舊分頁引擎。

目前資料流是：

```text
ReaderV2ContentTransformer
  -> ReaderV2Content
  -> TextPreprocessor
  -> Logical paragraph / ChapterBlock 工作映射
  -> Layout unit / LayoutTask
  -> 一個 ui.Paragraph / 穩定 layout unit
  -> block 的 lazy loading / admission / Sliver 映射
  -> DocumentIndex 的視覺幾何前綴和
```

根因在 `lib/features/reader_v2/hybrid/text/text_preprocessor.dart:62` 與 `:104`：一個邏輯段落會按 `maxBlockChars` 切成多個 `ChapterBlock`。`maxBlockChars` 並非固定排版規則，而是在 `lib/features/reader_v2/hybrid/hybrid_reader_screen.dart:643` 由 `LayoutCostModel.maxCharsForBudget` 推導；成本模型又會在 `lib/features/reader_v2/hybrid/pump/layout_pump.dart:148` 依實際排版耗時更新。因此 block 邊界可能因裝置、時機或效能狀態改變。

之後 `lib/features/reader_v2/hybrid/hybrid_reader_screen.dart:797` 對每個 block 建立一個 `LayoutTask`，`lib/features/reader_v2/hybrid/pump/layout_pump.dart:403` 對每個 task 建立獨立的 `ui.Paragraph`，最後 `lib/features/reader_v2/hybrid/view/cached_block_widget.dart:156` 將每個 Paragraph 畫成獨立 Sliver item。即使 `isContinuation` 為 true，目前只會在 `hybrid_reader_screen.dart:842` 取消續塊縮排與間距，不能讓下一個 Paragraph 接續前一個 Paragraph 的最後一行；因此 block 邊界會產生不可見於文字資料的硬換行。修正時不得把「兩個獨立 Paragraph 的 continuation」當成既有 Flutter API，而應重新定義穩定 layout unit 與 block 的工作映射。

這會讓同一個長段落在不同切法下出現不同的 line count、height、字元所在行與垂直位置。`DocumentIndex`、capture／restore、TTS 高亮與 progress 雖然各自使用一致的 block 座標，但它們是在錯誤的上游幾何上運作；不能用調整 `trailingSpacing`、`DocumentIndex` 或 anchor offset 取代修正排版單位。

現有 `test/features/reader_v2/hybrid/text_preprocessor_test.dart` 只驗證 block 文字串接、UTF-16 邊界與 range，沒有驗證同一邏輯段落以不同 block 切法排版後的 line boxes、總高度與每字元幾何相同。現有 `hybrid_pump_test.dart` 也主要驗證單一 Paragraph，並未驗證跨 block 的連續排版。

快取與視口還有一個必要連帶：目前 scheduling identity（`BlockKey`、block range、segmentation）與 visual layout identity（邏輯段落／內容 hash／style／layout epoch）被混在一起；`StyleFingerprint` 與 `MetricsDiskCache` 以 style／viewport／章節 content hash／`BlockKey` 識別 metrics，但沒有清楚區分工作排程與視覺幾何。章節被 repository 淘汰時，`HybridReaderScreen._onChapterEvent` 的 `evicted` 分支只移除 `_blocks`，沒有像 `invalidated` 分支一樣清理 metrics／Paragraph／DocumentIndex。修正後必須保留 block 作為工作單位，但解除 segmentation 與 visual layout identity 的綁定；不得只是把 `maxBlockChars`、`blockIndex` 或 segmentation 更完整地塞進 Paragraph／幾何快取 identity。若實作需要新增 layout identity 或 namespace 維度，需同步所有相關快取與失效路徑。

## Acceptance

- 新增或擴充 Hybrid 測試，使用至少一個長 CJK 邏輯段落，刻意讓 block 邊界落在一行中間；以至少三種不同 block 切法（包含一種會在句中切割的切法）排版後，連續排版與各切法的實際換行邊界完全一致，不得因 block 邊界多出硬換行。
- 上述測試必須比較至少：每一行涵蓋的文字／UTF-16 offset 範圍、總 line count、總 `BlockMetrics.height`，以及代表性字元的 `getBoxesForRange`／line-top 幾何；允許的浮點差異只能是既有 Flutter 幾何測試使用的微小誤差，不能用放寬到足以掩蓋一整行的 tolerance 通過。
- 同一個邏輯段落使用不同 block 切法時，`charOffset -> line top / world Y` 的結果必須一致；測試至少涵蓋段落中間、切割邊界前後、句中切割點與含 surrogate pair 的文字，並確認不會切開 UTF-16 代理對。
- 人工 block 邊界不得新增段落縮排或段落間距；但原本真正的語義邊界仍須保留：標題樣式、真正不同 source paragraph 的縮排／paragraph spacing、`isContinuation` 的既有語意與 `displayText` 的 UTF-16 range 不得被破壞。
- 不要求每個 `ChapterBlock` 繼續擁有獨立 `ui.Paragraph` 或獨立視覺高度；允許重新定義 Hybrid 內部 layout unit。一般邏輯段落可以作為一個 layout atom，但不得退化成整本書／整章一個無界 Paragraph；block 仍須保留 lazy loading、pump 預算、admission 與 LRU 的工作單位角色，也不得在拖曳期間違反現有 I4 契約直接 layout。
- 若單一邏輯段落極端巨大（例如 TXT 單段達數十萬字），使 Flutter `ui.Paragraph` 無法在既有 pump budget 下安全處理，應在測試／worker 報告列為明確未覆蓋風險；本任務不得自行引入新的文字 shaping／line-breaking engine，也不得用整章 Paragraph 逃避。
- 若實作調整 `LayoutTask`、`ParagraphCache`、`MeasurementStore`、`DocumentIndex`、`CachedBlockWidget` 或 metrics namespace，必須同步處理舊快取／舊 Paragraph／章節淘汰後重載的失效與重建，避免同一 `BlockKey` 重用不同文字或不同 range 的舊高度。
- 必須明確區分 scheduling identity 與 visual layout identity：`blockIndex`、block range、segmentation 只可用來管理工作與映射，不得讓它們決定同一邏輯段落的 Paragraph／geometry identity；視覺快取不得因效能切法不同而產生不同換行。
- `ReaderV2Location`、TTS `ensureCharRangeVisible`、bookmark／progress 的既有公開資料形狀與 viewport controller 七個閉包語意不得改變；同一內容世代內的 capture／restore 與 TTS 高亮必須維持現有行為。
- 不得刪除、弱化或改寫既有測試斷言來取得綠燈；若某個既有測試明確編碼了人工 block 硬換行，應改成驗證連續排版不變的測試，並在報告中說明。
- 在 repository root 執行 `flutter analyze`，結果不得新增 analyzer error。
- 在 repository root 執行 `flutter test test/features/reader_v2/hybrid`，結果為 `All tests passed!`。
- 在 repository root 執行 `flutter test test/features/reader_v2`，結果為 `All tests passed!`。
- 在 repository root 執行 `flutter test`，結果為 `All tests passed!`；若環境依賴導致與本修改無關的可重現失敗，須在報告列出實際失敗輸出與隔離判斷，不得宣稱完成。

## Constraints

- 本變更只處理「效能 block 被當成排版段落」及其必要的度量／快取連帶；不要順手改動內容轉換規則、書籤跨內容世代 mapping、垂直 padding 或舊分頁引擎，除非為了使連續段落幾何契約成立而確實必要。
- 語義段落邊界仍由目前 `ReaderV2Content`／`ChapterBlock` 的既有模型決定；本任務要移除的是人工效能切塊造成的視覺邊界，不是重新定義來源換行或 `reSegment` 產品語意。
- 保留既有 CJK typography feature、em-grid content width、indent placeholder、last-line spacing compensation 與文字色快取行為；修正不能以關閉這些排版功能來取得等價。
- 不新增第三方依賴，不改變 `ReaderV2Location` JSON schema，不做 production build 或 release tag。

## Starting Points

- `docs/night_reader/reader.md`
- `lib/features/reader_v2/hybrid/text/text_preprocessor.dart`
- `lib/features/reader_v2/hybrid/hybrid_reader_screen.dart`
- `lib/features/reader_v2/hybrid/pump/layout_pump.dart`
- `lib/features/reader_v2/hybrid/core/hybrid_types.dart`
- `lib/features/reader_v2/hybrid/measure/document_index.dart`
- `lib/features/reader_v2/hybrid/measure/measurement_store.dart`
- `lib/features/reader_v2/hybrid/measure/metrics_disk_cache.dart`
- `lib/features/reader_v2/hybrid/paragraph/paragraph_cache.dart`
- `lib/features/reader_v2/hybrid/view/cached_block_widget.dart`
- `test/features/reader_v2/hybrid/text_preprocessor_test.dart`
- `test/features/reader_v2/hybrid/hybrid_pump_test.dart`
- `test/features/reader_v2/hybrid/hybrid_reader_screen_test.dart`

## Evidence

由 relay／worker 填入：實際修改檔案、根因層級、驗收命令與完整輸出、未覆蓋風險，以及是否改變 reader 模組邊界或外部契約。

## Completion record
