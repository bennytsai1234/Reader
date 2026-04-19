# Source Audit Backlog

Updated: 2026-04-19

## Goal

把使用者提供的大型 Legado 書源清單，持續驗證到 `搜尋 -> 詳情 -> 目錄 -> 正文 -> 換章 -> 緩存/持續閱讀` 都可穩定運行，並把兼容缺口收斂成可回歸的 parser / JS bridge / tool 層修正。

## Current Track

1. 先穩住前 10 個來源，確認失敗是站點失效、規則兼容缺口，還是審計工具誤判。
2. 把已知兼容類型沉澱成單元測試，再擴到 `11-20`、`21-50` 的批量驗證。
3. 對剩餘失敗來源做分類修復，必要時對齊 Legado 行為。

## Baseline: Sources 1-10

- Latest rerun summary: `8/10` passed.

- Passed:
  - `#1` BB成人小说
  - `#2` 🎓 爱丽丝书屋
  - `#3` 随心看吧
  - `#4` 🎃酷匠阅读🎃
  - `#6` 五六中文
  - `#7` 🎃轻之文库🎃
  - `#8` 阅友小说🎃#2
  - `#9` SF轻小说🎃#2
- Failed:
  - `#5` ♜ ✎笔趣阁⑬⑥ #破冰1101
    - `POST` `Content-Type` 兼容已修，手動關鍵詞如 `龙族` 可正常出結果。
    - 目前剩餘問題是 audit 自動選詞仍可能挑到站點不穩定的書名關鍵詞，需再收斂。
  - `#10` AAA小说
    - 站點可連。
    - audit 關鍵詞發現仍未命中，需補更多 browse/explore 關鍵詞策略。

## Baseline: Sources 11-20

- Latest confirmed status: `7/10` passed.
  - `#20` 八叉书库已於單源 live 驗證中確認通過。
  - `11-20` 全批重跑仍受書源鏡像 timeout 影響，待鏡像恢復後再補完整 batch 統計。

- Passed:
  - `#12` 五六中万
  - `#14` 🎃读书网🎃
  - `#15` 新笔趣阁 wap2.xinbiquge.org
  - `#16` ❤️五六中文 破冰
  - `#18` 阅友小说🎃
  - `#19` 🎃笔趣阁🎃
  - `#20` 八叉书库
- Failed:
  - `#11` 爱优漫🎃
    - TLS 憑證過期，屬站點側問題。
  - `#13` 🎃一个阅读🎃
    - 關鍵詞探測命中 404，偏向站點路由已變或規則已失效。
  - `#17` ❤️酷我小说
    - `cache.getFile/putFile` 兼容已補。
    - headless 測試環境仍會遇到 `path_provider` plugin 缺失；即使略過後，主站 API `http://appi.kuwo.cn/novels/api/book` 目前也是 404，偏向站點側失效。

## Completed Foundations

- 批量連網審計工具已支持 `SOURCE_START` / `SOURCE_LIMIT`。
- 書源兼容已補上：
  - `POST` 字串 body 預設 `application/x-www-form-urlencoded; charset=utf-8`。
  - 相對 URL 轉絕對 URL。
  - CSS current-element / `:root` / `@html` 多節點合併。
  - `exploreUrl` async JS。
  - JS `source.key/source.tag`、`Jsoup` shim、`java.getString`、`java.put`。
  - JS `java.log` 明確回傳原值，對齊 Legado 的 branch completion 行為。
  - JS `cache.getFile` / `cache.putFile` alias。
  - JS `JavaImporter` / `Base64` / `GZIPInputStream` / `ByteArrayOutputStream` shim。
  - JS `strToBytes` / `bytesToStr` / `base64DecodeToByteArray` / `gzipToString` byte-array 語義。
  - JSON item 裸欄位規則 fallback。
  - JsonPath 陣列展平。
  - 搜尋列表可選欄位失敗不再整批中止。
  - `java.get('scopeKey')` 不再被 async rewriter 誤判成網路呼叫。
  - sync / async JS wrapper 改為保留更多 completion value 語義。
  - CSS `:contains(...)` 與未加引號的 attribute selector 相容。
  - JS response `header("location")`、redirect chain 與 redirect URL fallback。
  - `##...###` 同時兼容「只取捕獲組」與「只替換第一個命中」兩種語義。
  - audit 正文探測會跳過疑似鎖章，並從目錄前後兩端尋找一對可讀章節。
  - XPath `@class="..."` 兼容與壞 HTML 重複引號清洗。

## Next Queue

1. 收斂剩餘的 audit 關鍵詞來源。
   - `#5` 笔趣阁：自動選詞穩定度。
   - `#10` AAA：站點連線 / browse 選詞。
2. 將 `#11` / `#13` / `#17` 標記為站點側失效候選，避免持續投入 parser 修補。
3. 擴大批量審計到 `21-50`。
4. 把新的 live 結果持續回填到這份 backlog。

## Execution Commands

```bash
LD_LIBRARY_PATH="/home/benny/.pub-cache/hosted/pub.dev/flutter_js-0.8.7/linux/shared:${LD_LIBRARY_PATH}" \
SOURCE_LIMIT=10 flutter test tool/source_batch_validation_test.dart -r expanded

LD_LIBRARY_PATH="/home/benny/.pub-cache/hosted/pub.dev/flutter_js-0.8.7/linux/shared:${LD_LIBRARY_PATH}" \
SOURCE_START=10 SOURCE_LIMIT=10 flutter test tool/source_batch_validation_test.dart -r expanded
```
