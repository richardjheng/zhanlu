---
name: keyboard-controller
description: Keyboard Controller 韌體領域知識。適用 matrix scan、debounce、ghosting、Fn／hotkey、HID／PS2、背光協調與低功耗喚醒。
---

# Keyboard Controller

## 必要事實
- 從 `../../context-index.md` 確認 matrix rows／columns、diode 方向、KSO／KSI pin、scan rate、layout／SKU、host protocol 與 wake 需求。
- 區分鍵盤掃描、key mapping、hotkey policy、host report 與 lighting 互動層。

## 檢查面
- GPIO direction、idle level、settling、scan period、debounce、repeat 與 rollover。
- Ghost／mask、diode topology、stuck key、短路與開機按鍵處理。
- Fn layer、特殊鍵、地區／SKU table、N-key／6KRO 與 report ordering。
- USB HID／PS2／ACPI event／vendor command 的 protocol 與 reset recovery。
- S3／S5／deep sleep 掃描策略、wake key、功耗與恢復後首鍵行為。

## 間接關係追查
關係類型定義見 `../../templates/impact-analysis.md`；Keyboard 常見的間接路徑：
- **table dispatch**：matrix table、SKU／地區 table、Fn layer 與 hotkey 表以索引查表；修改一個鍵需追所有表與切換條件。
- **ISR→main**：KSI interrupt／wake 只觸發掃描排程，實際掃描、debounce 與 report 在 main 或 thread；確認 sleep 狀態下的路徑。
- **協定契約**：scan code、HID usage、ACPI Q-event 與 vendor command 編號由 host 端解讀，與 BIOS／驅動共用。
- **條件編譯**：KSO 擴充、SKU 與板級設定決定實際掃描腳位；各 SKU 需各自展開確認。
- **模式契約**：KSI 中斷延後掃描見第 1 組，debounce 見第 2 組，matrix／hotkey 表見第 5 組（`../architecture-design/patterns.md`）。

## 驗證
- 使用 matrix 測試、長按／多鍵／快速輸入、protocol trace、sleep wake 與不同 SKU 回歸。
- 修改 scan timing 時同步驗證 CPU loading、功耗、debounce 與遺漏率。
