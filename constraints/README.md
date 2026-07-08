# Pin constraints — TEC-PLUS hardwired controller

Populated in **HW-F01-S01** from course image-47.

Reference signal list (see `docs/ai/designs/HW-F01_DESIGN.md`):

| Direction | Signals |
|-----------|---------|
| IN | CLR#, T3, SWA, SWB, SWC, IR4–IR7, W1, W2, W3, C, Z |
| OUT | LDZ, LDC, CIN, S0–S3, M, ABUS, DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG, SEL0–SEL3 |

File: `tecplus.ucf` (created in HW-F01-S01)

## Required fly wires (not on default PCB to FPGA)

| Signal | FPGA pin (UCF) | Source on bench |
|--------|----------------|-----------------|
| **T3** | C10 | Timing generator **T3** output |
| **W3** | N5 | Timing generator **W3** output |

W1 (F9) and W2 (K12) are normally pre-wired. Without the two fly wires above, manual STO / LD / ST W3 micro-ops will not work correctly even if panel LEDs look fine.

Details: [HW-F01_BOARD_TEST.md](../docs/ai/designs/HW-F01_BOARD_TEST.md) §3.1
