# Release Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完善 GitHub Actions release pipeline，加入 tag 驅動版本注入、release notes 讀取，並修復現有 CI 的 Flutter 指令錯誤。

**Architecture:** `build-release.yml` 已有平行 Android + iOS build 結構，只需在最前面插入 `inject-version` job，並讓 build jobs 使用注入後的 pubspec.yaml artifact。`dart.yml` 需從 Dart 指令改為 Flutter 指令。`publish-release` job 改為讀取 `release-notes/vX.Y.Z.md`。

**Tech Stack:** GitHub Actions, Flutter stable, `subosito/flutter-action@v2`, `actions/upload-artifact@v4`, `actions/download-artifact@v4`, `softprops/action-gh-release@v2`

---

## 檔案清單

| 操作 | 路徑 | 說明 |
|------|------|------|
| Modify | `.github/workflows/dart.yml` | 修復 Dart → Flutter 指令 |
| Modify | `.github/workflows/build-release.yml` | 加入 inject-version、release notes 讀取 |
| Create | `release-notes/v0.1.7.md` | 第一份 release notes |

---

## Task 1：修復 dart.yml（Flutter CI）

`dart.yml` 目前使用 `dart-lang/setup-dart`、`dart pub get`、`dart analyze`、`dart test`，在 Flutter 專案上全部失效。

**Files:**
- Modify: `.github/workflows/dart.yml`

- [ ] **Step 1：確認目前 CI 是壞的**

  在本機執行（驗證指令本身正確）：
  ```bash
  cd /home/benny/.openclaw/workspace/projects/reader
  flutter analyze
  flutter test
  ```
  Expected: 兩個指令都通過（363 tests pass, 0 analyze issues）

- [ ] **Step 2：覆寫 dart.yml**

  將 `.github/workflows/dart.yml` 全部內容替換為：

  ```yaml
  name: Flutter CI

  on:
    push:
      branches: ["main"]
    pull_request:
      branches: ["main"]

  jobs:
    test:
      runs-on: ubuntu-latest

      steps:
        - uses: actions/checkout@v4

        - name: Set up Flutter
          uses: subosito/flutter-action@v2
          with:
            channel: stable
            cache: true

        - name: Install dependencies
          run: flutter pub get

        - name: Analyze
          run: flutter analyze

        - name: Test
          run: flutter test
  ```

- [ ] **Step 3：Commit**

  ```bash
  git add .github/workflows/dart.yml
  git commit -m "fix(ci): replace dart commands with flutter in CI workflow"
  ```

---

## Task 2：加入 inject-version job

在 `build-release.yml` 最前面加入 `inject-version` job，從 tag 讀取版本號，寫入 pubspec.yaml，commit 回 repo，並上傳 pubspec.yaml 為 artifact 供後續 build jobs 使用。

**Files:**
- Modify: `.github/workflows/build-release.yml`

- [ ] **Step 1：在 `jobs:` 區塊最前面加入 inject-version job**

  在 `android-release:` 之前插入：

  ```yaml
    inject-version:
      name: Inject Version from Tag
      runs-on: ubuntu-latest
      steps:
        - name: Checkout
          uses: actions/checkout@v4

        - name: Inject version into pubspec.yaml
          if: startsWith(github.ref, 'refs/tags/')
          run: |
            VERSION="${GITHUB_REF_NAME#v}"
            BUILD="${{ github.run_number }}"
            sed -i "s/^version: .*/version: ${VERSION}+${BUILD}/" pubspec.yaml
            echo "Injected version: ${VERSION}+${BUILD}"
            grep "^version:" pubspec.yaml

        - name: Commit version bump
          if: startsWith(github.ref, 'refs/tags/')
          run: |
            VERSION="${GITHUB_REF_NAME#v}"
            BUILD="${{ github.run_number }}"
            git config user.name "github-actions[bot]"
            git config user.email "github-actions[bot]@users.noreply.github.com"
            git add pubspec.yaml
            git diff --cached --quiet || git commit -m "chore: bump version to ${VERSION}+${BUILD} [skip ci]"
            git push

        - name: Upload pubspec artifact
          uses: actions/upload-artifact@v4
          with:
            name: pubspec-yaml
            path: pubspec.yaml
  ```

  > `if:` 條件放在步驟層而非 job 層：artifact 永遠產出，讓 build jobs 在 `workflow_dispatch` 觸發時也能正常執行（使用現有 pubspec 版本號）。`git diff --cached --quiet ||` 防止版本號未變動時 commit 空 diff 報錯。

