# Reader Review Plan

日期：2026-04-29

## 目的

這份文件用來安排 reader 的 code review。

不要把 review 做成「整個 reader 一次看完」。reader 的流程太長，直接做大型端到端 review 很容易漏掉中間的資料轉換、座標轉換、cache race、placeholder 邊界。

推薦方式是拆成一段一段「小端到小端」：

```text
Book / DB
-> chapters
-> raw content
-> display text
-> TextLine / ChapterLayout
-> PageCache / TextPage
-> scroll / slide viewport
-> visibleLocation
-> saveProgress
-> restore
```

每一段 review 都要確認：

```text
輸入是什麼
輸出是什麼
中間是否會改變資料真源
錯誤 / loading / placeholder 是否被錯當成 ready content
async / cache / generation 是否可能覆蓋新狀態
```

## 核心規則

reader review 必須圍繞這些核心 invariant：

```text
1. chapter display text 是 charOffset 真源。
2. 標題算進 charOffset。
3. scroll / slide 共用同一份 ChapterLayout / TextLine / PageCache。
4. pageMode 只影響顯示模式，不影響 layout cache key。
5. DB progress 只保存 ReaderLocation(chapterIndex, charOffset, visualOffsetPx)。
6. placeholder / loading / error 不可產生正式閱讀位置。
7. restore 期間不寫 DB。
8. saveProgress 必須先 capture current anchor。
9. async 舊任務不可覆蓋 newer visibleLocation / layoutGeneration / cache generation。
10. paint / drag / fling 不做 DB、network、昂貴 layout。
```

## Review 輸出格式

每個 review agent 都必須使用這個格式：

```text
Findings
- [P0/P1/P2/P3] 標題 - path:line
  問題：
  影響：
  違反的 invariant：
  建議修法：

Open Questions
- ...

Missing Tests
- ...

Verified Invariants
- ...
```

規則：

```text
只做 review，不修改程式碼。
findings 必須有檔案與行號。
findings 必須能對應到實際 runtime 錯誤、資料錯誤、位置錯誤、race、或缺測。
不要只列風格問題。
不要提出大型重構，除非目前架構無法滿足 invariant。
如果沒有 finding，要明確列出已確認哪些 invariant。
```

## Sub Agent 使用規則

可以使用 sub agent 並行 review，但要按依賴切分。

適合並行的 review：

```text
書籍入口 / 章節清單
內容載入 / DB content store
內容處理 / display text
layout / TextLine invariant
PageCache / TextPage invariant
scroll viewport
slide viewport
saveProgress / restore
TTS / auto page
overlay / gesture
lifecycle / exit
```

不適合讓多個 agent 同時 review 同一段：

```text
visibleLocation / restore / saveProgress
scroll viewport / scroll restore / anchor capture
layoutSignature / PageCache / mode switch
```

原因：

```text
這些部分共享同一套 ReaderLocation、ChapterLayout、PageCache、layoutGeneration。
如果多個 agent 同時各自判斷，很容易重複 findings，或各自提出互相衝突的修法。
```

並行規定：

```text
1. 每個 sub agent 只能負責一個 review slice。
2. 每個 slice 要明確列出檔案範圍與 invariant。
3. sub agent 只能 review，不要 edit。
4. 不同 sub agent 不要 review 同一個主要檔案，除非關注點不同且已明確說明。
5. 主 agent 最後負責合併 findings、去重、排序嚴重程度。
6. P2 以上 findings 修復後，要補 regression test。
```

建議主 agent 分工方式：

```text
Agent A: 書籍入口 -> raw content
Agent B: raw content -> display text -> layout
Agent C: layout -> PageCache -> scroll viewport
Agent D: layout -> PageCache -> slide viewport
Agent E: visibleLocation -> saveProgress -> restore
Agent F: TTS / auto page / lifecycle / overlay
```

如果人手或 token 不夠，優先順序是：

```text
1. 書籍入口 -> raw content
2. raw content -> layout
3. layout -> scroll / slide viewport
4. visibleLocation -> saveProgress -> restore
5. lifecycle / TTS / overlay
```

## Review Slices

### 1. 書籍入口 -> 章節清單

