# CTL-F02 — 中断扩展 Implementation Plan

## Meta
- **ID:** CTL-F02
- **Status:** Done
- **Owner:** maintainer
- **Last updated:** 2026-07-10
- **Related:** [CTL-F02_DESIGN](./CTL-F02_DESIGN.md)

## TL;DR

在 `hardwired_ctrl.v` 增量实现顺序中断；**设计细节以 [CTL-F02_DESIGN](./CTL-F02_DESIGN.md) §3 与 RTL 为准**。

---

## 1) 切片总览

| Slice ID | 内容 | 状态 | 验证 |
|----------|------|------|------|
| CTL-F02-S01 | 端口 + UCF（INTR/LIAR/IABUS）+ top | **Done** | 综合 |
| CTL-F02-S02 | EINT/INTQ/IWAIT + `int_ack_consumed` 时序 | **Done** | sim + 板 |
| CTL-F02-S03 | W1：INTQ→LIAR，IWAIT→SBUS+LPC | **Done** | sim + 板 |
| CTL-F02-S04 | OUT/DI/EI/IRET W2 | **Done** | sim |
| CTL-F02-S05 | tb_ctrl 扩展 + run_tb | **Done** | PASS |
| CTL-F02-S06 | BOARD_TEST §11 用例 D | **Done** | 用户板测 |

---

## 2) 切片详情

### S01 — 端口与约束
- **Touch:** `hardwired_ctrl.v`, `top.v`, `constraints/tecplus.ucf`
- **DoD:** INTR=G6，LIAR=N4，IABUS=N5；W3=F4

### S02 — 中断时序（实现对齐说明）
- **RTL 要点：**
  - `EINT`：仅 `EI`/`DI`/复位更新
  - `INTQ`：`int_ack==0` 时 `T3↓` 采样 `INTR&EINT`；`int_ack` 两拍后经 `int_ack_consumed` 清零
  - `IWAIT`：`int_ack_consumed` 置 1；`int_load` 当拍 `T3↓` 清 0
- **Verify:** 中断请求 → LIAR 可见 → 装入口 → 取指

### S03 — W1 译码
- **优先级：** `INTQ` → `IWAIT` → 正常取指（见 DESIGN §3.4）
- **Verify:** LIAR / SBUS+LPC 控制字

### S04 — 四条指令
- **Verify:** OUT/IRET/EI/DI W2 向量

### S05 — 仿真
- **Verify:** `.\sim\run_tb.ps1` PASS

### S06 — 上板
- **Touch:** `HW-F01_BOARD_TEST.md` §11
- **Verify:** 用户板测通过

---

## 3) 依赖

```text
CTL-F01 Done → S01 → S02 → S03 → S04 → S05 → S06
```

---

## 4) 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-10 | 对齐用户最终实现；S06 Done |
| 2026-07-09 | 初稿 S01–S05 |
