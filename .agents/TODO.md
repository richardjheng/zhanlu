# TODO.md — 模組母版工作追蹤

- 專案識別：`zhanlu-source`
- 當前 work item：`none`

## Work items
| ID | 工作類型 | 功能域 | 項目 | 相依 | 狀態 | 完成條件 |
|---|---|---|---|---|---|---|
| KIT-001 | 重構 | AI 協作模組 | 將 ITE EC 移植母版泛化為跨控制器、跨工作類型模組 | 無 | 完成 | 結構、技能、安裝、驗證、打包全部通過 |
| KIT-002 | Bug fix | Antigravity 載入 | 修正 workspace rule 未引用共用核心並完成三工具環境驗收 | KIT-001 | 完成 | Antigravity 規則可追溯至 `AGENTS.md`、regression 通過、三工具驗收有明確證據 |
| KIT-003 | 文件／封裝 | 可攜套件 | 新增套件根目錄 README，重建可直接安裝到其他專案的 7z | KIT-002 | 完成 | README 位於封裝根目錄、不覆蓋目標 README、乾淨與既有 README 目標安裝通過、封裝清單與完整性通過 |
| KIT-004 | Bug fix | 資料邊界 | 為 `.agents/resources/` 與 `.agents/reference-projects/` 隨套件提供 gitignore 保護 | KIT-003 | 完成 | 目標專案安裝後掛載點內容預設不進版控、不覆蓋目標根 `.gitignore`、驗證與安裝通過 |
| KIT-005 | 功能開發 | 安裝工具 | `setup-ai-module.ps1` 新增 `-Update` 升級模式，保留專案層三份作用中文件 | KIT-004 | 完成 | 升級只覆寫可攜檔案、作用中文件零改動、無可攜檔案時拒絕升級、乾淨安裝行為不變 |
| KIT-006 | 功能開發 | 技能 | 新增 `architecture-design` 與 `firmware-code-review` 技能並補齊路由表 | KIT-005 | 完成 | canonical skill、Claude loader、`module.json`、`AGENTS.md` 與 `.agents/README.md` 路由一致且驗證通過 |
| KIT-007 | 文件／封裝 | 可攜套件 | README 補前置需求、技能清單、升級與故障排除，版本升版並重建 7z | KIT-006 | 完成 | README 內容與實作一致、版本號一致、乾淨安裝與升級安裝實測通過、封裝清單與完整性通過 |
| KIT-008 | 文件 | 可攜套件 | README 補「套用到新專案要填什麼、資料放哪」的逐步指引 | KIT-007 | 完成 | 三份專案層文件的填寫欄位、資料放置位置與首次啟動驗收皆有明確指引，且母版驗證通過 |
| KIT-009 | 功能開發 | 專案層 schema | project.md 欄位收斂為 enum／pattern，並由 AI 於啟動確認驗證 | KIT-008 | 完成 | schema 寫入 module.json、範本改寫、AGENTS.md 補欄位驗證與技能自動推導、README 同步 |
| KIT-010 | 功能開發 | 資料邊界 | 目標專案安裝的模組一律不進版控 | KIT-009 | 完成 | 安裝時寫入目標 .git/info/exclude、verify 以 git ls-files 檢出誤追蹤、AGENTS.md Git 規則改寫、README 補風險警告 |
| KIT-011 | 重構 | 模組識別 | 模組更名為湛盧 zhanlu，五層名稱統一並處理既有安裝遷移 | KIT-010 | 完成 | 名稱五層一致、舊標記可自動清除、舊版套件升級不洩漏、封裝與驗證通過 |
| KIT-012 | 文件 | 可攜套件 | README 補 GitHub clone 安裝通道，明確區分「取得模組」與「安裝模組」 | KIT-011 | 完成 | clone 流程、`zhanlu/` 排除缺口、驗收方式與故障排除皆有指引，母版驗證通過 |
| KIT-013 | Bug fix／重構 | 安裝工具 | 安裝器自動排除 kit 目錄、修正 exclude 區塊堆疊、兩支腳本更名為 zhanlu | KIT-012 | 完成 | 區塊永遠一組、kit 在目標內自動排除且在目標外不多寫規則、更名可由舊版升級遷移、封裝與驗證通過 |
| KIT-014 | 功能開發／文件 | 維護工具 | 新增 `clean-backups.ps1` 清除專案層備份，README 補「升級會動到什麼」對照 | KIT-013 | 完成 | 只刪 `.agents/.backup-*`、非安裝目錄拒絕執行、`-WhatIf`／`-KeepLatest` 正確、升級不動使用者資料有實測佐證、封裝與驗證通過 |
| KIT-015 | Bug fix | 維護工具 | `clean-backups.ps1` 從 clone 目錄執行時找錯 `.agents/` | KIT-014 | 完成 | 從 clone 執行會往上定位到已安裝專案並印出位置、指向 kit 時明確拒絕、既有選項行為不變 |
| KIT-016 | 功能開發 | 維護工具 | 新增 `update-zhanlu.ps1`，把 `git pull` + `-Update` 收成一行 | KIT-015 | 完成 | 免參數即可執行、自動定位專案、pull 失敗中止、非自有 clone 不誤 pull、選項可透傳、封裝與驗證通過 |
| KIT-017 | 文件／封裝 | 發布 | 建立 GitHub Release v4.6.0，附可攜套件 | KIT-016 | 完成 | tag 推送、release 建立、7z asset 上傳且 SHA-256 相符 |
| KIT-018 | 功能開發 | 專案層 schema | 「目標晶片」支援一顆或多顆 ITE IC 型號 | KIT-017 | 完成 | schema、範本與 README 語意一致；單顆／多顆／錯誤分隔／非法型號 regression 通過；母版驗證與封裝通過 |
| KIT-019 | Bug fix | 專案層 schema | 多顆目標晶片改用全形逗號 `，` 分隔 | KIT-018 | 完成 | schema、驗證、範本與 README 一致；全形逗號通過，頓號與半形逗號拒絕；母版驗證與封裝通過 |
| KIT-020 | 文件／封裝 | 發布 | 將已驗證的 v4.7.1 推送並發布 GitHub Release | KIT-019 | 完成 | main、annotated tag 與 Release 可查，下載回驗 asset 的大小、SHA-256 與 7z 完整性均通過 |
| KIT-021 | Bug fix／重構 | 三工具載入 | 修正 Antigravity rule 並精簡啟動工作紀錄 | KIT-020 | 完成 | 載入規則與 verifier 一致、歷史零遺失、封裝及安裝回歸通過 |
| KIT-022 | Bug fix | 安裝驗證 | 修正合法程式碼識別字被誤判為範本 token | KIT-021 | 完成 | 合法巨集通過、真正範本 token 拒絕、已安裝專案升級與封裝回歸通過 |
| KIT-023 | 文件／封裝 | 發布 | 將已驗證的 v4.8.1 推送並發布 GitHub Release | KIT-022 | 完成 | main、annotated tag 與 Release 可查，下載回驗 asset 的大小、SHA-256 與 7z 完整性均通過 |
| KIT-024 | Bug fix／文件 | 安裝與可攜邊界 | 修正路徑越界、跨專案忽略規則、維護腳本漏查、Agora 路徑與版控指引 | KIT-023 | 完成 | 根因回歸、隔離安裝升級、資料保留、母版與封裝驗證通過；中文 commit，不 push |
| KIT-025 | Bug fix | 共用核心 | Agora 導引改為三工具通用，不再要求所有工具以 codex 身分發言 | KIT-024 | 完成 | 核心與專案層不綁單一發言身分、verify 拒絕單一身分、regression 與封裝通過；中文 commit，不 push |
| KIT-026 | 重構 | 模組邊界 | 移除 zhanlu 對 Agora 的全部耦合，模組視 Agora 為不存在 | KIT-025 | 完成 | 核心、專案層、索引、文件、驗證與測試不再提及 Agora；套件零 Agora 字樣；regression 與封裝通過；中文 commit，不 push |
| KIT-027 | 文件／封裝 | 發布 | 將已驗證的 v4.8.4 推送並發布 GitHub Release | KIT-026 | 完成 | main、annotated tag 與 Release 可查，下載回驗 asset 的大小、SHA-256 與 7z 完整性均通過 |
| KIT-028 | 功能開發 | 影響分析 | 影響分析共同格式，含最小變更原則（要改／刻意保留休眠程式碼／不改） | KIT-027 | 完成 | 範本與七項任務技能引用同一格式；區分候選／已確認及未找到／未解析／未涵蓋；回放 6 題範圍擴大題數低於基準 4 題且無新增誤判無影響 |
| KIT-029 | 功能開發 | 影響分析 | 韌體關係分類寫入任務與領域技能 | KIT-028 | 完成 | 範本關係類型與五個領域技能「間接關係追查」名稱一致；母版驗證、regression 與封裝通過 |
| KIT-030 | 功能開發 | 影響分析 | 機種 × 晶片 × 設定 × 建置涵蓋矩陣範本 | KIT-028 | 完成 | context-index 範本新增矩陣，影響分析以 `CFG-xx` 判定涵蓋，矩陣外組合列為未涵蓋；新安裝產出矩陣；母版驗證、regression 與封裝通過 |
| KIT-031 | 功能開發 | 證據 | 證據綁定快照（base revision、diff hash、設定、工具版本）與失效判定 | KIT-028 | 完成 | 快照欄位與失效規則寫入範本、量測證據格式與文件；雜湊方法於隔離 repo 驗證；母版驗證、regression 與封裝通過 |
| KIT-032 | 功能開發 | 專案導覽 | context-index 專案導覽資料（入口、流程、模組） | KIT-029、KIT-030 | 完成 | 生成資料不升格為權威；不新增專案技能目錄 |
| KIT-034 | 功能開發 | 影響分析 | 補強最小變更原則，並加入「要改」依據必填與交付前自我檢查 | KIT-028 | 完成 | 範本規則與自我檢查一致；母版驗證、regression 與封裝通過；回放效果列為後續觀察，不作為本項門檻 |
| KIT-035 | 文件／封裝 | 發布 | 將已驗證的 v4.9.0 推送至 `richardjheng/zhanlu` 並發布 GitHub Release | KIT-032 | 完成 | main、annotated tag 與 Release 可查，下載回驗 asset 的大小、SHA-256 與 7z 完整性均通過 |
| KIT-033 | 功能開發 | 安裝工具 | `setup-zhanlu.ps1 -Uninstall` 解除安裝 | KIT-027 | 完成 | WhatIf 零寫入；只移除可確認歸屬檔案；保留作用中文件與證據及其忽略保護；回放 ite-tools 誤裝情境 |
| KIT-036 | 功能開發 | 模式契約 | MCU 韌體常見模式契約參考，供任務與領域技能辨識既有模式 | KIT-034 | 完成 | 參考檔列入白名單；任務與領域技能有讀取條件；檔頭明定非修改依據；三方審查無異議；母版驗證、regression 與封裝通過 |
| KIT-037 | 文件／封裝 | 發布 | 將已驗證的 v4.10.0 推送至 `richardjheng/zhanlu` 並發布 GitHub Release | KIT-036 | 完成 | main、annotated tag 與 Release 可查，下載回驗 asset 的大小、SHA-256 與 7z 完整性均通過 |
| KIT-038 | 功能開發 | 外部工具 | context-index 選用〈外部工具〉`TOOL-xx` 與量測紀錄的工具版本 | KIT-037 | 完成 | 範本與兩技能不點名工具；預設使用者層並保留鎖版例外；授權仍依 AGENTS.md；三方審查無異議；母版驗證與 regression 通過 |

