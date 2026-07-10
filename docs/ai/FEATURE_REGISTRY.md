# Feature Registry

Last updated: 2026-07-10  
Purpose: **single source of truth** for `<DOMAIN>-F<nn>` IDs.

---

## Active & recent features

| Feature ID | Title | Status | Owner | Design / plan |
|------------|-------|--------|-------|----------------|
| `WF-F01` | 工程纪律、文档模板、Cursor 规则、verify 脚本 | **Done** | — | [DOC_GOVERNANCE](./templates/DOC_GOVERNANCE.md) |
| `CTL-F01` | 顺序硬布线控制器（基础） | **Done** | — | [DESIGN](./designs/CTL-F01_DESIGN.md) · `rtl/controller/hardwired_ctrl.v` |
| `CTL-F02` | 顺序中断扩展（OUT/DI/EI/IRET + INTR） | **Done** | — | [DESIGN](./designs/CTL-F02_DESIGN.md) · 板测通过 |
| `SIM-F01` | 仿真 Testbench 与控制字回归 | **Done** | — | `tb_ctrl` PASS |
| `HW-F01` | UCF、ISE 综合、上板（基础） | **Done** | — | [HW-F01_BOARD_TEST](./designs/HW-F01_BOARD_TEST.md) |
| `PL-F01` | 流水线 + 冒险 + 性能（进阶） | **In Progress** | — | [DESIGN](./designs/PL-F01_DESIGN.md) §3 + [IMPLEMENTATION](./designs/PL-F01_IMPLEMENTATION.md) |
| `PL-F02` | 流水线中断扩展（drain + LIAR/IABUS + IRET） | **In Progress** | — | [DESIGN](./designs/PL-F02_DESIGN.md) |

**总纲：** [REQUIREMENTS_ANALYSIS](./designs/REQUIREMENTS_ANALYSIS.md)（Approved）· [EXECUTION_ROADMAP](./designs/EXECUTION_ROADMAP.md)

---

## ID allocation by domain (next free)

| DOMAIN | Next Feature # |
|--------|----------------|
| `WF` | F02 |
| `CTL` | F03 |
| `PL` | F03 |
| `SIM` | F02 |
| `HW` | F02 |

---

## Handoff snapshot (2026-07-06)

- 基础 RTL 与引脚约束已就绪；仿真核心用例通过
- 未做：ISE 工程、bit 烧录、板上程序、流水线改造
- Git：本次 commit 后建议 `git push` 同步远程（若需要）