- [ ] **Step 2：讓 android-release 依賴 inject-version**

  在 `android-release:` job 加上 `needs`：

  ```yaml
    android-release:
      name: Android Release APK
      needs: inject-version
      runs-on: ubuntu-latest
  ```

- [ ] **Step 3：讓 ios-unsigned 依賴 inject-version**

  ```yaml
    ios-unsigned:
      name: iOS Unsigned Build
      needs: inject-version
      runs-on: macos-latest
  ```

- [ ] **Step 4：Commit**

  ```bash
  git add .github/workflows/build-release.yml
  git commit -m "feat(ci): add inject-version job to build-release workflow"
  ```

---

## Task 3：讓 build jobs 使用注入後的 pubspec.yaml

build-android 和 build-ios 各自 checkout tag（不含 inject-version 的 commit），需要在 `flutter pub get` 之前下載 artifact 覆蓋本地 pubspec.yaml。

**Files:**
- Modify: `.github/workflows/build-release.yml`

- [ ] **Step 1：在 android-release 的 Checkout 步驟後加入下載步驟**

  在 `android-release` job 的 `- name: Checkout` 之後、`- name: Set up Java` 之前插入：

  ```yaml
        - name: Download injected pubspec
          uses: actions/download-artifact@v4
          with:
            name: pubspec-yaml
            path: .
  ```

- [ ] **Step 2：在 ios-unsigned 的 Checkout 步驟後加入下載步驟**

  在 `ios-unsigned` job 的 `- name: Checkout` 之後、`- name: Set up Flutter` 之前插入：

  ```yaml
        - name: Download injected pubspec
          uses: actions/download-artifact@v4
          with:
            name: pubspec-yaml
            path: .
  ```

- [ ] **Step 3：驗證版本注入正確性（本機模擬）**

  ```bash
  cd /home/benny/.openclaw/workspace/projects/reader
  # 模擬 inject-version 的 sed 指令
  sed -i "s/^version: .*/version: 0.1.7+99/" pubspec.yaml
  grep "^version:" pubspec.yaml
  # Expected: version: 0.1.7+99

  # 還原
  git checkout pubspec.yaml
  grep "^version:" pubspec.yaml
  # Expected: version: 0.1.7+7
  ```

- [ ] **Step 4：Commit**

  ```bash
  git add .github/workflows/build-release.yml
  git commit -m "feat(ci): wire injected pubspec.yaml into android and ios build jobs"
  ```

---

## Task 4：更新 publish-release 讀取 release notes

`publish-release` job 目前使用 `generate_release_notes: true`，改為優先讀取 `release-notes/vX.Y.Z.md`，沒有時 fallback 到自動產生。

**Files:**
- Modify: `.github/workflows/build-release.yml`

- [ ] **Step 1：在 publish-release job 加入 Checkout 步驟**

  在 `publish-release` job 的最前面（`- name: Download Android artifact` 之前）插入：

  ```yaml
        - name: Checkout
          uses: actions/checkout@v4

        - name: Check for release notes
          id: notes
          run: |
            NOTES_FILE="release-notes/${GITHUB_REF_NAME}.md"
            if [ -f "$NOTES_FILE" ]; then
              echo "has_notes=true" >> $GITHUB_OUTPUT
              echo "notes_file=$NOTES_FILE" >> $GITHUB_OUTPUT
            else
              echo "has_notes=false" >> $GITHUB_OUTPUT
            fi
  ```

