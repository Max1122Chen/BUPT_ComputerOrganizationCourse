# HW-F01 — ISE 综合与上板 Design Spec

## Meta
- **ID:** HW-F01
- **Type:** Feature
- **Status:** Review
- **Owner:** maintainer
- **Last updated:** 2026-07-06
- **Related:**
  - [HW-F01_IMPLEMENTATION](./HW-F01_IMPLEMENTATION.md)
  - [ADR-20260706-01](../adrs/ADR-20260706-01-platform-ise-tecplus.md)

## TL;DR

将 `top` 映射到 Spartan-6；UCF 来自图片-47；ISE 14.7 生成 bit；IMPACT 烧录 TEC-PLUS；记录上板调试日志。

## Scope

- **In:** `constraints/tecplus.ucf`, `ise/`, IMPACT 流程说明
- **Out:** 实验室接线改动、ChipScope 深度调试（可选）

---

## 3) 方案

### 3.1 UCF

从图片-47 录入全部 NET 约束；`rtl/top/top.v` 端口名与 UCF 一致。

### 3.2 ISE 工程

| 项 | 值 |
|----|-----|
| Family | Spartan6 |
| Device | xc6slx9 |
| Package | ftg256 |
| Speed | -2 |
| Top | `top` |

### 3.3 烧录

IMPACT → Boundary Scan → Initialize Chain → Program `.bit`

### 3.4 板级检查

- 拨码：硬连线模式
- 复位 `CLR#`
- 运行课设测试程序；记录 LED/寄存器/存储器现象

---

## 6) 验收标准

- [ ] 综合/实现无 Error
- [ ] 时序满足（若失败记录 TD/BUG）
- [ ] 顺序控制器测试程序通过
- [ ] 流水版（PL-F01 后）测试程序通过

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-06 | 初稿 |
