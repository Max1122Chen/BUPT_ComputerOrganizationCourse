# ADR-20260706-02 — 流水线模型：按 W 周期重叠 + 冒险停顿

## Meta
- **ID:** ADR-20260706-02
- **Status:** **Accepted**
- **Owner:** maintainer
- **Last updated:** 2026-07-08
- **Related:** [PL-F01_DESIGN](../designs/PL-F01_DESIGN.md), [CTL-F01_DESIGN](../designs/CTL-F01_DESIGN.md)

## TL;DR

进阶层次在 **不修改实验箱数据通路** 前提下，将顺序控制器升级为 **三级流水（IF≈W1 / EX≈W2 / MEM≈W3）**；**手动 SW bypass 流水**；冒险用 **冻结 IF/EX（stall）** 与 **分支 flush**；LIR/PCINC 次序继承 CTL-F01。

## Decision (locked 2026-07-08)

1. **阶段：** IF=W1, EX=W2, MEM=W3；短指令 MEM bubble + `SHORT`；LD/ST `LONG`+第三拍。
2. **EX/MEM 寄存器：** 跨 W2（短指令 W2 末失效）或 W2+W3（访存 W3 末失效）；**不在执行中途被下一 W1 覆盖**。
3. **Stall：** 冻结 `pipe_regs` IF/EX 更新；**不拉 STOP**；`PCINC` 在 stall 时屏蔽。
4. **冒险：** load-use + RR RAW（1 bubble）；JC/JZ/JMP taken 在 W2 flush IF/EX。
5. **模块：** `hardwired_ctrl_core` 复用；`hardwired_ctrl` 保留顺序上板基线。
6. **IR / 数据冒险：** 图 47 控制器仅 **IR4–7**；板上 `HAZARD_FINE_GRAIN=0`（opcode 保守 stall）；仿真 `=1`（Rd/Rs 精确比较）。**不要求 IR0–3 飞线。**

## Consequences

- 仿真：`sim/tb_pipe.v` 用 `HAZARD_FINE_GRAIN=1`；`tb_ctrl` + `tb_pipe` PASS
- 上板：`top` 默认 `HAZARD_FINE_GRAIN=0`，`IR0–3` tie-off

## Supersedes / Superseded by

—
