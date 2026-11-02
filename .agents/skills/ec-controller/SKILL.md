---
name: ec-controller
description: Embedded Controller 韌體領域知識。適用 power state、host interface、keyboard、battery、charger、thermal、fan、ACPI 與板級事件的分析、修改或驗證。
---

# EC Controller

## 邊界地圖
- 先確認 host interface（eSPI／LPC）、power states、ACPI EC space、GPIO／wake、keyboard、battery／charger、thermal／fan 的實際落點。
- 以 `../../context-index.md` 登記的 EC SPEC、schematic、GPIO table、power sequence 與 host 文件為準。

## 交叉影響
- GPIO default、polarity、wake 與 interrupt 可能直接影響 power rail、PWRBTN#、LID 與 AC presence。
- G3／S5／S3／S0 狀態、host reset、VW／SCI／SMI、ACPI event 與初始化順序必須一起檢查。
- Battery、charger、thermal、fan policy 必須綁定正確 power state、sensor channel 與保護條件。
- Keyboard matrix、debounce、Fn hotkey、SKU table 與 host event 必須區分掃描層與平台事件層。

## 間接關係追查
關係類型定義見 `../../templates/impact-analysis.md`；EC 常見的間接路徑：
- **table dispatch**：power sequence 步驟表、service table、IRQ vector table 以函式指標執行；搜尋函式名只會找到表項，需再追 dispatcher 與步驟編號、delay、等待旗標。
- **ISR→main**：timer ISR 多半只設 service flag，實際工作在 main loop 的 service table；同一 hook 可能同時被 ISR 與 main 呼叫，需確認執行 context。
- **共享資料或記憶體別名**：EC RAM、ACPI EC space、H2RAM 欄位常以巨集定義位址；同一位址的 byte／word 別名、高低位元組順序與 SMBus 寫回寬度必須逐一對齊。
- **條件編譯**：平台或板級標頭、`CONFIG_*` 衍生開關與 `#ifndef` 預設值決定實際路徑；每個平台需各自展開確認。
- **協定或暫存器契約**：GPIO 表的 ALT／INPUT 設定、ACPI Q-event 編號、host command 欄位，與外部 BIOS／工具共用。

## 驗證
- 除 build 外，依功能提供 host 行為、EC log、GPIO／power waveform、battery／charger trace 或 fan／thermal 量測。
- 未取得實板證據時，明確限制為靜態路徑驗證。