流程：

```text
Book / ReaderOpenTarget / initialChapters / DB chapters
-> ChapterRepository.ensureChapters()
-> runtime.chapterCount / runtime.chapters
```

主要檔案：

```text
lib/features/reader/reader_page.dart
lib/features/reader/controllers/reader_dependencies.dart
lib/features/reader/engine/chapter_repository.dart
lib/features/reader/runtime/reader_runtime.dart
lib/core/database/dao/chapter_dao.dart
```

Review 重點：

```text
openBook 是否拿到正確 book / openTarget。
initialChapters、DB chapters、remote TOC、local TOC 的優先順序是否清楚。
source missing / local index missing 是否進 error。
不能回傳 empty chapters 後進入空白 ready。
chapterIndex normalize 是否正確。
ensureChapters 的 async failure 是否能被 runtime 顯示。
```

### 2. 章節清單 -> 原始章節內容

流程：

```text
BookChapter
-> ReaderChapterContentStore / DB cached content
-> local file 或 remote source fetch
-> raw chapter content
```

主要檔案：

```text
lib/features/reader/engine/chapter_repository.dart
lib/core/services/reader_chapter_content_store.dart
lib/core/services/reader_chapter_content_storage.dart
lib/core/services/chapter_content_preparation_pipeline.dart
lib/core/services/local_book_service.dart
lib/features/reader/change_chapter_source_sheet.dart
```

Review 重點：

```text
先讀 DB 還是先打書源是否合理。
local / remote 分支是否一致。
單章換源是否保存到 active chapter key。
failed content 是否不會被當 ready content。
clearContentCache 後 stale in-flight load 不可回填 cache。
source replacement / conversion / replace rule 改變後 cache invalidation 是否完整。
```

### 3. 原始章節內容 -> 處理後 display text

流程：

```text
raw content
-> replacement rules
-> re-segment
-> 繁簡轉換
-> title merge
-> chapter display text
```

主要檔案：

```text
lib/features/reader/engine/reader_chapter_content_loader.dart
lib/core/engine/reader/content_processor.dart
lib/core/engine/reader/chinese_text_converter.dart
lib/features/reader/engine/book_content.dart
lib/core/models/chapter.dart
```

Review 重點：

```text
display text 是否是唯一 charOffset 真源。
title 是否算入 display text 與 charOffset。
title replacement / body replacement 是否一致。
繁簡轉換後 offset 是否使用轉換後文字。
re-segment 是否改變 offset 真源但沒有通知 layout/cache。
錯誤文字、空章節、loading placeholder 不可進 layout。
```

### 4. display text -> TextLine / ChapterLayout

流程：

```text
chapter display text
-> LayoutEngine
-> TextLine[]
-> ChapterLayout
```

主要檔案：

```text
lib/features/reader/engine/layout_engine.dart
lib/features/reader/engine/chapter_layout.dart
lib/features/reader/engine/text_line.dart
lib/features/reader/engine/layout_spec.dart
```

Review 重點：

```text
TextLine.startCharOffset / endCharOffset 是否正確。
行與行不能漏字、重疊、跳 offset。
title line 是否可當 anchor。
paragraph gap 是否只存在 y 座標，不變成假文字 offset。
layoutSignature 必須包含會影響排版的設定。
layoutSignature 不可包含 pageMode、selection、overlay 這類 display-only 狀態。
```

### 5. ChapterLayout -> PageCache / TextPage

流程：

```text
ChapterLayout / TextLine[]
-> page grouping
-> TextPage / PageCache
```

主要檔案：

```text
lib/features/reader/engine/page_resolver.dart
lib/features/reader/engine/text_page.dart
lib/features/reader/engine/chapter_layout.dart
lib/features/reader/runtime/page_window.dart
```

Review 重點：

```text
每頁 start/end offset 是否正確。
同章頁面 range 必須連續。
page height / content localY 是否穩定。
placeholder page 不可產生正式位置。
scroll / slide 是否共用同一份 layout/page。
PageCache / TextPage 不可成為 DB progress 真源。
```

### 6. PageCache -> scroll viewport

流程：

```text
PageCache[]
-> scroll virtual window
-> signed virtualScrollY
-> canvas / painter 顯示
```

