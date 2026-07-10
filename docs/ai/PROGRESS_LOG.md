# Progress Log

按时间线记录开发与调试。课设验收的**调试日志**可从此文件导出或摘录。

---

### 2026-07-10 — PL-F02 流水线中断扩展（sim PASS）

- **Goal:** 让流水版控制器支持可演示的 `EI -> INTR -> LIAR -> 装入口 -> IRET`
- **Main changes:**
  - 新建 `PL-F02_DESIGN` / `PL-F02_IMPLEMENTATION`；登记 `PL-F02`
  - `hardwired_ctrl_core.v`：扩展 `OUT/DI/EI/IRET` 的 RUN 译码
  - `hardwired_ctrl_pipe.v`：加入 `EINT/INTQ/IWAIT`、interrupt stall、drain 后中断握手
  - `top.v`：接通 `INTR/LIAR/IABUS`
  - `tb_pipe.v`：新增 EX 命中中断、`LIAR/load`、`IRET` 回归
- **Validation done:** `sim/run_tb.ps1` PASS（`tb_ctrl` / `tb_manual_sto` / `tb_pipe`）
- **Next step:** 编写流水版中断板测程序并上板验证

---

### 2026-07-06 — 工程纪律骨架落地 (WF-F01)

- **Goal:** 从 minEngine 迁移轻量文档 + ID + 验证工作流到本课设仓库
- **Main changes:**
  - 建立 `docs/ai/`（PROJECT_CONTEXT、ACTIVE_WORK、FEATURE_REGISTRY、模板等）
  - 建立 `.cursor/rules/` 协作约束
  - 课设 PDF/图片迁入 `docs/course/`
  - 添加 `rtl/`、`sim/`、`constraints/`、`quartus/` 目录骨架
  - 添加 `scripts/verify.ps1`（分阶段占位）
- **Docs:** README、DOC_GOVERNANCE、CODING_STYLE
- **Risks or caveats:** 平台（TEC-8 vs TEC-PLUS）与 IDE 尚未最终确认
- **Validation done:** 目录与文档自检；`verify.ps1` Stage 0 占位通过
- **Next step:** 等待用户布置：锁定平台 → `CTL-F01` 设计

### 2026-07-06 — 基础至进阶需求分析与执行切片 (Review)

- **Goal:** 锁定 TEC-PLUS+ISE；完成需求分析、设计、27 切片计划；待审批后编码
- **Main changes:**
  - ADR-20260706-01 平台；ADR-20260706-02 流水模型（Proposed）
  - REQUIREMENTS_ANALYSIS、EXECUTION_ROADMAP
  - CTL/SIM/HW/PL 各 DESIGN + IMPLEMENTATION
  - 更新 PROJECT_CONTEXT、ACTIVE_WORK、FEATURE_REGISTRY、TECH_DEBT
- **Docs:** 见 `docs/ai/designs/`
- **Risks or caveats:** OUT/DI/EI/IRET 微操作待上板对标；审批前不写 RTL
- **Validation done:** 文档自检；`verify.ps1 -Stage 0` PASS
- **Next step:** 用户审批 → CTL-F01-S01

### 2026-07-06 — CTL-F01 基础阶段 RTL 实现 (CTL-F01-S01–S10)

- **Goal:** 顺序硬布线控制器 Verilog + 仿真框架
- **Main changes:**
  - `rtl/controller/hardwired_ctrl.v` — 14 指令 + 手动 SW 模式
  - `rtl/top/top.v` — 与图片-47 端口一致
  - `constraints/tecplus.ucf` — Spartan-6 引脚
  - `sim/tb_ctrl.v`, `sim/golden/ctl_vectors.txt`, `sim/run_tb.ps1`
  - `verify.ps1` Stage 1 支持 iverilog
- **Risks or caveats:** 本机无 iverilog，Stage 1 跳过；OUT/DI/EI/IRET 仍为暂定控制字
- **Validation done:** `verify.ps1 -Stage 0` PASS
- **Next step:** HW-F01 ISE 工程 + 上板，或安装 iverilog 跑仿真

