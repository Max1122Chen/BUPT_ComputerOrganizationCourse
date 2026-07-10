# PL-F02 — 流水线中断扩展 Design Spec

## Meta

- **ID:** PL-F02
- **Type:** Feature
- **Status:** In Progress
- **Owner:** maintainer
- **Last updated:** 2026-07-10
- **Related:**
  - [PL-F01_DESIGN](./PL-F01_DESIGN.md)
  - [CTL-F02_DESIGN](./CTL-F02_DESIGN.md)
  - RTL 真值：`rtl/controller/hardwired_ctrl_pipe.v`

## TL;DR

在 `PL-F01` 单发射两相流水线上加入 **可演示的中断响应**：`INTR` 在 `T3↓` 捕获；一旦捕获，**停止继续 IF**，允许当前最老指令自然完成（短指令到 EX 结束，`LD/ST` 到 MEM 结束）。流水线排空后，中断子状态机 **沿用 `feat/ctl-seq-interrupt` 的正确业务语义**：`INTQ` 在 `LIAR` 真正消费完成前保持有效，先经历 **两拍 `LIAR+STOP`**，再进入 `SBUS+LPC` 装入口，之后从空流水重新取指。

## Scope

- **In:** `hardwired_ctrl_pipe.v`、`hardwired_ctrl_core.v`、`top.v`、`sim/tb_pipe.v`
- **In:** `OUT/DI/EI/IRET` 在流水版 RUN 模式可用
- **Out:** 完整现场保存；多发射；异常回滚；数据通路改造

## Reader quick start

1. 本文件：流水版中断边界与状态机
2. [CTL-F02_DESIGN](./CTL-F02_DESIGN.md)：顺序版板级中断握手参考
3. `hardwired_ctrl_pipe.v`：代码真值

---

## 1) 目标与非目标

### 1.1 目标

- 在 **流水版 top** 上演示 `EI -> INTR -> LIAR -> 装 ISR 入口 -> IRET 返回`
- 中断不破坏 `PL-F01` 已验证的访存排他 IF 规则
- 保持“当前最老指令完成后再进中断”的语义

### 1.2 非目标

- 不实现精确异常系统或乱序回滚
- 不保存通用寄存器现场；ISR 自行约束
- 不追求与顺序版 `W1/W2/W3` 内部实现完全同构，只要求板级可演示语义一致

---

## 2) 语义定义

### 2.1 中断捕获

`INTR` 可在任意时刻为高；控制器在 **`T3↓`** 采样并置位 `INTQ`。

```text
T3↓: if (INTR & EINT) INTQ <= 1
```

### 2.2 响应边界

一旦 `INTQ=1`：

1. **停止继续 IF**，不再发出新的 `LIR+PCINC`
2. 允许流水线中 **最老的有效指令** 自然完成
3. younger、尚未进入执行承诺边界的指令不得再进入 `opcode_cache`
4. 当流水线排空后，才进入中断入口握手

### 2.3 返回点

返回点定义为：

> **当前最老指令完成之后，本来应当开始执行的下一条指令。**

因此若 `INTR` 到来时有一条 younger 指令仅被 IF 到 `IR`、但尚未进入 `opcode_cache` 执行，则该指令在中断前 **不提交**；`IRET` 返回后由正常 IF 重新取回。

---

## 3) 流水阶段下的中断行为

### 3.1 IF-only 周期命中中断

此时当前周期刚完成一条 IF；该指令视为“已进入机器”，下一周期仍需执行：

```text
cN   : IF(Ik), 同拍采样到 INTR
T3↓  : INTQ<=1, opcode_cache<=Ik
cN+1 : EX(Ik), 禁止继续 IF
cN+2 : 若 Ik 为短指令 -> pipe_idle，进入 LIAR
       若 Ik 为 LD/ST   -> MEM(Ik) 后再 LIAR
```

### 3.2 EX 周期命中中断

当前 EX 指令必须完成；同拍错误/预取的 younger 指令不得进入执行：

```text
cN   : EX(Ik) [+ 可能已有 IF(Ik+1)]
T3↓  : INTQ<=1; Ik 正常完成；丢弃 Ik+1 的执行推进
cN+1 : 若 Ik 为短指令 -> pipe_idle，进入 LIAR
       若 Ik 为 LD/ST   -> MEM(Ik) 后再 LIAR
```

### 3.3 MEM 周期命中中断

访存必须完整结束，尤其 `LD/ST` 依赖活的 `IR3:0`：

```text
cN   : MEM(Ik)
T3↓  : INTQ<=1, MEM 完成
cN+1 : pipe_idle，进入 LIAR
```

---

## 4) 状态与判定线

### 4.1 新增/复用寄存器

| 寄存器 | 含义 |
|--------|------|
| `EINT` | 中断允许；`EI` 置 1，`DI` 置 0 |
| `INTQ` | 已捕获中断请求 |
| `IWAIT` | 已保存断点，等待装入 ISR 入口 |
| `int_ack_consumed` | 第一拍 `LIAR` 已执行的确认位；用于延后清 `INTQ` |
| `allow_ex` / `instr_cached` / `opcode_cache` | 复用 `PL-F01` 流水状态 |

### 4.2 关键组合线

```verilog
wire pipe_idle  = pipe_run && allow_ex && !instr_cached;
wire int_stall  = pipe_run && (INTQ || IWAIT);
wire int_ack    = pipe_idle && W1 && INTQ && EINT;
wire int_load   = pipe_idle && W1 && IWAIT;
wire set_ei     = pipe_run && stage_ex && (opcode_cache == EI);
wire set_di     = pipe_run && stage_ex && (opcode_cache == DI);
```

