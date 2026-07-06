# Active work (agent backlog)

Last updated: 2026-07-06  
Purpose: **short, human-maintained** list of what matters now.

> **Agent:** 需求与切片已于 2026-07-06 **全部批准**。本 commit 后首步：`CTL-F01-S01`。

---

## In focus

- **平台：** TEC-PLUS + ISE 14.7（[ADR-20260706-01](./adrs/ADR-20260706-01-platform-ise-tecplus.md)）
- **范围批准：** 基础（顺序+全指令+手动SW）、进阶（流水+冒险+性能）、OUT/DI/EI/IRET 暂定策略
- **当前：** 仓库初始化 + 首次 commit（待用户执行批准）
- **下一编码步：** `CTL-F01-S01`（端口 + 骨架）

### 执行顺序（摘要）

```text
CTL-F01 (S01–S10) → SIM-F01 → HW-F01 (S01–S04) → PL-F01 (S01–S09) → HW-F01-S05
```

| Feature | Status | 设计 |
|---------|--------|------|
| WF-F01 | **Done** | 工程纪律 |
| CTL-F01 | **Review** | [DESIGN](./designs/CTL-F01_DESIGN.md) · [IMPL](./designs/CTL-F01_IMPLEMENTATION.md) |
| SIM-F01 | **Review** | [DESIGN](./designs/SIM-F01_DESIGN.md) · [IMPL](./designs/SIM-F01_IMPLEMENTATION.md) |
| HW-F01 | **Review** | [DESIGN](./designs/HW-F01_DESIGN.md) · [IMPL](./designs/HW-F01_IMPLEMENTATION.md) |
| PL-F01 | **Review** | [DESIGN](./designs/PL-F01_DESIGN.md) · [IMPL](./designs/PL-F01_IMPLEMENTATION.md) |

---

## Verification habit

| Check | Command |
|-------|---------|
| Sanity | `.\scripts\verify.ps1 -Stage 0` |
| Sim (after SIM-F01) | `.\scripts\verify.ps1 -Stage 1` |
| ISE (after HW-F01) | `.\scripts\verify.ps1 -Stage 2` |

---

## Explicitly not backlog

- 拓展：中断现场保存专题
- 题目 B / Quartus / TEC-8

---

## How this relates to other docs

| File | Role |
|------|------|
| [FEATURE_REGISTRY.md](./FEATURE_REGISTRY.md) | IDs |
| [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) | 快照 |