## 已完成項目：KIT-038
- 範圍：`.agents/templates/context-index.md` 新增選用〈外部工具〉（TOOL-xx：用途、Skill、位置、版本、狀態）與說明；measurement-note 在使用已登記外部工具時記 `TOOL-xx` 與當次實際版本；bug-fix、hardware-bringup 量測證據格式同步，並明定外部工具或其 skill 不擴張授權；README 步驟 2 補說明。
- 決策（Agora 三方，`.agora/threads/20261110-083006-外部工具-skill-如-dlb4-control-的歸屬與管理/`）：外部工具 skill 由工具 repository 維護，預設裝在三工具使用者層；只有專案需固定工具版本時，才把工具與完整 skill 同版複製進專案，不得覆蓋模組受管檔且需使用者明確同意；zhanlu 核心不點名任何工具；登記不代表已安裝或已授權。
- 相關外部工作（不在本 repository）：dlb4_web `922ba2e` 新增 `tools/install-skill.ps1`（三工具使用者層登記、安裝紀錄、先檢查後修改、inherits 與篩選檢查）與 `locate_root.py`（取消寫死路徑、鎖版核對）；已在本機安裝，Codex 與 Antigravity 新 session 皆列出 dlb4-control。
- 已完成靜態驗證：`verify-zhanlu.ps1 -PackageSource` 通過；regression 92 項通過；`git diff --check` 通過。
- 仍待驗證：既有專案手動加入〈外部工具〉後的實際使用；版本號未升。

