# PL-F01 — 流水线控制器 Implementation Plan

## Meta
- **ID:** PL-F01
- **Status:** In Progress
- **Owner:** maintainer
- **Last updated:** 2026-07-08
- **Related:** [PL-F01_DESIGN](./PL-F01_DESIGN.md)

## TL;DR

**9 个切片**；S01–S07 RTL + `tb_pipe` 初版完成；待 S08 性能报告、S09 上板。

---

## 1) 切片总览

| Slice ID | 内容 | 状态 | 验证 |
|----------|------|------|------|
| PL-F01-S01 | 流水架构骨架 + `pipe_regs` | **Done** | 编译 |
| PL-F01-S02 | 封装 `hardwired_ctrl_core` 复用顺序译码 | **Done** | `tb_ctrl` PASS |
| PL-F01-S03 | IF 级：LIR/PCINC + IF/EX 锁存 | **Done** | `tb_pipe` fetch |
| PL-F01-S04 | EX 级：RR/分支/JMP 重叠 | **Done** | `tb_pipe` EX |
| PL-F01-S05 | MEM 级：LD/ST 第三拍 | **Done** | `tb_pipe` MEM |
| PL-F01-S06 | 数据冒险：load-use + RAW stall | **Done** | `tb_pipe` stall |
| PL-F01-S07 | 控制冒险：branch flush | **Done** | `tb_pipe` JMP |
| PL-F01-S08 | 性能采集 + `PL-F01_PERFORMANCE.md` | Planned | 报告评审 |
| PL-F01-S09 | 上板回归 + 与顺序版对比 | Planned | HW + Progress |

---

## 2) RTL 文件

| 文件 | 作用 |
|------|------|
| `rtl/controller/hardwired_ctrl_core.v` | 组合译码（CTL-F01 抽取） |
| `rtl/controller/hardwired_ctrl.v` | 顺序包装（上板基线） |
| `rtl/controller/pipe_regs.v` | IF/EX、EX/MEM 流水寄存器 |
| `rtl/controller/hazard_unit.v` | stall / flush 检测 |
| `rtl/controller/hardwired_ctrl_pipe.v` | 流水顶层 |
| `sim/tb_pipe.v` | 流水向量 + 冒险用例 |

---

## 3) 验证

```powershell
.\sim\run_tb.ps1   # tb_ctrl + tb_pipe (HAZARD_FINE_GRAIN=1) + tb_manual_sto
```

**上板默认：** `hardwired_ctrl_pipe` 参数 `HAZARD_FINE_GRAIN=0`；`IR0–3` 在 `top` tie-off（图 47 无此引脚）。

---

## 4) 依赖顺序

```text
CTL-F01 Done → S01–S07 (Done) → S08 → S09
```

---

## 5) 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-06 | 初稿 |
| 2026-07-08 | S01–S07 实现；tb_pipe PASS |
