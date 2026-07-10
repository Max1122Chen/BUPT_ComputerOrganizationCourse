# CTL-F02 — 顺序硬布线中断扩展 Design Spec

## Meta
- **ID:** CTL-F02
- **Type:** Feature
- **Status:** Done
- **Owner:** maintainer
- **Last updated:** 2026-07-10
- **Related:**
  - [CTL-F02_IMPLEMENTATION](./CTL-F02_IMPLEMENTATION.md)
  - [CTL-F01_DESIGN](./CTL-F01_DESIGN.md)
  - RTL 真值：`rtl/controller/hardwired_ctrl.v`
  - 伙伴参考：`docs/partner-int-ref/controllerInt.v`（流程参考；**本实现时序与伙伴不同，以 RTL 为准**）

## TL;DR

在顺序 `hardwired_ctrl` 上实现 **OUT/DI/EI/IRET** 与 **W1 中断响应**：`LIAR` 保存断点 → `SBUS+LPC` 装入 ISR 入口 → 正常取指 → `IRET` 经 `IABUS+LPC` 恢复 PC。**PAUSE = INTR（G6）**。

## Scope

- **In:** `hardwired_ctrl.v`、`top.v`、`constraints/tecplus.ucf`、`sim/tb_ctrl.v`
- **Out:** 全寄存器现场保存；流水线；数据通路改动

## Reader quick start

1. 本文件 — **与 RTL 对齐**的状态机与时序（权威描述）
2. [CTL-F02_IMPLEMENTATION](./CTL-F02_IMPLEMENTATION.md) — 切片与验收
3. `hardwired_ctrl.v` — 代码真值；文档与代码冲突时 **以代码为准**

---

## 1) 背景与目标

- CTL-F01 基础 RUN 指令已验收。
- 拓展层次需支持：EI 开中断 → PAUSE 请求 → 保存断点 → 装入入口 → 执行 ISR → IRET 返回。
- **LIAR / IABUS** 需飞线（N4 / N5）；**INTR** 接面板 PAUSE（G6）。

---

## 2) 操作员流程（上板）

| 步 | 操作 | 控制器行为 |
|----|------|------------|
| 1 | 主程序执行 **EI**，RUN | `EINT=1` |
| 2 | 按 **PAUSE（INTR）** | `INTQ` 在 `T3↓` 采样置位 |
| 3 | 下一 **W1**（可需两拍，见 §3.4） | `LIAR+STOP+SHORT` |
| 4 | 拨 ISR 入口地址，下一 **W1** | `SBUS+LPC+SHORT` |
| 5 | RUN 继续 | `LIR+PCINC` 取指进入 ISR |
| 6 | ISR 末尾 **EI** + **IRET** | `IABUS+LPC` 恢复 PC |

---

## 3) 实现规格（与 RTL 对齐）

### 3.1 引脚

| 信号 | 方向 | 引脚 | 说明 |
|------|------|------|------|
| `INTR` | 入 | G6 | PAUSE，中断请求 |
| `LIAR` | 出 | N4 | IAR←PC |
| `IABUS` | 出 | N5 | IAR→DBUS |
| `T3` | 入 | C10 | 飞线 |
| `W3` | 入 | F4 | 板内 |

### 3.2 内部寄存器（均在 `T3↓` 更新）

| 寄存器 | 含义 |
|--------|------|
| `EINT` | 中断允许；**仅** `EI`/`DI` 指令或复位改变 |
| `INTQ` | 已捕获的中断请求 |
| `IWAIT` | 断点已保存，等待装入 ISR 入口 |
| `int_ack_consumed` | LIAR 响应“已执行一拍”标记（两拍清 `INTQ` 机制） |
| `int_load_consumed` | **已声明，当前 RTL 未使用** |

### 3.3 组合判定线

```verilog
wire int_ack  = (mode == RUN) & W1 & INTQ & EINT;
wire int_load = (mode == RUN) & W1 & IWAIT;
wire set_ei   = (mode == RUN) & W2 & (op == EI);
wire set_di   = (mode == RUN) & W2 & (op == DI);
```

**注意：** `int_ack` 用于时序状态推进；**W1 译码 LIAR 分支只看 `INTQ`**，不要求 `EINT=1`。因此须先 **EI** 使 `EINT=1`，才能在 `T3↓` 把 `INTQ` 采进来并在时序上推进 `int_ack_consumed` / `IWAIT`。

### 3.4 RUN / W1 组合优先级（译码）

