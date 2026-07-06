# Progress Log

按时间线记录开发与调试。课设验收的**调试日志**可从此文件导出或摘录。

---

### 2026-07-06 — 工程纪律骨架落地 (WF-F01)

- **Goal:** 从 minEngine 迁移轻量文档 + ID + 验证工作流到本课设仓库
- **Main changes:**
  - 建立 `docs/ai/`（PROJECT_CONTEXT、ACTIVE_WORK、FEATURE_REGISTRY、模板等）
  - 建立 `.cursor/rules/` 协作约束
  - 课设 PDF/图片迁入 `docs/course/`
  - 添加 `rtl/`、`sim/`、`constraints/`、`quartus/` 目录骨架
  - 添加 `scripts/verify.ps1`（分阶段占位）
- **Docs:** README、DOC_GOVERNANCE、CODING_STYLE
- **Risks or caveats:** 平台（TEC-8 vs TEC-PLUS）与 IDE 尚未最终确认
- **Validation done:** 目录与文档自检；`verify.ps1` Stage 0 占位通过
- **Next step:** 等待用户布置：锁定平台 → `CTL-F01` 设计

### 2026-07-06 — 基础至进阶需求分析与执行切片 (Review)

- **Goal:** 锁定 TEC-PLUS+ISE；完成需求分析、设计、27 切片计划；待审批后编码
- **Main changes:**
  - ADR-20260706-01 平台；ADR-20260706-02 流水模型（Proposed）
  - REQUIREMENTS_ANALYSIS、EXECUTION_ROADMAP
  - CTL/SIM/HW/PL 各 DESIGN + IMPLEMENTATION
  - 更新 PROJECT_CONTEXT、ACTIVE_WORK、FEATURE_REGISTRY、TECH_DEBT
- **Docs:** 见 `docs/ai/designs/`
- **Risks or caveats:** OUT/DI/EI/IRET 微操作待上板对标；审批前不写 RTL
- **Validation done:** 文档自检；`verify.ps1 -Stage 0` PASS
- **Next step:** 用户审批 → CTL-F01-S01

### 2026-07-06 — CTL-F01 基础阶段 RTL 实现 (CTL-F01-S01–S10)

- **Goal:** 顺序硬布线控制器 Verilog + 仿真框架
- **Main changes:**
  - `rtl/controller/hardwired_ctrl.v` — 14 指令 + 手动 SW 模式
  - `rtl/top/top.v` — 与图片-47 端口一致
  - `constraints/tecplus.ucf` — Spartan-6 引脚
  - `sim/tb_ctrl.v`, `sim/golden/ctl_vectors.txt`, `sim/run_tb.ps1`
  - `verify.ps1` Stage 1 支持 iverilog
- **Risks or caveats:** 本机无 iverilog，Stage 1 跳过；OUT/DI/EI/IRET 仍为暂定控制字
- **Validation done:** `verify.ps1 -Stage 0` PASS
- **Next step:** HW-F01 ISE 工程 + 上板，或安装 iverilog 跑仿真

### 2026-07-06 — iverilog 安装与仿真通过 (SIM-F01)

- **Goal:** 本机仿真环境 + 修复 tb 使控制向量测试通过
- **Main changes:**
  - 安装 iverilog 12.0 至 `%LOCALAPPDATA%\iverilog`（bleyer 安装包）
  - 修复 `tb_ctrl.v`：`ir` 8 位宽、IR7–IR4 接线
  - 更新 `sim/README.md`、文档状态
- **Validation done:** `.\sim\run_tb.ps1` PASS；`verify.ps1 -Stage 1` PASS
- **Next step:** HW-F01 ISE 工程 + 上板

### 2026-07-06 — 文档状态同步（commit 前）

- **Goal:** 交接用文档与 Feature 状态对齐当前进度
- **Main changes:** ACTIVE_WORK、FEATURE_REGISTRY、EXECUTION_ROADMAP、CTL/SIM 状态 → Done/In Progress
- **Next step:** 本 commit 批准后 → HW-F01-S02

<!-- 新条目请用 templates/progress-log-entry.template.md 格式追加在上方 -->
