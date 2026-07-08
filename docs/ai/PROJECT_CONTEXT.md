# Project Context

Last updated: 2026-07-08  
Purpose: **stable snapshot** for humans and AI. Details and churn live in designs + PROGRESS_LOG.

---

## Project in one line

**BUPT 计组课设 — 题目 A 硬布线控制器**，目标层次 **进阶（流水线）**；平台 **TEC-PLUS + ISE 14.7**；在实验箱给定数据通路上实现 Verilog 控制器。

---

## Course task (summary)

| Item | Value |
|------|-------|
| 题目 | A — 模型计算机系统控制器设计 |
| 目标层次 | 基础（顺序）→ 进阶（流水线 + 冒险 + 性能） |
| 平台 | **TEC-PLUS**，Spartan-6 XC6SLX9，**ISE 14.7** |
| 验收 | Verilog + 仿真 + 上板 + 调试日志 + 答辩 |

拓展层次（中断专题）不在范围。总需求见 [designs/REQUIREMENTS_ANALYSIS.md](./designs/REQUIREMENTS_ANALYSIS.md)。

---

## Platform & toolchain

| 项 | 值 |
|----|-----|
| 实验箱 | TEC-PLUS |
| 器件 | Xilinx Spartan-6 XC6SLX9-2FTG256 |
| 工具 | ISE 14.7、IMPACT |
| 约束 | `constraints/tecplus.ucf`（图片-47） |
| 工程 | `ise/` |
| ADR | [ADR-20260706-01](./adrs/ADR-20260706-01-platform-ise-tecplus.md) |

拨码：**硬连线模式**。

**上板飞线（必需）：** 时序发生器 **T3 → FPGA C10**，**W3 → FPGA N5**（面板 W3 灯 ≠ FPGA 输入；见 [HW-F01_BOARD_TEST §3.1](./designs/HW-F01_BOARD_TEST.md)）。

---

## Data path (given on board)

见 `docs/course/*-图片-42.jpg`。本课设 **只实现控制器**。

- **输入：** `CLR#`, `T3`, `SWA–C`, `IR4–IR7`, `W1–W3`, `C`, `Z`
- **输出：** `DRW`, `PCINC`, `LIR`, `LAR`, `LPC`, `PCADD`, `SEL0–3`, `SELCTL`, `S0–S3`, `M`, `CIN`, `ABUS`, `SBUS`, `MBUS`, `MEMW`, `LDZ`, `LDC`, `SHORT`, `LONG`, `STOP`, `ARINC`

---

## Instruction set

见 `docs/course/*-图片-45.jpg` 与 [REQUIREMENTS_ANALYSIS §3.2](./designs/REQUIREMENTS_ANALYSIS.md#32-指令级需求图片-45)。

---

## Control reference

硬布线流程：`docs/course/*-图片-43.jpg`。时序：`图片-44`。

---

## Repository layout

```text
rtl/           Verilog
sim/           Testbench、golden 向量
constraints/   tecplus.ucf
ise/           ISE 14.7 工程
scripts/       verify.ps1
docs/ai/       协作与设计
docs/course/   课设 PDF/图片
```

---

## Execution (handoff 2026-07-06)

| Phase | Feature | Status |
|-------|---------|--------|
| 工程纪律 | WF-F01 | **Done** |
| 需求/设计 | 总纲 + ADR | **Approved** |
| **基础 RTL** | CTL-F01 | **Done** |
| **仿真** | SIM-F01 | **Done**（核心 PASS） |
| **上板（基础）** | HW-F01 | **Done**（2026-07-08） |
| 进阶 | PL-F01 | Planned ← 下一步 |

详见 [EXECUTION_ROADMAP](./designs/EXECUTION_ROADMAP.md)、[ACTIVE_WORK](./ACTIVE_WORK.md)。

---

## Related docs

| Doc | Role |
|-----|------|
| [ACTIVE_WORK.md](./ACTIVE_WORK.md) | 当前任务 |
| [EXECUTION_ROADMAP.md](./designs/EXECUTION_ROADMAP.md) | 切片总览 |
| [BOOTSTRAP_DIGEST.md](./BOOTSTRAP_DIGEST.md) | 会话恢复 |
