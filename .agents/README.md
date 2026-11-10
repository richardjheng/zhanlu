# Embedded Firmware AI Collaboration Kit

本模組把同一套專案規則、專案事實、資料索引與工作流程提供給 Claude Code、Codex 與 Antigravity。它不限定 EC，也適用於 PD、lighting、keyboard controller 及其他嵌入式韌體；工作類型可為 bug fix、程式碼整合、韌體移植或硬體 bring-up。

## 單一真相來源

| 內容 | 唯一來源 | 是否隨套件複製 |
|---|---|---|
| 跨專案共同原則 | `AGENTS.md` | 是 |
| 套件清單與版本 | `.agents/module.json` | 是 |
| 目標專案事實 | `.agents/project.md` | 否，安裝時由範本建立 |
| 資料位置與閱讀順序 | `.agents/context-index.md` | 否，安裝時由範本建立 |
| 工作項目與驗證狀態 | `.agents/TODO.md` | 否，安裝時由範本建立；完成詳情可按需存入 `.agents/history/` |
| 通用工作方法 | `.agents/skills/*/SKILL.md` | 是 |
| Claude skill 載入器 | `.claude/skills/*/SKILL.md` | 是，只指向通用 skill |
| 欄位合法值 schema | `.agents/module.json` 的 `projectSchema` | 是，擴充一律回母版改再 `-Update` 下發 |
| 編輯器設定 | `.agents/templates/vscode-settings.json`、`workspace.code-workspace` | 是，安裝時只在目標缺少時產生一次 |
| SPEC、schematic、log 等 | `.agents/resources/` | 只複製 `.gitignore`，內容每案掛載 |
| golden reference | `.agents/reference-projects/` | 只複製 `.gitignore`，內容每案掛載或登記外部唯讀路徑 |

`CLAUDE.md`、`GEMINI.md` 與 `.agents/rules/project-context.md` 只負責導向上述共同來源，不複製規則內文。Claude 啟動時不展開完整 `TODO.md`；Antigravity 的 `@` 路徑只是檔案參照。Codex 直接從 `AGENTS.md` 進入；不同工具的自動載入能力若有差異，仍以 `AGENTS.md` 的 session 啟動確認為共同檢查點。

## 目錄結構

```text
AGENTS.md
CLAUDE.md
GEMINI.md
README.md                 # 壓縮套件入口說明；不複製到目標專案根目錄
pack.ps1
setup-zhanlu.ps1
verify-zhanlu.ps1
clean-backups.ps1
update-zhanlu.ps1
.agents/
  module.json
  README.md
  project.md               # 本專案作用中設定，不進套件
  context-index.md         # 本專案作用中索引，不進套件
  TODO.md                  # 本專案作用中工作狀態，不進套件
  templates/
  rules/
  skills/
  resources/               # 專案專屬資料掛載點；自帶 .gitignore
  reference-projects/      # 專案專屬參考專案掛載點；自帶 .gitignore
.claude/skills/             # Claude 輕量載入器
```

## 套用到任意目標專案

建議先把 7z 解壓到暫存資料夾，再從暫存資料夾執行安裝器；不要直接覆蓋目標 repository。

```powershell
7z x .\zhanlu-v4.12.0.7z -o'.\zhanlu-v4.12.0'
powershell -ExecutionPolicy Bypass -File .\zhanlu-v4.12.0\setup-zhanlu.ps1 `
  -TargetPath 'D:\path\to\target-project'
```

安裝器會先完成全量衝突檢查，任何目標檔案已存在時都會中止，不會局部覆蓋。成功後會：

1. 依 `.agents/module.json` 白名單複製通用檔案；`packageOnlyFiles` 只留在壓縮套件，不複製到目標專案。
2. 由範本建立新的 `.agents/project.md`、`.agents/context-index.md` 與 `.agents/TODO.md`。
3. 寫入目標資料夾名稱及新的驗證碼。
4. 執行 `verify-zhanlu.ps1`。

接著由維護者填寫三份作用中文件：

- `project.md`：controller、SoC、架構、建置方式、硬體限制與驗證能力。
- `context-index.md`：程式碼、SPEC、schematic、log、工具、參考專案的位置與閱讀順序。
- `TODO.md`：當前 work item、完成條件、驗證證據與未決風險；長篇完成紀錄可搬到 `.agents/history/`，在 TODO 留索引。升級不會自動搬移既有紀錄，搬移前先備份。

無法由 repository 或文件查得的板級事實必須向使用者確認，不可由 AI 猜測。

## 升級已安裝的模組

`setup-zhanlu.ps1` 的預設模式只做全新安裝，任何目標檔案已存在就會中止。要把既有專案更新到新版模組，改用 `-Update`：

```powershell
# 先看計畫，不寫入任何檔案
powershell -ExecutionPolicy Bypass -File .\setup-zhanlu.ps1 `
  -TargetPath 'D:\path\to\target-project' -Update -WhatIf

# 確認後實際升級
powershell -ExecutionPolicy Bypass -File .\setup-zhanlu.ps1 `
  -TargetPath 'D:\path\to\target-project' -Update
