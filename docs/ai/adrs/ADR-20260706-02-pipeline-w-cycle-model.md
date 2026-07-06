# ADR-20260706-02 — 流水线模型：按 W 周期重叠 + 冒险停顿

## Meta
- **ID:** ADR-20260706-02
- **Status:** Proposed
- **Owner:** maintainer
- **Last updated:** 2026-07-06
- **Related:** [PL-F01_DESIGN](../designs/PL-F01_DESIGN.md), [CTL-F01_DESIGN](../designs/CTL-F01_DESIGN.md)

## TL;DR

进阶层次在 **不修改实验箱数据通路** 前提下，将顺序控制器（按 W1/W2/W3 组合译码）升级为 **三级流水（IF ≈ W1 / EX ≈ W2 / MEM ≈ W3）**，用 `SHORT`/`LONG` 与内部停顿协调长短指令；冒险通过 **停顿注入（bubble）** 与 **分支冲刷** 解决；LIR/PCINC 在 IF 末拍锁存次序写 ADR。

## Context

- 课设进阶要求：顺序 → 流水，处理数据/控制冒险，分析吞吐
- 实验箱时序发生器输出 `W1,W2,W3` 作为控制器输入；`SHORT`/`LONG` 反馈机器周期长度
- 已知风险：LIR 与 PCINC 时序不当导致「吞指令」

## Decision

1. **流水阶段划分**
   - **IF：** 对应原 W1 控制（`LIR`, `PCINC`）
   - **EX：** 对应原 W2 控制（ALU、分支译码、`LAR`+`LONG` 发起）
   - **MEM：** 对应原 W3 控制（`DRW`+`MBUS` / `MEMW`）；非访存指令该级为空泡

2. **长短指令**
   - 2 周期指令（RR、分支、JMP、STP 等）：`SHORT=1`，MEM 级 bypass
   - 3 周期指令（LD、ST）：`LONG=1`，MEM 级有效

3. **冒险策略（第一版，可实现优先）**
   - **数据冒险：** 检测 EX/MEM 对 IF/EX 寄存器写后读（RAW），插入 1 个 bubble（拉低有效 W 推进或复用 `STOP` 握手 — 具体以时序发生器接口为准，在 `PL-F01-S06` 仿真验证）
   - **控制冒险：** JC/JZ/JMP 在 EX 末判定，错误取指路径 flush IF/EX 流水寄存器
   - **Load-use：** LD 后紧跟使用 Rd 的指令 → 至少 1 周期 stall（课设经典考点）

4. **LIR/PCINC 时序（防吞指令）**
   - 在 IF 级：**先** 在稳定取指后脉冲 `LIR`，**再** 于同一 W1 的较晚节拍（T3 窗口）断言 `PCINC`
   - 顺序实现（CTL-F01）即采用该次序；流水 IF 级继承并写入 ADR 注释

## Alternatives considered

| 选项 | 优点 | 缺点 |
|------|------|------|
| 全组合控制器（无流水） | 简单 | 不满足进阶 |
| 4 段经典 IF/ID/EX/WB 重构数据通路 | 教科书标准 | **超出课设范围**（数据通路固定） |
| **W 周期三级重叠 + stall** | 贴合实验箱信号 | 性能分析需自建计数 |

## Consequences

- `PL-F01` 依赖 `CTL-F01` 顺序版本为黄金参考（控制向量一致）
- 性能对比：记录顺序 CPI vs 流水有效 CPI、最大时钟频率（ISE 报告）
- 若板级 `STOP`/时序接口与仿真不一致，在 `BUG-HW-*` 记录并迭代

## Compliance

- Feature: `PL-F01`
- Slice: `PL-F01-S01`–`S09`

## Supersedes / Superseded by

待 `PL-F01` 验收后可将 Status 改为 Accepted。
