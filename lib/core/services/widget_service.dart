import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:legado_reader/core/models/book.dart';

/// WidgetService - 桌面小組件服務 (iOS WidgetKit / Android AppWidget)
/// 負責同步當前閱讀書籍的數據至原生 UserDefaults / SharedPreferences
class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  // App Group ID (需在 Xcode 中配置)
  static const String appGroupId = 'group.io.legado.reader';
  static const String iOSWidgetName = 'LegadoRecentWidget';

  /// 更新小組件顯示的書籍數據
  Future<void> updateRecentBook(Book book, {String? lastChapterTitle, double progress = 0.0}) async {
    try {
      // 1. 保存數據到共享區域 (原 Android RemoteViews 數據流)
      await HomeWidget.saveWidgetData<String>('recent_book_name', book.name);
      await HomeWidget.saveWidgetData<String>('recent_book_author', book.author);
      await HomeWidget.saveWidgetData<String>('recent_book_cover', book.getDisplayCover() ?? '');
      await HomeWidget.saveWidgetData<String>('recent_book_last_chapter', lastChapterTitle ?? '');
      await HomeWidget.saveWidgetData<double>('recent_book_progress', progress);
      await HomeWidget.saveWidgetData<String>('recent_book_url', book.bookUrl);

      // 2. 通知原生側更新 Widget
      // 僅在 iOS 端執行，Android 端目前尚未實作 AppWidgetProvider 類別，避免報錯
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.updateWidget(
          iOSName: iOSWidgetName,
        );
      }
      
      AppLog.d('Widget data updated for: ${book.name}');
    } catch (e) {
      AppLog.e('Failed to update widget data: $e', error: e);
    }
  }

  /// 註解：在 iOS 端實作時，原生 Swift 代碼需要：
  /// 1. 讀取 App Group 中的 UserDefaults。
  /// 2. 使用 WidgetKit 渲染 UI。
  /// 3. 處理點擊事件 (URL Scheme: legado://openBook?url=...)
}

