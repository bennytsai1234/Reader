# 閱讀器規格

這份文件只記錄目前 `main` 已經存在、可驗證的閱讀器規格。

## 範圍

閱讀器的正式範圍是：

1. 閱讀頁 UI 殼
2. `slide` / `scroll` 兩種閱讀模式
3. 進度保存與還原
4. 切章
5. 影響排版的閱讀設定
6. TTS 與自動翻頁
7. 閱讀中換源

## Durable Location

閱讀器目前的唯一 durable location 是：

- `chapterIndex + charOffset`

這表示：

- 書籍長期進度不以 `pageIndex` 為真源
- restore / repaginate / mode switch 都必須回到這個語義

## 使用者可感知的行為

### 開書與重進

- 打開書籍時，會依 `Book.chapterIndex` / `Book.charOffset` 還原
- 關閉再進後，應回到相同章節與合理的章內位置

### `slide` / `scroll`

- 只支援這兩種模式
- 切換模式時不應丟失閱讀位置語義
- 同一位置切換模式後，應保持同一個 `charOffset`

### 切章

- 章尾進下一章應落到下一章章首
- 章首回上一章時，行為由 runtime 契約控制，不靠頁面殼硬補

### 設定變更

會觸發排版重算的設定包括：

- 字級
- 行距
- 段距
- 縮排
- 其他影響分頁的閱讀設定

設定變更後：

- 重新分頁
- 位置回推仍以 durable location 為準

### TTS 與自動翻頁

- TTS 可從當前可見位置開始
- TTS progress 會回推 highlight / page follow
- 自動翻頁在 `slide` 與 `scroll` 下各有對應執行路徑

### 換源

- 閱讀失敗時可走自動換源或手動換源
- 切換來源後會保留書籍會話與閱讀位置語義

## 明確非目標

目前閱讀器不承諾：

- 第三種以上翻頁模式
- Android-only 工具頁
- 與 RSS 共享同一套閱讀 flow
- 僅為了模仿 Legado 而加入的額外功能

## 驗證基線

目前文檔要求的最低驗證基線是：

```bash
flutter analyze
flutter test test/features/reader
```

CI 不把 `flutter run` / 啟動 smoke 當作強制條件；互動體感仍需人工實測驗收。
