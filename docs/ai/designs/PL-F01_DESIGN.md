# PL-F01 — 流水线硬布线控制器 Design Spec

## Meta
- **ID:** PL-F01
- **Type:** Feature
- **Status:** In Progress
- **Owner:** maintainer
- **Last updated:** 2026-07-08
- **Related:**
  - [PL-F01_IMPLEMENTATION](./PL-F01_IMPLEMENTATION.md)
  - [CTL-F01_DESIGN](./CTL-F01_DESIGN.md)
  - [ADR-20260706-02](../adrs/ADR-20260706-02-pipeline-w-cycle-model.md)

## TL;DR

在 CTL-F01 顺序控制器 **语义不变** 前提下，增加流水寄存器与冒险单元，实现 IF/EX/MEM 重叠；解决 load-use 与 RAW、控制冒险；手动 SW 模式 **bypass 流水**。

## Scope

- **In:** `hardwired_ctrl_pipe.v`、`pipe_regs.v`、`hazard_unit.v`、`hardwired_ctrl_core.v`（S02 抽取）
- **Out:** 修改实验箱数据通路、拓展中断专题（OUT/DI/EI/IRET，TD-004）

## Reader quick start

1. [ADR-20260706-02](../adrs/ADR-20260706-02-pipeline-w-cycle-model.md)
2. 本文件
3. [PL-F01_IMPLEMENTATION](./PL-F01_IMPLEMENTATION.md)

---

## 1) 背景与目标

课设进阶：顺序 → 流水，处理数据/控制冒险，量化性能。

**前置：** CTL-F01 + HW-F01 基础上板 Done。

---

## 2) 已锁定决策（2026-07-08）

| # | 决策 | 结论 |
|---|------|------|
| D1 | 阶段模型 | **IF≈W1 / EX≈W2 / MEM≈W3**（ADR-02） |
| D2 | 手动 SW | **`mode≠RUN` 纯顺序 bypass**，与流水线无关 |
| D3 | 模块拆分 | 独立 `*_pipe` / `pipe_regs` / `hazard_unit` / `core` |
| D4 | 顺序版 | **保留** `hardwired_ctrl.v` 作回归基线 |
| D5 | 板上顶层 | S09 前 `top` 仍用顺序版；S09 切 `hardwired_ctrl_pipe` |
| D6 | Stall | **冻结 IF/EX 寄存器**；不用 `STOP` 停时序 |
| D7 | 流水锁存沿 | **W 相位内 `negedge T3`** |
| D8 | 控制字 | 每拍按当前 W 相位 mux 单路 core 输出 |
| D9 | EX/MEM 寿命 | 短指令 **W2 末** 失效；LD/ST **W3 末** 失效 |
| D10 | 数据冒险 | **双模式**：仿真精确 Rd/Rs；**上板保守 opcode 级**（见 §3.4） |
| D11 | 控制冒险 | **JC/JZ/JMP taken → flush IF/EX**（W2 判定） |
| D12 | 指令范围 | 10 条 RUN（同 CTL-F01）；不含 TD-004 四条 |
| D13 | IR 接口 | **板上仅 IR4–7**（图 47）；IR3–0 在数据通路内部，不送 FPGA |
| D14 | Hazard 参数 | `HAZARD_FINE_GRAIN=0` 上板默认；仿真 `=1` |

---

## 3) 结构

```text
hardwired_ctrl_pipe.v
  ├── pipe_regs.v          # IF/EX + EX/MEM；EX/MEM 跨 W2(/W3)
  ├── hazard_unit.v        # stall / branch flush
  └── hardwired_ctrl_core  # CTL-F01 组合译码（顺序+流水复用）

hardwired_ctrl.v           # 顺序包装（上板基线，含 STO）
```

### 3.1 RUN 模式数据通路

```text
W1: core(w1) → LIR, PCINC（stall 时 PCINC=0）
    negedge T3: IF/EX ← fetch；若 EX/MEM 空闲则 EX/MEM ← IF/EX
W2: core(w2, exmem.op) → EX 控制；SHORT=1（非访存）
    negedge T3: 短指令清除 exmem_valid；分支 taken → flush IF/EX
W3: core(w3, exmem.op) → MEM（仅 LD/ST）
    negedge T3: 清除 exmem_valid
```

### 3.2 冒险（仿真：精确模式）

| 冒险 | 检测（`HAZARD_FINE_GRAIN=1`） | 动作 |
|------|-------------------------------|------|
| Load-use | EX/MEM=LD 且 Rd 命中 IF/EX 源寄存器 | stall@W1 |
| RAW (RR) | EX/MEM 写 Rd，IF/EX RR 读 Rs | stall@W1 |
| 控制 | EX 级 JC/JZ/JMP taken | flush IF/EX |

### 3.3 平台约束与板上保守模式（图 47）

TEC-PLUS 给控制器的指令输入**只有 IR4–IR7**（操作码）。Rd/Rs（IR3–0）由板内数据通路使用，与顺序硬布线设计一致。

**推论：** FPGA 无法做寄存器级 hazard 比较；**不飞线 IR0–3**。

`hazard_unit` 参数 `HAZARD_FINE_GRAIN`（`hardwired_ctrl_pipe` 默认 **0**）：

| 模式 | 条件 | 行为 |
|------|------|------|
| **板上（0）** | EX/MEM=LD 且 IF/EX 有有效指令 | 一律 stall（load-use 保守） |
| **板上（0）** | EX/MEM 写寄存器 且 IF/EX 为 ADD/SUB/AND | 一律 stall（RAW 保守） |
| **仿真（1）** | 有完整 IR7–0 | 按 Rd/Rs 精确比较 |

板上可能多停几拍，但**保证正确**；性能报告用仿真精确模式测算 CPI，板上演示正确性。

`top` 上板时：`HAZARD_FINE_GRAIN=0`，`IR0–IR3` 接 `1'b0`（或省略端口由顶层 tie-off）。

### 3.4 性能计数（S08）

`cnt_cycles`, `cnt_stall`, `cnt_branch_flush` → `PL-F01_PERFORMANCE.md`

---

## 4) 验收标准

- [x] `tb_ctrl` 顺序回归 PASS（core 抽取后）
- [x] `tb_pipe` 流水 fetch/EX/MEM、stall、手动 bypass PASS
- [ ] 用例 C 程序级结果与顺序版一致
- [ ] 板上回归（S09）
- [ ] `PL-F01_PERFORMANCE.md`

---

## 7) Status note

**In Progress** — S01–S07 RTL + `tb_pipe` 初版 PASS；待 S08 性能文档、S09 上板。

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-06 | 初稿 |
| 2026-07-08 | 决策锁定；实现 pipe_regs/hazard/pipe；抽取 core |
| 2026-07-08 | 图 47 仅 IR4–7：板上保守 hazard（`HAZARD_FINE_GRAIN=0`） |