```

`-Update` 的邊界：

- 只覆寫 `portableFiles`，並列出哪些是新增、哪些會被覆寫、哪些內容相同。
- 絕不寫入 `.agents/project.md`、`.agents/context-index.md` 與 `.agents/TODO.md`；專案事實、資料索引與工作進度完整保留。
- 目標沒有 `.agents/module.json`，或三份作用中文件不齊全時直接拒絕，避免把半套模組蓋成看似完整。
- 會比對目標已安裝的舊 `module.json`，列出新版白名單已移除的檔案；預設只回報，加上 `-RemoveStale` 才刪除。
- 升級結束會自動執行 `verify-zhanlu.ps1`。
- 升級前會把三份作用中文件複製到 `.agents/.backup-<時間戳>/`，且不會自動清除；確認升級無誤後以 `clean-backups.ps1` 清理。
- `.agents/resources/` 與 `.agents/reference-projects/` 的內容不在白名單內，升級完全不會碰；自行新增的 skill 目錄同理，不會被當成 stale。

日常升級改用目標專案根目錄的 `update-zhanlu.ps1`：它依 `module.json` 的 `releaseRepository` 查詢 GitHub 正式 Release（預設最新，或 `-Version vX.Y.Z`；草稿與預發布一律拒絕），下載 `zhanlu-vX.Y.Z.7z` 並以 Release 提供的 SHA-256 核對，檢查壓縮檔內路徑後解壓到本次建立的暫存目錄，確認套件版本與 tag 相符，再以該套件的 `setup-zhanlu.ps1 -Update` 升級並清除暫存。它不執行任何 Git 更新命令。同版本預設略過（`-Force` 重套），降版預設拒絕（`-AllowDowngrade` 允許）；`-WhatIf` 只顯示「目前版本 → 目標版本」，不下載也不寫入；`-Local`（相容別名 `-NoPull`）不連網，套用腳本所在的 kit 母版。舊版更新器仍使用 `git pull`，第一次請先從 Release 取得新版套件，以套件的 `setup-zhanlu.ps1 -Update` 遷移一次。從 Release 更新需要 7-Zip；找不到 `7z.exe` 時更新器會在下載、建立暫存與修改專案之前停止，請以 `winget install --id 7zip.7zip -e` 或 [7-Zip 官方下載頁](https://www.7-zip.org/download.html) 安裝後重跑，或從 zhanlu clone 執行 `-Local` 離線套用；`-WhatIf`、`-Local` 與 `setup-zhanlu.ps1` 本身不需要 7-Zip。

若曾在目標專案手改過 `AGENTS.md` 或任一 skill，升級會覆蓋這些修改。共用規則的修改應該回到母版，不要留在單一專案。

解除安裝使用 `setup-zhanlu.ps1 -Uninstall`，只刪除已安裝 manifest 列出的檔案；預設保留三份作用中文件、備份與資料掛載點內容，`.git/info/exclude` 只保留仍存在路徑的規則。加上 `-RemoveProjectLayer` 才刪除作用中文件與備份。

## 資料邊界與版控保護

安裝到目標專案後，整個模組都不進該專案的版控。忽略規則寫入目標 repository 的 `.git/info/exclude`：

```text
# >>> zhanlu [.] >>>
/.agents/
/.claude/
/AGENTS.md
/CLAUDE.md
/GEMINI.md
/pack.ps1
/setup-zhanlu.ps1
/verify-zhanlu.ps1
/clean-backups.ps1
/update-zhanlu.ps1
# <<< zhanlu [.] <<<
```

用 `.git/info/exclude` 而不是目標的 `.gitignore`，是因為 `.gitignore` 本身會被 commit，會在該專案的歷史中暴露模組檔名。`.git/` 不屬於工作樹，不會被 commit 也不會被 push。標記區塊使 重複安裝與升級保持 idempotent；安裝器以 `git rev-parse --git-common-dir` 定位，worktree 與 submodule 的 `.git` 為檔案時同樣正確。

標記由 `module.json` 的 `name` 與安裝位置組成，例如根目錄為 `# >>> zhanlu [.] >>>`，子專案為 `# >>> zhanlu [alpha] >>>`；linked worktree 另帶 Git worktree 識別，避免共用忽略檔時互相覆寫。已退役名稱記錄在 `legacyMarkerNames`。升級只重寫當前安裝的區塊，其他安裝的規則保持原樣。舊版未帶位置的區塊會逐項遷移，保留其他位置的條目；既有忽略條目不以當前工作樹的檔案存在性刪除，避免遺失其他 worktree 的編輯器設定保護。

