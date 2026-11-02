# 湛盧 Zhanlu — 嵌入式韌體 AI 協作模組 v4.9.0

> 湛盧為十大名劍之首，仁道之劍：持劍者無道，劍自去之。本模組同理——不守規則、不留證據、靠猜作答，它就不為你所用。

這是一套可移植到嵌入式韌體 repository 的 AI 協作模組，讓 Claude Code、Codex 與 Antigravity 共用同一份專案規則、專案資料、工作追蹤與 skills。

支援的工作包含 Bug 修正、程式碼整合、跨晶片／跨架構移植、硬體 bring-up、架構設計、多專案收斂與程式碼審查；領域涵蓋 EC、USB PD、lighting、keyboard controller，以及 ITE EC 專門移植。

## 前置需求

- Windows 與 Windows PowerShell 5.1 以上；五支腳本都以 `powershell.exe` 執行。
- `git`：從 GitHub 取得模組需要；安裝器把整個模組排除在目標專案版控之外時同樣需要它在 PATH 上。沒有 `git` 時安裝仍會完成，但會改為印出需要手動加入的忽略項目。
- 7-Zip：只有走壓縮套件路線才需要；要重新打包 (`pack.ps1`) 時需要 `7z.exe` 在 PATH 或安裝於預設路徑。
- 目標專案建議已在 Git 版控下。
- 安裝完成後若 VSCode 已經開著目標專案，請重新載入視窗，工具才會重新掃描規則與 skill。

## 取得模組的三種方式

> **關鍵觀念：取得模組 ≠ 安裝模組。**
>
> 湛盧的預設安裝位置是**目標 repository 根目錄**。只把母版 clone 到子資料夾（例如 `zhanlu/`），不會讓開在目標根目錄的工作階段取得正確的專案層；請再跑 `setup-zhanlu.ps1`，由它把共用檔案送到根目錄並產生該專案自己的資料。各工具對巢狀規則的掃描方式不同，勿將子資料夾中的母版誤認為目標專案的入口。

| 你手上的東西 | 正確做法 |
|---|---|
| GitHub repository | `git clone` 到目標專案內或機器上任一位置，再執行 `setup-zhanlu.ps1 -TargetPath <目標>` |
| 壓縮套件 `zhanlu-v4.9.0.7z` | 解壓到暫存資料夾，再對目標專案執行 `setup-zhanlu.ps1` |
| 模組母版資料夾 | 直接在母版執行 `setup-zhanlu.ps1 -TargetPath <目標>`，或先用 `pack.ps1` 產生套件 |
| 目標專案已裝過舊版模組 | 改用 `-Update`，見〈升級既有專案〉 |

安裝器只複製 `.agents/module.json` 白名單內的共用檔案，並由 `.agents/templates/` 產生全新的專案層，所以不會把母版或其他專案的事實帶進來。

**不要把母版資料夾整包複製成新專案。** 母版 repository 本身帶著一份作用中的專案層（`.agents/project.md`、`.agents/context-index.md`、`.agents/TODO.md`），那是母版自己的專案事實與工作進度；整包複製會讓新專案的 AI 讀到母版的專案識別與母版的 work item，在錯誤前提下工作。若已經手動整包複製過，請先刪掉目標專案內的 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、`.agents/`、`.claude/`、`dist/` 與五支腳本，再重新安裝。

## 安裝流程 A：從 GitHub clone（建議）

把模組 clone 進目標專案，再對上一層執行安裝器。clone 出來的 `zhanlu/` 之後就是這個專案的升級來源，`git pull` 後直接 `-Update` 即可。

```powershell
# 1. 取得模組
cd D:\work\target-firmware-project
git clone https://github.com/ITE-Richard/zhanlu.git

# 2. 安裝到專案根目錄
cd zhanlu
powershell -ExecutionPolicy Bypass -File .\setup-zhanlu.ps1 -TargetPath ..

# 3. 驗收版控隔離
cd ..
git status --porcelain
```

第 3 步預期**完全空白**。安裝器發現自己就位在目標專案底下時，會把自己所在的那層目錄一併寫進排除規則，所以 clone 出來的 `zhanlu/` 不會出現在 `git status`，也不會被目標 repository 當成 embedded repository 收進 index。

這個判斷取自安裝器自己的路徑，不是猜的：kit 在目標之外就不會產生這條規則，clone 到 `tools\zhanlu` 這種更深的位置也會寫出正確的相對路徑。

