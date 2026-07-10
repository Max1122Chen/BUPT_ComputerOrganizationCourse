# PL-F01 — 流水线硬布线控制器 Design Spec

## Meta

- **ID:** PL-F01
- **Type:** Feature
- **Status:** In Progress
- **Owner:** maintainer
- **Last updated:** 2026-07-10
- **Related:**
  - [PL-F01_IMPLEMENTATION（out of date）](./PL-F01_IMPLEMENTATION.md)
  - [CTL-F01_DESIGN](./CTL-F01_DESIGN.md)

## TL;DR

在 CTL-F01 顺序语义不变前提下，用 **`allow_ex` 分相 + `Opcode_cache` 单源译码** 实现 IF/EX 重叠；**LD/ST 的 EX+MEM 与 IF 完全互斥**（保 IR3:0）；v1 **仅基础 10 条、无中断**。

## Scope

- **In:** `hardwired_ctrl_pipe.v`、`hardwired_ctrl_core.v`（从 `hardwired_ctrl.v` 抽取译码）、`sim/tb_pipe.v`；`top` 可选切换顺序/流水
- **Out:** 修改实验箱数据通路；**CTL-F02 中断**（留 `feat/ctl-seq-interrupt` 分支，流水稳定后再追）

## Reader quick start

1. [ADR-20260706-02](../adrs/ADR-20260706-02-pipeline-w-cycle-model.md)
2. 本文件
3. [PL-F01_IMPLEMENTATION](./PL-F01_IMPLEMENTATION.md)

---

## 1) 背景与目标

课设进阶：顺序 → 流水，处理数据/控制冒险，量化性能。

**前置：** CTL-F01 + HW-F01 基础上板 Done。

---

## 2）我的理解

**根因（板上实测）：** 数据通路在 LD/ST 的 MEM 拍用 **IR3:0** 选寄存器；若 EX 或 MEM 期间做 IF，`LIR` 会覆盖 IR，写回目标错误。

**错误演进（保留讨论记录）：**

| 版本 | 问题 |
|------|------|
| v0：c2 EX+IF，c3 MEM+bubble | IF 过早，MEM 拍 IR 已是下一条 |
| v1：c3 MEM 与 IF 同拍 | 仍覆盖 IR |

**正确时序（LD/ST 访存排他）：**

| 指令/Timing | c1 | c2 | c3 | c4 | c5 | c6 |
| ----------- | -- | -- | -- | -- | -- | -- |
| **I1 (LD)** | IF | EX | MEM | | | |
| **I2 (ADD)** | | | | IF | EX+IF | |
| **I3 (INC)** | | | | | | EX+IF |

规则：

1. **短指令**：EX 型拍可 **EX + IF** 重叠。
2. **LD/ST**：EX 型拍 **只 EX、不 IF**；MEM 型拍 **只 MEM、不 IF**；MEM 完成后下一拍才 IF 下一条。
3. `Opcode_cache` 缓存 **IR7:4**；**不缓存 IR3:0**——靠 IR 在 EX+MEM 期间不被 `LIR` 破坏。

any instruction cycle：相位由 `allow_ex`/`deny_ex` 与 `T3↓` 推进，不绑定 W1=IF。

### 2.1 状态与伪代码（2026-07-10 修订）

```
reg instr_cached = 0;
reg allow_ex = 1;
reg deny_ex = 0;
reg [3:0] Opcode_cache = 0000;

wire is_mem_op = (Opcode_cache == LD) || (Opcode_cache == ST);
wire deny_if = instr_cached && ((allow_ex && is_mem_op) || !allow_ex);

when T3↓:
    if (allow_ex && instr_cached && is_mem_op)
        deny_ex <= 1; allow_ex <= 0;
    else if (!allow_ex) begin          // MEM 结束
        deny_ex <= 0; instr_cached <= 0; allow_ex <= 1;
    end

always @(*):
    clear Output;
    if (allow_ex) begin
        if (instr_cached)
            Output += Decode(Opcode_cache, EX);
        if (!deny_if && !branch_flush)
            Output += LIR, PCINC;
        // T3↓: 首拍 IF 或短指令 EX+IF 后采样下一条 opcode
    end else if (instr_cached) begin
        Output += Decode(Opcode_cache, MEM);   // 无 IF
    end
```

---

## 3) Agent 补充 — 与 §2 对齐的正式规格

> §2 伪代码为作者修订版；本节为实现规格。冲突时以 **本节 + RTL** 为准。

### 3.1 核心原则

| 原则 | 说明 |
|------|------|
| **译码单源** | EX/MEM 控制字 **只** 来自 `Opcode_cache` |
| **cache 内容** | 仅 **IR7:4**；IR3:0 依赖 IR 寄存器在访存期间不被覆盖 |
| **短指令重叠** | EX 型拍：`EX + IF`（`LIR+PCINC`） |
| **访存排他** | LD/ST 的 **EX 型拍与 MEM 型拍均禁止 IF**（`deny_if`） |
| **分相** | `allow_ex=1` → EX 型；`allow_ex=0` → MEM 型（仅 LD/ST） |

### 3.2 状态寄存器

| 信号 | 含义 |
|------|------|
| `Opcode_cache[3:0]` | 队头指令操作码 |
| `instr_cached` | cache 有效；MEM 结束后清 0，下一拍先 IF |
| `allow_ex` | 1=EX 型，0=MEM 型 |
| `deny_ex` | LD/ST 的 EX 拍末置 1，下一拍进 MEM |
| `deny_if`（组合） | `instr_cached && ((allow_ex&&is_mem_op) \|\| !allow_ex)` |

