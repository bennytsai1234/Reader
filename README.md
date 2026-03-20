# Legado Reader (Flutter)

Flutter 閱讀器專案，當前最成熟的部分是文字閱讀 runtime。

目前閱讀器主鏈已完成一輪大重構，核心形狀是：

- 主控：`ReadBookController`
- 內容生命週期：`ReaderContentMixin -> ChapterContentManager`
- 章內 runtime：`ReaderChapter`
- 視圖執行層：`ReadViewRuntime -> ScrollModeDelegate / SlideModeDelegate`
- 朗讀：`ReadAloudController`

## 當前狀態

目前已落地的核心能力：

- `scroll / slide` 共用閱讀位置語義
- `restore / progress / TTS / auto page` 已走統一 command path
- `ReaderChapter` 已承接章內 offset、highlight、restore anchor、前後頁定位
- `ReadViewRuntime` 已明顯變薄，scroll execution / restore retry / visible strategy / TTS follow 已拆到對應 adapter 或 coordinator
- `ChapterContentManager` 已開始從 cache/preload manager 轉成 chapter lifecycle service

這表示閱讀器現在已經不是單純由多個 `mixin` 與 widget 邏輯拼起來，而是有一個相對穩定的 runtime 內核。

## 核心入口

- [read_book_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_book_controller.dart)
- [read_view_runtime.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/read_view_runtime.dart)
- [chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart)
- [reader_chapter.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/models/reader_chapter.dart)
- [read_aloud_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_aloud_controller.dart)

## 文檔入口

- [docs/README.md](/C:/Users/benny/Desktop/Folder/Project/reader/ios/docs/README.md)
- [reader_architecture_current.md](/C:/Users/benny/Desktop/Folder/Project/reader/ios/docs/reader_architecture_current.md)
- [next_refactor_roadmap.md](/C:/Users/benny/Desktop/Folder/Project/reader/ios/next_refactor_roadmap.md)
- [DATABASE.md](/C:/Users/benny/Desktop/Folder/Project/reader/ios/docs/DATABASE.md)

## 快速開始

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