### 2026-07-06 — iverilog 安装与仿真通过 (SIM-F01)

- **Goal:** 本机仿真环境 + 修复 tb 使控制向量测试通过
- **Main changes:**
  - 安装 iverilog 12.0 至 `%LOCALAPPDATA%\iverilog`（bleyer 安装包）
  - 修复 `tb_ctrl.v`：`ir` 8 位宽、IR7–IR4 接线
  - 更新 `sim/README.md`、文档状态
- **Validation done:** `.\sim\run_tb.ps1` PASS；`verify.ps1 -Stage 1` PASS
- **Next step:** HW-F01 ISE 工程 + 上板

### 2026-07-06 — 文档状态同步（commit 前）

- **Goal:** 交接用文档与 Feature 状态对齐当前进度
- **Main changes:** ACTIVE_WORK、FEATURE_REGISTRY、EXECUTION_ROADMAP、CTL/SIM 状态 → Done/In Progress
- **Next step:** 本 commit 批准后 → HW-F01-S02

### 2026-07-08 — 基础上板验收 + FPGA 飞线记录 (HW-F01)

- **Goal:** 手动模式与已实现 RUN 指令集板级验收；记录必需飞线
- **Main changes:**
  - STO 在 **T3 下降沿** 更新后，手动读/写寄存器、读/写存储器正常
  - 时序 **W3 未默认接 FPGA**，飞线 **W3→N5** 后 LD/ST 第三拍正常
  - 必需飞线：**T3→C10**、**W3→N5**（见 `HW-F01_BOARD_TEST` §3.1）
- **Validation done:** 板级用例 A/C PASS；`sim/run_tb.ps1` PASS
- **Next step:** PL-F01 流水线，或补 OUT/DI/EI/IRET

### 2026-07-08 — PL-F01 流水线 S01–S07 (RTL + sim)

- **Goal:** 决策锁定后实现流水控制器骨架与冒险处理
- **Main changes:**
  - 抽取 `hardwired_ctrl_core.v`；顺序 `hardwired_ctrl.v` 回归不变
  - 新增 `pipe_regs.v`、`hazard_unit.v`、`hardwired_ctrl_pipe.v`
  - `sim/tb_pipe.v` + `run_tb.ps1` 扩展
- **Validation done:** `tb_ctrl` + `tb_pipe` + `tb_manual_sto` PASS
- **Next step:** PL-F01-S08 性能文档；S09 上板

### 2026-07-08 — 板上 hazard 策略对齐图 47（PL-F01）

- **Goal:** 图 47 无 IR0–3 时流水 hazard 如何落地
- **Main changes:**
  - `hazard_unit` 双模式：`HAZARD_FINE_GRAIN=0` 板上保守 stall；`=1` 仿真精确 Rd/Rs
  - `hardwired_ctrl_pipe` 默认 `HAZARD_FINE_GRAIN=0`；`tb_pipe` 显式 `=1`
  - 更新 PL-F01_DESIGN §3.3、ADR-02、TD-008 Done
- **Validation done:** `run_tb.ps1` PASS
- **Next step:** S08 性能文档（仿真精确 CPI + 板上保守说明）；S09 `top` 切流水版

### 2026-07-08 — W3 引脚修正 F4（老师确认）

- **Goal:** UCF 与板内 W3 走线一致，取消 W3→N5 飞线
- **Main changes:** `constraints/tecplus.ucf`、`ise/tecplus.ucf`：`W3` **N5 → F4**；BOARD_TEST §3.1 仅保留 T3 飞线
- **Validation done:** 待 ISE 重综合烧录 + 用例 C（**拔掉 W3 飞线**）
- **Next step:** 板上验证 LD/ST 第三拍

### 2026-07-10 — CTL-F02 文档对齐用户最终实现

