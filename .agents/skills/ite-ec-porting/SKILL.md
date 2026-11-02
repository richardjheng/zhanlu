---
name: ite-ec-porting
description: ITE Embedded Controller 跨晶片或跨框架移植的專門技能。適用 IT51526、IT51386、IT8298、IT8233 等 ITE EC 與 legacy／Zephyr 差異；一般移植先使用 firmware-porting。
---

# ITE EC 移植技能包

本技能包只補充 ITE EC 特有的差異核對，應與 `../firmware-porting/SKILL.md` 及
`../ec-controller/SKILL.md` 組合使用。專案事實見 `../../project.md`，資料位置見
`../../context-index.md`，進度見 `../../TODO.md`，共用規則見專案根目錄 `AGENTS.md`。

## 專案資源載入與邊界
- 開始移植前，確認根目錄 `AGENTS.md` 與 `../../module.json`、`../../project.md`、`../../context-index.md`、`../../TODO.md` 已完整載入。
- 依 `context-index.md` 定位目標專案、唯讀基準、SPEC、schematic 與驗證證據。路徑不存在或型號矛盾時先列缺口，不可猜測。
- SPEC 與 golden reference 是專案資料，不屬於可攜 skill；可放在專案合法位置或 `.agents/resources/`、`.agents/reference-projects/`，但必須由索引登記。
- 只讀取當前 work item 需要的 SPEC 章節與程式碼，避免混入不相關晶片或模組。

## 適用情境
- 換 SoC：同廠不同型號或不同世代（例：IT51386 → IT51526、IT5570 → IT51526、IT8233 → IT8298）。
- 換框架：原廠 legacy bare-metal SDK → Zephyr RTOS，或反向。
- 換板級：同 SoC 不同機種，pinmux / power rail / 週邊 IC 不同。

## 移植方法論

### 步驟 1：建立對照地圖
先把參考專案與當前專案的**功能落點**對起來，再看程式碼細節。
- 參考專案（legacy 典型）：`code/api/`（暫存器層 API）、`code/core/`（核心流程）、`code/oem/` 或同義目錄（專案邏輯）、`lds/`（linker script）。
- 當前專案（Zephyr 典型）：`projects/<name>/`（專案層）、`services/`（服務執行緒）、`core/`、`api/`、`dts/` 與 board overlay、`prj.conf`。
- 產出：功能 → 參考專案檔案 → 當前專案落點 的三欄對照，寫進 `TODO.md` 對應項目。

### 步驟 2：SPEC 差異核對（不可省略）
每一項牽涉硬體資源的移植，都必須回到 datasheet 核對，不可用命名或印象推論。
固定核對清單：
- 腳位是否存在（跨世代常見腳位被移除或改為電源腳）
- GPIO port 數量、GCR 設定位元、電壓選擇暫存器（1.8V/3.3V）
- INTC / WUC 的暫存器命名與 wake event 對應
- Clock / PLL 頻率預設值，以及所有以時脈換算的計時邏輯
- ADC 解析度與通道對應、PWM / Tachometer 控制器數量
- I2C / SMBus 控制器數量與 master/slave 能力
- Host interface：eSPI VW index、OOB、H2RAM / shared memory 語意
- PECI 是原生硬體還是走 eSPI OOB relay
- 特殊硬體機制（例：PWRSW 硬體 WDT、BRAM、CIR、eRPMC 區段）
產出：SoC 世代差異與影響，寫進 `TODO.md` 當前 work item。

### 步驟 3：架構轉換判斷
legacy → Zephyr 時，逐一判定原始流程應轉為哪種執行體：
| legacy 型態 | Zephyr 對應 | 判斷依據 |
|-------------|-------------|----------|
| main loop 輪詢 | thread + `k_sleep` 或 work queue | 週期需求與即時性 |
| 全域旗標 | event / atomic / message queue | 是否跨 context |
| 裸中斷處理 | driver callback + work item | ISR 內可否執行 |
| busy wait delay | `k_busy_wait` / `k_msleep` | 是否在 ISR 或需精準時序 |
| 開機順序初始化 | `SYS_INIT` + init priority | 相依關係 |
不可在未確認執行 context 的情況下直接平移 delay 或 ISR 行為。