不想讓 clone 留在專案內，就改 clone 到專案外（例如 `D:\tools\zhanlu`），用 `-TargetPath` 指向目標專案即可。代價是升級時要自己記得那份 clone 放在哪。

## 安裝流程 B：從壓縮套件

不要直接把壓縮檔覆蓋解壓到目標 repository。請先解壓到暫存或相鄰資料夾，再執行安裝器；安裝器會在寫入前檢查所有衝突。

```powershell
$archive = 'D:\transfer\zhanlu-v4.9.0.7z'
$kitDir = 'D:\transfer\zhanlu-v4.9.0'
$target = 'D:\work\target-firmware-project'

7z x $archive "-o$kitDir"
powershell -ExecutionPolicy Bypass -File "$kitDir\setup-zhanlu.ps1" `
  -TargetPath $target
```

## 兩種流程共通

安裝成功時會顯示 `Install complete`，並自動完成結構驗證。若目標專案已存在任何將安裝的 AI 規則或 skill，安裝器會在寫入前停止，不會局部覆蓋。

安裝後可以確認排除規則確實寫入了：

```powershell
Get-Content .git\info\exclude | Select-String "zhanlu"
```

根目錄安裝應看到 **一組** `# >>> zhanlu [.] >>>` 標記區塊，裡面列著 `/AGENTS.md`、`/CLAUDE.md`、`/GEMINI.md`、`/.agents/`、`/.claude/`、五支 `.ps1` 與編輯器設定等條目；走流程 A 時還會多一條 clone 目錄（例如 `/zhanlu/`）。子專案以位置區分，例如 `# >>> zhanlu [alpha] >>>`；重複升級只改寫該安裝的區塊，其他專案保持原樣，舊版未帶位置的標記會自動遷移。

> 若目標專案的 `.gitignore` 本來就有 `.*` 之類的規則，`git status` 對 `.agents/`、`.claude/` 沒有鑑別力——就算排除沒寫成功也看不出來。這時要靠上面這行 `Select-String`，或觀察根目錄的 `AGENTS.md` 與五支 `.ps1` 有沒有冒出來（`.*` 蓋不到它們）。

## 安裝後必做：讓 AI 知道專案與任務

安裝器只會自動填入專案識別與驗證碼，其餘欄位都是 `待確認`。AI 讀到 `待確認` 只會回報缺口、不會猜測，所以下面三份檔案填得多完整，AI 就能做到多深。三份檔案分工固定：

| 檔案 | 回答的問題 | 沒填的後果 |
|---|---|---|
| `.agents/project.md` | 這是什麼專案、能做什麼驗證、哪裡不能碰 | AI 不知道晶片與建置方式，無法判斷可行性 |
| `.agents/context-index.md` | 資料放在哪裡、哪一份說了算 | AI 找不到 SPEC 與基準，結論無法追溯 |
| `.agents/TODO.md` | 現在要做什麼、做到什麼算完成 | AI 不知道工作目標，只能等你逐句下指令 |

### 步驟 1：`.agents/project.md` — 專案事實

欄位的合法值由 `.agents/module.json` 的 `projectSchema` 定義，AI 在啟動確認時逐欄檢查。留著 `待確認` 只會列為警告，**填了合法範圍以外的值會判定為錯誤並停止實質工作**。

| 欄位 | 合法值 | 誰來填 |
|---|---|---|
| 專案識別、Repository | 安裝器依目標資料夾名自動填入 | 已自動 |
| 產品類型 | `NB` | 你 |
| 控制器領域 | `EC`／`PD`／`Keyboard & Lighting` 擇一，不可複選 | 你 |
| 目標晶片 | 一個或多個 ITE 型號；多顆以全形逗號 `，` 分隔且不得重複 | 你 |
| 韌體架構 | `bare-metal`／`RTOS`／`Zephyr`／`vendor SDK`／`其他` | 你，AI 可從程式碼推測後由你確認 |
| Build | 可直接執行的完整指令 | AI 可掃描候選，你確認 |
| 支援工作類型（6 項） | 各自 `啟用`／`按需求`／`不適用` | 你 |
| 額外唯讀區域 | 專案內由他人負責的路徑，沒有填 `無` | 你 |
| 唯讀基準 | `.agents/reference-projects/` 底下的路徑，或 `無` | 你 |
| 機密或不可提交資料 | `.agents/resources/` 底下的路徑，或 `無` | 你 |
| 必要硬體證據 | 有無主板與可取得的量測類型 | 你 |

