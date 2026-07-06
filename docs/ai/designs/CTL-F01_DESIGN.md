# CTL-F01 — 顺序硬布线控制器 Design Spec

## Meta
- **ID:** CTL-F01
- **Type:** Feature
- **Status:** Review
- **Owner:** maintainer
- **Last updated:** 2026-07-06
- **Related:**
  - [CTL-F01_IMPLEMENTATION](./CTL-F01_IMPLEMENTATION.md)
  - [REQUIREMENTS_ANALYSIS](./REQUIREMENTS_ANALYSIS.md)
  - [ADR-20260706-01](../adrs/ADR-20260706-01-platform-ise-tecplus.md)

## TL;DR

实现 **组合+时序译码** 的顺序硬布线控制器：以 `W1,W2,W3` 与 `IR7–IR4` 为输入，输出实验箱全部控制信号；覆盖手动 SW 模式与 14 条指令微操作；`SHORT`/`LONG` 区分 2/3 周期指令。

## Scope

- **In:** `rtl/controller/hardwired_ctrl.v`、`rtl/top/top.v` 端口、控制译码逻辑
- **Out:** 流水线、时序发生器本体、数据通路模块

## Reader quick start

1. 本文件 — 模块划分与译码表
2. [CTL-F01_IMPLEMENTATION](./CTL-F01_IMPLEMENTATION.md) — 切片
3. 黄金参考：`docs/course/*-图片-43.jpg`

---

## 1) 背景与目标

课设基础层次要求在 TEC-PLUS 硬连线模式下替换微程序控制器。本模块是 **课设核心交付物**。

**成功标准：** 仿真控制向量全通过 + 板上运行测试程序与参考行为一致。

---

## 2) 现状

- 工程纪律已就绪（WF-F01 Done）
- 无 RTL
- 黄金微操作来自课设流程图（图片-43）与指令表（图片-45）

---

## 3) 方案

### 3.1 模块划分

```text
top.v
  └── hardwired_ctrl.v      # 主控制器
        ├── decode_ir.v     # IR7-4 → 指令类型（可选子模块）
        ├── decode_sw.v     # SW 手动模式译码（可选子模块）
        └── control_out.v   # 控制字拼装（可选子模块）
```

首版允许 **单文件** `hardwired_ctrl.v`；超过 300 行再拆（YAGNI）。

### 3.2 工作模式选择

```text
if (SWC,SWB,SWA) == 3'b000  → 指令执行路径
else                         → 手动调试路径（图片-43 上半）
```

### 3.3 指令执行译码表（W1）

| 条件 | 输出（高有效） |
|------|----------------|
| W1 && 指令模式 | `LIR`, `PCINC`；`SHORT` 默认准备（具体在 W2 锁存类型） |

**时序约束：** `LIR` 与 `PCINC` 同处 W1，但 `PCINC` 仅在取指稳定后有效（见 ADR-20260706-02 §LIR/PCINC）。

### 3.4 指令执行译码表（W2 / W3）

见 [REQUIREMENTS_ANALYSIS §3.2](./REQUIREMENTS_ANALYSIS.md#32-指令级需求图片-45)。

**SEL 编码：** 根据 Rd/Rs 字段驱动 `SEL0–SEL3` + `SELCTL`（与实验箱寄存器选择真值表一致；在 S03 从课设实验手册摘录或上板反推）。

**ALU 控制：** `S3–S0`, `M`, `CIN` 直接对应流程图 `S=xxxx`。

### 3.5 SHORT / LONG 生成

| 指令类型 | SHORT | LONG |
|----------|-------|------|
| LD, ST | 0 | 1 |
| 其余 | 1 | 0 |

在 **W2 开始** 或 **W1 末** 采样 IR 后输出，保持到时序发生器消费（与板级时序对齐，HW-F01 验证）。

### 3.6 默认输出

未断言的控制信号 **默认 0**（低有效输出如 `CLR#` 不在本模块）。

---

## 4) 备选方案

| 选项 | 结论 |
|------|------|
| 纯组合（仅 W 译码） | **选用** — 与课设硬布线一致 |
| 内部状态机自产 W | 不选用 — W 由板级时序发生器输入 |

---

## 5) 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| OUT/DI/EI/IRET 无流程图 | 基础验收 | CTL-F01-S08 单独切片 + 微程序对标 |
| SEL 真值表缺失 | 寄存器写错 | 从图片-43 手动模式反推 + 仿真 |
| 吞指令 | 程序跳过 | W1 内 LIR 优先于 PCINC |

---

## 6) 验收标准

- [ ] 全部 SW 模式仿真向量通过
- [ ] 14 条指令 W1/W2(/W3) 向量通过
- [ ] ISE 综合无 Error
- [ ] 上板跑通至少 1 套测试程序（HW-F01 联调）

---

## 7) Status note

Status **Review** — 等待用户审批后开始 S01。

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-06 | 初稿 |