## 已完成項目：KIT-037
- 範圍：版本升為 4.10.0（`module.json`、`project.md`、兩份 README；README 中「v4.9.0 以前安裝」指舊版，保留）；推送 `main` 與 annotated tag `v4.10.0` 至 `richardjheng`，建立 Release 並上傳 `dist/zhanlu-v4.10.0.7z`。`origin` 未推送。
- 發布前驗證：`verify-zhanlu.ps1 -PackageSource` 通過（4.10.0，portableFiles 44）；regression 92 項通過；`git diff --check` 通過；`7z t` OK。
- 已完成：commit `8f3f264` 推送至 `richardjheng/main`，tag `v4.10.0` 指向同一 commit；Release「湛盧 v4.10.0」非草稿、非預發布，API `releases/latest` 為 v4.10.0。
- 下載回驗：51,257 bytes；SHA-256 `1C489E5D2A9C5A91AF6E6C04BBA928FF9FC7A1C63F18229C0CDF005979CD1CF1`，與本地一致；`7z t` Everything is Ok，44 個檔案。
- 仍待驗證：既有專案 `-Update` 升級實測；`patterns.md` 在真實專案的使用效果。

## 已完成項目：KIT-036
- 範圍：新增 `.agents/skills/architecture-design/patterns.md`，整理 C/C++ MCU 韌體五組模式契約（跨 context 傳遞、狀態機與有界等待、共享資料與硬體存取、輸出仲裁與恢復、靜態分派與編譯期約束）及 C++ 條件小節；列入 `module.json` 的 `portableFiles`。
- 定位：辨識專案既有模式並維持契約，不是修改或重構依據；違反契約但非需求或根因者列入影響分析第 6 節；不因本檔引入專案沒有的機制。
- 接線：architecture-design、firmware-code-review、firmware-porting、bug-fix、code-integration、hardware-bringup 各一句讀取條件；ec、pd、lighting、keyboard 領域技能各一行指向對應組別；README 技能段補說明。
- 決策（Agora 三方討論，`.agora/threads/20261110-072052-zhanlu-值得加入的-C-C-MCU-韌體-design-pattern/`）：採獨立參考檔而非內嵌技能（`.claude/skills/` 只是載入器，不需雙份）；C++ 保留條件小節，exception／RTTI／heap 依 `project.md`，不收 CRTP；debounce 與 hysteresis 分列；watchdog 以受監控工作的進度證據為條件；有界等待限需有界完成的操作；memory pool 區分儲存區建立與執行期借還。
- Codex 審查修正：轉移入口不限於表內；時段排程以實際期限判定、不強制拆分；RW／W1C 混合 register 依 SPEC 組合寫入值；區域 buffer 在確認對方完成後才安全；C++ 靜態初始化時機改為標準語意；SPSC index 原子性可由同步機制保護；常見錯誤加上適用條件。
- 已完成靜態驗證：`verify-zhanlu.ps1 -PackageSource` 通過（portableFiles 44）；`tests/regression.ps1` 92 項通過；`git diff --check` 通過；`pack.ps1 -OutDir` 至暫存目錄，44 個檔案且含 `patterns.md`。未覆寫 `dist/` 中已發布的 v4.9.0 套件。
- 仍待驗證：實際專案中 AI 依本檔審查或修改的效果；版本號未升，待下次發布處理。

