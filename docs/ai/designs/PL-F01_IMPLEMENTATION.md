# PL-F01 — 流水线控制器 Implementation Plan

## Meta
- **ID:** PL-F01
- **Status:** In Progress
- **Owner:** maintainer
- **Last updated:** 2026-07-10
- **Related:** [PL-F01_DESIGN](./PL-F01_DESIGN.md)（§2 作者思路 + §3 正式规格）

## TL;DR

**全新 9 切片**；按 §3 `allow_ex` + `Opcode_cache` 模型实现；**不复用** 已回滚的旧 `pipe_regs`/`hazard_unit`。v1 **无中断**；顺序版保留在 `hardwired_ctrl.v`；中断在 `feat/ctl-seq-interrupt`。

---

## 0) 前置与分支

| 项 | 说明 |
|----|------|
| 基线 RTL | `hardwired_ctrl.v`（CTL-F01 + CTL-F02） |
| 冻结分支 | `feat/ctl-seq-interrupt` — 顺序+中断，不删 |
| 开发分支 | `main` — 流水 v1（无中断） |
| 旧实现 | **禁止回顾/恢复** 已回滚的 pipe RTL |

---

## 1) 切片总览

| Slice ID | 内容 | 状态 | 验证 |
|----------|------|------|------|
| PL-F01-S01 | `hardwired_ctrl_core` 抽取 + `hardwired_ctrl_pipe` 骨架 | Planned | 编译 |
| PL-F01-S02 | 状态机：`allow_ex`/`deny_ex`/`instr_cached`/`Opcode_cache` | Planned | `tb_pipe` 复位 |
| PL-F01-S03 | EX 型拍：cache 采样 + EX 译码 + `LIR+PCINC` | Planned | `tb_pipe` c1–c2 |
| PL-F01-S04 | MEM 型拍：MEM 译码 + bubble（MEM 排他） | Planned | `tb_pipe` LD c3 |
| PL-F01-S05 | 短指令背靠背（ADD→INC→ADD） | Planned | `tb_pipe` c4–c5 |
| PL-F01-S06 | 控制冒险：JC/JZ/JMP flush | Planned | `tb_pipe` 分支 |
| PL-F01-S07 | 手动 SW bypass + `run_tb.ps1` 集成 | Planned | 全 sim PASS |
| PL-F01-S08 | `PL-F01_PERFORMANCE.md` + CPI 统计 | Planned | 文档 |
| PL-F01-S09 | `top` 切换 + 上板回归 | Planned | HW |

---

## 2) 切片详情

### S01 — 译码抽取与骨架
- **Touch:** `hardwired_ctrl_core.v`（新建），`hardwired_ctrl_pipe.v`（新建）
- **DoD:**
  - `core`: `decode_ex(op, mode)`、`decode_mem(op, mode)` 与顺序版 W2/W3 RUN 一致
  - `pipe`: 端口与 `hardwired_ctrl` 对齐（**无 INTR/LIAR/IABUS**，v1）
- **Verify:** `iverilog` 编译通过

### S02 — 分相状态机
- **Touch:** `hardwired_ctrl_pipe.v`
- **DoD:** `T3↓` 更新 `allow_ex <= !deny_ex`；复位初值 `allow_ex=1, instr_cached=0, deny_ex=0`
- **Verify:** 仿真复位后状态正确

### S03 — EX 型拍
- **DoD（§3.3）:**
  - `allow_ex && !instr_cached`：仅 `LIR+PCINC`；拍初 `Opcode_cache <= IR7:4`，`instr_cached<=1`
  - `allow_ex && instr_cached`：先保持 cache，再 `Decode(EX)` + `LIR+PCINC`；LD/ST → `deny_ex`
- **Verify:** I1 单条 INC：c1 IF → c2 EX+IF；向量与 §3.4 c1–c2 一致

### S04 — MEM 型拍
- **DoD:**
  - `!allow_ex`：`Decode(MEM)` only；`deny_ex<=0`；`instr_cached<=0`
  - LD 后 I2 bubble（c3 无 EX/IF）
- **Verify:** §3.4 c3 向量

### S05 — 多指令重叠
- **DoD:** LD→ADD→INC 完整走表 §3.4 c1–c5
- **Verify:** `tb_pipe` 程序级向量

### S06 — 控制冒险
- **DoD:** taken 时屏蔽错误 `LIR+PCINC`，重置 cache 状态
- **Verify:** JMP 后 PC 路径仿真（控制字级）

### S07 — 集成回归
- **Touch:** `sim/tb_pipe.v`（新建），`sim/run_tb.ps1`
- **Verify:** `tb_ctrl` + `tb_manual_sto` + `tb_pipe` PASS

### S08 — 性能文档
- **Touch:** `docs/ai/designs/PL-F01_PERFORMANCE.md`
- **DoD:** 顺序 vs 流水 CPI；MEM bubble 次数；ISE Fmax 占位

### S09 — 上板
- **Touch:** `rtl/top/top.v`（`USE_PIPELINE` 或双实例）
- **DoD:** 烧录流水 bit；用例 A/C；与顺序行为对比记录

---

## 3) 建议实施顺序

```text
S01 → S02 → S03 → S04 → S05 → S06 → S07 → S08 → S09
         ↑_______________|
              核心闭环（c1–c5）
```

**每完成 S03–S05 之一** 即跑 `run_tb.ps1`；S07 后提议 commit。

---

## 4) 文件清单（预期）

| 文件 | 操作 |
|------|------|
| `rtl/controller/hardwired_ctrl_core.v` | 新建 |
| `rtl/controller/hardwired_ctrl_pipe.v` | 新建 |
| `rtl/controller/hardwired_ctrl.v` | 不改语义（顺序基线） |
| `rtl/top/top.v` | S09 可选切换 |
| `sim/tb_pipe.v` | 新建 |
| `sim/run_tb.ps1` | 扩展 |

**不创建：** `pipe_regs.v`、`hazard_unit.v`（旧架构废弃）

---

## 5) 风险与缓解

| 风险 | 缓解 |
|------|------|
| cache 采样与 `LIR` 时序竞争 | 采样仅在 `T3↓`；组合输出读 cache 旧值 |
| 首拍 / MEM 后 `instr_cached` 边界 | 严格按 §3.3；每切片写定向 tb |
| 与 ADR-02 文档不一致 | S08 后修订 ADR 或标 Superseded |

---

## 6) 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-10 | 按 §3 新模型重写；废弃旧 S01–S07 Done 记录 |
| 2026-07-08 | （作废）旧 pipe_regs 实现 |