主要檔案：

```text
lib/features/reader/viewport/scroll_reader_viewport.dart
lib/features/reader/viewport/reader_tile_layer.dart
lib/features/reader/viewport/reader_tile_painter.dart
lib/features/reader/runtime/reader_preload_scheduler.dart
lib/features/reader/engine/page_resolver.dart
```

Review 重點：

```text
上下 page 是否連續拼接。
previous/current/next chapter window shift 是否在滑動中完成。
window shift 不可依賴 saveProgress。
drag / fling 不可每幀 layout、DB、network。
captureVisibleLocation 可以更新 memory cache，但不應頻繁寫 DB。
scroll idle 後才 saveProgress。
not-ready chapter / placeholder 不可被正式滑入。
async ensure window 後必須 recheck visibleLocation / layoutGeneration。
```

### 7. PageCache -> slide viewport

流程：

```text
PageCache[]
-> PageWindow(prev/current/next)
-> slide viewport
```

主要檔案：

```text
lib/features/reader/viewport/slide_reader_viewport.dart
lib/features/reader/runtime/page_window.dart
lib/features/reader/runtime/reader_runtime.dart
lib/features/reader/engine/page_resolver.dart
```

Review 重點：

```text
slide 只能進入 ready page。
loading/error placeholder 不能被 threshold swipe 滑進畫面。
page transition 開始時不更新 visibleLocation。
page settle 後才 capture / saveProgress。
快速連續翻頁只保留最後 settled page。
slide restore 的座標必須扣除 content padding 後再跟 page-local line 比較。
```

### 8. viewport -> visibleLocation

流程：

```text
viewport anchor line
-> TextLine
-> ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
-> runtime.visibleLocation
```

主要檔案：

```text
lib/features/reader/runtime/reader_runtime.dart
lib/features/reader/viewport/scroll_reader_viewport.dart
lib/features/reader/viewport/slide_reader_viewport.dart
lib/features/reader/engine/reader_location.dart
```

Review 重點：

```text
anchor line 選擇是否穩定。
visualOffsetPx 必須使用：
visualOffsetPx = anchorLineY - lineTopOnScreen
charOffset 必須使用 selectedLine.startCharOffset。
visualOffsetPx normalize 範圍：-80 <= value <= 120。
loading/error/empty placeholder 不可 capture。
舊 async sync 不可覆蓋新的 visibleLocation。
```

### 9. visibleLocation -> saveProgress

流程：

```text
runtime.visibleLocation
-> saveProgress()
-> Book DB chapterIndex / charOffset / visualOffsetPx
```

主要檔案：

```text
lib/features/reader/runtime/reader_runtime.dart
lib/features/reader/runtime/reader_progress_controller.dart
lib/features/reader/runtime/reader_progress_store.dart
lib/core/database/dao/book_dao.dart
lib/core/models/book.dart
```

Review 重點：

```text
saveProgress 必須先 captureVisibleLocation。
scroll idle 才保存。
slide settled 才保存。
app paused / exit / dispose / mode switch 要 flush。
restore 期間不寫 DB。
DB 只保存 chapterIndex / charOffset / visualOffsetPx。
不可保存 pageIndex、scrollY、virtualTop、PageCache index。
```

### 10. DB progress -> restore

流程：

```text
DB ReaderLocation
-> layout ready
-> line/page lookup
-> viewport positioning
-> visibleLocation cache
```

主要檔案：

```text
lib/features/reader/runtime/reader_runtime.dart
lib/features/reader/viewport/scroll_reader_viewport.dart
lib/features/reader/viewport/slide_reader_viewport.dart
lib/features/reader/engine/page_resolver.dart
lib/features/reader/engine/chapter_layout.dart
```

Review 重點：

```text
scroll restore 必須使用：
virtualScrollY = lineVirtualTop + visualOffsetPx - anchorLineY
slide restore 必須在同一座標系比較 anchor / line.top。
restore 期間不寫 DB。
restore 成功只更新 runtime.visibleLocation。
restore 失敗不能覆蓋 DB。
找不到 charOffset 時 fallback 不能跳錯章。
layoutGeneration 改變後舊 restore 不可生效。
```

