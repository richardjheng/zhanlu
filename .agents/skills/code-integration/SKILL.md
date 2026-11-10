---
name: code-integration
description: 整合 upstream、vendor SDK、patch、branch 或另一 repository 的韌體程式碼。適用來源追蹤、差異映射、衝突處理與介面相容性驗證。
---

# Code Integration

## 來源鎖定
- 在修改前記錄來源 repository、branch／tag／commit、授權與允許修改範圍。
- 從 `../../context-index.md` 確認來源權威性；來源不明或工作樹不乾淨時先列出風險。
- 來源預設唯讀，禁止為方便整合而修改 upstream 或 golden reference。

## 方法
1. 建立來源檔案／介面到目標落點的對照，不以同名函式認定行為相同。
2. 比較 public API、資料結構、設定、初始化順序、執行 context 與錯誤處理；兩邊採用的模式依 `../architecture-design/patterns.md` 對照契約。
3. 將衝突分類為機械衝突、架構差異、產品差異或行為衝突，再選擇保留、調整或拒絕。
4. 保持 patch 可追溯；必要時記錄來源 commit 與未採用部分的理由。
5. 先驗證局部介面，再執行整體 build 與受影響回歸。
6. 整合或移除功能的影響與變更範圍依 `../../templates/impact-analysis.md` 記錄；失去呼叫者的程式碼與固定位址預設保留但停用。

## 停止條件
- 無法確認來源版本、授權、目標介面契約或衝突語意時，不自行選邊。
- 整合結果若改變外部行為，必須取得需求依據並更新完成條件。
