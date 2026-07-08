# Pin constraints — TEC-PLUS hardwired controller

Populated in **HW-F01-S01** from course image-47.

Reference signal list (see `docs/ai/designs/HW-F01_DESIGN.md`):

| Direction | Signals |
|-----------|---------|
| IN | CLR#, T3, SWA, SWB, SWC, IR4–IR7, W1, W2, W3, C, Z |
| OUT | LDZ, LDC, CIN, S0–S3, M, ABUS, DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG, SEL0–SEL3 |

File: `tecplus.ucf` (created in HW-F01-S01)

## Required fly wires

| Signal | FPGA pin (UCF) | Source on bench |
|--------|----------------|-----------------|
| **T3** | C10 | Timing generator **T3** output (fly wire required) |

**W3** is **pre-wired** on the bench to FPGA **F4** (`NET "W3"`). No fly wire for W3.

W1 (F9) and W2 (K12) are also pre-wired. Without the **T3 → C10** fly wire, manual STO / controller sync will not work correctly.

> Course image-47 may list W3 as N5; **teacher confirmed internal route to F4** (2026-07-08). Re-synthesize after UCF change if LD/ST W3 was wrong before.

Details: [HW-F01_BOARD_TEST.md](../docs/ai/designs/HW-F01_BOARD_TEST.md) §3.1

## Pipeline note (PL-F01)

- Controller FPGA inputs are **IR4–IR7 only** (image-47); **IR3–0 are not routed** to the controller.
- Pipelined top uses `hardwired_ctrl_pipe` with **`HAZARD_FINE_GRAIN=0`** (conservative opcode-level stall). Tie `IR0–IR3` to `0` in `top.v`.
- Simulation uses `HAZARD_FINE_GRAIN=1` in `tb_pipe.v` for precise Rd/Rs checks.

See [PL-F01_DESIGN.md](../docs/ai/designs/PL-F01_DESIGN.md) §3.3.
