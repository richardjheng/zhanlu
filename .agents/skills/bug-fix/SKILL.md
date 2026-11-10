---
name: bug-fix
description: 嵌入式韌體 Bug 修正方法。適用異常重現、根因分析、最小修正與 regression 驗證；不把未確認原因的現象直接改寫成新功能。
---

# Bug Fix

## 必要輸入
- 從 `../../TODO.md` 取得症狀、範圍與完成條件。
- 從 `../../context-index.md` 取得問題版本、last-known-good、issue、log、waveform 與測試入口。
- 缺少可重現條件時，先建立最小觀察點或等價證據，不宣稱已找到根因。

## 方法
1. 固定重現條件，分開記錄預期、實際與發生率。
2. 沿資料流、狀態轉移、時序或硬體事件縮小第一個偏離點；問題涉及 ISR、狀態機、共享資料或輸出仲裁時，依 `../architecture-design/patterns.md` 檢查既有模式的契約。
3. 以程式碼、log、量測或版本差異證明根因；相關性不是根因。
4. 優先修正最早造成錯誤的地方，避免用下游遮蔽或全域 workaround。
5. 保留對失敗路徑敏感的 regression，並執行受影響介面的回歸驗證。
6. 影響範圍、變更範圍與未解析項目依 `../../templates/impact-analysis.md` 記錄；修正採最小變更，不順便清理。


## 量測證據格式
- 證據置於 `../../resources/evidence/<WORK-ITEM-ID>/`，並在 `../../context-index.md` 登記。
- LA 匯出以協定解碼後的 CSV 為首選，一列一筆 transaction，可直接推理；raw sample 匯出動輒數百萬列，無法解析。
- 只匯出出問題的時間窗，例如 reset 後 0 至 50 ms，不整份匯出。
- 每組量測必須附 `measurement-note.md`，記載 channel 對應到哪個 net、取樣率、觸發條件、板號，以及韌體快照：base commit、未提交修改的 diff SHA-256（無則寫無）、建置的 `CFG-xx` 與燒錄 binary 的 SHA-256；使用 `../../context-index.md` 登記的外部工具時，另記 `TOOL-xx` 與當次實際版本（commit 或版本號）。
- 使用外部工具或其 skill 燒錄、重置或量測時，授權與證據規則仍以 `AGENTS.md` 為準；工具 skill 不擴張授權，`TOOL-xx` 登記也不代表已授權。
- 快照與目前修改不符的量測，只能作為歷史參考，不可當作本次修改的驗證結果。
- 缺少 channel 對應表時只能報告訊號未知，不得自行推測哪個 channel 是哪個 pin。
- 取樣率不足會產生假的 glitch；未記載取樣率時，相關結論一律標示為受量測條件限制。
- 波形截圖只能佐證有無訊號與大致形狀，不可作為精確時序或脈寬的依據。

## 交付證據
- 重現方式或無法重現的限制。
- 根因位置與因果鏈。
- 修改為何足夠且沒有擴張行為。
- 修正前後結果、regression 與仍待實板項目。
