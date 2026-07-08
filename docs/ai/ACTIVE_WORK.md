# Active work (agent backlog)

Last updated: 2026-07-08  
Purpose: **short, human-maintained** list for session handoff.

> **下一会话首句（建议）：** 基础层次已上板验收；开始 PL-F01 流水线，或补 OUT/DI/EI/IRET 译码。

---

## In focus

| 项 | 状态 |
|----|------|
| **CTL-F01** 顺序硬布线 | **Done**（手动模式 + RUN 已实现指令上板通过） |
| **SIM-F01** 仿真 | **Done**（`tb_ctrl` PASS） |
| **HW-F01** 上板（基础层次） | **Done** — 飞线 T3→C10、W3→N5 后验收 |
| **PL-F01** 流水线 | **Planned** ← 下一主线 |

### 里程碑

```text
[M1 仿真]  Done   — iverilog + tb_ctrl PASS
[M2 上板]  Done   — 手动模式 + 指令集（已实现部分）板级 PASS
[M3 进阶]  未开始 — PL-F01
```

---

## 交接要点

- **平台：** TEC-PLUS + ISE 14.7（[ADR-20260706-01](./adrs/ADR-20260706-01-platform-ise-tecplus.md)）
- **RTL 入口：** `rtl/controller/hardwired_ctrl.v`，顶层 `rtl/top/top.v`
- **约束：** `constraints/tecplus.ucf`
- **必需飞线：** T3→C10，W3→N5（[HW-F01_BOARD_TEST §3.1](./designs/HW-F01_BOARD_TEST.md)）
- **仿真：** `.\sim\run_tb.ps1`
- **上板用例：** [HW-F01_BOARD_TEST](./designs/HW-F01_BOARD_TEST.md) 用例 A/C
- **未实现指令：** OUT / DI / EI / IRET（[TD-004](./TECH_DEBT.md)）

---

## Verification habit

| Check | Command | 当前 |
|-------|---------|------|
| Sanity | `.\scripts\verify.ps1 -Stage 0` | PASS |
| Sim | `.\scripts\verify.ps1 -Stage 1` | PASS（iverilog） |
| Board | 用例 A/C + 飞线检查 | PASS（2026-07-08） |

---

## Explicitly not backlog

- 拓展中断专题

---

## Related

| File | Role |
|------|------|
| [EXECUTION_ROADMAP](./designs/EXECUTION_ROADMAP.md) | 切片总览 |
| [PROGRESS_LOG](./PROGRESS_LOG.md) | 调试/开发日志 |
| [FEATURE_REGISTRY](./FEATURE_REGISTRY.md) | Feature 状态 |
