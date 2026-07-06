# Feature Registry

Last updated: 2026-07-06  
Purpose: **single source of truth** for `<DOMAIN>-F<nn>` IDs.

---

## Active & recent features

| Feature ID | Title | Status | Owner | Design / plan |
|------------|-------|--------|-------|----------------|
| `WF-F01` | 工程纪律、文档模板、Cursor 规则、verify 脚本 | **Done** | — | [DOC_GOVERNANCE](./templates/DOC_GOVERNANCE.md) |
| `CTL-F01` | 顺序硬布线控制器（基础） | **Review** | — | [DESIGN](./designs/CTL-F01_DESIGN.md) · [IMPL](./designs/CTL-F01_IMPLEMENTATION.md) |
| `SIM-F01` | 仿真 Testbench 与控制字回归 | **Review** | — | [DESIGN](./designs/SIM-F01_DESIGN.md) · [IMPL](./designs/SIM-F01_IMPLEMENTATION.md) |
| `HW-F01` | UCF、ISE 综合、上板 | **Review** | — | [DESIGN](./designs/HW-F01_DESIGN.md) · [IMPL](./designs/HW-F01_IMPLEMENTATION.md) |
| `PL-F01` | 流水线 + 冒险 + 性能（进阶） | **Review** | — | [DESIGN](./designs/PL-F01_DESIGN.md) · [IMPL](./designs/PL-F01_IMPLEMENTATION.md) |

**总纲：** [REQUIREMENTS_ANALYSIS](./designs/REQUIREMENTS_ANALYSIS.md) · [EXECUTION_ROADMAP](./designs/EXECUTION_ROADMAP.md)

---

## ID allocation by domain (next free)

| DOMAIN | Next Feature # |
|--------|----------------|
| `WF` | F02 |
| `CTL` | F02 |
| `PL` | F02 |
| `SIM` | F02 |
| `HW` | F02 |

---

## Status flow (after approval)

`Review` → `In Progress`（S01 开工）→ `Done`（末切片 + 验收）
