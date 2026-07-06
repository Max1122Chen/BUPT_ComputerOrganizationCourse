# SIM-F01 — 仿真验证 Design Spec

## Meta
- **ID:** SIM-F01
- **Type:** Feature
- **Status:** Review
- **Owner:** maintainer
- **Last updated:** 2026-07-06
- **Related:** [SIM-F01_IMPLEMENTATION](./SIM-F01_IMPLEMENTATION.md)

## TL;DR

建立 **控制向量级** 仿真：不建模完整数据通路，只验证控制器在各 W 相、各 IR 下的输出是否与黄金表一致；接入 `verify.ps1 -Stage 1`。

## Scope

- **In:** `sim/` Testbench、黄金向量、`scripts/verify.ps1`
- **Out:** 完整 CPU 周期精确波形（可选后续）

---

## 3) 方案

### 3.1 黄金向量格式

`sim/golden/<suite>.txt` 每行示例：

```text
# IR W1 W2 W3 C Z SW  EXPECT: LIR PCINC S3S2S1S0 M ...
8'h11 1 0 0 0 0 3'b000  LIR=1 PCINC=1 ...
```

### 3.2 Testbench 结构

- `sim/tb_ctrl.v` — 实例化 DUT，按表驱动
- 可选 `sim/tb_w_sequence.v` — 自动生成 W1→W2→W3 序列

### 3.3 工具链

优先 **ISE Simulator / ModelSim**（与实验室一致）；开发机可用 `iverilog` 作快速检查（verify 脚本检测可用工具）。

---

## 6) 验收标准

- [ ] CTL-F01 全套件 PASS
- [ ] PL-F01 增量套件 PASS
- [ ] `verify.ps1 -Stage 1` 一键运行

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-06 | 初稿 |
