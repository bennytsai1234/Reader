import 'dart:convert';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import '../book.dart';

/// Book 業務邏輯擴展
extension BookLogic on Book {
  void overwriteFrom(Book other) {
    bookUrl = other.bookUrl;
    tocUrl = other.tocUrl;
    origin = other.origin;
    originName = other.originName;
    name = other.name;
    author = other.author;
    kind = other.kind;
    customTag = other.customTag;
    coverUrl = other.coverUrl;
    coverLocalPath = other.coverLocalPath;
    customCoverUrl = other.customCoverUrl;
    customCoverLocalPath = other.customCoverLocalPath;
    intro = other.intro;
    customIntro = other.customIntro;
    charset = other.charset;
    type = other.type;
    group = other.group;
    latestChapterTitle = other.latestChapterTitle;
    latestChapterTime = other.latestChapterTime;
    lastCheckTime = other.lastCheckTime;
    lastCheckCount = other.lastCheckCount;
    totalChapterNum = other.totalChapterNum;
    durChapterTitle = other.durChapterTitle;
    chapterIndex = other.chapterIndex;
    charOffset = other.charOffset;
    readerAnchorJson = other.readerAnchorJson;
    durChapterTime = other.durChapterTime;
    wordCount = other.wordCount;
    canUpdate = other.canUpdate;
    order = other.order;
    originOrder = other.originOrder;
    variable = other.variable;
    readConfig = other.readConfig;
    syncTime = other.syncTime;
    isInBookshelf = other.isInBookshelf;
    infoHtml = other.infoHtml;
    tocHtml = other.tocHtml;
  }

  void setVariable(String key, String value) {
    var map = variableMap;
    map[key] = value;
    variable = jsonEncode(map);
  }

  /// 轉換為 SearchBook (原 Android Book.toSearchBook)
  SearchBook toSearchBook() {
    return SearchBook(
      name: name,
      author: author,
      kind: kind,
      bookUrl: bookUrl,
      origin: origin,
      originName: originName,
      type: type,
      wordCount: wordCount,
      latestChapterTitle: latestChapterTitle,
      coverUrl: coverUrl,
      intro: intro,
      tocUrl: tocUrl,
      originOrder: originOrder,
      variable: variable,
    );
  }

  /// 書籍遷移邏輯 (原 Android Book.migrateTo)
  Book migrateTo(Book newBook, List<BookChapter>? toc) {
    var alignedIndex = chapterIndex;
    if (toc != null && toc.isNotEmpty) {
      alignedIndex = _getDurChapter(
        chapterIndex,
        durChapterTitle,
        toc,
        totalChapterNum,
      );
    }

    return newBook.copyWith(
      chapterIndex: alignedIndex,
      durChapterTitle:
          (toc != null && alignedIndex < toc.length)
              ? toc[alignedIndex].title
              : durChapterTitle,
      charOffset: charOffset,
      durChapterTime: durChapterTime,
      group: group,
      order: order,
      customCoverUrl: customCoverUrl,
      customIntro: customIntro,
      customTag: customTag,
      canUpdate: canUpdate,
      readConfig: readConfig,
      isInBookshelf: isInBookshelf,
    );
  }

  int _getDurChapter(
    int oldIndex,
    String? oldName,
    List<BookChapter> newChapters,
    int oldTotalNum,
  ) {
    if (oldIndex <= 0) return 0;
    if (newChapters.isEmpty) return oldIndex;

    final newSize = newChapters.length;
    // 1. 按名稱匹配
    if (oldName != null && oldName.isNotEmpty) {
      for (var i = 0; i < newSize; i++) {
        if (newChapters[i].title == oldName) return i;
      }
    }

    // 2. 按章節序號匹配 (例如 "第123章")
    final oldChapterNum = _extractChapterNum(oldName);
    if (oldChapterNum != null) {
      for (var i = 0; i < newSize; i++) {
        if (_extractChapterNum(newChapters[i].title) == oldChapterNum) return i;
      }
    }

    // 3. 按百分比估算
    var estimateIndex = oldIndex;
    if (oldTotalNum > 0) {
      estimateIndex = (oldIndex * newSize / oldTotalNum).round();
    }

    return estimateIndex.clamp(0, newSize - 1);
  }

  int? _extractChapterNum(String? title) {
    if (title == null) return null;
    final match = RegExp(r'第\s*(\d+)\s*[章節篇回集話]').firstMatch(title);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }
}
