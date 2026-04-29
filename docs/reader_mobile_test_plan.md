# Reader Mobile Test Plan

日期：2026-04-29

## 目的

reader 主幹已經完成，下一步是在手機上實際讀書。這份文件用來收集體感問題，尤其是單元測試不容易覆蓋的滑動手感、跨章穩定性、恢復位置、TTS 跟隨與效能卡頓。

## 測試前準備

每次測試記錄：

```text
app version / commit
device model
Android / iOS version
book type: web / TXT / EPUB / UMD
reader mode: scroll / slide
font size / line height / padding / theme
```

建議至少準備：

- 長章節小說。
- 短章節小說。
- 只有標題或接近空章節的測試書。
- 本地 TXT。
- 本地 EPUB。
- 一本文字處理後會有替換、繁簡或分段差異的書。

## 核心測試路線

### 1. 開書 / 恢復

測：

- 第一次開書是否進入正確章節。
- 關掉 app 後重開是否回到接近原位置。
- 從背景切回是否不跳章、不跳段。
- 書籍內容重新載入後是否不把錯誤位置寫回 DB。

### 2. Scroll 連續跨章

測：

- 往下滑過多個章節。
- 往上滑回上一章。
- 快速 fling 到章節邊界。
- 在短章節之間快速滑動。
- 滑動中是否卡一下、白屏、重畫閃爍、突然跳位置。

期待：

- 可以上下跨章連續滑。
- anchor 穩定進入鄰章後 window 自動切換。
- scroll idle 後才保存 DB。
- 不會滑進 loading/error placeholder。

### 3. Slide 翻頁

測：

- 左右翻頁。
- 快速連續翻頁。
- 在章尾翻到下一章。
- 在章首翻回上一章。
- swipe 到尚未 ready 的鄰頁。

期待：

- page settled 後才保存進度。
- placeholder 不會被正式 settle。
- 快速連翻只保存最後 settled page。

### 4. 模式切換

測：

- scroll -> slide。
- slide -> scroll。
- 在章節邊界附近切換。
- 在 TTS 朗讀中切換。

期待：

- 使用同一個 `ReaderLocation(chapterIndex, charOffset, visualOffsetPx)`。
- 不因為切模式產生另一套 layout truth。
- 位置接近原 anchor，不突然跳到章首或下一章。

### 5. Layout 改變

測：

- 改字級。
- 改行距。
- 改 padding。
- 改字體。
- 旋轉螢幕。

期待：

- 使用舊 visibleLocation 重新 restore。
- layout settle 後 capture 新 visibleLocation。
- 不因 layout 改變直接覆蓋 DB。

### 6. TTS / Auto Page

測：

- TTS 從目前位置開始朗讀。
- TTS highlight 是否跟著目前朗讀行。
- 朗讀跨頁、跨章。
- auto page 是否能推動 scroll / slide 到下一段。

期待：

- TTS highlight 使用整行 rect，沒有逐字要求。
- `ensureCharRangeVisible` 可以把朗讀 range 帶回 viewport。
- TTS / auto page 不直接寫 DB。

### 7. 退出與背景

測：

- 正常返回書架。
- app 切背景。
- app 被系統回收後重開。
- 正在 fling 或動畫中切背景。

期待：

- lifecycle flush 保存最後可信 visible location。
- restore 期間不寫 DB。
- capture 失敗時不覆蓋已保存位置。

## Bug 回報格式

每個體感 bug 盡量用這個格式：

```text
標題：
app version / commit：
裝置：
系統：
書籍類型：
閱讀模式：
設定：

重現步驟：
1.
2.
3.

預期：
實際：
是否穩定重現：
發生前位置：
發生後位置：
截圖 / 錄影：
log：
```

## 修復後驗證

reader 相關修復至少跑：

```bash
flutter test test/features/reader/page_cache_test.dart test/features/reader/line_layout_test.dart test/features/reader/reader_tile_viewport_test.dart
```

如果修到內容載入、章節 repository、progress 或 runtime race，再加：

```bash
flutter test test/features/reader
flutter analyze
```
