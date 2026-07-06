# Session 2026-07-06 — 基础阶段 RTL + 仿真交接

## Meta
- **Date:** 2026-07-06
- **Feature/Slice:** CTL-F01 Done · SIM-F01 S01–S03 Done
- **Status:** Archived

## TL;DR

顺序硬布线控制器 RTL/UCF 完成；iverilog 仿真核心用例 PASS。**下一主线：HW-F01 上板。**

## 已完成

- CTL-F01：`hardwired_ctrl.v`、`top.v`、`tecplus.ucf`
- SIM-F01：`tb_ctrl.v`、`run_tb.ps1`、iverilog 12.0
- 里程碑 M1（仿真核心）达成

## 未完成

- ISE 工程 / 综合 / `.bit`
- 板上测试程序与调试日志
- PL-F01 流水线（进阶）
- OUT/DI/EI/IRET 上板对标（TD-004）

## 下一步

1. **HW-F01-S02** 在 `ise/` 创建 ISE 14.7 工程（器件 xc6slx9-2-ftg256）
2. 添加 RTL + `constraints/tecplus.ucf`
3. Generate Programming File → IMPACT 烧录
4. 拨码硬连线，跑课设测试程序，记 `PROGRESS_LOG`

## 链接

- [ACTIVE_WORK](../ACTIVE_WORK.md)
- [EXECUTION_ROADMAP](../designs/EXECUTION_ROADMAP.md)
- [HW-F01_IMPLEMENTATION](../designs/HW-F01_IMPLEMENTATION.md)