五個容易填錯的地方：

- **Build 沒有命令列進入點就填 `無 CLI，須人工於 IDE 編譯`。** Keil、IAR 這類只有 GUI 的工具鏈很常見，填了這個值 AI 會把建置驗證標成待人工執行，不會一直跟你要指令。
- **控制器領域決定載入哪些領域技能**，不必另外填技能名稱：`EC` 載 `ec-controller`，`PD` 載 `pd-controller`，`Keyboard & Lighting` 同時載 `keyboard-controller` 與 `lighting-controller`。
- **多顆目標晶片使用全形逗號 `，` 分隔**，例如 `IT51526，IT8298`；半形逗號 `,`、頓號 `、` 與斜線都不符合此欄格式，也不要重複型號。這裡只列型號，各 IC 的角色以及 driver／HAL／SPEC 位置逐筆登記在 `context-index.md`。
- **升級既有專案時檢查這一欄。** `-Update` 會保留作用中的 `.agents/project.md`；若原本使用半形逗號或頓號分隔，需自行改為全形逗號，否則啟動確認會回報不合法。
- **分清楚「無」和「待確認」。** 確定沒有（沒實板、沒 golden reference）就填 `無`，AI 會據此把結論限制在靜態驗證；**不確定的才留 `待確認`**，AI 會持續列為缺口提醒你。一旦填了具體內容，AI 就當事實用，不會再質疑。
- **支援工作類型填 `不適用` 是有作用的。** 例如沒有實板就把硬體 bring-up 設為 `不適用`，AI 就不會提議那條路徑。全部填 `啟用` 等於這欄沒填。

本模組不登記 Flash 指令，燒錄一律人工執行。

### 步驟 2：`.agents/context-index.md` — 資料放哪、去哪找

先把檔案放到對的位置，再到索引登記一列。索引只登記路徑、用途與權威性，不複製內容。

| 資料 | 放這裡 | 版控 | 索引列 |
|---|---|---|---|
| 目標原始碼 | repository 原本的位置 | 進版控 | `CODE-01` Primary |
| 晶片 datasheet、SPEC | `.agents/resources/` | 預設不進版控 | `SPEC-01` Primary |
| Schematic、BOM、pin table | `.agents/resources/` | 預設不進版控 | `HW-01` Primary |
| Issue log、waveform、測試結果 | `.agents/resources/` | 預設不進版控 | `EVIDENCE-01` |
| Golden reference、上一版韌體、vendor tree | `.agents/reference-projects/` | 預設不進版控 | `BASE-01` 唯讀 |
| 體積過大或不該複製的參考樹 | 留在原處 | 不複製 | `BASE-01` 唯讀，索引寫絕對路徑 |

兩個掛載點各自帶一份 `.gitignore`（`*` 加 `!.gitignore`），放進去的東西預設不進版控，也不會動到專案原本的根 `.gitignore`。掛載點底下可自行分子目錄，例如 `.agents/resources/spec/`、`.agents/resources/evidence/issue-1234/`。

三件常被漏掉的事：

- **PDF 要登記章節與頁碼。** AI 讀得了 PDF，但單次讀取有頁數上限，數百頁的 datasheet 沒有頁碼只能盲翻。先讀目錄頁，把 `eSPI ch.7 p.183-201；GPIO register ch.12 p.340-372` 這種對照寫進索引的適用範圍欄。二進位檔（`.sal`、`.logicdata`）則一律讀不了。
- **同一件事有兩份來源時要標權威性**。例如 vendor SDK 與客戶 SPEC 對 timing 說法不同，就分成兩列並在〈資料衝突與限制〉記下衝突；AI 會標示矛盾，而不是挑一個方便的。
- **登記後才算數**。檔案放進 `.agents/resources/` 卻沒登記在索引，AI 不會主動去翻。

量測證據建議依 work item 分目錄：

```text
.agents/resources/evidence/<WORK-ITEM-ID>/
  measurement-note.md            人工撰寫，記錄量測條件（必要）
  la-i2c-charger-0to50ms.csv     LA 協定解碼後匯出
  uart-boot.log
  waveform-vr-rampup.png
```