## 已完成項目：KIT-035
- 範圍：推送 `main` 與 annotated tag `v4.9.0` 至 remote `richardjheng`（`richardjheng/zhanlu`），建立 Release 並上傳 `dist/zhanlu-v4.9.0.7z`；不改程式碼。`origin`（ITE-Richard/zhanlu）未推送。
- 方法：`gh` 以 `richardjheng` 帳號登入，權限 ADMIN；push 只在該次指令以 `-c credential.helper=!gh auth git-credential` 指定憑證，不修改全域 Git 設定。
- 已完成：`6091fd6` 推送至 `richardjheng/main`；tag `v4.9.0`（物件 `c266136`）指向同一 commit；Release「湛盧 v4.9.0」為非草稿、非預發布，並標為 latest，asset 狀態為 uploaded。
- 下載回驗：47,558 bytes；SHA-256 `F1041FAA3D51916CE97DB691EFE876FC155F5AE5598A668FDC77A6F22C4E7B0B`，與本地一致；`7z t` 回報 Everything is Ok，共 43 個檔案。
- 仍待驗證：既有專案的 `-Update` 實測、三工具 GUI 載入；`richardjheng` 尚無 v4.8.4 以前的 tag 與 Release。

## 已完成項目：KIT-032
- 範圍：
  - `templates/context-index.md` 新增〈專案導覽〉，類型分為模組、入口、流程，欄位含適用 CFG、來源、快照與狀態。
  - `templates/impact-analysis.md` 分析基準新增「起點」：先讀導覽並引用 `NAV-xx`。
  - `architecture-design` 盤點結果回寫導覽。
  - `README.md` 步驟 2 補充說明。
- 決策：工具產生的群集、流程或呼叫圖只能當候選，不得作為權威來源，也不得單獨決定模組邊界；程式碼變更後相關列改回待確認。不新增專案技能目錄，避開安裝後 `.agents/skills/` 唯讀的邊界。既有安裝需手動從範本加入。
- 已完成靜態驗證：`tests/regression.ps1` 92 項通過；`pack.ps1`（內含 `-PackageSource` 驗證）產出 `zhanlu-v4.9.0.7z`，47,555 bytes、43 個檔案；`git diff --check` 通過。
- 已完成動態驗證（腳本）：全新安裝的 `context-index.md` 含 `NAV-01`，技能目錄維持 11 個，安裝器驗證通過。

## 已完成項目：KIT-031
- 範圍：
  - `templates/impact-analysis.md`：「分析基準」改為必填快照（base commit、未提交修改的 diff SHA-256、untracked 檔名、分析時間），並加入失效規則；第 7 節自我檢查新增「快照一致」。
  - `bug-fix`、`hardware-bringup` 的 `measurement-note.md`：增列 diff SHA-256、`CFG-xx` 與燒錄 binary 的 SHA-256；快照不符的量測只能作為歷史參考。
  - `templates/context-index.md` 與 `README.md` 的證據說明同步修改。
- 決策：不新增腳本，以 `git diff HEAD --binary --output=<檔案>` 加上 SHA-256 作為通用做法；以 `--output` 寫檔，避免 shell 重導向改變內容。
- 已完成動態驗證（隔離 repo）：同一狀態的 hash 相同；內容改變後 hash 改變；乾淨工作樹的輸出為 0 bytes。測試中發現 `cmd /c` 的重導向會吃掉引號而沒有寫入檔案，另外 PowerShell 函式 `H` 被內建別名 `h`（Get-History）遮蔽；兩者都是測試寫法的問題，範本因此改為推薦 `--output`。
- 已完成靜態驗證：`tests/regression.ps1` 92 項通過；`pack.ps1`（內含 `-PackageSource` 驗證）產出 `zhanlu-v4.9.0.7z`，47,009 bytes、43 個檔案；`git diff --check` 通過。
- 一併修正：目標專案 replay 分支已依使用者要求刪除，規劃段的證據位置同步更新。

## 已完成項目：KIT-030
- 範圍：
  - `templates/context-index.md` 新增〈建置與設定矩陣〉，欄位為平台／機種、晶片、建置入口、設定來源、關鍵設定、狀態；規定執行期選擇與編譯期設定分開記錄，未列入的組合視為未涵蓋。
  - `templates/impact-analysis.md` 的分析基準與驗證計畫改以 `CFG-xx` 表示。
  - `README.md` 步驟 2 補充說明。
- 決策：矩陣屬於專案事實，放在專案層索引，不放進技能。`-Update` 不會改動作用中的 `context-index.md`，既有安裝需依 README 手動加入；不寫遷移腳本，以免改到使用者的作用中文件。
- 已完成靜態驗證：`tests/regression.ps1` 92 項通過；`pack.ps1`（內含 `-PackageSource` 驗證）產出 `zhanlu-v4.9.0.7z`，46,678 bytes、43 個檔案；`git diff --check` 通過。
- 已完成動態驗證（腳本）：在 scratchpad 全新安裝，產生的 `context-index.md` 含 `CFG-01`，安裝器驗證通過。

## 已完成項目：KIT-029
- 範圍：在 `ec-controller`、`pd-controller`、`lighting-controller`、`keyboard-controller`、`ite-ec-porting` 各新增「間接關係追查」段落，列出該領域常見的間接路徑與追查方式，並引用範本的類型定義；範本的關係類型新增「事件或 hook」。任務技能已在 KIT-028 引用範本，本項不重複修改。
- 內容來源：KIT-028 回放中實際出現的路徑，包括 power sequence 步驟表、timer ISR→main service、EC RAM 位址別名、平台標頭與 GPIO 表、charger→PD 事件、port→晶片映射、LightPipe 多方寫入與 ISR／main 雙入口。只寫成通用規則，不含專案名稱或路徑。Keyboard 段落沒有回放案例，依領域知識撰寫。
- 決策：依使用者指示以修改 zhanlu 為重點，完成條件由「回放第 2、6 題」改為靜態一致性與母版驗證。
- 已完成靜態驗證：5 個領域技能都引用範本；`tests/regression.ps1` 92 項通過；`pack.ps1`（內含 `-PackageSource` 驗證）產出 `zhanlu-v4.9.0.7z`，46,200 bytes、43 個檔案；`git diff --check` 通過。

