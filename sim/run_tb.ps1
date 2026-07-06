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
exit $LASTEXITCODE
