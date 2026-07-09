# Technical Debt Register

Last updated: 2026-07-08

| ID | Title | Module | Severity | Status | Feature / doc | Notes |
|----|-------|--------|----------|--------|---------------|-------|
| TD-001 | 平台与 IDE 未最终确认 | WF | **High** | **Done** | ADR-20260706-01 | TEC-PLUS + ISE |
| TD-002 | verify Stage 2 未接入 ISE | WF | **Medium** | Open | HW-F01-S02/S03 | Stage 0/1 PASS |
| TD-003 | 无标准课设测试程序与预期结果 | SIM | **Medium** | **Done** | [HW-F01_BOARD_TEST](./designs/HW-F01_BOARD_TEST.md) | 用例 A/B 已起草；板上实测待 S04 |
| TD-004 | OUT/DI/EI/IRET 控制字（拓展/自设计） | CTL | **Low** | **Open** | — | 图 45 有编码、图 43 无流程图；需自设计微操作并对标微程序/老师资料；见 TD-006 |
| TD-005 | STO 信号未接入控制器 | CTL | **Low** | **Done** | `rtl/common/manual_sto.v` | FPGA 内 W1 末拍翻转 STO |
| TD-006 | 中断拓展专题 | CTL | **Low** | **Open** | — | 若只做 DI/EI/IRET 的最小实现需界定范围；与 TD-004 关联 |
| TD-007 | tb 未穷举全手动 SW 边角 | SIM | **Low** | Open | SIM-F01 | 核心用例已 PASS |

---

## Adding a row

```text
| TD-0nn | Short title | DOMAIN | High/Med/Low | Open/Deferred/Done | Feature or link | One line |
```
