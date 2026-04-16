# 貢獻指南

感謝你對墨頁 Inkpage 的關注。以下說明如何有效地參與貢獻。

## 開始之前

- 閱讀 [README.md](README.md) 了解專案定位
- 閱讀 [docs/architecture.md](docs/architecture.md) 了解模組邊界
- 確認你的 Flutter SDK 版本符合 `pubspec.yaml` 中的 `sdk: ^3.7.0`

## 回報問題

在開 Issue 前，請先搜尋是否已有相同問題。使用 Issue 模板填寫：

- **Bug 回報**：提供複現步驟、預期行為、實際行為、裝置資訊與日誌
- **功能請求**：說明使用情境，以及為什麼現有功能無法滿足

> 目前專案的長期目標是**優化 8 項基礎功能**，暫不接受新功能的功能請求。詳見 [docs/roadmap.md](docs/roadmap.md)。

## 開發環境設定

```bash
# 1. Fork & Clone
git clone https://github.com/<your-username>/reader.git
cd reader

# 2. 安裝依賴
flutter pub get

# 3. 生成 Drift 程式碼（修改 table 定義後必跑）
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 確認環境
flutter doctor
flutter analyze
flutter test
```

## 提交 Pull Request

### 分支命名

| 類型 | 格式 | 範例 |
|------|------|------|
| 修復 bug | `fix/<簡短描述>` | `fix/tts-highlight-clear` |
| 重構 | `refactor/<模組>` | `refactor/reader-coordinator` |
| 文件 | `docs/<主題>` | `docs/database-schema` |
| 測試 | `test/<對象>` | `test/chapter-content-manager` |

### PR 規範

1. **一個 PR 只做一件事** — 不要把重構與修復混在同一個 PR
2. **必須通過 CI**：`flutter analyze` 零問題、`flutter test` 全數通過
3. **附上測試**：修復 bug 請附回歸測試；新邏輯請附單元測試
4. **描述清楚變更動機**：PR 說明要讓 reviewer 能在不看程式碼的情況下理解為什麼要改

### 提交訊息格式

遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hant/):

```
<type>(<scope>): <short summary>

[optional body]
```

類型：`feat` / `fix` / `refactor` / `test` / `docs` / `chore`

範例：
```
fix(reader): clear highlight immediately when TTS chapter ends

Prevents stale highlight persisting on screen when the chapter
finishes but the next chapter hasn't started yet.
```

## 程式碼規範

- 遵循 `analysis_options.yaml` 的 lint 規則，不得關閉警告
- 狀態管理一律使用 Provider，**禁止引入第二套**
- DB 操作統一走 DAO；UI 不直接碰 DAO、檔案路徑或平台 API
- `await` 後使用 `context` 前必加 `if (!mounted) return;`
- 不加不必要的 docstring、type annotation 或 comment — 只在邏輯不自明時才加
- 路徑統一經 `core/storage/AppStoragePaths`

## 常見問題

**Q: 修改了 Drift table 定義，build_runner 要怎麼跑？**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Q: 測試怎麼跑單一檔案？**
```bash
flutter test test/features/reader/read_book_controller_test.dart
```

**Q: 書源規則邏輯要怎麼對照 Android 原版？**

參考 `../legado/app/src/main/java/io/legado/app/model/analyzeRule/`，Flutter 實作在 `lib/core/engine/`。
