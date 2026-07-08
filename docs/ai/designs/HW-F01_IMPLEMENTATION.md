# HW-F01 — ISE 综合与上板 Implementation Plan

## Meta
- **ID:** HW-F01
- **Status:** Review
- **Last updated:** 2026-07-06
- **Related:** [HW-F01_DESIGN](./HW-F01_DESIGN.md)

## TL;DR

5 切片；S01–S03 可在 CTL-F01-S09 后启动；S04 顺序上板；S05 流水上板。

---

## 1) 切片总览

| Slice ID | 内容 | 状态 | 验证 |
|----------|------|------|------|
| HW-F01-S01 | `constraints/tecplus.ucf` 自图片-47 | **Done** | UCF 与 top 端口核对 |
| HW-F01-S02 | ISE 工程 `ise/` 创建 | Planned | 工程打开 |
| HW-F01-S03 | 综合 + Place & Route | Planned | `.bit` 生成 |
| HW-F01-S04 | IMPACT 烧录 + 顺序版程序 | Planned | 上板 PASS + Progress |
| HW-F01-S05 | 流水版烧录 + 对比演示 | Planned | PL-F01-S09 |

---

## 2) 切片详情

### HW-F01-S01 — UCF
- **Touch:** `constraints/tecplus.ucf`
- **Verify:** 端口名 1:1 对照图片-47

### HW-F01-S02 — ISE 工程
- **Touch:** `ise/*.xise` 或脚本生成
- **Verify:** 添加 rtl 源文件列表

### HW-F01-S03 — 实现
- **Verify:** ISE reports 无 Error；记录 Fmax、LUT

### HW-F01-S04 — 顺序上板
- **Touch:** 按 [HW-F01_BOARD_TEST](./HW-F01_BOARD_TEST.md) 执行用例 A/B/C
- **Hardware:** 飞线 **T3→C10**、**W3→N5**（§3.1，上电前必接）
- **Verify:** 调试日志；测试程序现象符合预期

### HW-F01-S05 — 流水上板
- **Verify:** 进阶验收演示

---

## 3) 依赖

```text
CTL-F01-S09 → HW-F01-S01..S04
PL-F01-S08  → HW-F01-S05
```

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-08 | 上板飞线 T3→C10、W3→N5；BOARD_TEST 用例 C |
| 2026-07-06 | 初稿 |
