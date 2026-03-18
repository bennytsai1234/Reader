import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';

/// ReaderProvider 的基礎狀態與 DAO 定義
abstract class ReaderProviderBase extends ChangeNotifier {
  final BookDao bookDao = getIt<BookDao>();
  final ChapterDao chapterDao = getIt<ChapterDao>();
  final ReplaceRuleDao replaceDao = getIt<ReplaceRuleDao>();
  final BookSourceDao sourceDao = getIt<BookSourceDao>();
  final BookSourceService service = BookSourceService();
  final BookmarkDao bookmarkDao = getIt<BookmarkDao>();
  final StreamController<int> jumpPageController = StreamController<int>.broadcast();
  final StreamController<double> scrollOffsetController = StreamController<double>.broadcast();
  /// 捲動模式 trim 補償：從頂部移除章節頁面後，需向上偏移等量像素才能維持視覺位置
  /// 值為正數，代表「向上移動 N 像素」
  final StreamController<double> scrollTrimAdjustController = StreamController<double>.broadcast();


  final Book book;
  BookSource? source;
  List<BookChapter> chapters = [];
  int currentChapterIndex = 0;
  int currentPageIndex = 0;
  String content = '';
  List<TextPage> pages = [];
  Size? viewSize;
  final Set<int> loadingChapters = {};
  final Set<int> silentLoadingChapters = {}; // 新增：用於追蹤靜默預加載，不觸發 UI 轉圈
  bool get isLoading => loadingChapters.isNotEmpty;

  bool showControls = false;
  int scrubbingChapterIndex = -1;
  int pivotChapterIndex = -1; // 捲動模式的雙向 SliverList 中心錨點章節

  /// 新增：是否正在恢復閱讀進度（跳轉中）
  bool isRestoring = false;

  /// 點擊區域動作映射 (對標 Android clickAction)
  /// 0: 菜單, 1: 下一頁, 2: 上一頁, 3: 下一章, 4: 上一章, 5: 朗讀, 7: 書籤
  List<int> clickActions = [2, 1, 1, 2, 0, 1, 2, 1, 1];

  final Map<int, List<TextPage>> chapterCache = {};
  final Map<int, String> chapterContentCache = {};
  List<Bookmark> bookmarks = [];

  // 精準更新組件
  final ValueNotifier<int> batteryLevelNotifier = ValueNotifier<int>(100);
  final ValueNotifier<double> autoPageProgressNotifier = ValueNotifier<double>(0.0);

  ReaderProviderBase(this.book);

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    jumpPageController.close();
    scrollOffsetController.close();
    scrollTrimAdjustController.close();
    batteryLevelNotifier.dispose();
    autoPageProgressNotifier.dispose();
    super.dispose();
  }

}

