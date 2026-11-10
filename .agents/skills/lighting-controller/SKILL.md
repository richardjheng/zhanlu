---
name: lighting-controller
description: LED／RGB／背光控制器韌體領域知識。適用 PWM、constant-current、pattern engine、色彩、功耗、熱限制與主控制器同步。
---

# Lighting Controller

## 必要事實
- 確認 LED 拓樸、driver 型號、channel mapping、供電、最大電流、PWM／scan 頻率、色彩順序與校正資料。
- 從 `../../context-index.md` 取得 schematic、driver SPEC、光效需求與量測限制。

## 檢查面
- 初始化期間的 default off／亮度、reset、open／short fault 與 brownout 行為。
- PWM resolution、frequency、gamma、dithering、current limit 與低亮閃爍。
- Pattern／frame buffer 更新的 atomicity、同步、DMA／interrupt 與 race condition。
- Power state、thermal derating、battery mode、sleep leakage 與喚醒恢復。
- 主控制器命令、版本相容性、資料長度與錯誤回覆。

## 間接關係追查
關係類型定義見 `../../templates/impact-analysis.md`；Lighting 常見的間接路徑：
- **共享資料（多方寫入）**：power source 事件、power state、host／panel 命令與 pattern 狀態機都可能寫同一組 PWM duty 或模式旗標；列出所有寫入者與先後順序，確認模式切換時誰負責恢復輸出。
- **ISR→main**：呼吸或 pattern 狀態機可能同時由 timer ISR 與 main service 推進；確認呼叫來源、頻率與共享狀態保護。
- **共享資料**：保存的設定值（例如百分比）與硬體暫存器原始值（DCR）單位不同；停止 pattern 時不會自動回寫設定值。
- **模式契約**：PWM 多寫入者與 override 恢復見第 4 組，pattern 狀態機跨 ISR／main 見第 1 組（`../architecture-design/patterns.md`）。

## 驗證
- 除功能目視外，量測頻率、duty、電流、功耗、溫升與長時間 pattern 穩定性。
- 色彩或亮度結論需註明校正工具、環境與容差。