LA log 要用**協定解碼後的 CSV**，一列一筆 transaction；raw sample 匯出動輒數百萬列，AI 讀不完。
只匯出出問題的那段時間窗，不要整份匯出。`measurement-note.md` 必須寫明 channel 對應到哪個 net、
取樣率、觸發條件與當時的韌體版本——CSV 裡只有 `Channel 0/1/2`，沒有對照表 AI 無法把訊號連到實際 pin，
取樣率不足造成的假 glitch 也無從判斷。波形截圖只能佐證有無訊號，不能當精確時序依據。

### 步驟 3：`.agents/TODO.md` — 工作目標

`TODO.md` 是 AI 判斷「現在要做什麼」的唯一來源，至少要填一筆 work item 與檔頭的「當前 work item」。

- **ID**：自訂前綴加流水號，例如 `EC-001`、`PD-014`；commit 與驗證證據都會引用它。
- **工作類型**：決定載入哪個任務技能（Bug fix、程式碼整合、功能開發、韌體移植、硬體 bring-up、重構、程式碼審查）。
- **完成條件**：寫成可驗證的句子。「修好風扇控制」不可驗證；「60°C 以上 PWM ≥ 50%，且 build 無新增 warning」可驗證。
- **狀態**：只用 `尚未開始` / `進行中` / `已完成，待動態驗證` / `已完成` / `已阻擋` 五種。
- **當前項目**：填問題、範圍、使用技能、必要證據、風險。「範圍」寫清楚哪些模組**不**在這次動的範圍，可避免 AI 順手改到無關程式碼。
- **驗證**：AI 每次做完會回填靜態驗證；動態／實板結果由你補上實測內容。

範例一筆：

| ID | 工作類型 | 功能域 | 項目 | 相依 | 狀態 | 完成條件 |
|---|---|---|---|---|---|---|
| EC-001 | Bug fix | Thermal | S3 喚醒後風扇維持全速 | 無 | 進行中 | 可穩定重現、修正後連續 20 次 S3 循環不再全速、build 無新增 warning |

填完把 `project.md` 的「目前 work item」與這裡的「當前 work item」對齊；兩邊不一致時 AI 以 `TODO.md` 為準並回報衝突。

`TODO.md` 建議只保留 work item 總表、當前項目與歷史索引；完成項目的長篇紀錄可另存於 `.agents/history/`，按目前任務需要再讀。升級器不會替既有專案搬移或刪除工作紀錄，搬移前請先備份。

### 步驟 4：首次啟動與驗收

以 VSCode 開啟目標 repository 根目錄（不是上層資料夾），啟動 Claude Code、Codex 或 Antigravity，輸入「工作開始」。Agent 應先回報：

```text
啟動確認：core=<版本> / project=<專案識別> / context=<索引版次> / work-item=<ID 或 none> / schema=<ok｜未填 n 欄｜不合法: 清單｜n/a> / missing=<none 或清單>
```

確認三件事：

1. `project=` 是你的專案識別，不是別的專案。
2. `work-item=` 是你剛填的 ID，不是 `none`。
3. `missing=none`。

還不放心時，可以要求 Agent 覆誦 `project.md` 最末的載入驗證碼與 `context-index.md` 最末的索引驗證碼。兩個碼刻意放在檔案最後一行，唸得出來就代表整份檔案真的讀完了。

若缺少必要檔案或引用失效，Agent 應停止實作並指出缺口。

### 讓 AI 幫你填

三份文件不必手工從零寫。在目標專案裡對 Agent 說「套用到新專案」，它會掃描 repository，把可自動查得的欄位（建置與測試指令、目錄結構、既有工具）先填好，再列出**必須由你提供**的項目（晶片型號、板級連線、機密邊界、驗證能力）。

兩句可直接使用的指令：

- `套用到新專案` — 盤點現況、初始化專案層、列出待補資訊。
- `工作開始` — 核對五份檔案，完整讀取核心、清單與專案設定／索引，從 TODO 讀當前項目及相依，再按需讀歷史與證據。

## 三個工具如何載入

| 工具 | 專案入口 | Skill 位置 |
|---|---|---|
| Claude Code | `CLAUDE.md` | `.claude/skills/` 載入器導向 `.agents/skills/` |
| Codex | `AGENTS.md` | `.agents/skills/` |
| Antigravity | `AGENTS.md`、`GEMINI.md`、`.agents/rules/project-context.md`（帶 `always_on` trigger） | `.agents/skills/` |

