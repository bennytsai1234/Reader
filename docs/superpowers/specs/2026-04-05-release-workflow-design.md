# Release Workflow Design

日期：2026-04-05

## 背景

專案目前缺少自動化發版流程。M1–M5 完成後，代碼品質與架構已收斂，下一步是建立可重複執行的 GitHub Actions release pipeline。

## 目標

- 推 tag 即觸發 build + release，不需要本機任何平台工具
- 產出 Android APK（給開發者自用）與未簽名 iOS IPA（給朋友用 AltStore 安裝）
- 版本號從 tag 讀取，自動寫入 pubspec.yaml，不需要手動維護

## 不在範圍內

- iOS 簽名與 Apple Developer 帳號相關設定
- TestFlight / App Store 發版
- Android Play Store 上架
- 自動化測試（現有 CI 另外處理）

## 架構

### Workflow 觸發條件

```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

### Job 圖

```
push tag v*.*.*
    │
    ▼
[inject-version]  ubuntu-latest
  - 從 tag 解析版本號
  - 寫入 pubspec.yaml
  - git commit + push（不帶 tag，不觸發二次 workflow）
    │
    ├──────────────────────────────────┐
    ▼                                  ▼
[build-android]  ubuntu-latest    [build-ios]  macos-latest
  flutter build apk --release       flutter build ipa --no-codesign
  → upload APK artifact             → upload IPA artifact
    └──────────────────────────────────┘
                    │
                    ▼
           [create-release]  ubuntu-latest
             - download APK + IPA artifacts
             - gh release create $TAG
             - release notes 讀取 release-notes/vX.Y.Z.md
             - 上傳 APK + IPA
```

## 各 Job 細節

### inject-version

**執行環境**：`ubuntu-latest`

**版本注入邏輯**：

```bash
VERSION="${GITHUB_REF_NAME#v}"   # e.g. v0.1.7 → 0.1.7
BUILD="${{ github.run_number }}" # GitHub 自動遞增
sed -i "s/^version: .*/version: $VERSION+$BUILD/" pubspec.yaml
```

**Git push**：

```bash
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add pubspec.yaml
git commit -m "chore: bump version to $VERSION+$BUILD [skip ci]"
git push
```

`[skip ci]` 標記確保這個 commit 不觸發其他 workflow。

**防止二次觸發**：inject-version 只做 commit push，不推 tag，workflow 的觸發條件為 `tags: ['v*.*.*']`，因此不會重新觸發。

**傳遞更新後的 pubspec.yaml**：inject-version 結束前用 `actions/upload-artifact` 上傳 pubspec.yaml。build-android 與 build-ios 在 checkout 後立即用 `actions/download-artifact` 下載並覆蓋本地 pubspec.yaml，確保拿到正確版本號。這樣 build jobs 仍 checkout tag（取得完整代碼），同時使用 CI 注入的版本資訊。

### build-android

**執行環境**：`ubuntu-latest`

**步驟**：
1. `actions/checkout`（含 submodules）
2. `subosito/flutter-action`，指定 Flutter stable channel
3. `flutter pub get`
4. `flutter build apk --release`
5. `actions/upload-artifact`，上傳 `app-release.apk`

**artifact 路徑**：`build/app/outputs/flutter-apk/app-release.apk`

### build-ios

**執行環境**：`macos-latest`

**步驟**：
1. `actions/checkout`
2. `subosito/flutter-action`
3. `flutter pub get`
4. `flutter build ipa --no-codesign`
5. `actions/upload-artifact`，上傳 IPA

**IPA 路徑**：`build/ios/ipa/*.ipa`

**無簽名說明**：`--no-codesign` 產出未簽名 IPA，朋友使用 AltStore 安裝時 AltStore 會以朋友自己的 Apple ID 重新簽名。

### create-release

**執行環境**：`ubuntu-latest`

**步驟**：
1. `actions/download-artifact`，下載 APK + IPA
2. 讀取 `release-notes/vX.Y.Z.md`（若不存在則用空 body）
3. `gh release create $TAG --title "$TAG" --notes-file ... APK IPA`

**release notes 讀取邏輯**：

```bash
NOTES_FILE="release-notes/${GITHUB_REF_NAME}.md"
if [ -f "$NOTES_FILE" ]; then
  gh release create "$TAG" ... --notes-file "$NOTES_FILE"
else
  gh release create "$TAG" ... --notes ""
fi
```

## Secrets

不需要任何 Secrets。`GITHUB_TOKEN` 為 GitHub Actions 內建，`gh` CLI 自動使用。

## 發版 SOP

```
1. 撰寫 release-notes/vX.Y.Z.md
2. git add . && git commit -m "chore: prepare vX.Y.Z"
3. git tag vX.Y.Z
4. git push && git push --tags
```

CI 接手，約 25 分鐘後 GitHub Releases 頁面出現 Android APK 與 iOS IPA 下載連結。

## 成功判斷標準

- push tag 後 workflow 自動觸發，不需要手動操作
- pubspec.yaml 版本號與 tag 一致
- GitHub Releases 頁面有 APK 與 IPA 兩個 artifact
- 朋友可從 Releases 下載 IPA 並透過 AltStore 安裝
- 發版流程可在 SOP 四步內完成
