# Slide Mode 頁面切換 Bug 分析與修復

## Bug 1：在章節最後一頁無法滑動到下一章

### 現象

開啟書籍時，若進度停在某章節的最後一頁，向右滑動無法進入下一章。必須先退回上一頁，再向前滑兩頁才能到達下一章。此問題僅在首次進入時出現，之後正常。

### 根因

`_handleChapterReady()` 在 slide mode 下缺少 `notifyListeners()`。

```dart
// reader_content_mixin.dart — _handleChapterReady()
if (!_isScrollMode) {
  _refreshSlidePages();
  // ← 缺少 notifyListeners()，UI 不會重建
} else if (pages != null && pages.isNotEmpty) {
  notifyListeners();
}
```

#### 完整時序

1. 讀者進入閱讀器，載入當前章節 N，進度在最後一頁
2. `loadChapterWithPreloadRadius(N, preloadRadius: 1)` 載入章節 N 並顯示
3. `_presentLoadedChapter()` → `_refreshSlidePages()` 建立 slide window
4. 此時只有章節 N 已載入，`slidePages = [ch_N 的所有頁面]`
5. PageView 的 `itemCount = ch_N 頁數`，使用者在最後一頁 → 無法往右滑
6. `_preloadSlideNeighbors()` 以 `unawaited` 方式異步載入 N-1、N+1
7. N+1 載完 → `_handleChapterReady(N+1)` 觸發
8. `_refreshSlidePages()` 內部更新 `slidePages = [ch_N-1, ch_N, ch_N+1]` 並設定 `pendingJump`
9. **但沒有 `notifyListeners()`** → Consumer 不重建 → PageView 的 `itemCount` 不變
10. 使用者依然卡在舊的最後一頁

退回一頁後可以的原因：手動滑動觸發 `onPageChanged()`，其末尾有 `notifyListeners()`，Consumer 重建，此時 `slidePages` 已包含下一章的頁面。

### 修復

在 `_handleChapterReady()` 的 slide mode 分支加上 `notifyListeners()`：

```dart
if (!_isScrollMode) {
  _refreshSlidePages();
  if (!isDisposed) notifyListeners();  // ← 新增
} else if (pages != null && pages.isNotEmpty) {
  notifyListeners();
}
```

---

## Bug 2：切換章節瞬間閃現錯誤頁面

### 現象

在 slide mode 下滑動跨越章節邊界時，畫面會先短暫顯示錯誤頁面（新章節中段某頁），再跳回正確頁面。從上一章最後一頁滑到下一章第一頁、以及反向操作時均會出現。

### 根因

slide window 重建（`slidePages` 資料更新）與 `PageController` 跳轉不在同一幀。

#### 關鍵程式碼

```dart
// reader_content_mixin.dart — onPageChanged()
if (needsRecenter) {
  final result = SlideWindow.build(...);
  _slideWindow = result.window;
  slidePages = result.window.flatPages;                  // ← Frame N：立即更新資料
  currentPageIndex = result.mappedIndex.clamp(...);
  requestJumpToPage(currentPageIndex, ...);              // ← 跳轉延遲到 Frame N+2
}
notifyListeners();  // ← Frame N：觸發 Consumer 重建

// slide_page_controller.dart — jumpTo()
WidgetsBinding.instance.addPostFrameCallback((_) {      // ← Frame N+1
  pageController.jumpToPage(target);                     // ← 才真正跳轉
});
```

#### 具體範例

假設舊 window = `[ch4: 8頁, ch5: 10頁, ch6: 12頁]`（共 30 頁）。
使用者從 ch5 最後一頁（index=17）滑到 ch6 第一頁（index=18）。

| Frame | 事件 | PageController 位置 | slidePages | 畫面顯示 |
|-------|------|---------------------|------------|----------|
| N | 使用者滑動完成 | 18 | 舊(30頁) | ch6[0] ✓ |
| N | `onPageChanged(18)` → 重建 window，`notifyListeners()` | 18 | 新 `[ch5:10, ch6:12]` (22頁) | — |
| N+1 | Consumer 重建，PageView 用新資料 | **18（還沒跳）** | 新(22頁) | **ch6[8] ✗ 錯誤** |
| N+2 | post-frame callback → `jumpToPage(10)` | 10 | 新(22頁) | ch6[0] ✓ |

Frame N+1 就是使用者看到的「閃跳」：`slidePages` 已更新（30→22頁），但 PageController 仍指向 index 18，在新資料中 index 18 = ch6 的第 9 頁。

### 修復方案：重建 PageController

核心思路：不用 `requestJumpToPage`（會延遲一幀），改為重建 `PageController(initialPage: mappedIndex)`，確保新 PageView 從建立的第一幀就在正確位置。

#### 實作步驟

1. **`ReaderProviderBase`**：新增 `_pendingControllerReset` 旗標
   - `onPageChanged` recenter 時設定此旗標（替代 `requestJumpToPage`）
   - 提供 `consumeControllerReset()` 給 Widget 層消費

2. **`_ReaderPageState`（reader_page.dart）**：偵測旗標並重建 controller
   - 消費 `controllerReset` 後建立新的 `PageController(initialPage: mappedIndex)`
   - 給 `ReadViewRuntime` 新的 `ValueKey` 強制重建

3. **為什麼不會割裂**：
   - 新 PageView 從第一幀就在正確頁面
   - 使用者剛滑完看到的本來就是那一頁，視覺上無縫
   - `jumpToPage` 不能在 build 階段呼叫（Flutter 限制），重建 controller 繞過此限制