### 4.3 IF 屏蔽规则

`PL-F01` 原有访存排他规则扩展为：

```verilog
deny_if = mem_exclusive_if || int_stall;
```

其中 `mem_exclusive_if` 保持原语义：

- `LD/ST` 的 EX 拍不允许 IF
- `LD/ST` 的 MEM 拍不允许 IF

`int_stall` 语义：

- `INTQ=1`：停止注入新指令，等待 pipe drain 后进入 `LIAR`；在 `LIAR` 真正消费完成前持续保持
- `IWAIT=1`：停止 IF，等待下一 `W1` 用 `SBUS+LPC` 装入口

---

## 5) `T3↓` 时序规格

### 5.1 中断状态

```verilog
if (set_ei)      EINT <= 1;
else if (set_di) EINT <= 0;

if (int_ack && !int_ack_consumed)
    int_ack_consumed <= 1;
else if (int_ack && int_ack_consumed) begin
    INTQ <= 0;
    int_ack_consumed <= 0;
end else
    INTQ <= (INTR & EINT);

if (int_ack_consumed)
    IWAIT <= 1;
else if (int_load)
    IWAIT <= 0;
```

说明：

- 与 `main` 上曾出现的错误版本不同，**第一次 `LIAR` 不能立即清 `INTQ`**
- `EINT` 不随响应自动清零；其职责是控制是否采样新的 `INTR`
- `INTQ` 的职责是表明“当前中断请求是否已完成断点保存”

### 5.2 流水推进

#### 正常短指令

若无 `INTQ`，维持 `PL-F01` 原模型：EX 结束后可把 IF 的 younger 指令推进到 `opcode_cache`。

#### EX 周期已捕获中断

若当前最老指令在 EX 完成，同时 `INTQ` 已置位或本拍采到 `INTR`：

- **不得** 再把 younger `IR7:4` 推进到 `opcode_cache`
- 直接转为 `pipe_idle`
- 后续按 `INTQ -> LIAR(1) -> LIAR(2) -> IWAIT/load` 推进

#### MEM 周期已捕获中断

MEM 拍结束后自然回到 `pipe_idle`；下一 `W1` 响应中断。

---

## 6) RUN 组合优先级

RUN 模式下优先级定义为：

```text
1. pipe_idle & W1 & INTQ       -> LIAR + STOP + SHORT
2. pipe_idle & W1 & IWAIT      -> SBUS + LPC + SHORT
3. else if pipeline executing  -> 正常 EX / MEM 译码
4. else if !deny_if            -> LIR + PCINC
```

语义重点：

- `LIAR` / `SBUS+LPC` 只在 **空流水 + W1** 时发生，保证板测可观察
- `LIAR` 优先于 `IWAIT`；只要 `INTQ` 还未清掉，就继续断点保存
- EX/MEM 一旦开始，不被中断直接打断

---

## 7) 指令支持

流水版 RUN 模式扩展为 14 条指令：

| 类别 | 指令 |
|------|------|
| 基础 | `ADD SUB AND INC LD ST JC JZ JMP STP` |
| 中断 | `OUT DI EI IRET` |

约束：

- `EI` / `DI`：无控制字副作用，只在 `T3↓` 改 `EINT`
- `IRET`：执行拍输出 `IABUS + LPC`
- `OUT`：沿用顺序版 ALU/总线组合

---

## 8) 例子时序

### 8.1 短指令 EX 命中中断

```text
c1: IF(ADD)
c2: EX(ADD) + IF(INC), 同拍采到 INTR
T3↓: INTQ<=1, ADD 完成, 丢弃 INC 的执行推进
c3: W1 & pipe_idle -> LIAR + STOP
c4: W1 & pipe_idle -> LIAR + STOP
c5: W1 & IWAIT     -> SBUS + LPC
c6: IF(ISR[0])
```

### 8.2 LD 的 MEM 命中中断

```text
c1: IF(LD)
c2: EX(LD)                // 原有规则：无 IF
c3: MEM(LD), 同拍采到 INTR
T3↓: INTQ<=1, LD 完成
c4: W1 & pipe_idle -> LIAR + STOP
c5: W1 & pipe_idle -> LIAR + STOP
c6: W1 & IWAIT     -> SBUS + LPC
c7: IF(ISR[0])
```

---

## 9) 验证要求

### 9.1 仿真

- `tb_pipe` 保留 `PL-F01` 全部回归
- 新增：
  - `EI -> INTR -> LIAR -> load -> IF ISR`
  - EX 命中中断时 younger 指令不推进
  - MEM 命中中断时 `LD/ST` 完成后再响应
  - `IRET` 输出 `IABUS + LPC`

### 9.2 上板

- `top.v` 不再 tie-off `LIAR/IABUS`
- 复用 CTL-F02 飞线：`INTR=G6`, `LIAR=N4`, `IABUS=N5`
- 需要新的流水版中断板测程序

---

## 10) 风险

| 风险 | 缓解 |
|------|------|
| EX 命中中断时 younger 指令误推进到 `opcode_cache` | `T3↓` 明确在 `INTQ/intr_capture` 下丢弃 younger |
| 中断与分支 flush 竞争 | `branch_flush` 优先清空当前错误路径；中断只在已完成最老指令后生效 |
| `INTR` 电平过长导致重入 | `int_ack` 自动清 `EINT` |
| 板测看不到中断入口拍 | `LIAR` / `SBUS+LPC` 绑定 `W1` 且仅在 `pipe_idle` |

---

## 11) 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-10 | 初稿：定义 drain-then-interrupt 语义，与 PL-F01 / CTL-F02 合并 |
