---
name: hardware-bringup
description: 新晶片、新板或新控制器韌體 bring-up。適用從權威文件建立安全的最小啟動路徑，逐步啟用周邊並以 log、量測與波形驗證。
---

# Hardware Bring-up

## 進場條件
- 從 `../../context-index.md` 確認 silicon／board revision、SPEC、schematic、power tree、build、flash 與 debug 路徑。
- 缺少會影響供電、boot strap、reset 或 pin safety 的資料時，不驅動未知輸出。

## 啟用順序
1. 確認工具鏈、最小映像、燒錄、reset 與 console。
2. 確認 clock、memory、watchdog 與基本 fault path。
3. 以安全 default state 初始化 pinmux／GPIO，再逐個啟用周邊。
4. 依 power tree 與相依關係啟用外部 IC、電源與通訊介面。
5. 每一步保留可觀察 checkpoint，失敗時回到最後已知正常狀態。

## 證據
- 記錄韌體版本、板號、供電與量測條件。
- 將 console、register dump、電壓、時序與波形對應到完成條件。
- Build 或 UART 輸出正常不等於整板功能驗證完成。
- 修改初始化或序列時，影響與變更範圍依 `../../templates/impact-analysis.md` 記錄，步驟表、延遲與等待條件逐項比對；有界等待與 watchdog 的契約見 `../architecture-design/patterns.md`。


## 量測證據格式
- 證據置於 `../../resources/evidence/<WORK-ITEM-ID>/`，並在 `../../context-index.md` 登記。
- LA 匯出以協定解碼後的 CSV 為首選，一列一筆 transaction，可直接推理；raw sample 匯出動輒數百萬列，無法解析。
- 只匯出出問題的時間窗，例如 reset 後 0 至 50 ms，不整份匯出。
- 每組量測必須附 `measurement-note.md`，記載 channel 對應到哪個 net、取樣率、觸發條件、板號，以及韌體快照：base commit、未提交修改的 diff SHA-256（無則寫無）、建置的 `CFG-xx` 與燒錄 binary 的 SHA-256。
- 快照與目前修改不符的量測，只能作為歷史參考，不可當作本次修改的驗證結果。
- 缺少 channel 對應表時只能報告訊號未知，不得自行推測哪個 channel 是哪個 pin。
- 取樣率不足會產生假的 glitch；未記載取樣率時，相關結論一律標示為受量測條件限制。
- 波形截圖只能佐證有無訊號與大致形狀，不可作為精確時序或脈寬的依據。

## 停止條件
- 偵測過流、異常溫升、電壓跌落、未知 pin drive 或 reset loop 時停止擴大啟用範圍。
