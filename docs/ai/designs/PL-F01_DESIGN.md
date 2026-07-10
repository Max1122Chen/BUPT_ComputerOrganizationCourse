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

在 CTL-F01 顺序语义不变前提下，用 **`allow_ex` 分相 + `Opcode_cache` 单源译码** 实现 IF/EX/MEM 重叠（MEM 排他）；v1 **仅基础 10 条、无中断**；手动 SW bypass 流水。§2 为作者原始思路；§3 起为对齐后的实现规格。

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

指令重叠例子：

| 指令/Timing | any instruction cycle1 | c2   | c3     | ...  |      |
| ----------- | ---------------------- | ---- | ------ | ---- | ---- |
| **I1**      | IF                     | EX   | MEM    |      |      |
| **I2**      |                        | IF   | bubble | EX   |      |
| **I3**      |                        |      |        | IF   | EX   |

any instruction cycle的意思是这条指令可能在任何一个W时进行，不再是W1只能IF，W2只能EX。而是假如现在是W2，照样可以IF，甚至我一直拉高SHORT，指令周期不再由W来塑造，而是由T3来分割了，那照样也能成立。



我的理解是：

1. 周期1：IF，激活LIR，PCINC。

2. 周期2：此时控制已经拿到第一条的Opcode，可以译码出执行控制字，这时控制器已经可以判断指令1是什么了，此时指令2到IF，没有冲突，所以这个周期激活的控制字是LIR，PCINC，以及指令1的执行控制字。但是由于控制器知道这条指令要访存，所以下一周期不允许EX或IF，只能bubble。

   并且由于指令1的访存要下一个周期才执行，所以得缓存指令1的Opcode，这样下一个周期才知道要怎么译码出指令1的访存操作。

3. 周期3：这个周期需要译码出指令1的MEM控制字，这个周期输出的控制字是指令1访存控制字。这个周期需要阻止指令2的EX

4. 周期4：译码指令2得到指令2的执行控制字，所以这个周期的控制字是LIR，PCINC和指令2执行控制字。

5. 周期5：由上可知



我们需要什么：

- 一个四位Opcode控制器内寄存器，用于缓存当前最先头的一条指令字，这个寄存器只对3周期指令有意义，这个寄存器的更新时机是EX和IF重叠的阶段，但是是在第二条指令的IF控制字输出之前。也就是说，进到一个周期，假如这个周期是EX周期，先立即缓存Opcode，再给出控制字。
- 一个"allow_ex"“flag，初始为真，“allow_ex”为真也就意味着现在是EX周期，这个周期开始时已经缓存了当前正在处理的指令的Opcode，现在IR7~4上也是当前这条指令的Opcode，所以可以用缓存或IR7~4上译出这条指令的EX阶段控制字，也就是顺序版中的指令的W2时的内容。
- 一个“指令已取出”flag，初始为假，因为MEM不允许和IF同时执行，所以MEM之后Opcode_cache中还是旧指令，所以下一周期只取指，没有可执行的指令
- 一个deny_ex在T3时更新allow_ex，来保证指令周期分明。



逻辑伪代码：

```
初始赋值：
reg instr_fetched = 0;
reg allow_ex = 1;
reg handling_memins = 0;
reg [3:0] Opcode_cache = 0000;

// Update allow_ex flag only on T3 to make sure instr cycle
when T3:
	allow_ex = !deny_ex;
	

whenever:	// always @(*)
	clear Output;
	
	if (allow_ex == true)
	{
		if(instr_fetched == ture)
		{
			Output += Decode(Opcode_cache).EXControlWord;
            if (Opcode_cache is a memory accessing instr)
            {
                deny_ex = true;
            }
		}
		
		// Only fetch instr, no execution. 
        // This can happen at the begin of the program or after a memory access.
        Opcode_cache = IR7~4;
        output+= LIR,PCINC
		
	}
	else	// Memory accessing time
	{
		output += Decode(Opcode_cache).MEMControlWord;
		deny_ex = false;
		instr_fetched = false;
	}

```



---

## 3) Agent 补充 — 与 §2 对齐的正式规格