## 已完成項目：KIT-034
- 範圍：只修改 `.agents/templates/impact-analysis.md`。
  - 新增規則：禁止新增需求外的介面或行為；禁止為一致性改型別；需求是移除功能時，移除入口與專用程式碼，共用部分保留。
  - 「要改」加上必填的依據欄，只能填「需求」或「根因」。
  - 新增第 7 節「交付前自我檢查」。
- 回放觀察（只加禁止性規則、尚未加入自我檢查時）：範圍過大仍為 3 題（GPI7、EPR、RSOC），與 KIT-028 相同，沒有變差；第 4 題第一次執行時 Codex 工具讀不到檔案，已重跑。據此改採必填依據與自我檢查。
- 決策：使用者指示以修改 zhanlu 為重點，不再以目標專案回放作為本項門檻；加入自我檢查後的回放效果，列為後續觀察。
- 已完成靜態驗證：`tests/regression.ps1` 92 項通過；`pack.ps1`（內含 `-PackageSource` 驗證）產出 `zhanlu-v4.9.0.7z`，44,946 bytes、43 個檔案；`git diff --check` 通過。

## 已完成項目：KIT-033
- 決策：改為在 `setup-zhanlu.ps1` 新增 `-Uninstall` 與 `-RemoveProjectLayer`，不另增第六支 `.ps1`；沿用 manifest、路徑安全檢查與 exclude 範圍邏輯，不修改 `AGENTS.md` 的唯讀清單。
- 行為：只刪除已安裝 manifest 列出的檔案；與範本相同的編輯器設定才刪除；預設保留三份作用中文件、`.backup-*` 與資料掛載點內容；exclude 只保留仍存在路徑的規則，其他安裝位置的區塊不動；刪除後變空的目錄會一併清掉；拒絕在 kit source、未安裝目錄，以及與 `-Update` 併用時執行。
- 已完成靜態驗證：parser errors 0、腳本維持 ASCII；`pack.ps1`（內含 `-PackageSource` 驗證）產出 `zhanlu-v4.9.0.7z`，44,661 bytes、43 個檔案；`git diff --check` 通過。
- 已完成動態驗證（腳本）：`tests/regression.ps1` 92 項通過，新增 25 項，涵蓋 WhatIf 零寫入、保留作用中文件雜湊與資料、資料仍受忽略、改過的設定保留、其他安裝不受影響、完整移除後不留 `.agents` 與 exclude 區塊，以及拒絕路徑。
- 仍待驗證：未在實際專案（例如 ite-tools）重跑，以隔離 fixture 代替。

## 已完成項目：KIT-028
- 範圍：新增可攜範本 `.agents/templates/impact-analysis.md`，6 個任務技能各加一行引用，`module.json` 白名單加入該範本，版本升為 v4.9.0；不修改 `AGENTS.md`。
- 已完成靜態驗證：在 `AGENTS.md` 改用 HEAD 版本的隔離 clone 中，`verify-zhanlu.ps1 -PackageSource` 通過（43 個檔案、11 個技能）；`tests/regression.ps1` 67 項通過；`pack.ps1` 產出 `zhanlu-v4.9.0.7z`，43,150 bytes、43 個檔案；`git diff --check` 通過。
- 回放對照（6 題題目與基準相同，改用 UTF-8，在乾淨的 detached worktree 執行，6 題都讀取了新範本）：修改範圍超出實際修正從 4 題降為 3 題，未新增誤判「無影響」。第 2 題改善為保留 SMBus 初始化與固定 RAM；第 3 題部分改善，已保留 RAM、enum、helper，並指出 unused warning；第 1、4 題仍有超出範圍的建議。
- 仍待改善：範本未明文禁止「新增需求以外的介面或行為」；第 4 題無視「不改型別」。建議另開 work item 補強，並以同一批回放案例驗證。
- 對照組報告：session scratchpad `replay2/out/`，未存入目標專案分支。
- 工作目錄另有 `agora install` 寫入 `AGENTS.md` 的區塊，含本機路徑，會使工作目錄的 `-PackageSource` 失敗；不屬於本項，未 stage，待使用者決定處理方式。

## 規劃：KIT-028～KIT-033（GitNexus 概念借鏡）
- 來源：與 Codex 兩輪唯讀討論，以及 2026-11-02 在使用者指定的 IT51526 EC 專案做的回放盲測。只借鏡 GitNexus 的概念；它採 PolyForm Noncommercial 授權，不複製其程式碼或技能文字，zhanlu 也不依賴該工具。
- 服務範圍：README 列出的七種工作，以及 EC、USB PD、Lighting、Keyboard 與 ITE 移植。
- 基準結果（現有方法，由 Codex 盲測、Claude 評分，共 6 題）：命中 26、部分命中 5、漏掉 1；誤判「無影響」0 題；修改範圍超出實際修正 4 題（eUSB2、EPR、RSOC、GPI7）。主要缺口是最小變更原則：休眠程式碼、unused 屬性、RAM 位址、layout 保留。
- 證據位置：原存於目標專案的本地分支 `zhanlu-replay/case1-gpi7`～`case6-lightpipe`，從未推送；2026-11-02 依使用者要求，連同 worktree 一併刪除。題目、報告與評分只剩 session scratchpad 的暫存副本，不保證保留。第 1、4、6 題的題目中文在傳送時亂碼，Codex 由英文關鍵字推出題意；第 2、3、5 題已用 UTF-8 重跑。
- 驗收方式：合成案例為必要條件；有已完成的真實案例時，以回放結果為加分證據。Keyboard 領域目前沒有案例，標為未涵蓋。
- 已有共識、不納入：固定使用者 gate、`project.md` 持久修改開關、硬體 MCP、zhanlu 自有 MCP server。

