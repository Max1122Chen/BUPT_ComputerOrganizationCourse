# PL-F01 — 流水线硬布线控制器 Design Spec

## Meta
- **ID:** PL-F01
- **Type:** Feature
- **Status:** Review
- **Owner:** maintainer
- **Last updated:** 2026-07-06
- **Related:**
  - [PL-F01_IMPLEMENTATION](./PL-F01_IMPLEMENTATION.md)
  - [CTL-F01_DESIGN](./CTL-F01_DESIGN.md)
  - [ADR-20260706-02](../adrs/ADR-20260706-02-pipeline-w-cycle-model.md)

## TL;DR

在 CTL-F01 顺序控制器 **语义不变** 前提下，增加流水寄存器与冒险单元，实现 IF/EX/MEM 重叠；解决 load-use 与控制冒险；输出性能对比文档。

## Scope

- **In:** `rtl/controller/hardwired_ctrl_pipe.v`（或 `PIPELINE` 参数化）、`hazard_unit.v`、`pipe_regs.v`
- **Out:** 修改实验箱数据通路、拓展中断专题

## Reader quick start

1. [ADR-20260706-02](../adrs/ADR-20260706-02-pipeline-w-cycle-model.md)
2. 本文件
3. [PL-F01_IMPLEMENTATION](./PL-F01_IMPLEMENTATION.md)

---

## 1) 背景与目标

课设进阶要求将顺序控制器流水化，并处理冒险、量化性能。

**前置条件：** `CTL-F01` Done（黄金向量基线）。

---

## 2) 现状（计划起点）

- 顺序控制器 `hardwired_ctrl` 已验证
- 时序发生器仍产生 W1–W3；流水控制器需与之协调

---

## 3) 方案

### 3.1 结构

```text
hardwired_ctrl_pipe.v
  ├── pipe_regs.v          # IF/EX/MEM 流水寄存器（IR, 控制字, 有效位）
  ├── hazard_unit.v        # RAW, load-use, branch
  └── hardwired_ctrl_core  # 复用 CTL-F01 组合译码逻辑
```

### 3.2 流水寄存器

| 寄存器 | 锁存内容 | 更新时机 |
|--------|----------|----------|
| IF/EX | IR, Rd, Rs, 指令有效 | W1 末 / 时序 T3 |
| EX/MEM | 访存控制、写回信息 | W2 末 |
| MEM/WB | （控制字输出级） | W3 末 |

（具体时钟沿与 `T3` 输入对齐，在 S03 仿真确定。）

### 3.3 停顿与冲刷

| 冒险 | 检测 | 动作 |
|------|------|------|
| Load-use | EX 为 LD，EX.Rd == IF 源寄存器 | 插入 1 bubble，冻结 IF/EX |
| RAW（RR） | EX 写寄存器与 IF 读冲突 | 1 bubble（若板级无旁路） |
| 控制 | EX 判定 JC/JZ/JMP  taken | flush IF；`PCINC`/`LPC`/`PCADD` 按顺序语义 |

### 3.4 与 SHORT/LONG 交互

- LD/ST 占据 EX+MEM 两级；`LONG` 在 EX 级断言
- 短指令 MEM 级为空泡，不重复 W2 操作

### 3.5 性能计数（仿真 + 可选板上）

- `cnt_cycles`, `cnt_stall`, `cnt_branch_flush`
- 用于 `PL-F01_PERFORMANCE.md`

---

## 4) 验收标准

- [ ] 顺序版测试程序在流水版上结果一致
- [ ] load-use 用例可观察 stall
- [ ] 分支用例可观察 flush
- [ ] 性能文档含 CPI / Fmax 对比
- [ ] 板上无吞指令回归

---

## 7) Status note

**Review** — 依赖 CTL-F01 完成后启动；审批后可先写 S01 架构骨架。

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-06 | 初稿 |