- [ ] **Step 2：將 Publish GitHub release 步驟拆成兩個條件步驟**

  刪除現有的 `- name: Publish GitHub release` 步驟，替換為：

  ```yaml
        - name: Publish GitHub release (with release notes)
          if: steps.notes.outputs.has_notes == 'true'
          uses: softprops/action-gh-release@v2
          with:
            files: |
              dist/app-release.apk
              dist/保安專用閱讀器-ios-unsigned.ipa
            body_path: ${{ steps.notes.outputs.notes_file }}

        - name: Publish GitHub release (auto notes)
          if: steps.notes.outputs.has_notes == 'false'
          uses: softprops/action-gh-release@v2
          with:
            files: |
              dist/app-release.apk
              dist/保安專用閱讀器-ios-unsigned.ipa
            generate_release_notes: true
  ```

- [ ] **Step 3：Commit**

  ```bash
  git add .github/workflows/build-release.yml
  git commit -m "feat(ci): read release-notes file in publish-release, fallback to auto"
  ```

---

## Task 5：建立第一份 release notes 與 SOP 說明

**Files:**
- Create: `release-notes/v0.1.7.md`

- [ ] **Step 1：建立 release-notes/v0.1.7.md**

  ```markdown
  ## v0.1.7

  ### 架構整理

  - M5：消除所有 widget 層直接呼叫 DAO 的情況，改由 Provider / Service 代理
  - 刪除兩個死碼檔（`bookmark_list_page.dart`、`local_book_provider.dart`）
  - 廢棄的 settings 擴展 mixin 合併進 `SettingsProvider`
  - `HttpTtsProvider` 提取為獨立 provider

  ### 品質

  - 363 tests 全通過
  - `flutter analyze` 零問題
  ```

- [ ] **Step 2：更新 README.md 的發版 SOP**

  在 README.md 加入（或更新）發版說明段落：

  ```markdown
  ## 發版流程

  1. 撰寫 `release-notes/vX.Y.Z.md`
  2. `git add . && git commit -m "chore: prepare vX.Y.Z"`
  3. `git tag vX.Y.Z`
  4. `git push && git push --tags`

  CI 自動觸發，約 25 分鐘後 GitHub Releases 頁面出現 Android APK 與 iOS IPA。
  ```

- [ ] **Step 3：Commit**

  ```bash
  git add release-notes/v0.1.7.md README.md
  git commit -m "docs: add v0.1.7 release notes and release SOP to README"
  ```

---

## Task 6：端對端驗證

- [ ] **Step 1：確認 workflow YAML 語法正確（本機）**

  ```bash
  # 安裝 actionlint（若未安裝）
  # macOS: brew install actionlint
  # Linux: bash <(curl https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash)
  actionlint .github/workflows/build-release.yml .github/workflows/dart.yml
  ```

  Expected: 無 error 輸出

- [ ] **Step 2：推 test tag 觸發 workflow**

  ```bash
  git tag v0.1.7
  git push --tags
  ```

  在 GitHub → Actions 頁面確認：
  - `inject-version` job 成功，pubspec.yaml commit 出現在 main branch
  - `android-release` 與 `ios-unsigned` 平行執行
  - `publish-release` 成功，GitHub Releases 頁面出現 APK + IPA

- [ ] **Step 3：確認 release notes 正確顯示**

  GitHub Releases 頁面的 body 應顯示 `release-notes/v0.1.7.md` 的內容，而不是自動產生的 commit 清單。

- [ ] **Step 4：更新 roadmap**

  在 `docs/roadmap.md` 的執行進度表中，將第 6 項標為 ✅：

  ```markdown
  | 6 | 平台能力與發版流程（GitHub Actions release pipeline） | ✅ 完成 |
  ```

  ```bash
  git add docs/roadmap.md
  git commit -m "docs: mark M6 release pipeline as complete"
  ```
