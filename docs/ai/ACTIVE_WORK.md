# Active work (agent backlog)

Last updated: 2026-07-06  
Purpose: **short, human-maintained** list for session handoff.

> **下一会话首句（建议）：** 继续课设，从 HW-F01-S01 建 ISE 工程并综合 `top`，或补全 `sim/tb_ctrl.v` 穷举测试。

---

## In focus

| 项 | 状态 |
|----|------|
| **CTL-F01** 顺序硬布线 | **Done**（RTL + UCF；仿真核心用例通过） |
| **SIM-F01** 仿真 | **In Progress**（`tb_ctrl` PASS；可扩展穷举） |
| **HW-F01** 上板 | **Planned** — **下一主线** |
| **PL-F01** 流水线 | Planned（HW 通过后） |

### 里程碑

```text
[M1 仿真]  Done   — iverilog 12.0 + tb_ctrl PASS
[M2 上板]  未开始 — ISE 工程 / 综合 / IMPACT
[M3 进阶]  未开始 — PL-F01
```

---

## 交接要点

- **平台：** TEC-PLUS + ISE 14.7（[ADR-20260706-01](./adrs/ADR-20260706-01-platform-ise-tecplus.md)）
- **RTL 入口：** `rtl/controller/hardwired_ctrl.v`，顶层 `rtl/top/top.v`
- **约束：** `constraints/tecplus.ucf`
- **仿真：** `%LOCALAPPDATA%\iverilog\bin`，`.\sim\run_tb.ps1`
- **风险：** OUT/DI/EI/IRET 控制字暂定（[TD-004](./TECH_DEBT.md)）；上板对标微程序

---

## Verification habit

| Check | Command | 当前 |
|-------|---------|------|
| Sanity | `.\scripts\verify.ps1 -Stage 0` | PASS |
| Sim | `.\scripts\verify.ps1 -Stage 1` | PASS（iverilog） |
| ISE | `.\scripts\verify.ps1 -Stage 2` | SKIP（无工程） |

---

## Explicitly not backlog

- PL-F01 流水线（进阶）
- 拓展中断专题

---

## Related

| File | Role |
|------|------|
| [EXECUTION_ROADMAP](./designs/EXECUTION_ROADMAP.md) | 27 切片总览 |
| [PROGRESS_LOG](./PROGRESS_LOG.md) | 调试/开发日志 |
| [FEATURE_REGISTRY](./FEATURE_REGISTRY.md) | Feature 状态 |