三個入口都導向同一份 `AGENTS.md`、`.agents/project.md`、`.agents/context-index.md` 與 `.agents/TODO.md`，避免不同 Agent 各自維護互相矛盾的規則。Antigravity 的 `@` 檔案參照不等於展開內容，仍須核對啟動確認。

## 內建技能

每個 work item 先選一個任務技能，再視需要加上一個或多個領域技能。

| 技能 | 用途 |
|---|---|
| `bug-fix` | 重現、根因定位、最小修正與 regression |
| `code-integration` | upstream、vendor SDK、patch、branch 或另一 repository 的整合 |
| `firmware-porting` | 跨晶片、跨板級、跨框架的功能移植與行為對等驗證 |
| `hardware-bringup` | 新晶片或新板的最小啟動路徑與逐步啟用 |
| `architecture-design` | 分層、模組邊界、介面契約、硬體抽象與多專案收斂 |
| `firmware-code-review` | patch、移植成果與整合結果的審查 |
| `ec-controller` | power、host interface、battery、charger、thermal、fan、ACPI |
| `pd-controller` | Type-C attach、PDO、contract、VDM 與保護流程 |
| `lighting-controller` | PWM、constant-current、pattern、功耗與熱限制 |
| `keyboard-controller` | matrix scan、debounce、ghosting、hotkey、host protocol、wake |
| `ite-ec-porting` | ITE EC 跨晶片或 legacy／Zephyr 跨框架移植，搭配 `firmware-porting` |

常見組合：多個既有專案要收斂時，先用 `architecture-design` 決定共用基底與差異層，再用 `code-integration` 執行搬移。

審查技能刻意命名為 `firmware-code-review` 而不是 `code-review`，避免與 Claude Code 內建的同名 skill 互相遮蔽。

## 升級既有專案

已經裝過本模組的專案，不要重新執行乾淨安裝，改用升級。

若你用流程 A 把 `zhanlu/` clone 在專案內，升級就是**一行**：

```powershell
cd D:\work\target-firmware-project\zhanlu
.\update-zhanlu.ps1
```

`update-zhanlu.ps1` 做兩件事：先在 kit 目錄 `git pull --ff-only`，再對專案執行 `setup-zhanlu.ps1 -Update`。專案位置由它自己往上找（`.agents/module.json` 的 `projectKind` 不是 `kit-source` 的那一層），所以不必給 `-TargetPath`，也不會誤認 kit 自己。

| 選項 | 用途 |
|---|---|
| `-WhatIf` | 先看計畫，`git pull` 與安裝都不執行 |
| `-NoPull` | 跳過 `git pull`，直接套用手上這份 kit |
| `-RemoveStale` | 一併刪除新版白名單已移除的檔案；不加只回報 |
| `-TargetPath` | 手動指定專案，指定後就不往上搜尋 |

只有 kit 本身就是一個 git clone 的根目錄時才會 pull。7z 解壓出來的 kit、或放在專案 repo 底下而沒有自己 `.git` 的 kit，會直接跳過並印出原因 —— 否則 `git pull` 會落在**你的韌體專案** repo 上。

`git pull` 失敗會**中止**整個流程，不會拿舊 kit 去覆蓋 —— 否則你會以為升級了，其實裝回同一版。

要拆開手動執行也可以：

```powershell
cd D:\work\target-firmware-project\zhanlu
git pull
powershell -ExecutionPolicy Bypass -File .\setup-zhanlu.ps1 -TargetPath .. -Update -WhatIf
powershell -ExecutionPolicy Bypass -File .\setup-zhanlu.ps1 -TargetPath .. -Update
```

從壓縮套件或母版升級則是：

```powershell
# 先看計畫，不寫入任何檔案
powershell -ExecutionPolicy Bypass -File "$kitDir\setup-zhanlu.ps1" `
  -TargetPath $target -Update -WhatIf

# 確認後實際升級
powershell -ExecutionPolicy Bypass -File "$kitDir\setup-zhanlu.ps1" `
  -TargetPath $target -Update
```

### 升級會動到什麼、不會動到什麼

專案文件都填好、參考專案也放好之後才升級，是最常見的情境。實際會發生的事：

