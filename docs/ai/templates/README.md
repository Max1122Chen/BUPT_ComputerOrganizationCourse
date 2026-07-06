# 文档模板

新文档从本目录复制。协作规范见 [DOC_GOVERNANCE.md](./DOC_GOVERNANCE.md)。

## 模板清单

| 模板 | 何时用 | 落盘位置 |
|------|--------|----------|
| [design-spec.template.md](./design-spec.template.md) | 单能力设计 | `docs/ai/designs/` |
| [implementation-plan.template.md](./implementation-plan.template.md) | 设计 → 切片 | `docs/ai/designs/` |
| [adr.template.md](./adr.template.md) | 架构取舍 | `docs/ai/adrs/` |
| [bug-record.template.md](./bug-record.template.md) | 缺陷 / 上板问题 | `docs/ai/bugs/` |
| [progress-log-entry.template.md](./progress-log-entry.template.md) | 任务收尾 | 追加到 `PROGRESS_LOG.md` |
| [session-note.template.md](./session-note.template.md) | 会话上下文 | `docs/ai/sessions/` |

## 快速规则

- Feature：`<DOMAIN>-F<nn>`
- Slice：`<FeatureID>-S<nn>`
- 新 Feature 先登记 [FEATURE_REGISTRY.md](../FEATURE_REGISTRY.md)
