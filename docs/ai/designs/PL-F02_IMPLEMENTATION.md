# PL-F02 — 流水线中断扩展 Implementation Plan

## Meta
- **ID:** PL-F02
- **Status:** In Progress
- **Owner:** maintainer
- **Last updated:** 2026-07-10
- **Related:** [PL-F02_DESIGN](./PL-F02_DESIGN.md)

## TL;DR

在 `PL-F01` 基础上增量实现流水版中断：`INTR` 捕获、drain 停注入、**两拍 `LIAR` 后再 `SBUS+LPC`** 的入口握手，以及 `OUT/DI/EI/IRET` 在流水 RUN 模式的支持。

---

## 1) 切片总览

| Slice ID | 内容 | 状态 | 验证 |
|----------|------|------|------|
| PL-F02-S01 | Feature 注册 + 设计规格（drain 语义） | Done | 文档 |
| PL-F02-S02 | `hardwired_ctrl_core` 扩展 `OUT/DI/EI/IRET` | Done | `tb_pipe` |
| PL-F02-S03 | `hardwired_ctrl_pipe` 增加 `EINT/INTQ/IWAIT/int_ack_consumed` 与 interrupt stall | In Progress | `tb_pipe` |
| PL-F02-S04 | `top.v` 接通 `INTR/LIAR/IABUS` | Done | 编译 |
| PL-F02-S05 | `tb_pipe` 中断回归（EX 命中、LIAR/load、IRET） | Done | `run_tb.ps1` PASS |
| PL-F02-S06 | 流水版中断板测程序与说明 | Planned | 板测 |

---

## 2) 实现要点

### S02 — core 指令覆盖
- **Touch:** `rtl/controller/hardwired_ctrl_core.v`
- **DoD:**
  - `OUT`、`IRET` 在 `stage_ex` 有控制字
  - `EI` / `DI` 作为无控制字但可被顶层时序识别的 opcode

### S03 — pipe 中断状态机
- **Touch:** `rtl/controller/hardwired_ctrl_pipe.v`
- **DoD:**
  - `EINT`：仅 `EI` / `DI` 改变，不随响应自动清零
  - `INTQ`：`T3↓` 采样 `INTR&EINT`；第一次 `LIAR` 后仍保持
  - `int_ack_consumed`：记录第一拍 `LIAR` 已执行；第二拍 `LIAR` 后清 `INTQ`
  - `IWAIT`：`int_ack_consumed` 置 1 后进入；`SBUS+LPC` 后清 0
  - `INTQ/IWAIT` 期间 `deny_if=1`
  - EX 命中中断时丢弃 younger 指令推进

### S04 — top 接线
- **Touch:** `rtl/top/top.v`
- **DoD:** 不再 tie-low `LIAR/IABUS`；`INTR` 传入 pipe

### S05 — 仿真
- **Touch:** `sim/tb_pipe.v`
- **DoD:**
  - 保留 `PL-F01` 访存排他与分支回归
  - 新增 `EI -> INTR -> LIAR -> LIAR -> load -> IRET`
- **Verify:** `.\sim\run_tb.ps1`

---

## 3) 风险

| 风险 | 缓解 |
|------|------|
| 中断握手拍误把 `IR` 推进到 `opcode_cache` | `int_ack/int_load` 拍强制保持 `pipe_idle` |
| 误用 `main` 上错误顺序版逻辑 | 对齐 `feat/ctl-seq-interrupt`：`INTQ` 延后到第二拍 `LIAR` 后再清 |
| 设计文档与顺序版实现细节不完全同构 | 以 `PL-F02_DESIGN` 的流水语义为准 |

---

## 4) 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-10 | 修订：按 `feat/ctl-seq-interrupt` 业务语义重移植；`S03` 回到进行中 |
