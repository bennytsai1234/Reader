# 平移翻頁章節切換流暢度改善計劃

> 狀態：第一階段已實作 · 第二階段待執行
> 建立：2026-04-17

---

## 問題描述

### 根本原因

平移翻頁（slide mode）的 `PageView` 是由 `slidePages` 這個扁平頁面陣列驅動的。  
`slidePages` 由 `SlideWindow.build()` 組成，**只包含已在 `chapterPagesCache` 中的章節**：

```dart
// slide_window.dart
if (nextIdx < totalChapters && (cache[nextIdx]?.isNotEmpty ?? false))
  SlideSegment(...)  // ← 沒有 cache 就沒這段
```

因此：

| 情況 | 結果 |
|------|------|
| N+1 已在 cache | `slidePages` 包含它 → 使用者可以直接滑過去 ✅ |
| N+1 尚未 cache | `slidePages` 在 N 的最後一頁結束 → `PageView` 彈回來 → **使用者滑不過去** ❌ |

當 `PageView` 到達邊界後，系統呼叫 `nextChapter()` → `loadChapter()` 非同步流程：  
讀取內容 → 分頁計算 → 寫入 cache → `slidePages` 更新 → 使用者才能繼續翻頁。

### 本地書 vs. 網路書

| 類型 | 主要等待來源 |
|------|------------|
| 網路書 | 網路請求（無法完全消除）+ 分頁計算 |
| **本地書** | **只有分頁計算（通常 < 200ms），理論上可消除等待** |

使用者回報的問題主要出現在**本地閱讀**，這是修改的優先目標。

---

## 發現的問題（已修復）

### Bug 1：`_preloadSlideNeighbors` 忽略 `preloadRadius`

```dart
// 修改前：無論傳入 preloadRadius=1 或 2，永遠只抓 ±1
for (final neighbor in [chapterIndex - 1, chapterIndex + 1]) { ... }
```

`_warmupAfterChapterLoad` 以 `preloadRadius: 2` 呼叫此方法，但 radius 從未被用到。  
實際上所有路徑都只預載了 N±1，而非 N±2。

**修復**：改為依 radius 展開雙向迴圈，近的優先：

```dart
for (int delta = 1; delta <= preloadRadius; delta++) {
  for (final neighbor in [chapterIndex + delta, chapterIndex - delta]) {
    if (...) unawaited(_loadAndCacheChapter(neighbor, silent: true));
  }
}
```

### Bug 2：本地書被人為限制 radius = 1

```dart
// 修改前
int _effectivePreloadRadius(int requestedRadius) {
    if (_isLocalBook) return 1;  // ← 強制覆蓋，無視傳入值
}
int get _defaultSlideWarmupRadius => _isLocalBook ? 1 : 2;  // ← 本地書也只有 1
```

這兩個 cap 的原意是**網路書節省流量**。本地書沒有網路成本，磁碟讀取幾乎免費，  
限制在 1 反而讓章節邊界的緩衝時間大幅縮短。

**修復**：本地書 slide 模式移除 cap，改為與網路書相同（radius = 2）；  
scroll 模式維持 1，因為 scroll 透過 `activateWindow` 管理視窗，不需要大 radius。

### 優化 3：Warmup 延遲 1500ms → 150ms（slide 模式）

章節切換完成後，原本等 1500ms 才觸發 N±2 的暖機預載。  
對 slide 模式改為 150ms，讓相鄰章節更快進入背景分頁佇列。

### 優化 4：邊界提早偵測（`_prefetchSlideNeighborIfNearBoundary`）

在 `onPageChanged` 中，偵測目前頁是否接近所在章節的末尾或開頭（預設 3 頁內），  
立即呼叫 `contentManager.prioritizeChapter()`，把目標章節推到預載佇列最前端。

---

## 效果對比

| 時間點 | 修改前 | 修改後 |
|--------|--------|--------|
| 開啟書時預載範圍（本地 slide） | N±1（Bug 使 radius 失效） | N±2（radius 真正作用） |
| 章節切換後 warmup 延遲 | 1500ms | 150ms |
| 章節切換後 warmup 範圍 | N±1（本地書 cap） | N±2 |
| 接近章節末尾時 | 無動作 | 立即 prioritize 相鄰章節 |

---

## 目前仍然存在的限制

現有改動本質上都是**「讓預載有更多時間完成」**。當以下情況發生時，邊界等待仍可能出現：

- 本地書章節很短（數秒即翻完），分頁計算來不及
- 網路書在慢速網路下，下載時間超過讀完當前章節的時間

---

## 第二階段計劃：本地書全書背景預載

### 思路

`ChapterContentManager` 中已有 `enableWholeBookPreload()` API：

```dart
void enableWholeBookPreload({int? startIndex}) {
    _wholeBookPreloadEnabled = true;
    _targetWindow = {所有章節};
    _startPreloading(center, preloadRadius: _chapters.length);
}
```

對於**本地書**，可在 `_init()` 完成後立即啟用全書預載，  
讓所有章節的分頁計算在背景陸續完成，之後任何章節切換都能即時響應。

### 實作要點

1. **觸發時機**：`_init()` Phase 3（warmup 階段），`isDisposed` 檢查後
2. **觸發條件**：`_isLocalBook && pageTurnMode == PageAnim.slide`
3. **記憶體影響**：每章節分頁結果約佔 10–50KB，100 章節 ≈ 1–5MB，可接受
4. **進度通知**：透過現有的 `onChapterReady` stream，`_handleChapterReady` 會自動更新 `slidePages`

### 預期效果

啟用後，從第二次翻頁開始（第一次需等全書掃描完），  
任何章節邊界切換**完全不需等待**，與實體書翻頁體感相同。

### 風險與緩解

| 風險 | 緩解方式 |
|------|---------|
| 啟動時分頁佔用 CPU | 使用現有 4ms yield budget，不會卡 UI |
| 書籍很長（1000+ 章）時記憶體壓力 | 可加上章節數上限（如 > 500 章時才啟動視窗模式） |
| 使用者快速切換書籍 | `dispose()` 會取消所有 loading，無需額外處理 |

---

## 相關檔案

| 檔案 | 說明 |
|------|------|
| `lib/features/reader/provider/reader_content_mixin.dart` | `_effectivePreloadRadius`、`_defaultSlideWarmupRadius`、`_preloadSlideNeighbors`、`scheduleDeferredWindowWarmup` |
| `lib/features/reader/runtime/read_book_controller.dart` | `onPageChanged`、`_prefetchSlideNeighborIfNearBoundary`、`_init()` preloadRadius |
| `lib/features/reader/engine/chapter_content_manager.dart` | `enableWholeBookPreload()`（第二階段入口） |
| `lib/features/reader/provider/slide_window.dart` | `SlideWindow.build()`（了解 slidePages 組成條件） |
