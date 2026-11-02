---
name: pd-controller
description: USB Type-C／USB Power Delivery 控制器韌體領域知識。適用 attach、role、PDO、contract、VDM、保護、韌體更新與主控制器資料交換。
---

# PD Controller

## 必要事實
- 從 `../../context-index.md` 確認 PD controller 型號與 revision、port 拓樸、CC／VBUS 路徑、power role、data role、PDO、保護 IC 與通訊介面。
- 規範版本、vendor register map 與產品 power budget 不可混用。

## 檢查面
- Attach／detach、DRP／Try role、source／sink state machine 與 debounce。
- Source／sink capability、RDO、contract 更新、hard／soft reset 與 error recovery。
- VBUS discharge、OVP／OCP／OTP、dead-battery、VCONN 與 cable／e-marker。
- Alt mode／VDM／UCSI／host command、interrupt、shared memory 或 I2C 交換。
- 多埠 power budget、charger／battery／EC 協調與 boot-time blocking。

## 間接關係追查
關係類型定義見 `../../templates/impact-analysis.md`；PD 常見的間接路徑：
- **事件或 hook**：charger 初始化完成、power state 轉換、flash tool 狀態等事件經 hook 或 event code 觸發 PD 動作；需追到事件來源與所有 handler，不只看直接呼叫。
- **table dispatch 與映射表**：邏輯 port 到晶片、I2C 位址、register 的對照表；同一 command 依 port 落到不同晶片時需逐一列出。
- **共享資料**：PD 共用的 I2C buffer、transport 與 contract 讀值被 power-path、充電限流與 host 回報共用；停用某個命令不可連帶移除共用 transport。
- **協定契約**：「不送命令」與「送 disable 命令」是不同操作；變更命令前確認 PD 韌體對寫入值的語意與持續性。

## 驗證
- 將 protocol trace、CC／VBUS waveform、contract、power role 與 fault injection 對應到需求。
- 不以單次成功充電取代不同方向、功率、線材與 recovery 路徑測試。
