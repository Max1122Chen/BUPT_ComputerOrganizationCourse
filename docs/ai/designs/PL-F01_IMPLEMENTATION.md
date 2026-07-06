# PL-F01 — 流水线控制器 Implementation Plan

## Meta
- **ID:** PL-F01
- **Status:** Review
- **Owner:** maintainer
- **Last updated:** 2026-07-06
- **Related:** [PL-F01_DESIGN](./PL-F01_DESIGN.md)

## TL;DR

**9 个切片**；**硬依赖 CTL-F01 Done**；末片交付性能报告。

---

## 1) 切片总览

| Slice ID | 内容 | 状态 | 验证 |
|----------|------|------|------|
| PL-F01-S01 | 流水架构骨架 + `pipe_regs` | Planned | 编译 |
| PL-F01-S02 | 封装 `hardwired_ctrl_core` 复用顺序译码 | Planned | 与 CTL 向量对比 |
| PL-F01-S03 | IF 级：LIR/PCINC 时序 + IF/EX 锁存 | Planned | sim: pipe_fetch |
| PL-F01-S04 | EX 级：RR/分支/JMP 重叠 | Planned | sim: pipe_ex |
| PL-F01-S05 | MEM 级：LD/ST 第三拍 | Planned | sim: pipe_mem |
| PL-F01-S06 | 数据冒险：load-use + RAW stall | Planned | sim: hazard_data |
| PL-F01-S07 | 控制冒险：branch flush | Planned | sim: hazard_ctrl |
| PL-F01-S08 | 性能采集 + `PL-F01_PERFORMANCE.md` | Planned | 报告评审 |
| PL-F01-S09 | 上板回归 + 与顺序版对比 | Planned | HW + Progress |

---

## 2) 切片详情

### PL-F01-S01 — 骨架
- **Goal:** 新建 `hardwired_ctrl_pipe.v`、`pipe_regs.v`、`hazard_unit.v` 空壳
- **Touch:** `rtl/controller/*`
- **Verify:** 编译通过

### PL-F01-S02 — 复用顺序译码
- **Goal:** 将 CTL-F01 组合逻辑提取为 `hardwired_ctrl_core`（输入：IR,W,C,Z,阶段）
- **Touch:** 重构 `hardwired_ctrl.v` → core + 包装
- **Verify:** 顺序模式回归全绿

### PL-F01-S03 — IF 级
- **Goal:** 流水 IF；LIR/PCINC 次序；ADR-02 落地
- **Verify:** sim pipe_fetch

### PL-F01-S04 — EX 级
- **Goal:** 重叠执行 RR/分支；SHORT 断言
- **Verify:** sim pipe_ex

### PL-F01-S05 — MEM 级
- **Goal:** LD/ST 长指令第三拍
- **Verify:** sim pipe_mem

### PL-F01-S06 — 数据冒险
- **Goal:** `hazard_unit` 检测 load-use；stall 信号
- **Verify:** 构造 LD;ADD Rd 相邻用例

### PL-F01-S07 — 控制冒险
- **Goal:** JC/JZ/JMP flush
- **Verify:** 分支前后指令检查

### PL-F01-S08 — 性能文档
- **Goal:** `PL-F01_PERFORMANCE.md`：CPI、Fmax、stall 统计
- **Touch:** `docs/ai/designs/PL-F01_PERFORMANCE.md`
- **Verify:** 含顺序 vs 流水表

### PL-F01-S09 — 上板
- **Goal:** 流水版 bit 下载；演示程序；调试日志
- **Verify:** HW-F01 流程 + Progress

---

## 3) 依赖顺序

```text
CTL-F01 Done → S01 → S02 → S03 → S04 → S05 → S06 → S07 → S08 → S09
```

---

## 5) 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-06 | 初稿 |
