# 文档与协作规范 v1

Last updated: 2026-07-06  
Status: **Active**  
Owner: project maintainer + AI collaborator  
Adapted from: minEngine `DOC_GOVERNANCE.md`

---

## 1) 目标

让**不了解开发上下文**的读者，仅凭文档就能回答：

1. 这项工作在解决什么？
2. 当前做到哪、还缺什么？
3. 下一步是谁做、怎么验收？
4. 若暂停/取消，原因和重开条件是什么？

---

## 2) 文档类型（六类）

| 类型 | 回答的问题 | 典型文件名 |
|------|------------|------------|
| **Roadmap** | 为什么做、先后顺序 | `*_ROADMAP.md` |
| **Design Spec** | 做什么、不做什么、方案与风险 | `designs/*_DESIGN.md` |
| **Implementation Plan** | 怎么拆成可提交切片 | `designs/*_IMPLEMENTATION.md` |
| **ADR** | 为什么选 A 不选 B | `adrs/ADR-*.md` |
| **Progress Log** | 何时做了什么、验了什么 | `PROGRESS_LOG.md` |
| **Bug Record** | 出了什么问题、如何修复与回归 | `bugs/*.md` |

---

## 3) 统一 ID 与领域代号

### 3.1 领域（DOMAIN）

| 代号 | 范围 |
|------|------|
| `WF` | 工程流程、文档、脚本、Quartus/ISE 工程 |
| `CTL` | 硬布线控制器、译码、状态机 |
| `PL` | 流水线、冒险检测与处理 |
| `SIM` | Testbench、仿真脚本 |
| `HW` | 引脚约束、综合、上板、时序 |

新领域：在 FEATURE_REGISTRY 的 ID 表登记，代号全大写 2–8 字符。

### 3.2 Feature / Slice / Bug / ADR

- Feature：`<DOMAIN>-F<nn>`（须在 FEATURE_REGISTRY 登记）
- Slice：`<FeatureID>-S<nn>`
- Bug：`BUG-<DOMAIN>-<nnn>`
- ADR：`ADR-<yyyyMMdd>-<nn>`

---

## 4) 每篇长文档必填页眉

```markdown
## Meta
- **ID:** CTL-F01
- **Status:** Draft | Planned | In Progress | Review | Done | ...
- **Owner:**
- **Last updated:** YYYY-MM-DD
- **Related:** [链接]

## TL;DR

## Scope
- **In:**
- **Out:**
```

---

## 5) 状态机与 Agent 文档信任

- **Planning：** ACTIVE_WORK、FEATURE_REGISTRY (In Progress/Planned)、TECH_DEBT (Open)、用户点名的 In Progress 设计、**RTL + verify.ps1**
- **Reference only：** `docs/course/`、Done/Snapshot/Archived 文档、sessions/
- **Conflict：** 代码与仿真/综合结果 > 陈旧文档

详见 `.cursor/rules/docs-trust-tiers.mdc`。

---

## 6) Bug 流程

1. 复制 `bug-record.template.md`，分配 `BUG-*` ID。
2. Severity：S0 阻塞 / S1 高 / S2 中 / S3 低。
3. 上板问题务必记录：拨码状态、现象、波形路径。
4. Fixed 后必填：根因、修复、回归验证。

---

## 7) Slice 完成定义（DoD）

### 7.1 文档 DoD

| 动作 | 位置 |
|------|------|
| 追加进展 | `PROGRESS_LOG.md` |
| 更新 Design / Implementation | `designs/` |
| Registry 状态 | `FEATURE_REGISTRY.md` |
| 架构取舍 | `adrs/` |
| 大任务结束 | 可选 `sessions/` |

### 7.2 工程 DoD

| 检查 | 要求 |
|------|------|
| **验证** | 执行并记录：`.\scripts\verify.ps1` 或等价命令（注明 Stage） |
| **RTL** | 相关模块可综合（或 Slice 明确仅仿真） |
| **控制字** | 与课设流程图一致，或 ADR 说明偏差 |
| **缺陷** | S0/S1 已修复或已登记 Bug |

### 7.3 Commit

- Subject：`type(scope): 具体事项`（Conventional Commits）
- **准备 commit ≠ 执行** — 用户明确批准后才 `git commit`
- 完成 Slice 后默认提议 commit，再开下一 Feature

---

## 8) 目录与命名

| 路径 | 用途 |
|------|------|
| `docs/ai/designs/` | Design + Implementation |
| `docs/ai/adrs/` | ADR |
| `docs/ai/bugs/` | Bug |
| `docs/ai/sessions/` | Session notes |
| `docs/course/` | 课设 PDF/图片（只读） |
| `rtl/` | Verilog |
| `sim/` | 仿真 |
| `constraints/` | 引脚 |
| `quartus/` | Quartus 工程 |

---

## 9) Handoff

会话结束前：

1. 更新 PROGRESS_LOG
2. 未完成 Slice 标 Blocked + 原因
3. 可选写 `sessions/YYYY-MM-DD-*.md`
4. 给出下一会话**第一条可执行动作**

---

## 10) Pre-flight（大改前）

适用于：新 Feature、流水线改造、控制器重写。

- 目标结构与删除列表（不保留废弃 wrapper）
- Touch 文件列表
- 验证计划（哪个 Stage）
- 与课设图的差异点

用户确认后再写代码。
