# project.md — 模組母版專案設定

> 本 repository 是嵌入式韌體 AI 協作模組的母版，不是產品韌體專案。
> `pack.ps1` 刻意排除本檔；新專案必須由範本建立自己的 `project.md`。

## 專案識別
- 專案識別：`zhanlu-source`
- Repository：本目錄
- 產品類型：AI 協作模組母版
- 目前 work item：`none`

## 控制器與架構
- 控制器領域：不適用；母版可支援 EC、PD、Lighting、Keyboard 與其他嵌入式控制器。
- 目標晶片：不適用。
- 韌體架構：不適用。
- 建置系統：不適用。

## 專案能力
- Build：不適用。
- Test：`powershell -ExecutionPolicy Bypass -File .\verify-zhanlu.ps1 -PackageSource`
- Regression：`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\regression.ps1`
- Package：`powershell -ExecutionPolicy Bypass -File .\pack.ps1`
- 產出：`./dist/zhanlu-v4.10.0.7z`

## 支援工作類型
- Bug fix、程式碼整合、功能開發、韌體移植、硬體 bring-up、重構與程式碼審查。

## 啟用技能
- 母版維護時僅載入當前工作直接相關技能。
- 可攜套件包含 `module.json` 登記的全部任務型、領域型與 ITE 專門技能。

## 專案限制
- 母版不得包含任何產品專案的 SPEC、schematic、BOM、log、binary 或 golden reference；可攜核心不得包含本機實體路徑。
- 作用中專案層可記錄本機選用工具的實體路徑並註明理由；這些設定不進可攜套件，新專案需自行登記。
- `.agents/resources/` 與 `.agents/reference-projects/` 在母版只保留自我保護的 `.gitignore`。
- 作用中的 `project.md`、`context-index.md` 與 `TODO.md` 不得進入可攜套件。

## 載入驗證碼
- 本次驗證碼：`ZHANLU-V4-F6C3C4`
- 本章節置於最末，作為完整載入 sentinel；複製到新專案時必須產生新碼。
