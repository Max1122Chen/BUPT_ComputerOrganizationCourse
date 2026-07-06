# AI 文档索引

本目录供 AI 与开发者共享**设计案、进度、会话记录**。新文档从 [templates/](./templates/) 复制，并遵循 [DOC_GOVERNANCE](./templates/DOC_GOVERNANCE.md)。

## Agent：读哪些文档（必读）

**排期与「还有什么没做」** — 只认：

1. [ACTIVE_WORK.md](./ACTIVE_WORK.md) — 当前短 backlog（人维护）
2. [FEATURE_REGISTRY.md](./FEATURE_REGISTRY.md) — 仅 **In Progress** / **Planned** 行
3. [TECH_DEBT.md](./TECH_DEBT.md) — 仅 **Open** 行
4. [PROGRESS_LOG.md](./PROGRESS_LOG.md) — 近期已落地事实
5. **RTL + 仿真/综合** — `rtl/`、`scripts/verify.ps1`；与文档冲突时以代码与验证结果为准

规则全文：`.cursor/rules/docs-trust-tiers.mdc`。

**不要**根据 `docs/course/` 课设 PDF/图片或旧 session 自动推导待办。

### Planning sources（可驱动工作）

| 文件 | 用途 |
|------|------|
| [ACTIVE_WORK.md](./ACTIVE_WORK.md) | 你现在关心的 1–5 件事 |
| [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) | 稳定项目快照 |
| [BOOTSTRAP_DIGEST.md](./BOOTSTRAP_DIGEST.md) | 命令、DoD、协作习惯 |
| [FEATURE_REGISTRY.md](./FEATURE_REGISTRY.md) | Feature ID 与进行中登记 |
| [TECH_DEBT.md](./TECH_DEBT.md) | 明确推迟的问题 |
| [designs/](./designs/) | 控制器 / 流水线设计定稿 |

### Reference only（背景；勿当 backlog）

- [docs/course/](../course/) — 课设 PDF 与参考图片
- `Status: Done` / `Snapshot` / `Archived` / `Reference` 的设计文档
- [sessions/](./sessions/) — 会话笔记

---

## 布局约定

| 路径 | 用途 |
|------|------|
| `PROJECT_CONTEXT.md` | 稳定高层快照（bootstrap 必读） |
| `PROGRESS_LOG.md` | 按时间线的变更与调试记录 |
| `FEATURE_REGISTRY.md` | Feature ID 登记册 |
| `ACTIVE_WORK.md` | 当前短 backlog |
| `BOOTSTRAP_DIGEST.md` | 一页会话恢复 |
| `TECH_DEBT.md` | 技术债登记 |
| `WORKING_WITH_AI.md` | 与 AI 协作约定 |
| `CODING_STYLE.md` | Verilog 编码规范 |
| `templates/` | 文档模板 + DOC_GOVERNANCE |
| `designs/` | 设计规格与实施计划 |
| `adrs/` | 架构决策记录 |
| `bugs/` | 缺陷与上板问题 |
| `sessions/` | 会话笔记 |

**新功能：** 先在 FEATURE_REGISTRY 登记 ID，再读 DOC_GOVERNANCE 并选模板。切片格式 `<FeatureID>-S<nn>`。
