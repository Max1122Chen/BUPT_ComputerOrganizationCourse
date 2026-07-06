# Working With AI

Last updated: 2026-07-06

## Why this exists

课设周期跨多周、多会话。用 `docs/ai/` 避免每次重复背景，并让 AI 与文档、代码保持一致。

## Minimal workflow

1) **Before coding**
- 说一句：继续本仓库课设任务。

2) **During discussion**
- 请 AI 先读 `PROJECT_CONTEXT.md`、`ACTIVE_WORK.md`、`PROGRESS_LOG.md`（近期条目）。
- 新设计：从 `templates/` 复制，遵循 `DOC_GOVERNANCE.md`（Feature ID、Slice ID、DoD）。
- **准备 commit** = 草稿 + 你审批，**不**自动 `git commit`。
- 新 Feature：先在 `FEATURE_REGISTRY.md` 登记。
- 大改 / 流水线改造：先 Pre-flight（设计范围 + 删除旧路径，不堆补丁层）。

3) **End of session**
- 请 AI 用 progress 模板追加 `PROGRESS_LOG.md`，并给出下一会话第一句。

## Suggested user prompts

**Start:**
```
继续 BUPT 课设。先读 docs/ai/PROJECT_CONTEXT.md、ACTIVE_WORK.md、PROGRESS_LOG.md 最近几条，总结上下文并提议下一步。
```

**End:**
```
请用 progress-log-entry 模板追加 PROGRESS_LOG，并写下一会话第一句 actionable 动作。
```

**Handoff:**
```
请按 handoff 流程写 session 笔记、更新 Progress，未完成 slice 标 Blocked，并给我下一会话首句。
```

**Commit prep:**
```
准备 commit。先检查 Doc DoD + 工程 DoD，起草 Conventional Commits 信息，等我批准再执行。
```

## Session notes

复杂讨论可写：`docs/ai/sessions/YYYY-MM-DD-topic.md`（用 session-note 模板）。
