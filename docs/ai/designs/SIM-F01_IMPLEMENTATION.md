# SIM-F01 — 仿真验证 Implementation Plan

## Meta
- **ID:** SIM-F01
- **Status:** Review
- **Last updated:** 2026-07-06
- **Related:** [SIM-F01_DESIGN](./SIM-F01_DESIGN.md)

## TL;DR

3 切片；与 CTL-F01-S02 起可并行。

---

## 1) 切片总览

| Slice ID | 内容 | 状态 | 验证 |
|----------|------|------|------|
| SIM-F01-S01 | `tb_ctrl.v` + 向量解析框架 | Planned | 空表编译 |
| SIM-F01-S02 | 黄金表 + CTL 全指令套件 | Planned | sim PASS |
| SIM-F01-S03 | `verify.ps1` Stage 1 接入 | Planned | `verify -Stage 1` |

---

## 2) 依赖

```text
CTL-F01-S01 → SIM-F01-S01
CTL-F01-S09 → SIM-F01-S02 完整
SIM-F01-S03 在 S02 后
```

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-06 | 初稿 |
