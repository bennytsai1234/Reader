# 貢獻指南

這份文件描述目前 `main` 的實際開發方式。

## 先讀哪些文件

- [README.md](README.md)
- [docs/README.md](docs/README.md)
- 如果要改閱讀器：
  - [docs/reader_current_state.md](docs/reader_current_state.md)
  - [docs/reader_mobile_test_plan.md](docs/reader_mobile_test_plan.md)

## 環境需求

- Flutter stable
- Dart `^3.7.0`
- 可執行 `flutter analyze` 與 `flutter test`

## 本地初始化

```bash
git clone https://github.com/<your-username>/reader.git
cd reader
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

如果本機 Linux 測試需要 QuickJS shared library，可改用：

```bash
tool/flutter_test_with_quickjs.sh
```

## 變更後驗證

一般功能：

```bash
flutter analyze
flutter test
```

只改閱讀器：

```bash
flutter analyze
flutter test test/features/reader
```

改 Drift schema / DAO：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## 提交原則

- 一個 commit / PR 只解一個主問題。
- 行為改動要補對應測試。
- 可見規格改動要同步更新文件。
- 不保留已失效的 handoff、roadmap 或階段性執行稿。

## 文件規則

文件只能描述 `main` 上已存在、可被程式碼驗證的事實。

需要同步更新文件的改動：

- reader runtime / progress / layout / viewport：`docs/reader_current_state.md`
- reader 手機實測流程：`docs/reader_mobile_test_plan.md`
- 專案文件入口：`docs/README.md`
- 逐版變更：`release-notes/vX.Y.Z.md`

## 程式碼規則

- 狀態管理維持 Provider / ChangeNotifier，不引入第二套全域狀態框架。
- DB 操作經由 DAO / Drift，不直接在 UI 層拼 SQL。
- 閱讀器 durable location 是 `ReaderLocation(chapterIndex, charOffset, visualOffsetPx)`。
- 修改閱讀器時，先確認目前主線是 `ReaderPage -> ReaderRuntime -> ChapterRepository/PageResolver -> Viewport`。
- 新的書源解析邏輯放在 `core/engine/` 對應子目錄。

## 發版相關

Release 由 tag 觸發，不是手動改 `pubspec.yaml` 後上傳產物。

目前流程：

1. `main` 上完成改動並通過驗證。
2. 可選：撰寫 `release-notes/vX.Y.Z.md`。
3. 推送 tag `vX.Y.Z`。
4. `build-release.yml` 回寫 `pubspec.yaml` 版本到 `main`，建 Android / iOS artifacts，並發佈 GitHub Release。

逐版說明放在 [release-notes/](release-notes/)。
