# ADR-20260706-01 — 平台选型：TEC-PLUS + ISE 14.7

## Meta
- **ID:** ADR-20260706-01
- **Status:** Accepted
- **Owner:** maintainer
- **Last updated:** 2026-07-06
- **Related:** [REQUIREMENTS_ANALYSIS](../designs/REQUIREMENTS_ANALYSIS.md), [PROJECT_CONTEXT](../PROJECT_CONTEXT.md)

## TL;DR

课设实现锁定 **TEC-PLUS 实验箱（Spartan-6 XC6SLX9）+ Xilinx ISE 14.7**；引脚约束以课设图片-47 为准；不再使用 Quartus/TEC-8 路径。

## Context

- 题目 A 可选 EPM7128（TEC-8）或 Spartan-6（TEC-PLUS）
- 用户明确选用 ISE + TEC-PLUS
- 控制器逻辑与流程图（图片-43）两平台一致，差异仅在引脚与工具链

## Decision

| 项 | 选择 |
|----|------|
| 实验箱 | TEC-PLUS |
| 器件 | Xilinx Spartan-6 XC6SLX9-2FTG256 |
| 工具 | ISE 14.7（综合、实现、IMPACT 烧录） |
| 约束 | `constraints/tecplus.ucf` |
| 工程目录 | `ise/` |

## Alternatives considered

| 选项 | 优点 | 缺点 |
|------|------|------|
| TEC-8 + Quartus | 课设 PPT 示例多 | 与用户选择不符 |
| **TEC-PLUS + ISE** | 用户实验室环境、Artix 同级教学链 | ISE 老旧、Win10/11 兼容性需注意 |

## Consequences

- `quartus/` 目录弃用（保留 README 说明即可）
- `verify.ps1` Stage 2 改为检测 ISE 工程（`.xise`/`.prj`）
- 拓展层次中断（LIAR/IABUS）为 TEC-8 特有问题；TEC-PLUS 若接入 IAR 需单独评估，**不在基础–进阶范围内**

## Compliance

- Feature: `HW-F01`
- Slice: `HW-F01-S01`（UCF）、`HW-F01-S02`（ISE 工程）

## Supersedes / Superseded by

N/A
