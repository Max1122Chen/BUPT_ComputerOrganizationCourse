# BUPT 计算机组成原理课程设计

题目 A — **TEC-PLUS 硬布线控制器**（基础顺序 → 进阶流水线）  
工具：**Xilinx ISE 14.7**

## 当前状态

需求已批准；仓库已关联 GitHub。首次 commit 待你批准后执行。编码从 `CTL-F01-S01` 开始。

| 文档 | 说明 |
|------|------|
| [需求分析](docs/ai/designs/REQUIREMENTS_ANALYSIS.md) | 基础→进阶功能与非功能需求 |
| [执行路线图](docs/ai/designs/EXECUTION_ROADMAP.md) | 27 切片、5 阶段 |
| [ACTIVE_WORK](docs/ai/ACTIVE_WORK.md) | 当前 backlog |

## 目录

```text
docs/course/     课设 PDF/图片
docs/ai/         设计、进度、协作
rtl/             Verilog（待开工）
sim/             仿真
constraints/     tecplus.ucf
ise/             ISE 14.7 工程
scripts/         verify.ps1
```

## 验证

```powershell
.\scripts\verify.ps1 -Stage 0
```

## 平台

- 实验箱：TEC-PLUS（Spartan-6 XC6SLX9）
- 引脚：`constraints/tecplus.ucf`（见课设图片-47）
- ADR：[ADR-20260706-01](docs/ai/adrs/ADR-20260706-01-platform-ise-tecplus.md)
