# Reader 2026-04 Design Archive

這個目錄保留 2026-04 reader 重構討論期的設計稿、修復計劃、review 計劃與實作順序。

這些文件已經不是目前 docs 主入口。reader 主幹已落地後，請先讀：

```text
docs/README.md
docs/reader_current_state.md
docs/reader_mobile_test_plan.md
```

## 文件狀態

- `reader_repair_plan.md`：重構前的總修復方案。
- `reader_implementation_order.md`：實作順序與 sub-agent 建議。
- `reader_review_plan.md`：review 拆分方式與 review prompt。
- `reader_visible_location_design.md`：visible location / saveProgress 設計。
- `reader_restore_design.md`：開書恢復設計。
- `reader_layout_coordinate_design.md`：layout 與座標 mapping 設計。
- `reader_page_cache_render_design.md`：PageCache / RenderTile 設計。
- `reader_scroll_canvas_window_design.md`：scroll canvas window 設計。
- `reader_overlay_gesture_design.md`：overlay / gesture / TTS highlight 設計。

如果 archive 內容和目前程式碼不一致，以目前程式碼與 `docs/reader_current_state.md` 為準。