### 11. mode switch

流程：

```text
scroll visibleLocation
-> switch mode
-> slide restore

slide visibleLocation
-> switch mode
-> scroll restore
```

主要檔案：

```text
lib/features/reader/runtime/reader_runtime.dart
lib/features/reader/engine/layout_spec.dart
lib/features/reader/viewport/reader_screen.dart
lib/features/reader/viewport/scroll_reader_viewport.dart
lib/features/reader/viewport/slide_reader_viewport.dart
```

Review 重點：

```text
切換前先 capture 目前位置。
切換後用同一個 ReaderLocation restore。
pageMode 不可造成 layout cache 分裂。
mode switch 中間狀態不可保存到 DB。
切換完成後 capture 一次更新 memory visibleLocation。
```

### 12. layout 改變

流程：

```text
font / lineHeight / padding / viewport size / orientation
-> invalidate layout
-> restore old visibleLocation
-> capture new visibleLocation
```

主要檔案：

```text
lib/features/reader/runtime/reader_runtime.dart
lib/features/reader/engine/layout_spec.dart
lib/features/reader/controllers/reader_settings_controller.dart
lib/features/reader/reader_page.dart
```

Review 重點：

```text
哪些設定會影響 layout 必須清楚。
哪些設定只是 display-only 必須不清 layout。
layoutGeneration race 是否被擋住。
舊 async layout 不可覆蓋新 layout。
改字級 / 行距 / padding 本身不應直接寫 DB。
```

### 13. preload / cache / window 管理

流程：

```text
visible chapter
-> preload neighbors
-> cache content/layout/pages
-> evict old cache
```

主要檔案：

```text
lib/features/reader/runtime/reader_preload_scheduler.dart
lib/features/reader/engine/chapter_repository.dart
lib/features/reader/engine/page_resolver.dart
lib/features/reader/viewport/scroll_reader_viewport.dart
```

Review 重點：

```text
preload 不阻塞 drag / fling。
cache window 不可太小，避免滑動中突然 reload。
cache invalidation 要跟替換規則、繁簡、換源同步。
clear cache 後舊 in-flight 不可回填。
preload error 不可污染目前 ready page。
```

### 14. gesture / overlay

流程：

```text
tap / drag / pan / long press
-> reader action / scroll / menu
```

主要檔案：

```text
lib/features/reader/widgets/reader_page_shell.dart
lib/features/reader/reader_page.dart
lib/features/reader/viewport/reader_screen.dart
lib/features/reader/viewport/scroll_reader_viewport.dart
lib/features/reader/viewport/slide_reader_viewport.dart
lib/features/reader/models/reader_tap_action.dart
```

Review 重點：

```text
controlsVisible 時 content gesture 不處理。
drag / pan 只交給 scroll/slide viewport。
tap 走既有九宮格 ReaderTapAction。
long press 第一版 no-op。
overlay 不應干擾 anchor / saveProgress。
```

### 15. TTS / auto page

流程：

```text
visibleLocation / TextLine range
-> TTS text source
-> highlight range
-> ensure visible / auto page
```

主要檔案：

```text
lib/features/reader/controllers/reader_tts_controller.dart
lib/features/reader/controllers/reader_auto_page_controller.dart
lib/features/reader/runtime/models/reader_tts_highlight.dart
lib/features/reader/reader_page.dart
lib/features/reader/viewport/reader_viewport_controller.dart
```

Review 重點：

```text
TTS 文字來源是否是 displayText。
TTS highlight 是否用 TextLine range / full-line rect。
第一版不做 glyph-level hit test。
ensure visible 不可進入 placeholder。
auto page 不可跳到 not-ready page。
TTS / auto page 觸發的移動和 saveProgress 時機是否一致。
```

### 16. lifecycle / exit

流程：

```text
app pause / background / exit / dispose
-> capture current anchor
-> flush progress
-> release runtime
```

主要檔案：

```text
lib/features/reader/reader_page.dart
lib/features/reader/runtime/reader_runtime.dart
lib/features/reader/runtime/reader_page_exit_coordinator.dart
lib/features/reader/viewport/scroll_reader_viewport.dart
```