## 已完成項目：KIT-027
- 問題／需求：使用者要求 commit、push 並發布 release。
- 範圍：推送 `main` 與 annotated tag、建立 GitHub Release 並上傳 `dist/zhanlu-v4.8.4.7z`；不改程式碼。v4.8.2、v4.8.3 未單獨發布，其內容併入 v4.8.4 的說明。
- 方法：本機未安裝 `gh`；`git push` 走 Git Credential Manager，Release 建立與 asset 上傳以同一 GitHub 憑證呼叫 REST API，腳本放在 session scratchpad，未輸出 token、未寫入 repository。
- 已完成：`227d6d9` 推送至 `origin/main`；annotated tag `v4.8.4`（物件 `7183d9d`）指向同一 commit；Release `湛盧 v4.8.4` 為非草稿、非預發布，且為 latest，資產 `zhanlu-v4.8.4.7z` 狀態 uploaded。
- 下載回驗：從公開下載網址取回 42,243 bytes，SHA-256 `51499AB281A5A8531FEF64135F2D1EC9CBD6B07E0899AE0A6A97BAE75AB26C5A` 與本地一致；`7z t` Everything is Ok、Files: 42。
- 仍待驗證：三工具 GUI 新 session 載入未重測；`dist/` 內 v4.8.2、v4.8.3 舊套件含 Agora 段落，保留待使用者決定是否刪除。

## 已完成項目：KIT-026
- 問題／需求：使用者決定 zhanlu 維持單純，必須視 Agora 為不存在。KIT-024 起核心內含 Agora 標記區段，Agora 的 `install` 與 zhanlu 的 `-Update` 會互相覆寫同一段，且未使用 Agora 的專案也會收到該導引。
- 範圍：移除 `AGENTS.md` 的 `agora:begin/end` 區段、作用中 `project.md` 與 `context-index.md` 的本機 Agora 登記、兩份 README 的 Agora 說明、KIT-025 新增的發言身分檢查與兩項 regression；磁碟路徑 regression 改用不依賴 Agora 標記的 fixture。歷史紀錄維持原樣。不修改外部 Agora 工具。
- 決策：取代 KIT-024「核心保留通用 Agora 導引」與 KIT-025 的發言身分修正；zhanlu 不偵測、不保留、不檢查 Agora 寫入的內容。v4.8.3 未發布即被取代，版號升為 v4.8.4。
- 影響：若在 zhanlu 專案執行 `agora install`，其寫入 `AGENTS.md` 的區段會在下次 `-Update` 被覆寫；若含本機路徑，`verify-zhanlu.ps1 -PackageSource` 依既有規則拒絕封裝。Agora 寫入 `.git/info/exclude` 的區塊與未追蹤檔案不受 zhanlu 管理。
- 已完成靜態驗證：tracked 檔案（歷史紀錄除外）`git grep -i agora` 零結果；`verify-zhanlu.ps1 -PackageSource`（由 `pack.ps1` 執行）與 `git diff --check` 通過。
- 已完成動態驗證（腳本）：`tests/regression.ps1` 67 項全部通過。
- 封裝驗證：`pack.ps1` 與內建 `7z t` 通過，`dist/zhanlu-v4.8.4.7z` 為 42,243 bytes、42 個檔案，SHA-256 `51499AB281A5A8531FEF64135F2D1EC9CBD6B07E0899AE0A6A97BAE75AB26C5A`；解壓後全文搜尋 `agora` 零結果。未發布、未 push。
- 仍待驗證：三工具 GUI 新 session 載入未重測。

## 已完成項目：KIT-025
- 問題／需求：共用核心 `AGENTS.md` 的 Agora 區塊沿用 Codex 視角，要求「你用 `--from codex` 發言」；Claude Code 與 Antigravity 也讀同一份核心，照字面會冒用 codex 身分。該區塊在 KIT-024 已改為通用導引並隨套件發布，`dist/zhanlu-v4.8.2.7z` 內含此句。
- 範圍：`AGENTS.md` 的 Agora 區塊、作用中 `project.md` 的本機 Agora 指令、`verify-zhanlu.ps1`、`tests/regression.ps1` 與版號；不修改外部 Agora 工具。
- 使用技能：`bug-fix`。
- 決策：保留 KIT-024「核心保留通用 Agora 導引」的決定，不在打包時移除區塊；改為依目前執行的工具填入 `claude`、`codex` 或 `antigravity`（身分清單取自 Agora `AI_PARTIES`）。版號升為 v4.8.3，v4.8.2 套件保留未發布。
- 已知限制：在本工作副本重跑 `agora install` 會以 Agora 自身的 Codex 範本（含本機路徑）覆寫標記區段；新的 verify 會以單一身分與本機路徑兩項錯誤擋下封裝。Agora 範本是否改為通用，屬 Agora 專案範圍。
- 根因證據：以 HEAD 的 `AGENTS.md` 搭配新版 verifier 執行 `-PackageSource`，回報 `AGENTS.md must not bind the Agora speaking identity to a single tool: codex` 並失敗。
- 已完成靜態驗證：`verify-zhanlu.ps1 -PackageSource` 通過（42 個檔案、11 個技能）；`git diff --check` 通過。
- 已完成動態驗證（腳本）：`tests/regression.ps1` 69 項全部通過，新增核心三種身分皆在與移除兩種身分後被拒絕兩項。
- 封裝驗證：`pack.ps1` 與內建 `7z t` 通過，`dist/zhanlu-v4.8.3.7z` 為 42,925 bytes、42 個檔案，SHA-256 `CA6015BF45A8F5D1E1BCF17715DC522D3C2728E124AD30D435B05DFD9A166EA0`；解壓後 `AGENTS.md` 含 `--from claude`、`--from codex`、`--from antigravity`。未發布、未 push。
- 仍待驗證：三工具 GUI 新 session 載入與實際 Agora 發言身分未實測。

