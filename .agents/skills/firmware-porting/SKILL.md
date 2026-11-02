---
name: firmware-porting
description: 在不同晶片、板級、框架或產品間移植嵌入式韌體功能。適用功能對照、硬體與架構差異分析、逐項實作及行為對等驗證。
---

# Firmware Porting

## 建立對照
- 先從 `../../context-index.md` 確認來源基準、目標程式碼、規格與驗證證據。
- 建立「功能／來源位置／目標落點／差異／驗證」對照；來源基準不是必填，但缺少時不得宣稱行為完全對等。

## 必做差異
- 晶片：pin、clock、memory、interrupt、peripheral、power domain 與 register 語意。
- 板級：pinmux、polarity、default state、電源、sensor、外部 IC 與連線。
- 架構：init、scheduler、ISR、thread、callback、driver model、設定與 logging。
- 驗證：來源如何證明功能，目標如何建立等價證據。

## 方法
1. 依相依關係排序 work item，先完成 build、初始化與共用介面。
2. 一次移植一個可驗證功能，不直接平移 delay、ISR、全域旗標或 register 常數。
3. 對硬體相關值回到權威 SPEC／schematic；無證據時停止並列出缺口。
4. 靜態比較來源與目標路徑，再以 build、log、測試或波形驗證。
5. 每個移植項目的影響、各目標平台涵蓋與未解析項目依 `../../templates/impact-analysis.md` 記錄。

## 專門技能
- ITE EC 跨晶片或 legacy／Zephyr 移植，額外讀取 `../ite-ec-porting/SKILL.md`。
- 控制器行為另搭配對應的領域技能。
