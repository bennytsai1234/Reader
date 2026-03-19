import 'dart:async';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'reader_content_mixin.dart';
/// ReaderProvider 的進度管理擴展
/// 負責：位置儲存/恢復、字元偏移量計算、滾動位置追蹤
mixin ReaderProgressMixin on ReaderProviderBase, ReaderSettingsMixin, ReaderContentMixin {
  /// 儲存從資料庫讀取的初始字元偏移量
  int initialCharOffset = 0;

  /// 延遲恢復的閱讀位置（charOffset）：_init 時 viewSize 尚未就緒，需等 doPaginate 後再恢復
  int? pendingRestorePos;
  
  /// 首屏渲染的絕對 Y 軸座標 (Zero-Jump 核心)
  double initialTargetY = 0.0;

  // --- 捲動模式：追蹤精確滾動位置（供 dispose 時精確儲存進度）---
  double lastScrollY = 0.0;
  Timer? scrollSaveTimer;

  /// showHead 時，ListView 頂部有 2px head
  double get scrollHeadOffset =>
      (pages.isNotEmpty && pages.first.chapterIndex > 0) ? 2.0 : 0.0;

  int _lastSavedCharOffset = -1;

  /// 由 ReaderViewBuilder 在每次捲動時呼叫，記錄最新 scroll offset
  void updateScrollOffset(double scrollY) {
    if (lastScrollY == scrollY) return;
    lastScrollY = scrollY;

    if (!isRestoring && !isLoading) {
      // 記憶體單行追蹤
      final currentCharOffset = getCharOffsetForScrollY(scrollY);
      if (book.durChapterPos != currentCharOffset) {
        book.durChapterPos = currentCharOffset;
        if (_lastSavedCharOffset == -1) _lastSavedCharOffset = currentCharOffset;
        
        // 計數器寫入：行數差距 (假設每行約 30 字，20行 = 600字)
        final bool crossThreshold = (currentCharOffset - _lastSavedCharOffset).abs() > 600;
        
        if (crossThreshold) {
          scrollSaveTimer?.cancel();
          saveProgress(currentChapterIndex, currentPageIndex);
        } else {
          // 滾動時自動儲存進度（Debounce 500ms）
          scrollSaveTimer?.cancel();
          scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
            if (!isDisposed) saveProgress(currentChapterIndex, currentPageIndex);
          });
        }
      }
    }
  }

  /// 統一跳轉定位邏輯 (核心方法)
  /// 無論是開書恢復、目錄跳轉、還是 TTS 追蹤，都經由此處
  void jumpToPosition({int? charOffset, int? pageIndex, bool isRestoringJump = false}) {
    if (pages.isEmpty) return;

    if (isRestoringJump) isRestoring = true;

    if (pageTurnMode == PageAnim.scroll) {
      // 捲動模式：優先使用 charOffset 計算精確像素
      double targetPixels = 0.0;
      if (charOffset != null && charOffset > 0) {
        targetPixels = calcScrollOffsetForCharOffset(charOffset);
      } else if (pageIndex != null) {
        targetPixels = calcScrollOffsetForPageIndex(pageIndex);
      }

      scrollOffsetController.add(targetPixels);
      // 捲動模式跳轉後，ListView 會觸發監聽，進而更新 currentPageIndex
    } else {
      // 分頁模式：將 charOffset 轉換為頁碼
      int targetPage = 0;
      if (charOffset != null && charOffset > 0) {
        targetPage = findPageIndexByCharOffset(charOffset);
      } else if (pageIndex != null) {
        targetPage = pageIndex.clamp(0, pages.length - 1);
      }

      currentPageIndex = targetPage;
      jumpPageController.add(targetPage);
      // 分頁模式跳轉後，由 ReaderViewBuilder 負責將 isRestoring 設為 false
    }

    if (pageTurnMode != PageAnim.scroll && !isRestoringJump) notifyListeners();
  }

  /// 根據頁碼計算捲動像素 (用於目錄跳轉等場景)
  double calcScrollOffsetForPageIndex(int pageIndex) {
    if (pages.isEmpty || pageIndex <= 0) return 0.0;
    final headOffset = scrollHeadOffset;
    double cumHeight = 0;
    for (int i = 0; i < pageIndex.clamp(0, pages.length - 1); i++) {
      final page = pages[i];
      cumHeight += page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
    }
    return headOffset + cumHeight;
  }

  /// 根據字元偏移量尋找對應頁碼
  int findPageIndexByCharOffset(int charOffset) {
    int targetPage = 0;
    for (int i = 0; i < pages.length; i++) {
      final firstLineOffset = getCharOffsetForPage(i);
      if (firstLineOffset <= charOffset) {
        targetPage = i;
      } else {
        break;
      }
    }
    return targetPage;
  }

  /// 延遲恢復閱讀位置：在 doPaginate() 完成後呼叫
  void applyPendingRestore() {
    if (pendingRestorePos == null || pages.isEmpty) return;
    final pos = pendingRestorePos!;
    pendingRestorePos = null;

    if (pageTurnMode == PageAnim.scroll) {
      initialTargetY = calcScrollOffsetForCharOffset(pos);
      isRestoring = false; // Zero-Jump: 已經算出初始坐標，解除恢復狀態
    } else {
      jumpToPosition(charOffset: pos, isRestoringJump: true);
    }
  }

  /// 統一進度儲存：同時更新 DB 與 in-memory book 物件
  /// durChapterPos 儲存字元偏移量（TextLine.chapterPosition），對標 Android Legado 行為
  /// 捲動模式：精確儲存視窗頂端可見行，而非頁首行（修正「向下移半個窗口」問題）
  void saveProgress(int chapterIndex, int pageIndex) {
    final title = chapters.isNotEmpty && chapterIndex < chapters.length
        ? chapters[chapterIndex].title
        : null;
    final charOffset = (pageTurnMode == PageAnim.scroll)
        ? getCharOffsetForScrollY(lastScrollY)
        : getCharOffsetForPage(pageIndex);
        
    book.durChapterIndex = chapterIndex;
    book.durChapterPos = charOffset;
    book.durChapterTitle = title;
    _lastSavedCharOffset = charOffset;
    unawaited(bookDao.updateProgress(book.bookUrl, chapterIndex, title ?? '', charOffset));
  }

  /// 返回 [pageIndex] 頁第一個文字行的 chapterPosition（字元偏移量）
  int getCharOffsetForPage(int pageIndex) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex >= pages.length) return 0;
    for (final line in pages[pageIndex].lines) {
      if (line.image == null) return line.chapterPosition;
    }
    return 0;
  }

  /// 計算捲動模式下 charOffset 對應的像素 Y 位置（用於開書恢復捲動位置）
  /// 包含 showHead 的 2px 偏移
  double calcScrollOffsetForCharOffset(int charOffset) {
    final headOffset = scrollHeadOffset;
    double cumHeight = 0;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
      
      // O(N) 降維優化：查表跳過整頁
      final pageStartOffset = getCharOffsetForPage(i);
      final pageEndOffset = pageStartOffset + (page.lines.isEmpty ? 0 : page.lines.last.chapterPosition + page.lines.last.text.length + 100);
      if (charOffset >= pageEndOffset) {
        cumHeight += pageHeight;
        continue;
      }

      for (final line in page.lines) {
        if (line.image == null && line.chapterPosition >= charOffset) {
          return (headOffset + cumHeight + line.lineTop).clamp(0.0, double.infinity);
        }
      }
      cumHeight += pageHeight;
    }
    return headOffset + cumHeight;
  }

  /// 捲動模式：由實際 scroll offset 反算視窗頂端第一個可見行的 chapterPosition
  /// 修正「向下移半個窗口」問題：儲存視窗頂端行而非頁首行
  int getCharOffsetForScrollY(double scrollY) {
    if (pages.isEmpty) return 0;
    final headOffset = scrollHeadOffset;
    double cumHeight = 0;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
      
      // O(N) 降維優化：查表跳過整頁
      if (headOffset + cumHeight + pageHeight <= scrollY) {
        cumHeight += pageHeight;
        continue;
      }

      for (final line in page.lines) {
        if (line.image != null) continue;
        // 行的底部絕對 Y（包含 headOffset）
        final lineAbsBottom = headOffset + cumHeight + line.lineBottom;
        if (lineAbsBottom > scrollY) {
          return line.chapterPosition;
        }
      }
      cumHeight += pageHeight;
    }
    return getCharOffsetForPage(0);
  }

  /// 捲動模式：由 ReaderViewBuilder 在捲動時輕量更新當前可見頁（不寫 DB、不 notify）
  void updateScrollPageIndex(int i) {
    if (i < 0 || i >= pages.length) return;
    currentPageIndex = i;
    final pageChapterIndex = pages[i].chapterIndex;
    if (currentChapterIndex != pageChapterIndex) {
      currentChapterIndex = pageChapterIndex;
    }
  }
}