安裝、驗證與封裝共用 `.agents/lib/module-safety.ps1`：所有白名單路徑必須是安全的相對路徑，拒絕 `..`、絕對路徑與穿越 junction／symlink。升級先檢查新舊 manifest 與來源／目標路徑，再進行備份或寫入；不安全清單會直接中止。驗證器由同一份清單檢查全部模組檔案的 Git 追蹤與忽略狀態，包含兩支維護腳本。

目標不是 git repository，或機器上沒有 `git` 時，安裝仍會完成，並改為印出需要手動加入的項目。

`.agents/resources/` 與 `.agents/reference-projects/` 仍各自保留一份 `.gitignore`（`*` 加 `!.gitignore`），作為 `.git/info/exclude` 未生效時的第二道防線。

兩個必須向使用者說明的後果：

- 在目標專案執行 `git clean -x` 會刪除整個模組，包含工作歷史與 `.agents/resources/` 內的證據。
- `.agents/` 沒有版控後盾，必須納入使用者自己的備份；`-Update` 會在寫入前把三份作用中文件複製到 `.agents/.backup-<時間戳>/`。

母版 repository 本身照常全部版控，本節只適用安裝到目標專案的那一份。

## 工作路由

每個工作先選一個 task skill，再視需要加上一個 controller skill：

| 類型 | Skill |
|---|---|
| Bug 修正 | `bug-fix` |
| 程式碼／分支／供應商元件整合 | `code-integration` |
| 跨晶片或跨架構移植 | `firmware-porting` |
| 新板或新硬體啟動 | `hardware-bringup` |
| 架構設計、分層調整與重構 | `architecture-design` |
| 多個既有專案收斂成共用基底 | `architecture-design` 先定界線，`code-integration` 執行搬移 |
| Patch、移植成果或整合結果審查 | `firmware-code-review` |
| EC／PD／lighting／keyboard domain | 對應的 `*-controller` |
| ITE EC 特殊移植 | `ite-ec-porting`，搭配 `firmware-porting` |

skill 是方法，不承載專案事實；所有具體型號、路徑、register 依據與驗證結果仍回到專案層文件。

## 驗證與打包

驗證目前資料夾：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify-zhanlu.ps1 -PackageSource
```

建立可攜套件：

```powershell
powershell -ExecutionPolicy Bypass -File .\pack.ps1
```

`pack.ps1` 只接受 `.agents/module.json` 的 `portableFiles` 白名單，打包前後都會驗證，並以 `7z t` 測試封裝。作用中的 `project.md`、`context-index.md`、`TODO.md`、SPEC、golden reference、binary 與 build output 都不會進入套件。

## 維護原則

- 共同規則只改 `AGENTS.md`；不要在入口檔重複規則。
- 新增或改名 skill 時，同步更新 canonical skill、Claude loader 與 `module.json`。
- 新增可攜檔案只改 `module.json`，不要在 `pack.ps1` 再維護第二份清單。
- 修改後先跑驗證，再重建套件；不要用 `7z u` 更新舊封裝。
- 目標專案的 `.agents/`、作用中專案層與模組檔案不進目標版控，需由使用者納入本機備份，也不得回灌到通用 7z；模組母版本身照常版控。
