import 'package:flutter/material.dart';

/// PageDelegate - 翻頁策略抽象基類
/// 對標 Android PageDelegate.kt 策略模式
abstract class PageDelegate {
  /// 建立翻頁視圖
  /// [currentPage] 當前頁內容 Widget
  /// [nextPage] 下一頁內容 Widget（可為 null）
  /// [prevPage] 上一頁內容 Widget（可為 null）
  /// [onNext] 翻到下一頁的回調
  /// [onPrev] 翻到上一頁的回調
  Widget build({
    required BuildContext context,
    required Widget currentPage,
    Widget? nextPage,
    Widget? prevPage,
    required VoidCallback onNext,
    required VoidCallback onPrev,
  });
}
