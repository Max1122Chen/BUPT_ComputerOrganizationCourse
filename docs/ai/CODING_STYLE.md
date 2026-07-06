# Verilog Coding Style

Last updated: 2026-07-06  
Applies to: `rtl/`, `sim/`

---

## Naming

| 对象 | 风格 | 示例 |
|------|------|------|
| module | `snake_case` | `hardwired_ctrl` |
| 文件名 | 与 module 同名 | `hardwired_ctrl.v` |
| 端口 / 内部信号 | 与实验箱一致 | `LIR`, `PCINC`, `SEL0` |
| 参数 | `UPPER_SNAKE` | `DATA_WIDTH` |
| 时钟 / 复位 | `clk`, `rst_n` 或课设名 `T3`, `CLR#`（顶层与约束一致） |

**不要**自造与实验箱不同的控制信号别名（顶层可用 `assign` 映射一次）。

---

## Structure

- 一个文件一个 `module`（小型组合逻辑辅助模块可例外，需在 Design 中说明）。
- 目录：`rtl/controller/` 控制器；`rtl/top/` 顶层；`rtl/common/` 参数与公共定义。
- 顶层 `top` 仅例化 + 引脚映射，不写复杂译码逻辑。

---

## Synthesis-friendly rules

- **时序逻辑：** `always @(posedge clk or posedge rst)` 内只用 **非阻塞** `<=`。
- **组合逻辑：** `always @(*)` 内用 **阻塞** `=`；所有分支必须赋值，避免 latch。
- **连续赋值：** `assign` 用于简单组合逻辑。
- 不在 `always` 块中对同一变量混用 `=` 与 `<=`。
- 复位策略在 Design/ADR 中统一（异步高有效 `CLR#` 与课设一致）。

---

## Controller-specific

- 控制字输出与课设流程图（图片-43）对齐；偏差须写 ADR。
- W1/W2/W3 与 `W1`,`W2`,`W3` 输入的关系在 Design 中画清时序表。
- 流水线阶段寄存器命名统一：`pipe_w1`, `pipe_w2` 或 `if_id` / `id_ex`（二选一并写 ADR）。

---

## Comments

- 代码以自解释为主；注释解释**非显而易见的时序**或**与课设图的对应关系**。
- 不写「翻译 Verilog 语法」的废话注释。

---

## What we do not do (yet)

- SystemVerilog assertions（除非仿真阶段单独启用）
- `ifndef` 头文件守卫在单 module 单文件项目中非必须；大型项目再引入 `rtl/common/defines.vh`