Review 重點：

```text
dispose 前是否 flush。
paused 是否保存最新 visibleLocation。
flush 前是否重新 capture。
restore / loading / error 中不保存錯誤位置。
多次 flush 是否安全。
exit flow 是否會漏掉未上架書籍的進度。
```

### 17. error / loading / placeholder

流程：

```text
load failed / chapter missing / source missing
-> error state / placeholder
-> user notice
```

主要檔案：

```text
lib/features/reader/runtime/reader_runtime.dart
lib/features/reader/engine/page_resolver.dart
lib/features/reader/engine/chapter_repository.dart
lib/features/reader/viewport/scroll_reader_viewport.dart
lib/features/reader/viewport/slide_reader_viewport.dart
```

Review 重點：

```text
error 不可被當正文。
placeholder 不可產生 progress。
placeholder 不可被 slide/scroll 正式進入。
retry / reload 是否能清掉舊錯誤。
UI 不可進入空白 ready。
```

### 18. performance / smoothness

流程：

```text
drag / fling / paint frame
-> no expensive work
```

主要檔案：

```text
lib/features/reader/viewport/scroll_reader_viewport.dart
lib/features/reader/viewport/slide_reader_viewport.dart
lib/features/reader/viewport/reader_tile_painter.dart
lib/features/reader/engine/layout_engine.dart
lib/features/reader/runtime/reader_preload_scheduler.dart
```

Review 重點：

```text
paint 不做 layout。
paint 不 await。
drag / fling 每幀不打 DB/network。
notifyListeners / setState 不可每 pixel 無限制觸發。
large chapter / many pages 不應卡住主執行緒。
preload 應在背景做，不阻塞 gesture。
```

## 推薦 Review 順序

如果要一輪完整 review，建議按這個順序：

```text
1. 書籍入口 -> 章節清單
2. 章節清單 -> 原始章節內容
3. 原始章節內容 -> display text
4. display text -> TextLine / ChapterLayout
5. ChapterLayout -> PageCache / TextPage
6. PageCache -> scroll viewport
7. PageCache -> slide viewport
8. viewport -> visibleLocation
9. visibleLocation -> saveProgress
10. DB progress -> restore
11. mode switch
12. layout 改變
13. preload / cache / window
14. gesture / overlay
15. TTS / auto page
16. lifecycle / exit
17. error / loading / placeholder
18. performance / smoothness
```

若要加速，可以分兩批：

第一批，資料與位置真源：

```text
1. 書籍入口 -> 章節清單
2. 章節清單 -> 原始章節內容
3. 原始章節內容 -> display text
4. display text -> TextLine / ChapterLayout
5. ChapterLayout -> PageCache / TextPage
```

第二批，viewport 與 runtime：

```text
6. PageCache -> scroll viewport
7. PageCache -> slide viewport
8. viewport -> visibleLocation
9. visibleLocation -> saveProgress
10. DB progress -> restore
11. mode switch
12. layout 改變
13. preload / cache / window
14. gesture / overlay
15. TTS / auto page
16. lifecycle / exit
17. error / loading / placeholder
18. performance / smoothness
```

## 通用 Review Prompt

可直接交給 agent：

```text
請做 code review，不要修改程式碼。

Review slice:
<填入本次 slice 名稱>

範圍檔案:
<填入檔案列表>

請檢查這段流程是否滿足 docs/reader_review_plan.md 中對應 slice 的 invariant。

要求：
1. findings 先列，依嚴重程度排序。
2. 每個 finding 必須有 path:line。
3. 每個 finding 必須說明違反哪個 invariant。
4. 如果沒有 finding，請列出已確認的 invariant。
5. 請列出 missing tests。
6. 不要修改程式碼。
7. 不要提出大重構，除非目前架構無法滿足 invariant。
```

## Fix Prompt

review 完成後，如果要交給 agent 修：

```text
請 fix review findings。

要求：
1. 只修 findings 指出的問題。
2. 不做無關重構。
3. P2 以上 finding 必須補 regression test。
4. 修完跑相關測試。
5. 回報改了哪些檔案、跑了哪些測試、是否還有殘留風險。
```

