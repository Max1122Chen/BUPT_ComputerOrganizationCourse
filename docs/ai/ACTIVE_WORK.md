# Active work (agent backlog)

Last updated: 2026-07-09  
Purpose: **short, human-maintained** list for session handoff.

> **下一会话首句（建议）：** CTL-F02 仿真 PASS；请按 HW-F01 §11 上板测中断（EI→PAUSE→装入口→ISR→IRET）。

---

## In focus

| 项 | 状态 |
|----|------|
| **CTL-F01** 顺序硬布线 | **Done** |
| **CTL-F02** 中断拓展 | **Done** — RTL+UCF+sim+板测 |
| **SIM-F01** 仿真 | **Done**（`tb_ctrl` + `tb_manual_sto` PASS） |
| **HW-F01** 上板 | **Done**（基础）；拓展飞线见 §3.1 |
| **PL-F01** 流水线 | **Deferred** |

### 里程碑

```text
[M1 仿真]  Done   — iverilog + tb_ctrl PASS
[M2 上板]  Done   — 基础层次 PASS
[M3 拓展]  Done   — CTL-F02 中断
[M4 进阶]  Deferred — PL-F01
```

---

## 交接要点

- **RTL：** `rtl/controller/hardwired_ctrl.v`（含 INTR/LIAR/IABUS）
- **约束：** `constraints/tecplus.ucf` — W3=F4；INTR=G6；LIAR=N4；IABUS=N5
- **飞线：** T3→C10；LIAR→N4；IABUS→N5；PAUSE=INTR（板内 G6）
- **仿真：** `.\sim\run_tb.ps1` PASS
- **上板：** [HW-F01_BOARD_TEST §11](./designs/HW-F01_BOARD_TEST.md) 用例 D

---

## Verification habit

| Check | Command | 当前 |
|-------|---------|------|
| Sanity | `.\scripts\verify.ps1 -Stage 0` | PASS |
| Sim | `.\sim\run_tb.ps1` | PASS |
| Board | 用例 D（中断） | **Done** |

---

## Explicitly not backlog

- PL-F01 流水线（Deferred）

---

## Related

| File | Role |
|------|------|
| [FEATURE_REGISTRY](./FEATURE_REGISTRY.md) | Feature 状态 |
| [CTL-F02_DESIGN](./designs/CTL-F02_DESIGN.md) | 中断设计 |
| [PROGRESS_LOG](./PROGRESS_LOG.md) | 时间线 |
