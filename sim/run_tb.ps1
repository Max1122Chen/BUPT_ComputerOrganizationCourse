# Run control testbench (requires iverilog + vvp on PATH)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Work = Join-Path $Root "sim\work"
New-Item -ItemType Directory -Force -Path $Work | Out-Null

iverilog -o (Join-Path $Work "tb_ctrl.out") `
    (Join-Path $Root "rtl\controller\hardwired_ctrl.v") `
    (Join-Path $Root "sim\tb_ctrl.v")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

vvp (Join-Path $Work "tb_ctrl.out")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

iverilog -o (Join-Path $Work "tb_manual_sto.out") `
    (Join-Path $Root "rtl\common\manual_sto.v") `
    (Join-Path $Root "sim\tb_manual_sto.v")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

vvp (Join-Path $Work "tb_manual_sto.out")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

iverilog -o (Join-Path $Work "tb_pipe.out") `
    (Join-Path $Root "rtl\controller\hardwired_ctrl_core.v") `
    (Join-Path $Root "rtl\controller\hardwired_ctrl_pipe.v") `
    (Join-Path $Root "sim\tb_pipe.v")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

vvp (Join-Path $Work "tb_pipe.out")
exit $LASTEXITCODE
