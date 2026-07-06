# CTL-F01 — 顺序硬布线控制器 Implementation Plan

## Meta
- **ID:** CTL-F01
- **Status:** Done
- **Owner:** maintainer
- **Last updated:** 2026-07-06
- **Related:** [CTL-F01_DESIGN](./CTL-F01_DESIGN.md)

## TL;DR

共 **10 个切片**（S01–S10）；审批后按序执行；每切片完成跑仿真子集 + Progress 记录；S10 与 SIM-F01 联调。

## Scope

- **In:** `rtl/`, `sim/` 中控制器相关文件
- **Out:** ISE 工程（HW-F01）、流水线（PL-F01）

---

## 1) 切片总览

| Slice ID | 内容 | 状态 | 验证 |
|----------|------|------|------|
| CTL-F01-S01 | 顶层端口 + `hardwired_ctrl` 骨架 | **Done** | 编译（lint） |
| CTL-F01-S02 | W1 取指：`LIR`,`PCINC` + 默认 idle | **Done** | sim: fetch |
| CTL-F01-S03 | RR 型：ADD,SUB,AND,INC | **Done** | sim: alu4 |
| CTL-F01-S04 | LD, ST（W2+W3,LONG） | **Done** | sim: ld/st |
| CTL-F01-S05 | JC, JZ, JMP | **Done** | sim: branch |
| CTL-F01-S06 | STP | **Done** | sim: stp |
| CTL-F01-S07 | 手动 SW 模式 001/010/011/100 | **Done** | sim: manual |
| CTL-F01-S08 | OUT, IRET, DI, EI | **Done** | sim + 备注待上板 |
| CTL-F01-S09 | `top` 集成 + SHORT/LONG 完整 | **Done** | sim: full isa |
| CTL-F01-S10 | 黄金向量表固化 + 文档 | **Done** | verify Stage 1 预备 |

---

## 2) 切片详情

### CTL-F01-S01 — 端口与骨架
- **Goal:** 定义与图片-47 一致的 module 端口；输出全 0 占位
- **Touch:** `rtl/controller/hardwired_ctrl.v`, `rtl/top/top.v`
- **DoD:** 文件可编译；端口名与 UCF 预告一致
- **Verify:** `iverilog -t null` 或 ISE 语法检查（本地有工具时）

### CTL-F01-S02 — W1 取指
- **Goal:** `SW=000` 且 W1 时 `LIR`,`PCINC`=1；防吞指令注释与次序
- **Touch:** `hardwired_ctrl.v`
- **DoD:** sim 单测 W1 向量
- **Verify:** `sim/tb_fetch.v`（或统一 tb 子套件）

### CTL-F01-S03 — RR 算术逻辑
- **Goal:** ADD/SUB/AND/INC 的 W2 控制字
- **Touch:** `hardwired_ctrl.v`, `sim/golden/ctl_rr.txt`
- **DoD:** 4 条指令 × W2 向量 PASS
- **Verify:** sim alu4

### CTL-F01-S04 — 访存 LD/ST
- **Goal:** W2 LAR+LONG；W3 DRW+MBUS / MEMW
- **Touch:** `hardwired_ctrl.v`
- **DoD:** LD/ST 各 2 阶段向量 PASS；LONG 断言
- **Verify:** sim ld/st

### CTL-F01-S05 — 分支与跳转
- **Goal:** JC/JZ 条件 PCADD；JMP LPC
- **Touch:** `hardwired_ctrl.v`
- **DoD:** C/Z 分支真/假各 1 例
- **Verify:** sim branch

### CTL-F01-S06 — 停机
- **Goal:** STP → STOP
- **Touch:** `hardwired_ctrl.v`
- **DoD:** W2 STOP=1
- **Verify:** sim stp

### CTL-F01-S07 — 手动调试
- **Goal:** SW≠000 时上半部流程图
- **Touch:** `hardwired_ctrl.v`
- **DoD:** 4 种 SW 模式最小向量（STO 若未接入则 stub 输入）
- **Verify:** sim manual

### CTL-F01-S08 — 流程图外指令
- **Goal:** OUT/DI/EI/IRET 暂定控制字（见 REQUIREMENTS §3.4）
- **Touch:** `hardwired_ctrl.v`, 可选 `adrs/ADR-*-out-iret.md`
- **DoD:** 仿真有期望向量；上板待 HW-F01 对标
- **Verify:** sim misc4

### CTL-F01-S09 — 顶层集成
- **Goal:** `top` 仅例化；SHORT/LONG 全指令覆盖
- **Touch:** `rtl/top/top.v`
- **DoD:** 全 ISA 仿真套件 PASS
- **Verify:** sim full

### CTL-F01-S10 — 黄金表与交接
- **Goal:** `sim/golden/` 控制字表 + CTL-F01 标 Done
- **Touch:** `docs/ai/PROGRESS_LOG.md`, `FEATURE_REGISTRY`
- **DoD:** 表格式文档；Registry → Done
- **Verify:** 文档评审

---

## 3) 依赖顺序

```text
S01 → S02 → S03 → S04 → S05 → S06 → S07 → S08 → S09 → S10
         ↘ SIM-F01-S01 可并行启动（S02 后）
```

---

## 4) 延后切片

无。

---

## 5) 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-06 | 全部切片 Done；仿真核心 PASS |