### 3.3 组合输出规则

```text
EX 型拍 (allow_ex=1):
  若 instr_cached：Output += Decode(Opcode_cache, EX)
  若 LD/ST：下一 T3↓ 进 MEM（deny_ex）
  若 !deny_if && !branch_flush：Output += LIR, PCINC

MEM 型拍 (allow_ex=0):
  Output += Decode(Opcode_cache, MEM)
  无 LIR/PCINC
  T3↓：instr_cached<=0，allow_ex<=1
```

### 3.4 时序表（LD → ADD → INC）

| 周期 | 型 | IR（板） | Opcode_cache | 输出摘要 |
|------|----|----------|--------------|----------|
| c1 | EX | →LD | — | 只 IF |
| c2 | EX | LD | LD | 只 EX(LD)；**无 IF** |
| c3 | MEM | LD | LD | 只 MEM(LD)；**无 IF** |
| c4 | EX | LD→ADD | — | 只 IF(ADD) |
| c5 | EX | ADD→INC | ADD | EX(ADD)+IF(INC) |
| c6 | EX | INC→… | INC | EX(INC)+IF |

### 3.5 指令长度

| 类型 | 节拍 | `deny_ex` |
|------|------|-----------|
| 短指令（ADD…JMP, STP） | EX 型 → 结束 | 不置位 |
| LD/ST | EX 型 → MEM 型 → 结束 | EX 型发现 LD/ST 时置位 |

`SHORT`/`LONG` 与顺序版相同：短指令在 EX 型拍末拉 `SHORT`；LD/ST 在 EX 型拍拉 `LONG`。

### 3.6 与全局 W1/W2/W3 的关系

§2「any instruction cycle」：**流水相位由 `allow_ex` 决定，不绑定「W1=IF」**。

实现建议（v1）：

- 仍接平台 `W1/W2/W3/T3`；用 **`T3↓` 推进 `allow_ex`/`deny_ex`/`instr_cached`/cache 采样**。
- 组合输出在 `always @(*)` 中根据 `allow_ex` 与 `instr_cached` 驱动；与当前全局 W 线无固定 IF/EX/MEM 映射。

### 3.7 控制冒险（§2 未写，v1 必做）

JC/JZ/JMP 在 **EX 型拍** 判定 taken 时：

- 屏蔽本拍或下一拍的 `LIR+PCINC`（不取错误路径）；
- 清空误取的 `instr_cached` / cache 状态；
- 细节在 S06 用 `tb_pipe` 向量锁定。

### 3.8 手动模式

`mode != RUN`：**bypass 流水**，直接复用 `hardwired_ctrl` 顺序路径（或 `allow_ex` 恒 1 且禁止重叠），与 CTL-F01 行为一致。

### 3.9 与 ADR-20260706-02 的关系

ADR-02 中的「三槽 `pipe_regs` + IF 绑 W1」模型 **已被 §2 新模型替代**。保留 ADR 中：

- 不修改数据通路；
- 手动 bypass；
- 板上仅 IR4–7；**LD/ST 靠访存排他保 IR3:0**，不依赖 IR 字段 cache 或 hazard 单元。

实现以 **本节 + §2 时序表** 为准；ADR 待 PL-F01 稳定后修订。

---

## 4) 模块划分（实现向）

| 模块 | 职责 |
|------|------|
| `hardwired_ctrl_core` | 组合：`Decode(opcode, stage, mode)` → 控制字（从 `hardwired_ctrl.v` RUN 路径抽取） |
| `hardwired_ctrl_pipe` | `Opcode_cache`、`allow_ex`、`deny_ex`、`instr_cached`；分相调度；输出 MUX |
| `hardwired_ctrl` | **顺序基线**（含 CTL-F02），上板对照 / 回退 |
| `top` | 参数或实例选择 seq / pipe（S09） |

**不采用** 旧版 `pipe_regs`/`hazard_unit` 三槽绑 W 结构（已回滚，勿复用）。

---

## 5) 验收标准（v1）

- [ ] `tb_ctrl` 仍 PASS（顺序基线未破坏）
- [ ] `tb_pipe`：c1–c5 类重叠 + LD 三拍 + bubble
- [ ] `tb_pipe`：JC/JZ/JMP taken flush
- [ ] 与顺序版同一程序控制语义等价（仿真）
- [ ] 上板：基础用例 A/C + 流水对比演示（S09）
- [ ] `PL-F01_PERFORMANCE.md`（CPI / 停顿，S08）

---

## 6) Status note

**In Progress（设计）** — §2 作者思路保留；§3 为实现对齐规格。RTL 待按 [PL-F01_IMPLEMENTATION](./PL-F01_IMPLEMENTATION.md) 重做。

---

## 变更记录


| 日期         | 说明                                              |
| ---------- | ----------------------------------------------- |
| 2026-07-10 | 访存排他：LD/ST EX+MEM 禁止 IF；修正 IR 冲突根因与 §3.4 六拍表 |
| 2026-07-10 | §3–§6 Agent 补充（Opcode_cache 单源译码、instr_cached、MEM 排他）；§2 保留不动 |
| 2026-07-06 | 初稿                                              |
| 2026-07-08 | 决策锁定；实现 pipe_regs/hazard/pipe；抽取 core           |
| 2026-07-08 | 图 47 仅 IR4–7：板上保守 hazard（`HAZARD_FINE_GRAIN=0`） |