| 你的東西 | 升級後 |
|---|---|
| `.agents/project.md`、`.agents/context-index.md`、`.agents/TODO.md` | **完全不動**，`-Update` 從不寫入這三個檔 |
| `.agents/reference-projects/` 底下的 golden reference | **完全不動**，不在白名單內 |
| `.agents/resources/` 底下的 SPEC、schematic、量測證據 | **完全不動**，不在白名單內 |
| 你自己新增的 skill 目錄 | **完全不動**，不在任何 manifest 內，也不會被判為 stale |
| 目標專案的原始碼與 `.gitignore` | **完全不動** |
| `AGENTS.md`、內建 11 個 skill、三工具入口 | **會被覆寫**成新版 |
| 舊版白名單有、新版沒有的檔案 | 列為 stale，加 `-RemoveStale` 才刪 |

會被覆寫的只有模組自己的共用檔案。**唯一要注意的是：如果你手改過目標專案內的 `AGENTS.md` 或任何內建 skill，那些修改會被蓋掉。** 共用規則的修改要回母版改，再 `-Update` 下發到各專案。

`-Update -WhatIf` 會先列出完整計畫而不寫入任何檔案，不確定時先跑這個。

升級開始前，三份作用中文件會先複製到 `.agents/.backup-<時間戳>/`。模組不在目標專案的版控內，沒有 `git` 可以還原，這是唯一的復原點。備份不會自動清除，確認升級沒問題後用 `clean-backups.ps1` 清掉：

```powershell
powershell -ExecutionPolicy Bypass -File .\clean-backups.ps1 -WhatIf      # 先看要刪什麼
powershell -ExecutionPolicy Bypass -File .\clean-backups.ps1              # 刪除，會先問過
powershell -ExecutionPolicy Bypass -File .\clean-backups.ps1 -KeepLatest 1
```

從專案根目錄或 `zhanlu/` clone 裡跑都可以：在 clone 裡執行時它會往上找到真正的安裝位置，並印出用的是哪個專案。它只會刪 `.agents/` 底下名為 `.backup-*` 的目錄，指到 kit 而非已安裝專案時直接拒絕執行，也不會跟著 junction 或 symlink 刪到別的地方去。

新版白名單移除的檔案會列為 stale，預設只回報；確認後加上 `-RemoveStale` 才刪除，並一併清掉變空的目錄。

若曾在目標專案手改過 `AGENTS.md` 或任一 skill，升級會覆蓋這些修改。共用規則的修改應該回到母版，不要留在單一專案。

> 流程 A 裝完後，專案內會有**兩份**模組：根目錄那份是 AI 實際讀的，`zhanlu/` 那份只當升級來源，內容相同是正常的。改規則要回母版改，改根目錄那份會在下次 `-Update` 被蓋掉。

## 解除安裝

從 kit（clone 或解壓目錄）對目標專案執行，不能用目標專案裡那份安裝器：

```powershell
# 先看計畫，不刪除任何檔案
powershell -ExecutionPolicy Bypass -File .\zhanlu\setup-zhanlu.ps1 -TargetPath . -Uninstall -WhatIf

# 只移除模組，保留專案層與資料
powershell -ExecutionPolicy Bypass -File .\zhanlu\setup-zhanlu.ps1 -TargetPath . -Uninstall

# 裝錯專案時，連三份作用中文件與備份一起移除
powershell -ExecutionPolicy Bypass -File .\zhanlu\setup-zhanlu.ps1 -TargetPath . -Uninstall -RemoveProjectLayer
```

| 項目 | `-Uninstall` | 加 `-RemoveProjectLayer` |
|---|---|---|
| 已安裝 manifest 列出的模組檔案 | 刪除 | 刪除 |
| 與範本相同的編輯器設定 | 刪除 | 刪除 |
| 改過的編輯器設定 | 保留 | 保留 |
| 三份作用中文件、`.backup-*` | 保留 | 刪除 |
| `.agents/resources/`、`.agents/reference-projects/` 的資料 | 保留 | 保留 |
| `.git/info/exclude` | 只保留仍存在路徑的規則 | 同左；全部移除時整個區塊刪除 |

刪除後變空的目錄會一併清掉；同一 repository 其他位置的安裝不受影響。`zhanlu/` clone 本身不會被刪除，需要時自行移除。

## 一台機器多個專案

每個 repository 各裝一份，不要多個專案共用同一份 `.agents/`。共用檔案（核心規則與 skills）在各專案內容相同，差異只在專案層三份文件，這樣每個專案的事實、索引與工作進度才不會互相污染。