- **Goal:** 设计文档与 `hardwired_ctrl.v` 一致，消除与伙伴参考/旧方案的歧义
- **Main changes:** `CTL-F02_DESIGN` §3 重写（`int_ack_consumed` 两拍清 INTQ、W1 优先级 INTQ→IWAIT、EINT 不随响应清零）
- **Validation done:** 与用户板测通过版 RTL 对照
- **Next step:** commit CTL-F02

### 2026-07-09 — CTL-F02 顺序中断扩展（sim PASS）

- **Goal:** OUT/DI/EI/IRET + INTR 中断响应（PAUSE=INTR）；LIAR/IABUS 飞线
- **Main changes:**
  - `hardwired_ctrl.v`：EINT/INTQ/IWAIT；W1 中断优先；INTQ 电平锁存 `INTQ | (INTR&EINT)`
  - `top.v`、`constraints/tecplus.ucf`：INTR G6、LIAR N4、IABUS N5
  - `sim/tb_ctrl.v`：OUT/IRET/EI/DI + 中断 W1 序列
  - 文档：`CTL-F02_DESIGN` / `CTL-F02_IMPLEMENTATION`；BOARD_TEST §11 用例 D
- **Validation done:** `sim/run_tb.ps1` PASS
- **Next step:** ISE 重综合烧录；用户板上用例 D 验收

### 2026-07-09 — 回滚 PL-F01，实现转回顺序中断

- **Goal:** 放弃当前流水线实现，恢复顺序版作为开发基线；保留 W3=F4 的约束与接线结论
- **Main changes:**
  - 回滚删除流水相关 RTL/tb（`hardwired_ctrl_pipe`/`pipe_regs`/`hazard_unit`/`tb_pipe*`）
  - `hardwired_ctrl.v` 恢复为顺序单体实现（partner baseline replica，STO on T3↓）
  - 保持 `constraints/tecplus.ucf` 中 `W3=F4`；仅 `T3→C10` 飞线
  - 文档与 Feature 状态：PL-F01 → Deferred；下一步转中断相关指令
- **Validation done:** `sim/run_tb.ps1` PASS（顺序版）
- **Next step:** 设计 DI/EI/IRET/OUT 的顺序控制字，并对标微程序/老师资料

### 2026-07-10 — PL-F01 板上综合测试通过

- **Goal:** 程序 B 综合验收流水控制器
- **Main changes:** 修正板测文档 R3/JC 预期（`SUB R0,R0` 后 C=1）；访存排他 IF RTL
- **Validation done:** 板上程序 B 通过；`sim/run_tb.ps1` PASS
- **Next step:** 可选 commit；S08 性能文档

### 2026-07-10 — PL-F01 访存排他 IF 修复

- **Goal:** 修复 LD/ST MEM 写回用错 IR3:0（提前 IF 覆盖 IR）
- **Main changes:** `deny_if` 屏蔽 LD/ST EX+MEM 的 `LIR+PCINC`；MEM 后 `instr_cached<=0` 再 IF；设计/板测时序表更新
- **Validation done:** `sim/run_tb.ps1` PASS
- **Next step:** 板上重测程序 B；可选第二 commit

### 2026-07-10 — PL-F01 流水 RTL S01–S07（sim PASS）

- **Goal:** 按 §3 `Opcode_cache` + `allow_ex` 模型实现流水控制器 v1（无中断）
- **Main changes:**
  - 新建 `hardwired_ctrl_core.v`、`hardwired_ctrl_pipe.v`；`sim/tb_pipe.v`；`run_tb.ps1` 扩展
  - 顺序基线 `hardwired_ctrl.v` 中断逻辑对齐 partner/tb（`IWAIT` 优先、`int_ack` 含 `~IWAIT`）
- **Validation done:** `sim/run_tb.ps1` — `tb_ctrl` + `tb_manual_sto` + `tb_pipe` PASS
- **Next step:** S08 性能文档；ISE 重综合烧录流水 bit

<!-- 新条目请用 templates/progress-log-entry.template.md 格式追加在上方 -->
