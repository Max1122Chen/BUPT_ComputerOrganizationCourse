# Bootstrap Digest (read in under 2 min)

Last updated: 2026-07-09  
Purpose: **one-page** context for humans and AI when starting or recovering a session.  
**Doc trust:** `.cursor/rules/docs-trust-tiers.mdc` — do not treat course PDF as backlog; use [ACTIVE_WORK.md](./ACTIVE_WORK.md).

---

## Project in one line

**BUPT 计组课设** — 基础+CTL-F02 Done；**当前 PL-F01 流水线 v1**（`Opcode_cache` 模型，无中断）。

**冻结分支：** `feat/ctl-seq-interrupt`（顺序+中断）。

---

## Read order (new session)

1. [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) — 课设快照
2. [PROGRESS_LOG.md](./PROGRESS_LOG.md) — 近期变更（只看最近几条）
3. [ACTIVE_WORK.md](./ACTIVE_WORK.md) — **当前 backlog**
4. **This file** — 规则 + 命令 + 习惯
5. [TECH_DEBT.md](./TECH_DEBT.md) — Open 行 only
6. Task-specific design — 仅当用户点名或 ACTIVE_WORK 链接；先查 Meta **Status**

Do **not** scan `docs/course/` PDF 推断必做任务。

---

## IDs and docs

| Item | Rule |
|------|------|
| Feature | `<DOMAIN>-Fnn` — register in [FEATURE_REGISTRY.md](./FEATURE_REGISTRY.md) first |
| Slice | `<FeatureID>-Snn` |
| Bug | `BUG-<DOMAIN>-nnn` |
| ADR | `ADR-<yyyyMMdd>-nn` |
| New design | [DOC_GOVERNANCE.md](./templates/DOC_GOVERNANCE.md) + [templates/](./templates/) |

**Domains:** `WF`, `CTL`, `PL`, `SIM`, `HW` — not a closed list.

---

## Agent partner (short)

- **Partner, not servant:** 大改控制器 / 流水线前先 Pre-flight（设计 + 范围）；用户拍板。
- **课设 ≠  sloppy:** 可简化范围，不简化验证与模块边界。
- **Defects:** 修控制器时不要顺带大改无关模块；先建 `BUG-*`。
- **Work boundary:** 完成一个 Slice 后 → **提议准备 commit**，再开下一 Feature。
- **Prepare commit ≠ execute** until user approves.

---

## Slice Done (DoD summary)

**Docs:** Progress entry; Design/Implementation updated; Registry status.  
**Engineering:** `verify.ps1` 或等价命令已执行（记录 Stage 与结果）。  
**Commit message:** 具体事项 — 不以 `CTL-F01-S02` 作 subject。  
**Prepare commit ≠ execute** until you approve.

Full checklist: [DOC_GOVERNANCE.md](./templates/DOC_GOVERNANCE.md) §7.

---

## Build and verify (current)

| What | Command |
|------|---------|
| **Verify (default)** | `.\scripts\verify.ps1` — Stage 0/1 PASS；Stage 2 待 ISE |
| Sim only | `.\sim\run_tb.ps1` |
| iverilog | `%LOCALAPPDATA%\iverilog\bin`（见 `sim/README.md`） |

Record which command you ran in `PROGRESS_LOG.md`.

---

## End-of-session prompts

- **Handoff:** `请按 handoff 流程写 session 笔记、更新 Progress，未完成 slice 标 Blocked，并给我下一会话首句。`
- **Progress:** 用 [progress-log-entry.template.md](./templates/progress-log-entry.template.md) 追加到 PROGRESS_LOG。