換到新版模組時，對每個專案各跑一次 `-Update` 即可，專案層不受影響。

## 套件包含內容

- `AGENTS.md`、`CLAUDE.md`、`GEMINI.md`：三工具入口與共用核心。
- `.agents/module.json`：版本、skills 與可攜檔案白名單。
- `.agents/templates/`：新專案的 project、context-index、TODO 範本，以及編輯器設定與 workspace 範本。
- `.agents/rules/`：Antigravity workspace rule。
- `.agents/skills/`：11 個 canonical skills。
- `.claude/skills/`：11 個 Claude skill 載入器。
- `.agents/resources/`、`.agents/reference-projects/`：資料掛載點，各自帶一份 `.gitignore`。
- `setup-zhanlu.ps1`：安全安裝、專案層初始化與 `-Update` 升級。
- `verify-zhanlu.ps1`：結構、引用與 skill 驗證。
- `update-zhanlu.ps1`：一行升級，`git pull` 後對所在專案執行 `-Update`。
- `clean-backups.ps1`：刪除 `-Update` 留下的 `.agents/.backup-*` 專案層備份。
- `pack.ps1`：由白名單重建 7z 套件。
- `.agents/README.md`：安裝後保留在目標專案內的完整維護說明。

本檔 `README.md` 是 GitHub repository 與壓縮套件的第一層使用說明，標示為 package-only，不會覆蓋或複製成目標 repository 的根目錄 README。

## 可以交由 AI 協助的內容

- 掃描 repository，整理可確認的 controller、架構、build 與 test 資訊。
- 建立或拆分 work item、相依關係與驗證清單。
- 依任務選擇 Bug fix、整合、移植、bring-up、架構設計、審查及控制器領域 skill。
- 對照來源與目標程式碼，列出差異、風險與待補證據。

AI 不得猜測 pin、polarity、register value、timing、reset sequence、power rail ordering 或未提供的客戶需求。這些資料若無法從權威文件查得，必須由專案負責人補充。

## 不會打包的專案資料

母版作用中的 `.agents/project.md`、`.agents/context-index.md`、`.agents/TODO.md`，以及 SPEC、schematic、BOM、log、binary、build output、golden reference 與客戶資料不會進入套件。每個目標專案會由範本建立自己的專案層，避免不同專案互相污染。

## 目標專案不會 commit 到模組

安裝到工作專案後，**整個模組都不進該專案的版控**：`.agents/`、`.claude/`，以及根目錄的 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 與五支 `.ps1`。

忽略規則寫在目標 repository 的 `.git/info/exclude`，**不會新增也不會修改目標專案的 `.gitignore`**。`.git/` 不屬於工作樹，不會被 commit、不會被 push，所以模組的檔名不會出現在該專案的歷史裡。安裝器產生的 `.vscode/settings.json` 與 workspace 檔同樣列入排除；如果目標本來就有自己的 `.vscode/settings.json`，安裝器會原封不動保留它。

`verify-zhanlu.ps1` 依安裝白名單以 `git ls-files` 檢查全部模組檔案是否被誤追蹤，包含兩支維護腳本；也會以 `git check-ignore` 檢查忽略保護是否生效。誤追蹤會報錯並附修復指令；忽略規則缺漏則提示重新執行 `-Update`。

安裝與升級在寫入前檢查新舊 manifest、來源與目標路徑，拒絕絕對路徑、`..` 與 junction／symlink；`-RemoveStale` 只會刪除目標內經檢查的舊模組檔案。共用檢查位於 `.agents/lib/module-safety.ps1`，由安裝、驗證與封裝工具共同使用。

