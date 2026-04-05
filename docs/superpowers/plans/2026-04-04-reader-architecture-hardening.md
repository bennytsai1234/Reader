# Reader Architecture Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修復閱讀器模塊的 5 個架構問題，提升可維護性與 Bug 定位難度。

**Architecture:** 每個 Task 獨立可交付。Task 1–3 是 bug fix/防禦性強化，Task 4 是測試補強，Task 5 是架構重構（最大）。依序執行，每個 Task 結束後都能通過 `flutter analyze` 和現有測試。

**Tech Stack:** Flutter 3.7+, Dart null-safety, flutter_test, Provider + ChangeNotifier, GetIt DI, Drift SQLite

---

## 背景知識

閱讀器核心是 `ReadBookController`，透過 mixin chain 組合功能：
```
ReaderProviderBase → ReaderSettingsMixin → ReaderContentMixin
  → ReaderProgressMixin → ReaderAutoPageMixin → ReadBookController
```

`ContentCallbacks` 是 mixin 呼叫 controller 方法的橋樑（因為 mixin 不能直接存取 controller 上才有的東西）。

---

## Task 1：修復 `_handleChapterReady` 的 `isDisposed` 遺漏

**問題：** `reader_content_mixin.dart:686` 在 scroll mode 分支呼叫 `notifyListeners()` 但沒有 `isDisposed` 保護。這行由 `contentManager.onChapterReady` Stream 觸發，是非同步回呼——用戶關掉書後，前一本書的章節載入仍可能完成並觸發此處，對已 dispose 的 ChangeNotifier 呼叫 `notifyListeners()` 會拋例外。

**Files:**
- Modify: `lib/features/reader/provider/reader_content_mixin.dart:682-687`

- [ ] **Step 1: 確認問題位置**

  打開 `lib/features/reader/provider/reader_content_mixin.dart`，找到 `_handleChapterReady` 方法（約 L664）。
  目前的問題程式碼：
  ```dart
  if (!_isScrollMode) {
    _refreshSlidePages();
    if (!isDisposed) notifyListeners();   // ✅ 有保護
  } else if (pages != null && pages.isNotEmpty) {
    notifyListeners();                     // ❌ 沒有保護
  }
  ```

- [ ] **Step 2: 修正**

  將 `reader_content_mixin.dart:682-687` 的程式碼改為：
  ```dart
  if (!_isScrollMode) {
    _refreshSlidePages();
    if (!isDisposed) notifyListeners();
  } else if (pages != null && pages.isNotEmpty) {
    if (!isDisposed) notifyListeners();
  }
  ```

- [ ] **Step 3: 執行分析確認沒有新問題**

  ```bash
  flutter analyze
  ```
  預期：`No issues found!`