### 步驟 4：逐項移植與驗證
一次只做一個 work item，並依專案根目錄 `AGENTS.md` 的通用流程完成驗證、追蹤與中文 commit。
每項都要留下：來源功能位置、目標落點、差異原因、驗證方式。

## 逐項檢查表

- **GPIO**：pin 存在性、direction、polarity、default level、boot strap、GCR、interrupt trigger type、開機初始化是否會誤動作到電源腳。
- **Power sequence**：G3/S5/S3/S0 轉移條件、各段 delay 與 retry、PGOOD 檢查來源、AC-in 自動開機、異常關機復原、強制關機路徑。
- **Host interface**：VW 事件與交握（SUS_WARN/SUSACK、PLTRST、BOOT_STS/BOOT_DONE）、SCI/SMI 送出、OOB 收送時機與保護條件、reset 生命週期下的 callback 註冊/移除冪等性。
- **Keyboard**：matrix table、掃描與 debounce、Fn hotkey（純 PS/2 e0-prefix vs WMI/ACPI Q-event 兩類要分開處理）、多 SKU 鍵盤表切換、擴充 KSO。
- **Power switch / Lid**：短按/長按判定（軟體計時 vs 硬體 WDT）、PCH pulse 寬度、debounce（open/close 常不同）、Sx 喚醒路徑、防誤觸條件。
- **Battery / Charger**：週期輪詢欄位、電芯串數判定、OVP/UVP/OTP 門檻、充電溫度窗口、飽充 debounce、pre-charge 階梯、adapter ICO 與 Prochot、ship mode。
- **ADC / Thermal / Fan**：通道對應與數位腳衝突、熱敏查表點數、board ID 分壓門檻、PECI 溫度來源與 Tjmax、PROCHOT 遲滯、風扇 stall 偵測與自救、fan fail 通知。
- **ACPI EC**：ACPI 模式切換、EC space 欄位配置、Q-event 表完整度、OEM 命令 handler。
- **Power limit / PECI policy**：PL1/PL2/PL4 計算、寫入回讀校驗、AC/DC 與 adapter 瓦數動態切換。
- **Type-C PD**：controller 型號與 I2C 通道、PDO 資料、interrupt pin、是否阻塞開機序列。

## 間接關係追查
關係類型定義見 `../../templates/impact-analysis.md`；ITE EC 常見的間接路徑：
- **板級 GPIO 表**：以巨集組成的 GPIO 初始化表決定 INPUT／OUTPUT／ALT、電壓與極性；只有特定模式才寫入 GPCR，ALT 設定可能被其他模組（UART、ADC、SMBus）在執行期覆寫。
- **平台標頭**：多平台共用程式時，同名訊號在不同平台標頭指向不同腳位；改一個平台後需比對其他平台的同名定義。
- **IRQ 與 service table**：INTC 中斷經 vector table 進入 hook，timer 中斷只排程；追到實際執行的 main service。
- **固定位址**：EC RAM、H2RAM 與診斷欄位以固定位址巨集定義，外部工具可能依賴；移植或移除功能時保留位址。

## 常見陷阱
- 跨世代腳位消失：舊專案有效的 GPIO 在新晶片可能是電源腳，直接沿用會在開機時拉低造成電壓跌落。
- PLL 頻率不同卻沿用計時常數，造成 delay 與 timeout 全數偏移。
- ADC 解析度由 10-bit 變 12-bit，查表與門檻換算必須同步調整。
- 通用 SoC driver 與特定型號暫存器語意不一致（例：H2RAM），需 patch 並實測。
- 以函式名稱相同就認定行為等價，忽略參考專案裡的 workaround 與時序保護。
- 週邊 IC 型號在移植中被換掉卻未更新暫存器設定（充電 IC、IO expander）。

## 驗證要求
- 靜態：編譯乾淨、程式碼路徑檢查、與參考專案的邏輯逐行比對。
- 動態：實板 log、波形（power rail、PWM、UART console）、host 端行為。
- 無法實板驗證時，必須明確分列「已完成靜態驗證」「已完成路徑檢查」「待實板驗證」三類，不可含糊帶過。