母版維護可執行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\regression.ps1`，在隔離暫存目錄驗證上述邊界及封裝／安裝流程。測試需 Git 與 7-Zip，不進可攜套件。

**kit 目錄本身也在排除範圍內。** 安裝器會比對自己所在的位置與目標專案根目錄，只要 kit 位在目標底下（clone 進專案就是這種情形），就把那層目錄的相對路徑一併寫進排除區塊。位置取自安裝器自己的路徑而非猜測，所以 kit 在目標之外時不會多寫任何規則，也不會誤忽略你自有的目錄。

> **兩個要注意的後果**
>
> - **不要在工作專案跑 `git clean -x`。** 這個指令專門刪除被忽略的檔案，會連同 `.agents/` 一起清掉——包含 `TODO.md` 的工作歷史與 `.agents/resources/` 裡的 SPEC 和量測證據，而且沒有確認提示。
> - **`.agents/` 沒有版控後盾，請納入你自己的備份。** 工作歷史、決策記錄與驗證證據只存在本機工作副本，磁碟壞掉就沒了。

母版 repository 本身不受這條規則影響，照常全部版控。

## 故障排除

| 症狀 | 檢查方式 |
|---|---|
| Agent 沒有輸出啟動確認 | 確認 VSCode 開的是 repository 根目錄，且根目錄看得到 `AGENTS.md` 與 `.agents/`；直接輸入「工作開始」依規則重新載入當前必要內容 |
| clone 完了但 AI 完全不知道有規則 | 只 clone 沒安裝。根目錄必須有 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 與 `.agents/`；放在 `zhanlu/` 子資料夾不會被任何工具載入，補跑 `setup-zhanlu.ps1 -TargetPath ..` |
| AI 讀到的專案識別是 `zhanlu-source` | 讀到的是 `zhanlu/` 子資料夾裡的母版專案層，不是你的專案層；確認根目錄已完成安裝，並把 `/zhanlu/` 加進 `.git/info/exclude` |
| `git status` 出現 `?? zhanlu/` | 該 clone 是在 v4.3.0 或更早版本安裝的，當時安裝器不排除 kit 目錄；以 v4.6.0 以上重跑 `-Update` 即可補上，或手動加 `/zhanlu/` 到 `.git/info/exclude` |
| `.git/info/exclude` 有重複的同位置標記區塊 | 以 v4.8.2 以上版本重跑 `-Update`，會合併同一安裝位置的重複區塊並遷移舊標記；不同子專案或 linked worktree 各有區塊，請保留 |
| 安裝後工具仍看不到規則或 skill | 重新載入 VSCode 視窗；工具通常在啟動時才掃描專案規則 |
| Claude Code 少了某個 skill | 確認 `.claude/skills/<名稱>/SKILL.md` 存在，且 frontmatter 的 `name` 與資料夾同名 |
| 某個 skill 突然消失或行為不對 | 可能與工具內建 skill 撞名；改用帶專案前綴的名稱，並同步更新 `module.json` 與兩處 SKILL.md |
| `Target files already exist; nothing was written` | 目標已經裝過模組，改用 `-Update` |
| `No installed module found` | 目標沒裝過模組，拿掉 `-Update` 做乾淨安裝 |
| 啟動確認的 `project=` 不是自己的專案 | 目標專案是整包複製來的，帶著別人的專案層；依〈取得模組的三種方式〉清掉後重新安裝 |
| 啟動確認的 `work-item=none` | `.agents/TODO.md` 還沒填 work item，或檔頭的當前 work item 沒對齊 |
| 啟動確認的 `schema=不合法` | 欄位值不在 `.agents/module.json` 的 `projectSchema` 允許範圍內；錯誤訊息會點名是哪幾欄 |
| `module files are tracked by this repository` | 模組被誤加入版控；照錯誤訊息執行 `git rm -r --cached`，檔案不會被刪除 |
| `git was not found` 警告 | 安裝 git 或加入 PATH；否則需手動把訊息列出的項目加進目標的 `.git/info/exclude` |
| 工作專案的 `.agents/` 整個不見了 | 極可能是跑過 `git clean -x`；從你自己的備份還原，模組本體可以重裝但工作歷史不行 |
| `still contains template token: __PROJECT_ID__` | 專案層三份文件仍有模組範本佔位值，請填入實際內容；其他合法的 `__...__` 程式碼識別字不屬於範本 token |
| `7z.exe was not found` | 安裝 7-Zip，或把 `7z.exe` 加入 PATH |
| `.agents/` 被 `.backup-*` 佔滿 | 每次 `-Update` 都會留一份，不會自動清；跑 `clean-backups.ps1` 刪除，或 `-KeepLatest 1` 只留最新一份 |
| 升級後專案事實不見了 | `-Update` 不會寫入作用中三份文件；若內容確實變了，代表有人手動覆蓋，請從版控還原 |

## 手動驗證

在目標專案根目錄執行：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify-zhanlu.ps1
```

若要維護並重新打包本套件，請參考 `.agents/README.md`。