## 已完成項目：KIT-024
- 問題／需求：依使用者確認的五項審查發現修正母版，加入可重跑的回歸測試。
- 範圍：安裝、驗證、封裝、共用檢查、核心可攜導引、文件與本機工作追蹤；不修改產品韌體或外部 Agora 工具。
- 使用技能：`bug-fix`、`firmware-code-review`。
- 根因證據：隔離環境的舊 manifest 注入 `../stale-sentinel.review.txt` 後，`-RemoveStale` 刪除目標外測試檔仍 exit 0；同 repository 安裝 alpha 再 beta 使 alpha 的 check-ignore 從 exit 0 變 1；兩支維護腳本被追蹤仍驗證通過；本機 Agora 路徑會進入封裝；內部 README 與核心版控規定相反。
- 已確認決策：新增共用路徑與清單檢查；忽略標記依安裝位置區分並遷移舊區塊；驗證涵蓋追蹤及忽略狀態；Agora 本機設定移入作用中專案層；升版 v4.8.2，保留舊套件。
- 已完成靜態驗證：七支 PowerShell 原始碼的 parser errors 為 0；`verify-zhanlu.ps1 -PackageSource` 與 `git diff --check` 通過，白名單 42 個檔案、11 個技能。
- 已完成動態驗證（腳本）：`powershell -NoProfile -ExecutionPolicy Bypass -File ./tests/regression.ps1` 全部 67 項通過；涵蓋來源與已安裝 manifest 越界拒絕且零寫入、junction 拒絕、合法 stale 刪除與目標內空目錄清理、WhatIf 零寫入、跨子專案與 linked worktree 保護、舊名稱及舊區塊遷移的 idempotence、兩支維護腳本誤追蹤、忽略缺漏、核心路徑與 sentinel、封裝清單及從解壓套件安裝。
- 舊版實測：從本機 `v4.8.1` tag 匯出真正的舊版 source，使用其安裝器建立隔離目標，再以新版升級至 v4.8.2；三份作用中文件前後 SHA-256 完全相同，workspace 忽略保護保留。另確認既有 README、編輯器設定與目標 `.gitignore` 保留。
- 封裝驗證：最終 `pack.ps1` 與內建 `7z t` 通過，`dist/zhanlu-v4.8.2.7z` 為 42,655 bytes、42 個檔案，SHA-256 `DCC4C3285798EE6D5EA19F2AC5F7DF82CE7D1B6605A2C2B1B342523120507EC7`。作用中專案層、測試與本機工具設定不在白名單內，僅建立新版套件，未發布或 push。
- 提交方式：僅本 KIT-024 的母版程式碼、規則、文件及測試建立一筆中文 commit；套件輸出不 stage。
- 仍待驗證：三工具 GUI 新 session 載入未重測；不以腳本測試代替工具動態載入。

## 已完成項目：KIT-021
- 問題／需求：修正 Antigravity workspace rule 的載入相容性，降低啟動時強制讀取的歷史資料量。
- 範圍：共用入口、驗證器、母版工作紀錄、範本與使用說明；不改 11 個技能本體或已安裝專案的作用中文件。
- 使用技能：`bug-fix`、`architecture-design`。
- 完成條件：rule frontmatter regression、載入邊界驗證、歷史搬移一致性、封裝與安裝回歸通過。