> **不修改 §2 原文。** 本节把讨论中已对齐的语义写成可实现规格；与 §2 冲突时以 **本节 + RTL** 为准，§2 保留作讨论记录。

### 3.1 核心原则

| 原则 | 说明 |
|------|------|
| **译码单源** | EX/MEM 控制字 **只** 来自 `Opcode_cache`，不用 `IR7:4` 直接译码 |
| **cache 更新时机** | **仅** 在 EX 型周期（`allow_ex=1`）入口，且在 **`LIR+PCINC` 之前**，将 **当时 IR 上的 opcode** 采样进 `Opcode_cache` |
| **IF 不写 cache** | IF 只输出 `LIR+PCINC`；IR 变化不影响本拍已锁定的 cache |
| **分相** | `allow_ex=1` → EX 型拍（可 IF+EX）；`allow_ex=0` → MEM 型拍（只 MEM，禁止 IF/EX） |
| **MEM 排他** | MEM 型拍期间不更新 cache、不取指、不执行其它指令的 EX（§2 表中的 bubble） |

### 3.2 状态寄存器（命名对齐讨论）

| 信号 | 类型 | 含义 |
|------|------|------|
| `Opcode_cache[3:0]` | reg | 当前译码用的操作码（EX 型拍入口采样；MEM 型拍沿用直至消费完） |
| `instr_cached` | reg | **控制器 cache 已有效**（≠ IR 里是否有指令）；为 1 时 EX 型拍可输出 EX 控制字 |
| `allow_ex` | reg | 1=EX 型拍，0=MEM 型拍；`T3↓` 更新：`allow_ex <= !deny_ex` |
| `deny_ex` | reg | EX 型拍发现 `Opcode_cache` 为 LD/ST 时置 1，下一 `T3↓` 强制进入 MEM 型拍 |

§2 伪代码中的 `instr_fetched` 在实现中统一为 **`instr_cached`**（见上表）。

### 3.3 组合输出规则（每个全局节拍）

```text
EX 型拍 (allow_ex=1):
  1. （时序已在拍初完成）Opcode_cache 已有效 → instr_cached=1
  2. 若 instr_cached：Output += Decode(Opcode_cache, stage=EX)
     若 LD/ST：deny_ex = 1（时序在 T3↓ 生效）
  3. Output += LIR, PCINC          // IF，不改变 Opcode_cache

MEM 型拍 (allow_ex=0):
  1. Output += Decode(Opcode_cache, stage=MEM)
  2. deny_ex = 0
  3. instr_cached = 0              // MEM 消费完队头；下一 EX 型拍再采样
  4. 无 LIR/PCINC（MEM 与 IF 互斥，§2 c3）
```

### 3.4 时序表实例（LD → ADD → INC，与 §2 一致）

| 周期 | 型 | IR（板） | Opcode_cache | 输出摘要 |
|------|----|----------|--------------|----------|
| c1 | EX | →I1 | （采 I1 前无 EX） | 只 IF：I1 进 IR |
| c2 | EX | I1→I2 | I1 | EX(I1)+IF(I2)；LD → `deny_ex` |
| c3 | MEM | I2 | I1 | MEM(I1)；I2 bubble |
| c4 | EX | I2→I3 | I2 | EX(I2)+IF(I3) |
| c5 | EX | I3→I4 | I3 | EX(I3)+IF(I4) |

c1 细节：首拍 `instr_cached=0`，仅 IF；c2 入口采 I1 进 cache 后 `instr_cached=1`。

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
- 板上仅 IR4–7（v1 用 MEM 排他 + bubble，**不依赖** IR0–3 精确 hazard）。

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
| 2026-07-10 | §3–§6 Agent 补充（Opcode_cache 单源译码、instr_cached、MEM 排他）；§2 保留不动 |
| 2026-07-06 | 初稿                                              |
| 2026-07-08 | 决策锁定；实现 pipe_regs/hazard/pipe；抽取 core           |
| 2026-07-08 | 图 47 仅 IR4–7：板上保守 hazard（`HAZARD_FINE_GRAIN=0`） |