```text
1. INTQ=1  → LIAR, STOP, SHORT     （保存断点）
2. IWAIT=1 → SBUS, LPC, SHORT      （装入入口）
3. else    → LIR, PCINC             （正常取指）
```

**与伙伴参考不同：** 本实现 **INTQ 优先于 IWAIT**（伙伴为 IWAIT 优先）。

### 3.5 时序块逻辑（`T3↓`）

#### EINT

```verilog
if (set_ei)  EINT <= 1;
else if (set_di) EINT <= 0;
// 响应中断时不自动关 EINT
```

#### INTQ + int_ack_consumed（两拍清请求）

```verilog
if (int_ack & !int_ack_consumed)
    int_ack_consumed <= 1;
else if (int_ack & int_ack_consumed) begin
    INTQ <= 0;
    int_ack_consumed <= 0;
end else  // int_ack == 0
    INTQ <= (INTR & EINT);
```

语义：

- **无 `int_ack` 时：** 每个 `T3↓` 用 `INTR & EINT` **采样**（非 `INTQ | …` 锁存）。
- **有 `int_ack` 的第一拍 `T3↓`：** 仅置 `int_ack_consumed`，**不清 `INTQ`**。
- **有 `int_ack` 的第二拍 `T3↓`：** 清 `INTQ` 与 `int_ack_consumed`。

因此 LIAR 组合条件在 `INTQ` 清掉前可连续有效 **两拍 W1**；第一拍 `T3↓` 后 `int_ack_consumed=1` 且 `IWAIT=1`。

#### IWAIT

```verilog
if (int_ack_consumed)
    IWAIT <= 1;
else if (int_load)
    IWAIT <= 0;
```

- `IWAIT` 在 **第一拍 LIAR 的 `T3↓`**（`int_ack_consumed` 已为 1）置位。
- 装入口拍（`int_load=1`）的 **`T3↓` 清 `IWAIT`**。

### 3.6 拍级时序（典型成功路径）

| 阶段 | W1 组合输出 | 关键状态（`T3↓` 后） |
|------|-------------|----------------------|
| 捕获 | 正常取指 | `INTQ=1`（`INTR&EINT` 采样） |
| LIAR 拍 1 | `LIAR+STOP` | `int_ack_consumed=1`, `IWAIT=1`, `INTQ` 仍为 1 |
| LIAR 拍 2 | `LIAR+STOP` | `INTQ=0`, `int_ack_consumed=0` |
| 装入口拍 | `SBUS+LPC` | `IWAIT=0` |
| 后续 | `LIR+PCINC` | 进入 ISR |

若第二拍 LIAR 因单步/时序未出现，只要 `INTQ` 仍为 1，下一 W1 仍走 LIAR，直至两拍 `int_ack` 完成清 `INTQ`。

### 3.7 W2 指令扩展

| 指令 | W2 控制字 |
|------|-----------|
| OUT | `M,S=1010, ABUS` |
| IRET | `IABUS, LPC` |
| EI / DI | 无总线；`EINT` 在时序块更新 |
| STP | `STOP` |

---

## 4) 与伙伴参考的差异（避免混读）

| 项 | 伙伴 `controllerInt.v` | **本实现（RTL）** |
|----|------------------------|-------------------|
| W1 优先级 | IWAIT → INTQ | **INTQ → IWAIT** |
| LIAR 组合条件 | `INTQ & EINT` | **`INTQ` only** |
| 响应时关 EINT | 是 | **否** |
| INTQ 捕获 | `INTQ \|= INTR&EINT` 式锁存 | **`int_ack==0` 时 `INTQ<=INTR&EINT` 采样** |
| 清 INTQ 时机 | `int_ack` 当拍 | **`int_ack` 连续两拍后清** |
| 延后清机制 | 无 | **`int_ack_consumed`** |

阅读伙伴代码时 **不要** 直接套用到本仓库时序推断。

---

## 5) 验收标准

- [x] `tb_ctrl`：OUT/DI/EI/IRET W2 向量 PASS
- [x] `tb_ctrl`：中断 W1 序列 PASS
- [x] 上板：EI → PAUSE → LIAR → 装入口 → ISR → IRET（用户已验收）

---

## 7) Status note

**Done** — 文档已与 `hardwired_ctrl.v` 用户对齐版同步；板级行为以用户实测为准。

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-10 | 对齐 RTL：`int_ack_consumed` 两拍清 INTQ；W1 优先级；EINT 不随响应清零 |
| 2026-07-09 | 初稿 |