## KIT-021 驗證紀錄
- 根因與修正：Antigravity 現行 rule 契約要求 `trigger` frontmatter，原 `.agents/rules/project-context.md` 未提供；加入 `always_on` 與封閉 frontmatter 的驗證。Antigravity 的 `@` 為檔案參照，入口文字改為明確要求實際讀取。
- 啟動資料：Claude 不再預先匯入完整 TODO；共用核心改為前四份文件全文、TODO 當前段與相依按需載入。母版舊紀錄搬至 `.agents/history/KIT-001-KIT-020.md`，搬移前後歷史段 30,458 個字元逐字相同；作用中 TODO 由 54,197 bytes 降至約 7.5 KB。
- `verify-zhanlu.ps1 -PackageSource` 與 `git diff --check` 通過；缺少 trigger、未關閉 frontmatter、Claude 恢復整份 TODO 匯入的負向測試均被驗證器拒絕。
- v4.7.1 暫存安裝升級到 v4.8.0、v4.8.0 全新安裝與兩個目標的驗證器均通過；升級前後三份作用中文件的 SHA-256 與備份一致。
- `pack.ps1` 通過，`dist/zhanlu-v4.8.0.7z` 為 39,615 bytes、41 個檔案；SHA-256 `A6905BBC0E4CA1D5B85EAA74B582392C4AFE94CC7E337C7F6EE929FB86D70797`。舊版封裝保留，未發布 Release、未推送。
- Claude Code 動態載入（2026-09-24，使用者提供的本專案 VS Code session 回覆）：啟動確認為 `core=ZHANLU-CORE-v4 / project=zhanlu-source / context=ZHANLU-CONTEXT-v4 / work-item=KIT-021 / schema=n/a / missing=none`。該 session 回報 `CLAUDE.md` 自動展開前四份檔案，讀到核心、專案與索引 sentinel；`TODO.md` 未預先匯入，而是依規則按需讀取檔頭、總表與當前段。此為使用者提供的模型回報，非本機獨立觀察的載入追蹤。
- Antigravity 動態啟動（2026-09-24，使用者提供的本專案 VS Code session 回覆）：啟動確認為 `core=ZHANLU-CORE-v4 / project=zhanlu-source / context=ZHANLU-CONTEXT-v4 / work-item=KIT-021 / schema=n/a / missing=none`；該 session 回報讀取五份必要檔案、識別母版 schema 為 `n/a`，並載入 `bug-fix`、`architecture-design`。此證明該環境可完成啟動流程，但回覆未提供規則來源或注入清單，不能單憑結果證明 `project-context.md` 確曾注入或排除多入口重複。該回覆稱 KIT-021 尚未 commit，與本 repository 已有 `1cac31b` 不符；Git 狀態以本機查驗為準。
- Antigravity 受控動態驗收（2026-09-24，使用者提供的新對話輸出）：暫時在 `GEMINI.md` 與 `.agents/rules/project-context.md` 各加入不同標記，僅輸入「工作開始」後，session 在啟動確認下方同時回傳 `entry-gemini=G-7F31` 與 `entry-rule=R-B2C8`。提供的操作紀錄顯示讀取五份必要檔案及兩項技能，未列出讀取兩個入口檔案的工具呼叫。這支持兩個入口皆在啟動時注入；不能由模型回覆精確量出 prompt token 或證明底層去重機制。
- 多入口評估：兩處入口皆含指向同一批檔案的短導引，確有少量重複；`@檔名` 只作檔案參照，不展開核心全文。保留 workspace rule 作為備援入口，未觀察到啟動錯誤；檢查時兩個暫時標記已從檔案移除，未進入套件。

## 已完成項目：KIT-022
- 問題／需求：v4.8.0 升級一個已安裝專案時，驗證器將作用中文件中的合法巨集 `__ITE8297__` 誤判為未填範本 token，導致安裝已完成但最終驗證失敗。
- 根因：`verify-zhanlu.ps1` 使用過寬的 `__[A-Z0-9_-]+__`，未區分模組範本佔位值與程式碼識別字。
- 範圍：母版驗證器、對應說明與版號；不改已安裝專案三份作用中文件、韌體原始碼或 v4.8.0 既有 Release。
- 使用技能：`bug-fix`。
- 完成條件：只拒絕範本實際使用的佔位值，合法雙底線識別字通過；負向測試、母版驗證、安裝升級與封裝均通過。發布另由 KIT-023 追蹤。
- 初步處置：失敗的安裝器已建立三份作用中文件備份，模組檔案更新至 v4.8.0；備份時的作用中文件雜湊已核對。後續發現目標 TODO 另有新修改，須保留並以升級前後即時雜湊再驗證。
- 修正與回歸：驗證器只在欄位值仍為五個實際範本佔位值之一時拒絕；來源母版對 token 的文字敘述、含 `__ITE8297__` 的已安裝專案均通過驗證。隔離新安裝通過；把其 Build 欄改為 `__PROJECT_ID__` 後，驗證器以 exit 1 精確拒絕，隔離測試專案已移除。
- 升級驗證：v4.8.0 → v4.8.1 的 `-WhatIf` 僅列出三個模組檔案覆寫；實際升級與安裝後驗證通過，三份作用中文件即時前後 SHA-256 完全相同，既有韌體修改清單保留。目標內模組 clone 的快進另由 KIT-023 完成。
- 封裝驗證：`pack.ps1` 與 7z 完整性檢查通過，`dist/zhanlu-v4.8.1.7z` 為 40,031 bytes、41 個檔案，SHA-256 `20439E78A042476E565AFCBAD2959E37DD899EF84F6566BE3A9694614A10A613`；舊版套件保留。

## 已完成項目：KIT-023
- 範圍：只推送已驗證的 v4.8.1 修正、建立 annotated tag、發布並下載回驗 7z，最後快進已安裝專案內乾淨的模組 clone；不修改韌體原始碼或作用中文件。
- 完成條件：遠端 main、tag、非草稿 Release 與 asset 可查，下載資產的大小、SHA-256 與 7z 完整性均與本地一致，目標 clone 與已安裝模組版本一致。
- 已完成：`6358c24` 推送至 `origin/main`，annotated tag `v4.8.1` 指向同一 commit；GitHub Release `v4.8.1` 為非草稿、非預發布，資產 `zhanlu-v4.8.1.7z` 已上傳。
- 下載回驗：遠端資產及實際下載副本均為 40,031 bytes、41 個檔案，SHA-256 `20439E78A042476E565AFCBAD2959E37DD899EF84F6566BE3A9694614A10A613`；7z 完整性通過，驗證用暫存副本已移除。
- 目標更新：已安裝模組與乾淨的內嵌 clone 均為 v4.8.1，目標驗證器通過；再次 `-WhatIf` 僅顯示因 `projectKind=firmware` 而不同的 `.agents/module.json`。三份作用中文件與原有韌體修改保持在目標專案，未納入模組發布。

## 歷史索引
- KIT-001～KIT-020 的詳細紀錄與原有未決事項：`.agents/history/KIT-001-KIT-020.md`。
- 依目前 work item 需要再讀取歷史紀錄；本檔保留總表與當前狀態。
