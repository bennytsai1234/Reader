# Source Audit Backlog

Updated: 2026-04-20

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

## Recent Window: Sources 89-96

- Latest confirmed status across two small reruns:
  - `#89-91`: `pass=1 / skip=2 / fail=0`
  - `#93-96`: `pass=3 / skip=1 / fail=0`

- Passed:
  - `#89` QQ阅读
    - 先前的 comment-prefixed JSON rule / JS parity 問題已修復。
  - `#93` 乡土小说
    - `POST -> 302 -> GET` 搜尋鏈路已 live 驗證通過。
  - `#94` 漫小肆20251217
  - `#95` 🎃阅友小说🎃#2
- Skipped:
  - `#90` 🎃连城读书🎃
    - 站點入口 `http://a.lc1001.com/false` 返回 404，偏向上游失效。
  - `#91` 破天小说
    - 目前關鍵詞 `我的` 搜尋結果為空，先歸為 `source-search-empty`，待更穩定的 browse/explore 選詞再確認。
  - `#96` 🚬 疯情书库
    - 已可到詳情與目錄，正文驗證卡在 headless `webview` 環境限制，歸為 `env-webview`。

- Known outlier:
  - `#92` 小小阅读/书香之家app
    - Rhino-style Java crypto 規則已補上大部分 shim，`createSymmetricCrypto(...)` 可解出正確內容。
    - 目前仍有單點 `Cipher.doFinal(...)` / 書源腳本語義差異，暫不阻塞整體擴窗驗證。

## Recent Window: Sources 100-115

- Latest confirmed status from serial 20s windows / single-source reruns:
  - `#100-109`: `pass=6 / skip=4 / fail=0`
  - `#110-111`: `pass=2 / skip=0 / fail=0`
  - `#112`: 站點在目前 20s 預算下仍會拖住搜尋 POST，暫列 timeout candidate，待專項排查。
  - `#113-115`: `pass=2 / skip=1 / fail=0`

- Passed:
  - `#101` 奇书网络
  - `#104` 第一版主网
  - `#105` 👔 疯情书库
    - 已修復 `java.ajax(...).replaceAll(...)` 這類帶 regex literal 的 async chained rule。
  - `#107` 💠 手机看书
  - `#108` 🎃顶点中文🎃
  - `#109` 中华诗词（优+）
  - `#110` 💠 望书阁网
  - `#111` 笔趣阁
  - `#114` 🎃笔趣阁🎃#15
  - `#115` 学外漫画
    - 已補 `unpack(...)` helper，可解 Dean Edwards packed JS 後還原漫畫圖片列表。

- Skipped:
  - `#100` 🎃宜搜小说🎃
    - `source-search-empty`
  - `#102` 🎃兔九三吧🎃
    - `source-search-mismatch`
  - `#103` 果露小说
    - `upstream-blocked` / 404
  - `#106` 茶杯狐狸（优+++）
    - parser / JS context 已修正，剩餘是 headless `path_provider` 缺件，歸 `env-path-provider`
  - `#113` 超星网站🎃#书源.com
    - `source-search-empty`

- New parity fixes validated in this window:
  - `book` / `chapter` scoped JS object bridge：
    - 補 `book.name` / `chapter.title` 等欄位讀取
    - 補 `book.getVariable/putVariable`、`chapter.getVariable/putVariable`
    - 補常見欄位回寫（如 `book.type`、`chapter.url/title`）
  - Java-style string parity：
    - `String.prototype.replaceAll`
    - `String.prototype.replaceFirst`
    - `String.prototype.contains`
    - `JavaString.replaceAll/replaceFirst/contains`
  - Async JS rewriter：
    - 修正 async call 參數中含 regex literal 時的括號匹配
  - Packed script helper：
    - 全域 `unpack(...)`

## Recent Window: Sources 120-139

- Latest confirmed status from serial 20s windows / single-source reruns:
  - `#120-129`: `pass=8 / skip=2 / fail=0`
  - `#130-139`: `pass=8 / skip=2 / fail=0`

- Passed:
  - `#120` 夜天连看🎃
  - `#122` 🎃笔趣阁🎃#18
  - `#124` 心动小说
  - `#125` 新笔趣阁
  - `#126` 七猫小说🎃
  - `#127` 旧钢笔
  - `#128` 冷冷文学
  - `#129` 🎃若初文学🎃
  - `#130` ❤️Woo18小说🎃
  - `#131` ❤️圣墟小说🎃
  - `#133` 五六中文（发现）
  - `#135` 西瓜书屋
  - `#136` 硬币女宝
  - `#137` 笔趣阁
  - `#138` 笔趣阁
  - `#139` 笔趣阁

- Skipped:
  - `#121` 顶点小说
    - `env-webview`
  - `#123` 全本同人
    - `env-webview`
  - `#132` 风扇枕说（日+）
    - `source-search-empty`
  - `#134` 爱轻写真（优+）
    - `source-search-empty`

