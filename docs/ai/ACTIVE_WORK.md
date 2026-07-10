# Active work (agent backlog)

Last updated: 2026-07-10  
Purpose: **short, human-maintained** list for session handoff.

> **下一会话首句（建议）：** 按 PL-F01 §3 实现 S01–S03（core 抽取 + allow_ex 状态机 + EX 型拍）。

---

## In focus

| 项 | 状态 |
|----|------|
| **CTL-F01** 顺序硬布线 | **Done** |
| **CTL-F02** 中断拓展 | **Done**（冻结于 `feat/ctl-seq-interrupt`） |
| **PL-F01** 流水线 v1 | **In Progress** — 设计 §2+§3；**无中断**；按 IMPLEMENTATION 重做 RTL |
| **SIM-F01** / **HW-F01** | **Done** |

### 里程碑

```text
[M1 仿真]  Done   — tb_ctrl PASS
[M2 上板]  Done   — 基础 + CTL-F02（interrupt 分支）
[M3 拓展]  Done   — CTL-F02
[M4 进阶]  In Progress — PL-F01（Opcode_cache 模型）
```

---

## 交接要点

- **顺序+中断冻结：** `git checkout feat/ctl-seq-interrupt`
- **流水开发：** `main`；设计 [PL-F01_DESIGN §3](./designs/PL-F01_DESIGN.md)；执行 [PL-F01_IMPLEMENTATION](./designs/PL-F01_IMPLEMENTATION.md)
- **顺序基线：** `rtl/controller/hardwired_ctrl.v`（勿破坏 `tb_ctrl`）
- **仿真：** `.\sim\run_tb.ps1`

---

## Explicitly not backlog（本阶段）

- 流水版 CTL-F02 中断（等 PL-F01 v1 板上通过后再追）
- 旧版 `pipe_regs`/`hazard_unit` RTL

---

## Related

| File | Role |
|------|------|
| [FEATURE_REGISTRY](./FEATURE_REGISTRY.md) | Feature 状态 |
| [CTL-F02_DESIGN](./designs/CTL-F02_DESIGN.md) | 中断设计 |
| [PROGRESS_LOG](./PROGRESS_LOG.md) | 时间线 |