- [ ] **Step 4: 執行現有測試確認沒有破壞**

  ```bash
  flutter test test/features/reader/
  ```
  預期：全部通過。

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/reader/provider/reader_content_mixin.dart
  git commit -m "fix: add isDisposed guard in _handleChapterReady scroll branch"
  ```

---

## Task 2：修復 `onPageChanged` 的進度寫入競爭條件

**問題：** `onPageChanged`（slide mode 換頁時觸發）直接呼叫 `bookDao.updateProgress()`，而 `ReaderProgressMixin` 的 `updateVisibleChapterPosition` 使用 `ReaderProgressStore` + 500ms debounce timer 寫入。兩條路徑可能同時跑，快速翻頁時 DB 紀錄可能亂序。

**修法：** 把 `onPageChanged` 裡的直接 DB 寫入改成透過 `persistCurrentProgress` callback（走 `ReaderProgressStore`，有版本保護）。

**Files:**
- Modify: `lib/features/reader/provider/reader_content_mixin.dart:515-527`

- [ ] **Step 1: 找到問題程式碼**

  在 `reader_content_mixin.dart` 的 `onPageChanged` 方法（約 L467），找到結尾的直接 DB 寫入：
  ```dart
  notifyListeners();
  final title = chapters.isNotEmpty ? chapters[currentChapterIndex].title : '';
  unawaited(
    bookDao.updateProgress(
      book.bookUrl,
      page.chapterIndex,
      title,
      ChapterPositionResolver.getCharOffsetForPage(
        chapterPagesCache[page.chapterIndex] ?? const <TextPage>[],
        page.index,
      ),
    ),
  );
  ```

- [ ] **Step 2: 替換為透過 callback 的統一寫入路徑**

  將上面那段程式碼（從 `notifyListeners()` 之後）改為：
  ```dart
  notifyListeners();
  _contentCallbacks.persistCurrentProgress?.call(
    chapterIndex: page.chapterIndex,
    pageIndex: i,
    reason: ReaderCommandReason.user,
  );
  ```

  同時刪除 `onPageChanged` 裡不再需要的 `title` 變數和 `bookDao.updateProgress` 呼叫。

- [ ] **Step 3: 確認 `persistCurrentProgress` callback 的實作端（`ReadBookController`）有正確處理**

  打開 `lib/features/reader/runtime/read_book_controller.dart`，確認 `persistCurrentProgress` 方法：
  ```dart
  void persistCurrentProgress({
    required int chapterIndex,
    int? pageIndex,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    if (!_navigation.canPersistProgress(reason)) return;
    saveProgress(chapterIndex, pageIndex ?? currentPageIndex, reason: reason);
  }
  ```
  這條路徑走 `saveProgress` → `_progressStore.persistCharOffset` → DB，是正確的統一路徑。

- [ ] **Step 4: 執行分析與測試**

  ```bash
  flutter analyze
  flutter test test/features/reader/
  ```
  預期：全部通過。

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/reader/provider/reader_content_mixin.dart
  git commit -m "fix: route onPageChanged DB write through persistCurrentProgress to eliminate race"
  ```

---

## Task 3：強化 `ContentCallbacks` — 加入 debug 驗證

**問題：** `ContentCallbacks` 所有欄位都是 nullable，呼叫失敗只會靜默跳過（`?.call()` 沒有任何錯誤輸出），讓 bug 很難發現。

**修法：** 加入 `debugAssertComplete()` 方法，在開發時（debug mode）驗證所有必要的 callback 都已注入。在 `ReadBookController._init()` 注入 callbacks 後立刻呼叫。

**Files:**
- Modify: `lib/features/reader/provider/content_callbacks.dart`
- Modify: `lib/features/reader/runtime/read_book_controller.dart`

- [ ] **Step 1: 在 `ContentCallbacks` 加入 `debugAssertComplete()`**

  在 `lib/features/reader/provider/content_callbacks.dart` 的 class 末尾（`}` 前），加入：
  ```dart
  /// 在 debug mode 驗證所有必要的 callback 都已注入。
  /// 在 ReadBookController._init() 注入 callbacks 後呼叫。
  void debugAssertComplete() {
    assert(refreshChapterRuntime != null,
        'ContentCallbacks.refreshChapterRuntime is required');
    assert(buildSlideRuntimePages != null,
        'ContentCallbacks.buildSlideRuntimePages is required');
    assert(jumpToSlidePage != null,
        'ContentCallbacks.jumpToSlidePage is required');
    assert(jumpToChapterLocalOffset != null,
        'ContentCallbacks.jumpToChapterLocalOffset is required');
    assert(jumpToChapterCharOffset != null,
        'ContentCallbacks.jumpToChapterCharOffset is required');
    assert(chapterAt != null,
        'ContentCallbacks.chapterAt is required');
    assert(pagesForChapter != null,
        'ContentCallbacks.pagesForChapter is required');
    assert(progressStore != null,
        'ContentCallbacks.progressStore is required');
    assert(shouldPersistVisiblePosition != null,
        'ContentCallbacks.shouldPersistVisiblePosition is required');
    assert(persistCurrentProgress != null,
        'ContentCallbacks.persistCurrentProgress is required');
  }
  ```

- [ ] **Step 2: 在 `ReadBookController._init()` 呼叫驗證**

  打開 `lib/features/reader/runtime/read_book_controller.dart`，找到 `_init()` 方法中 `contentCallbacks = ContentCallbacks(...)` 那段（約 L365）。在 `contentCallbacks = ContentCallbacks(...)` 指派結束的 `);` 之後，加一行：
  ```dart
  contentCallbacks = ContentCallbacks(
    // ... 現有的所有 callback ...
  );
  contentCallbacks.debugAssertComplete(); // 加這行
  ```

- [ ] **Step 3: 執行分析與測試**

  ```bash
  flutter analyze
  flutter test test/features/reader/
  ```
  預期：全部通過。

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/reader/provider/content_callbacks.dart \
          lib/features/reader/runtime/read_book_controller.dart
  git commit -m "feat: add ContentCallbacks.debugAssertComplete() to catch missing callbacks early"
  ```

---

## Task 4：補充 `ReadBookController` 生命週期整合測試

**問題：** `ReadBookController`（1050 行）本身沒有任何測試，是最難定位 bug 的地方。

**目標：** 新增一個測試檔，驗證最容易出錯的場景：dispose 後的 notifyListeners、基本初始化流程。

**Files:**
- Create: `test/features/reader/read_book_controller_test.dart`
- Reference: `test/features/reader/reader_runtime_flow_test.dart`（參考現有的 fake DAO 設定方式）

- [ ] **Step 1: 建立測試檔，複製 fake DAO 設定**

  建立 `test/features/reader/read_book_controller_test.dart`：

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:legado_reader/core/database/dao/book_dao.dart';
  import 'package:legado_reader/core/database/dao/book_source_dao.dart';
  import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
  import 'package:legado_reader/core/database/dao/chapter_dao.dart';
  import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
  import 'package:legado_reader/core/di/injection.dart';
  import 'package:legado_reader/core/models/book.dart';
  import 'package:legado_reader/features/reader/runtime/read_book_controller.dart';

  // ── Fake DAOs ────────────────────────────────────────────────────────────────

  class _FakeBookDao implements BookDao {
    @override
    Future<void> updateProgress(
      String bookUrl,
      int chapterIndex,
      String chapterTitle,
      int pos,
    ) async {}

    @override
    dynamic noSuchMethod(Invocation invocation) => null;
  }

  class _FakeChapterDao implements ChapterDao {
    @override
    dynamic noSuchMethod(Invocation invocation) => null;
  }

  class _FakeReplaceRuleDao implements ReplaceRuleDao {
    @override
    dynamic noSuchMethod(Invocation invocation) => null;
  }

  class _FakeBookSourceDao implements BookSourceDao {
    @override
    dynamic noSuchMethod(Invocation invocation) => null;
  }

  class _FakeBookmarkDao implements BookmarkDao {
    @override
    dynamic noSuchMethod(Invocation invocation) => null;
  }

  void _setupDi() {
    for (final type in [BookDao, ChapterDao, ReplaceRuleDao, BookSourceDao, BookmarkDao]) {
      if (getIt.isRegistered(type: type)) getIt.unregister(type: type);
    }
    getIt.registerLazySingleton<BookDao>(() => _FakeBookDao());
    getIt.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
    getIt.registerLazySingleton<ReplaceRuleDao>(() => _FakeReplaceRuleDao());
    getIt.registerLazySingleton<BookSourceDao>(() => _FakeBookSourceDao());
    getIt.registerLazySingleton<BookmarkDao>(() => _FakeBookmarkDao());
  }

  Book _makeBook() => Book(
        bookUrl: 'http://test.com/book',
        name: 'Test Book',
        author: 'Author',
        origin: 'local',
        durChapterIndex: 0,
        durChapterPos: 0,
      );

  // ── Tests ─────────────────────────────────────────────────────────────────

  void main() {
    setUpAll(() {
      WidgetsFlutterBinding.ensureInitialized();
      _setupDi();
    });

    group('ReadBookController lifecycle', () {
      test('可以建立並立即 dispose，不會拋例外', () {
        final controller = ReadBookController(book: _makeBook());
        // dispose 應該能安全執行，即使 _init() 還在跑
        expect(() => controller.dispose(), returnsNormally);
      });

      test('dispose 後 isDisposed 為 true', () {
        final controller = ReadBookController(book: _makeBook());
        controller.dispose();
        expect(controller.isDisposed, isTrue);
      });

      test('dispose 後 lifecycle 為 disposed', () {
        final controller = ReadBookController(book: _makeBook());
        controller.dispose();
        expect(controller.lifecycle, equals(ReaderLifecycle.disposed));
      });

      test('dispose 後呼叫 notifyListeners 不會拋例外', () {
        // ReaderProviderBase.notifyListeners() 有 isDisposed 保護
        final controller = ReadBookController(book: _makeBook());
        controller.dispose();
        // 不應拋 FlutterError: "A notifier was used after being disposed"
        expect(() => controller.notifyListeners(), returnsNormally);
      });

      test('初始狀態：lifecycle 為 loading', () {
        final controller = ReadBookController(book: _makeBook());
        expect(controller.lifecycle, equals(ReaderLifecycle.loading));
        controller.dispose();
      });

      test('初始狀態：isReady 為 false', () {
        final controller = ReadBookController(book: _makeBook());
        expect(controller.isReady, isFalse);
        controller.dispose();
      });
    });
  }
  ```

- [ ] **Step 2: 執行新測試，確認全數通過**

  ```bash
  flutter test test/features/reader/read_book_controller_test.dart -v
  ```
  預期：6 個測試全數通過（PASS）。

- [ ] **Step 3: 執行全套 reader 測試確認沒有 regression**

  ```bash
  flutter test test/features/reader/
  ```
  預期：全部通過。

- [ ] **Step 4: Commit**

  ```bash
  git add test/features/reader/read_book_controller_test.dart
  git commit -m "test: add ReadBookController lifecycle integration tests"
  ```

---

## Task 5：將 `ReaderProgressMixin` 提取為 `ReaderProgressCoordinator`

**問題：** `ReaderProgressMixin` 透過 `contentCallbacksRef` 間接取用 `ReadBookController` 上直接存在的資料（`chapterAt`、`pagesForChapter` 等），是不必要的繞道。改為 coordinator 後，依賴關係變明確，也容易單獨測試。

**設計：**
- 新建 `ReaderProgressCoordinator`（持有需要的依賴）
- `ReaderProgressMixin` 裡的邏輯搬進去
- `ReadBookController` 持有這個 coordinator
- 從 mixin chain 移除 `ReaderProgressMixin`
- `jumpToPosition()` 的實作移回 `ReadBookController`（因為它能直接存取所有資料）

**Files:**
- Create: `lib/features/reader/runtime/reader_progress_coordinator.dart`
- Modify: `lib/features/reader/runtime/read_book_controller.dart`
- Modify: `lib/features/reader/provider/reader_content_mixin.dart`（移除 abstract `jumpToPosition` 或改為 concrete）
- Delete: `lib/features/reader/provider/reader_progress_mixin.dart`
- Create: `test/features/reader/reader_progress_coordinator_test.dart`

### Step 5.1：建立 `ReaderProgressCoordinator`

- [ ] **建立新檔案**

  建立 `lib/features/reader/runtime/reader_progress_coordinator.dart`：

  ```dart
  import 'dart:async';

  import 'package:legado_reader/core/constant/page_anim.dart';
  import 'package:legado_reader/core/models/book.dart';
  import 'package:legado_reader/core/models/chapter.dart';
  import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
  import 'package:legado_reader/features/reader/engine/text_page.dart';
  import 'package:legado_reader/features/reader/runtime/models/reader_chapter.dart';
  import 'package:legado_reader/features/reader/runtime/reader_progress_store.dart';
  import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';

  /// 管理閱讀進度的更新與持久化。
  ///
  /// 取代原本 ReaderProgressMixin 的 contentCallbacksRef 繞道模式，
  /// 改由建構時注入明確的依賴。
  class ReaderProgressCoordinator {
    final Book Function() _book;
    final List<BookChapter> Function() _chapters;
    final ReaderChapter? Function(int chapterIndex) _chapterAt;
    final List<TextPage> Function(int chapterIndex) _pagesForChapter;
    final ReaderProgressStore _store;
    final bool Function() _shouldPersistVisiblePosition;
    final void Function({
      required int chapterIndex,
      int? pageIndex,
      required ReaderCommandReason reason,
    }) _persistCurrentProgress;

    Timer? scrollSaveTimer;

    ReaderProgressCoordinator({
      required Book Function() book,
      required List<BookChapter> Function() chapters,
      required ReaderChapter? Function(int) chapterAt,
      required List<TextPage> Function(int) pagesForChapter,
      required ReaderProgressStore store,
      required bool Function() shouldPersistVisiblePosition,
      required void Function({
        required int chapterIndex,
        int? pageIndex,
        required ReaderCommandReason reason,
      }) persistCurrentProgress,
    })  : _book = book,
          _chapters = chapters,
          _chapterAt = chapterAt,
          _pagesForChapter = pagesForChapter,
          _store = store,
          _shouldPersistVisiblePosition = shouldPersistVisiblePosition,
          _persistCurrentProgress = persistCurrentProgress;

    /// 更新可見章節位置，並在需要時觸發進度持久化。
    void updateVisibleChapterPosition({
      required int chapterIndex,
      required double localOffset,
      required double alignment,
      required int pageTurnMode,
      required bool isLoading,
      required int currentPageIndex,
      required void Function(int, double, double) updateVisible,
      required void Function(int) updateCurrentChapterIndex,
    }) {
      updateVisible(chapterIndex, localOffset, alignment);

      if (pageTurnMode != PageAnim.scroll || isLoading) return;
      if (!_shouldPersistVisiblePosition()) return;

      final runtimeChapter = _chapterAt(chapterIndex);
      final pages = _pagesForChapter(chapterIndex);
      final book = _book();
      final currentCharOffset = runtimeChapter != null
          ? runtimeChapter.charOffsetFromLocalOffset(localOffset)
          : ChapterPositionResolver.localOffsetToCharOffset(pages, localOffset);

      if (book.durChapterIndex == chapterIndex &&
          book.durChapterPos == currentCharOffset) {
        return;
      }

      _store.updateBookProgress(
        book: book,
        chapterIndex: chapterIndex,
        charOffset: currentCharOffset,
      );

      final crossThreshold = _store.shouldSaveImmediately(
        currentCharOffset: currentCharOffset,
        currentChapterIndex: book.durChapterIndex,
        targetChapterIndex: chapterIndex,
      );
      updateCurrentChapterIndex(chapterIndex);

      if (crossThreshold) {
        scrollSaveTimer?.cancel();
        _persistCurrentProgress(
          chapterIndex: chapterIndex,
          pageIndex: currentPageIndex,
          reason: ReaderCommandReason.userScroll,
        );
      } else {
        scrollSaveTimer?.cancel();
        scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
          _persistCurrentProgress(
            chapterIndex: chapterIndex,
            pageIndex: currentPageIndex,
            reason: ReaderCommandReason.userScroll,
          );
        });
      }
    }

    /// 解析頁面/偏移，計算目標 char offset，持久化進度。
    void saveProgress({
      required int chapterIndex,
      required int pageIndex,
      required int pageTurnMode,
      required double visibleChapterLocalOffset,
      required List<TextPage> slidePages,
      required Future<void> Function(int chapterIndex, String title, int charOffset) write,
    }) {
      final runtimeChapter = _chapterAt(chapterIndex);
      final pages = _pagesForChapter(chapterIndex);

      final charOffset = pageTurnMode == PageAnim.scroll
          ? (runtimeChapter != null
              ? runtimeChapter.charOffsetFromLocalOffset(visibleChapterLocalOffset)
              : ChapterPositionResolver.localOffsetToCharOffset(
                  pages,
                  visibleChapterLocalOffset,
                ))
          : _resolveSlideCharOffset(
              pageIndex: pageIndex,
              slidePages: slidePages,
              runtimeChapter: runtimeChapter,
              pages: pages,
            );

      unawaited(
        _store.persistCharOffset(
          write: write,
          book: _book(),
          chapters: _chapters(),
          chapterIndex: chapterIndex,
          charOffset: charOffset,
        ),
      );
    }

    /// 更新 scroll mode 的頁面索引（不觸發持久化）。
    void updateScrollPageIndex({
      required int chapterIndex,
      required double localOffset,
      required void Function(int) setCurrentPageIndex,
      required void Function(int) setVisibleChapterIndex,
      required void Function(int) setCurrentChapterIndex,
    }) {
      setVisibleChapterIndex(chapterIndex);
      final runtimeChapter = _chapterAt(chapterIndex);
      final pages = _pagesForChapter(chapterIndex);
      final pageIndex = runtimeChapter != null
          ? runtimeChapter.pageIndexAtLocalOffset(localOffset)
          : ChapterPositionResolver.pageIndexAtLocalOffset(pages, localOffset);
      setCurrentPageIndex(pageIndex);
      setCurrentChapterIndex(chapterIndex);
    }

    void dispose() {
      scrollSaveTimer?.cancel();
      scrollSaveTimer = null;
    }

    int _resolveSlideCharOffset({
      required int pageIndex,
      required List<TextPage> slidePages,
      required ReaderChapter? runtimeChapter,
      required List<TextPage> pages,
    }) {
      if (pageIndex >= 0 && pageIndex < slidePages.length) {
        final page = slidePages[pageIndex];
        final runtime = _chapterAt(page.chapterIndex);
        final chapterPages = _pagesForChapter(page.chapterIndex);
        return runtime != null
            ? runtime.charOffsetForPageIndex(page.index)
            : ChapterPositionResolver.getCharOffsetForPage(chapterPages, page.index);
      }
      return runtimeChapter != null
          ? runtimeChapter.charOffsetForPageIndex(
              pageIndex.clamp(0, (pages.length - 1).clamp(0, 1 << 20)),
            )
          : ChapterPositionResolver.getCharOffsetForPage(
              pages,
              pageIndex.clamp(0, (pages.length - 1).clamp(0, 1 << 20)),
            );
    }
  }
  ```

### Step 5.2：寫 coordinator 的單元測試

- [ ] **建立測試檔**

  建立 `test/features/reader/reader_progress_coordinator_test.dart`：

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:legado_reader/core/constant/page_anim.dart';
  import 'package:legado_reader/core/models/book.dart';
  import 'package:legado_reader/core/models/chapter.dart';
  import 'package:legado_reader/features/reader/runtime/reader_progress_coordinator.dart';
  import 'package:legado_reader/features/reader/runtime/reader_progress_store.dart';

  Book _makeBook() => Book(
        bookUrl: 'http://test.com/book',
        name: 'Test Book',
        author: 'Author',
        origin: 'local',
        durChapterIndex: 0,
        durChapterPos: 0,
      );

  ReaderProgressCoordinator _makeCoordinator({
    Book? book,
    required void Function({
      required int chapterIndex,
      int? pageIndex,
      required ReaderCommandReason reason,
    }) onPersist,
  }) {
    final b = book ?? _makeBook();
    return ReaderProgressCoordinator(
      book: () => b,
      chapters: () => [
        BookChapter(url: 'ch1', title: 'Chapter 1', index: 0),
      ],
      chapterAt: (_) => null,
      pagesForChapter: (_) => const [],
      store: ReaderProgressStore(),
      shouldPersistVisiblePosition: () => true,
      persistCurrentProgress: onPersist,
    );
  }

  void main() {
    group('ReaderProgressCoordinator', () {
      test('dispose 時取消 scrollSaveTimer', () async {
        var persistCalled = false;
        final coordinator = _makeCoordinator(
          onPersist: ({required chapterIndex, pageIndex, required reason}) {
            persistCalled = true;
          },
        );

        // 觸發帶 timer 的更新
        coordinator.updateVisibleChapterPosition(
          chapterIndex: 0,
          localOffset: 100.0,
          alignment: 0.0,
          pageTurnMode: PageAnim.scroll,
          isLoading: false,
          currentPageIndex: 0,
          updateVisible: (_, __, ___) {},
          updateCurrentChapterIndex: (_) {},
        );

        // dispose 應該取消 timer，所以 persist 不會被呼叫
        coordinator.dispose();
        await Future.delayed(const Duration(milliseconds: 600));
        expect(persistCalled, isFalse);
      });

      test('滾動超過 600 字元閾值時立即持久化', () {
        var persistCalled = false;
        ReaderCommandReason? persistReason;
        final book = _makeBook()
          ..durChapterIndex = 0
          ..durChapterPos = 0;
        final store = ReaderProgressStore();
        // 模擬已儲存過 0 這個位置
        final coordinator = ReaderProgressCoordinator(
          book: () => book,
          chapters: () => [BookChapter(url: 'ch1', title: 'C1', index: 0)],
          chapterAt: (_) => null,
          pagesForChapter: (_) => const [],
          store: store,
          shouldPersistVisiblePosition: () => true,
          persistCurrentProgress: ({required chapterIndex, pageIndex, required reason}) {
            persistCalled = true;
            persistReason = reason;
          },
        );

        // localOffset 對應 charOffset 0（空頁面時），所以先更新到 0
        coordinator.updateVisibleChapterPosition(
          chapterIndex: 0,
          localOffset: 0,
          alignment: 0.0,
          pageTurnMode: PageAnim.scroll,
          isLoading: false,
          currentPageIndex: 0,
          updateVisible: (_, __, ___) {},
          updateCurrentChapterIndex: (_) {},
        );

        // 重設標誌，再更新到不同章節（跨章節一定立即持久化）
        persistCalled = false;
        coordinator.updateVisibleChapterPosition(
          chapterIndex: 1,
          localOffset: 0,
          alignment: 0.0,
          pageTurnMode: PageAnim.scroll,
          isLoading: false,
          currentPageIndex: 0,
          updateVisible: (_, __, ___) {},
          updateCurrentChapterIndex: (_) {},
        );

        expect(persistCalled, isTrue);
        expect(persistReason, equals(ReaderCommandReason.userScroll));
        coordinator.dispose();
      });

      test('isLoading 時不持久化', () {
        var persistCalled = false;
        final coordinator = _makeCoordinator(
          onPersist: ({required chapterIndex, pageIndex, required reason}) {
            persistCalled = true;
          },
        );

        coordinator.updateVisibleChapterPosition(
          chapterIndex: 0,
          localOffset: 50.0,
          alignment: 0.0,
          pageTurnMode: PageAnim.scroll,
          isLoading: true, // ← 正在載入
          currentPageIndex: 0,
          updateVisible: (_, __, ___) {},
          updateCurrentChapterIndex: (_) {},
        );

        expect(persistCalled, isFalse);
        coordinator.dispose();
      });
    });
  }
  ```

- [ ] **執行測試確認通過**

  ```bash
  flutter test test/features/reader/reader_progress_coordinator_test.dart -v
  ```
  預期：3 個測試全數通過。

### Step 5.3：在 `ReadBookController` 整合 `ReaderProgressCoordinator`

- [ ] **在 `ReadBookController` 加入 coordinator**

  在 `lib/features/reader/runtime/read_book_controller.dart` 的 import 區塊加入：
  ```dart
  import 'package:legado_reader/features/reader/runtime/reader_progress_coordinator.dart';
  ```

  在 class 的欄位區塊（`_chapterRuntimeCache` 附近）加入：
  ```dart
  late final ReaderProgressCoordinator _progressCoordinator;
  ```

  在 `ReadBookController` constructor 的 `_init()` 呼叫前，加入初始化：
  ```dart
  ReadBookController({...}) : super(book) {
    currentChapterIndex = chapterIndex;
    visibleChapterIndex = chapterIndex;
    initialCharOffset = chapterPos;
    _readAloudController = _buildReadAloudController();
    _progressCoordinator = ReaderProgressCoordinator(     // ← 新增
      book: () => book,
      chapters: () => chapters,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      store: _progressStore,
      shouldPersistVisiblePosition: shouldPersistVisiblePosition,
      persistCurrentProgress: ({required chapterIndex, pageIndex, required reason}) =>
          persistCurrentProgress(
            chapterIndex: chapterIndex,
            pageIndex: pageIndex,
            reason: reason,
          ),
    );
    _init();
  }
  ```

- [ ] **把 mixin 方法呼叫替換為 coordinator**

  找到 `ReadBookController` 中呼叫 `updateVisibleChapterPosition`、`saveProgress`、`updateScrollPageIndex` 的地方，全部改為呼叫 `_progressCoordinator` 的對應方法。

  **`handleVisibleScrollState` 裡的 `updateVisibleChapterPosition`：**
  ```dart
  // 原本：
  updateVisibleChapterPosition(
    chapterIndex: chapterIndex,
    localOffset: localOffset,
    alignment: alignment,
  );

  // 改為：
  _progressCoordinator.updateVisibleChapterPosition(
    chapterIndex: chapterIndex,
    localOffset: localOffset,
    alignment: alignment,
    pageTurnMode: pageTurnMode,
    isLoading: isLoading,
    currentPageIndex: currentPageIndex,
    updateVisible: (ci, lo, al) {
      visibleChapterIndex = ci;
      visibleChapterLocalOffset = lo;
      visibleChapterAlignment = al;
    },
    updateCurrentChapterIndex: (ci) => currentChapterIndex = ci,
  );
  ```

  **`persistCurrentProgress` 裡的 `saveProgress`：**
  ```dart
  // 保持呼叫 saveProgress，這個方法留在 controller 裡（見下方 Step 5.4）
  ```

### Step 5.4：在 `ReadBookController` 實作 `jumpToPosition` 和 `saveProgress`

移除 `ReaderProgressMixin` 後，這兩個方法需要直接在 `ReadBookController` 實作。

- [ ] **在 `ReadBookController` 加入 `jumpToPosition`**

  在 controller 末尾加入：
  ```dart
  void jumpToPosition({
    int? chapterIndex,
    int? charOffset,
    int? pageIndex,
    bool isRestoringJump = false,
  }) {
    final targetChapter = chapterIndex ?? currentChapterIndex;

    if (pageTurnMode == PageAnim.scroll) {
      final runtimeChapter = chapterAt(targetChapter);
      final pages = pagesForChapter(targetChapter);
      final targetCharOffset = charOffset ?? 0;
      final localOffset = runtimeChapter != null
          ? runtimeChapter.localOffsetFromCharOffset(targetCharOffset)
          : ChapterPositionResolver.charOffsetToLocalOffset(pages, targetCharOffset);
      final alignment = runtimeChapter != null
          ? runtimeChapter.alignmentForCharOffset(targetCharOffset)
          : ChapterPositionResolver.charOffsetToAlignment(pages, targetCharOffset);
      requestJumpToChapter(
        chapterIndex: targetChapter,
        localOffset: localOffset,
        alignment: alignment,
        reason: isRestoringJump
            ? ReaderCommandReason.restore
            : ReaderCommandReason.system,
      );
      notifyListeners();
      return;
    }

    final pages = pagesForChapter(targetChapter);
    var targetPage = 0;
    if (charOffset != null && charOffset > 0) {
      final runtimeChapter = chapterAt(targetChapter);
      final localPageIndex = runtimeChapter != null
          ? runtimeChapter.getPageIndexByCharIndex(charOffset)
          : ChapterPositionResolver.findPageIndexByCharOffset(pages, charOffset);
      final globalIndex = slidePages.indexWhere(
        (page) => page.chapterIndex == targetChapter && page.index == localPageIndex,
      );
      targetPage = globalIndex >= 0 ? globalIndex : 0;
    } else if (pageIndex != null) {
      targetPage = pageIndex.clamp(0, slidePages.length - 1);
    }
    currentPageIndex = targetPage;
    requestJumpToPage(
      targetPage,
      reason: isRestoringJump
          ? ReaderCommandReason.restore
          : ReaderCommandReason.system,
    );
    notifyListeners();
  }
  ```

- [ ] **在 `ReadBookController` 加入 `saveProgress`**

  ```dart
  void saveProgress(
    int chapterIndex,
    int pageIndex, {
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    _progressCoordinator.saveProgress(
      chapterIndex: chapterIndex,
      pageIndex: pageIndex,
      pageTurnMode: pageTurnMode,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
      slidePages: slidePages,
      write: (ci, title, offset) => bookDao.updateProgress(
        book.bookUrl, ci, title, offset,
      ),
    );
  }
  ```

- [ ] **在 `ReadBookController.dispose()` 加入 coordinator 的 dispose**

  在 `dispose()` 方法裡加入：
  ```dart
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistSessionProgress();
    _progressCoordinator.dispose();   // ← 新增（確保 scrollSaveTimer 被取消）
    scrollSaveTimer?.cancel();        // ← 這行可以移除（已由 coordinator 管理）
    _heartbeatTimer?.cancel();
    disposeAutoPageCoordinator();
    _readAloudController.dispose();
    disposeContentManager();
    super.dispose();
  }
  ```

### Step 5.5：移除 `ReaderProgressMixin`

- [ ] **從 `ReadBookController` 的 mixin chain 移除**

  在 `read_book_controller.dart` 找到：
  ```dart
  class ReadBookController extends ReaderProviderBase
      with
          ReaderSettingsMixin,
          ReaderContentMixin,
          ReaderProgressMixin,    // ← 刪除這行
          ReaderAutoPageMixin,
          WidgetsBindingObserver {
  ```
  並刪除 `ReaderProgressMixin,` 這行和對應的 import。

- [ ] **移除 `reader_content_mixin.dart` 裡的 `abstract jumpToPosition`**

  找到 `reader_content_mixin.dart` 裡的：
  ```dart
  void jumpToPosition({
    int? chapterIndex,
    int? charOffset,
    int? pageIndex,
    bool isRestoringJump = false,
  });
  ```
  由於這個 abstract 方法的唯一目的是讓 `ReaderProgressMixin` 實作，移除 mixin 後它不再需要。刪除這個宣告。
  
  同時找到呼叫 `jumpToPosition` 的地方（`_restoreDisplayPositionAfterRepaginate`、`_presentLoadedChapter` 等），把呼叫改為透過 `_contentCallbacks.jumpToChapterCharOffset` 或直接呼叫（因為 controller 現在有 concrete 實作）。

  > **注意：** 搜尋所有呼叫 `jumpToPosition` 的地方：
  > ```bash
  > grep -n "jumpToPosition" lib/features/reader/provider/reader_content_mixin.dart
  > ```
  > 一一確認並改成對應的 callback 或直接呼叫。

- [ ] **刪除 `reader_progress_mixin.dart`**

  ```bash
  rm lib/features/reader/provider/reader_progress_mixin.dart
  ```

- [ ] **更新 `ReaderContentMixin` 的 on 約束**

  找到 `reader_content_mixin.dart` 開頭：
  ```dart
  mixin ReaderContentMixin on ReaderProviderBase, ReaderSettingsMixin {
  ```
  確認已移除對 `ReaderProgressMixin` 的依賴（這個 mixin 原本不在 `ReaderContentMixin` 的 `on` 裡，所以不需要改）。

- [ ] **移除 `ReaderContentMixin` 裡的 `initialCharOffset` 欄位引用**

  `initialCharOffset` 原本定義在 `ReaderProgressMixin`，現在要移到 `ReadBookController` 的欄位區塊：
  ```dart
  int initialCharOffset = 0;  // 加在 ReadBookController 的欄位區塊
  ```

### Step 5.6：驗證整合

- [ ] **執行 flutter analyze**

  ```bash
  flutter analyze
  ```
  預期：`No issues found!`

- [ ] **執行全套測試**

  ```bash
  flutter test test/features/reader/
  ```
  預期：全部通過（包括新加的 coordinator 測試和 controller lifecycle 測試）。

- [ ] **Commit**

  ```bash
  git add lib/features/reader/runtime/reader_progress_coordinator.dart \
          lib/features/reader/runtime/read_book_controller.dart \
          lib/features/reader/provider/reader_content_mixin.dart \
          test/features/reader/reader_progress_coordinator_test.dart
  git rm lib/features/reader/provider/reader_progress_mixin.dart
  git commit -m "refactor: extract ReaderProgressMixin into ReaderProgressCoordinator"
  ```

---

## 完整驗收

所有 Task 完成後執行：

```bash
flutter analyze
flutter test
```

預期結果：
- `No issues found!`
- 所有測試通過
- Mixin chain 縮短為：`ReaderProviderBase → ReaderSettingsMixin → ReaderContentMixin → ReaderAutoPageMixin → ReadBookController`
- 進度邏輯有獨立的 coordinator 和單元測試

---

## 修改摘要

| Task | 主要修改 | 風險 |
|---|---|---|
| T1 | `reader_content_mixin.dart` L686 加 1 行 | 🟢 極低 |
| T2 | `reader_content_mixin.dart` onPageChanged 改路由 | 🟢 低 |
| T3 | `content_callbacks.dart` 加方法 + controller 加 1 行呼叫 | 🟢 低 |
| T4 | 新增測試檔，不改生產程式碼 | 🟢 零 |
| T5 | 新增 coordinator + 移除 mixin | 🟠 中（需整合驗證） |