- New parity / validation fixes validated in this window:
  - `AnalyzeRule.isUrl` 會保留 `,{"headers":...}` 這類 AnalyzeUrl 參數尾綴，不再把 JSON 選項 URL-encode。
  - `java.put/java.get` source-scoped persistence 打通，`#126` 這類跨規則傳 headers 的書源可正常工作。
  - JS dynamic fragments 在 async 路徑改走 `makeUpRuleAsync(...)`，`{{java.importScript(...)}}` 等片段不再落回同步執行。
  - `importScript(...)` 以 browser-like wrapper 執行，UMD 腳本不再誤走 `require/module` 分支。
  - 補 `java.getElement / java.getElements` JS bridge，`#135` 這類正文重排腳本可直接取 DOM 列表。
  - 詳情頁 HTML 會回用為 TOC 首頁，`tocUrl == bookUrl` 的來源不再重打一遍詳情頁。
  - validator 目錄驗證改用有限章節數，並同步把 `ChapterListParser` 補成 sync fast path，避免大目錄來源被審計成本誤判為 fail。

## Recent Window: Sources 140-159

- Latest confirmed status from serial 20s windows / single-source reruns:
  - `#140-149`: `pass=6 / skip=4 / fail=0`
  - `#150-159`: `pass=5 / skip=5 / fail=0`
  - `#160-169`: `pass=10 / skip=0 / fail=0`
  - `#170-179`: `pass=5 / skip=3 / fail=2`

- Passed:
  - `#141` 瀚海书阁
  - `#142` 📖PO18文
  - `#143` 笔趣阁2345-夜明空
  - `#144` SHF笔趣阁
  - `#145` po18文学壬二酸
  - `#149` 精华书阁手机版
  - `#152` 笔趣阁
  - `#154` 笔趣阁
  - `#157` 错层小说网
  - `#158` 宠耳小说
  - `#159` Icu

- Skipped:
  - `#140` 英语阅读（英）
    - `source-search-empty`
  - `#146` ❤️飘天文学org🎃
    - `source-search-empty`
  - `#147` 英语阅读（英）
    - `source-search-empty`
  - `#148` 独步小说
    - `env-webview`
  - `#150` ❤️笔趣阁²
    - `source-marked-broken`
  - `#151` 🎃笔趣阁🎃#12
    - `source-search-empty`
  - `#153` ❤️天悦小说
    - `source-search-empty`
  - `#156` 八一
    - `source-search-empty`

- Resolved:
  - `#155` 👍 笔趣阁¹
    - `java.connect(...).raw().request().url()` parity 已補齊。
    - 單源回驗已可 `PASS` 完整鏈路；窗口刷新時偶發 `503`，目前應視為 `upstream-blocked` 噪音，不再當 parser canary。
  - `#161` 🎃顶点小说🎃#4
    - CSS 結構 pseudo parity 已補齊，`#list@dt:nth-of-type(2)~a` 這類目錄規則已可過。
  - `#167` 悦读小说（繁体）
    - JSON map 動態 URL 組裝與 root-array JsonPath (`$.[*]`) parity 已補齊，已可完整 PASS。

- Current canaries:
  - `#171` 全本小说quanben
    - `toc` 階段仍拿不到可閱讀章節，訊號偏向 `jsonp` / 目錄拼接鏈。
  - `#179` 悸花阅读
    - 目前停在 `keyword` 階段的 URL `FormatException`，偏向 `AnalyzeUrl` / URL 組裝輸入正規化問題。

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
  - JS `java.getElement` / `java.getElements` bridge。
  - JS `java.connect(...).raw().request().url()` / `code()` / `message()` / `isSuccessful()` parity。
  - bare-origin response URL 正規化，補齊 OkHttp/Legado 末尾 `/` 語義。
  - CSS `:nth-of-type` / `:nth-child` / `:eq` / `first|last-child` 結構 pseudo parity。
  - CSS compat selector / compound parse 快取與 simple selector fast path，避免大目錄頁卡死。
  - JSON 動態 URL 規則在 `Map` 輸入下直接回組裝後字串，不再誤送入 XPath。
  - JsonPath root-array `$.[*]` 語法兼容。
  - `##...###` 同時兼容「只取捕獲組」與「只替換第一個命中」兩種語義。
  - audit 正文探測會跳過疑似鎖章，並從目錄前後兩端尋找一對可讀章節。
  - XPath `@class="..."` 兼容與壞 HTML 重複引號清洗。
  - 書籍詳情頁 HTML / TOC 首頁 HTML 回用。
  - validator 限制大目錄章節樣本數，避免審計成本誤判。

## Next Queue

1. 優先拆 `#171` 全本小说quanben 的 `toc/jsonp` canary。
2. 再拆 `#179` 悸花阅读 的 URL `FormatException` canary。
3. 持續擴窗驗證 `180+`，優先抓新的真 fail canary。
4. 收斂剩餘的 audit 關鍵詞來源。
   - `#5` 笔趣阁：自動選詞穩定度。
   - `#10` AAA：站點連線 / browse 選詞。
5. 將 `#11` / `#13` / `#17` 標記為站點側失效候選，避免持續投入 parser 修補。

## Execution Commands

```bash
LD_LIBRARY_PATH="/home/benny/.pub-cache/hosted/pub.dev/flutter_js-0.8.7/linux/shared:${LD_LIBRARY_PATH}" \
SOURCE_LIMIT=10 flutter test tool/source_batch_validation_test.dart -r expanded

LD_LIBRARY_PATH="/home/benny/.pub-cache/hosted/pub.dev/flutter_js-0.8.7/linux/shared:${LD_LIBRARY_PATH}" \
SOURCE_START=10 SOURCE_LIMIT=10 flutter test tool/source_batch_validation_test.dart -r expanded
```
