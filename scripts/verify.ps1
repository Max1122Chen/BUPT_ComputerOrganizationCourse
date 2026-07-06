# Local verify for BUPT Computer Organization course project
# Usage:
#   .\scripts\verify.ps1           # run all enabled stages
#   .\scripts\verify.ps1 -Stage 0  # repo sanity only
#   .\scripts\verify.ps1 -Stage 1  # simulation smoke (when ready)
#   .\scripts\verify.ps1 -Stage 2  # ISE compile (when ready)

param(
    [int]$Stage = -1
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Write-StageHeader([string]$Name) {
    Write-Host ""
    Write-Host "=== $Name ===" -ForegroundColor Cyan
}

function Test-Stage0 {
    Write-StageHeader "Stage 0: repository sanity"
    $required = @(
        "docs/ai/ACTIVE_WORK.md",
        "docs/ai/PROJECT_CONTEXT.md",
        "docs/ai/FEATURE_REGISTRY.md",
        "docs/ai/BOOTSTRAP_DIGEST.md",
        "scripts/verify.ps1"
    )
    foreach ($rel in $required) {
        $path = Join-Path $RepoRoot $rel
        if (-not (Test-Path $path)) {
            throw "Missing required path: $rel"
        }
    }
    Write-Host "OK: required docs and scripts present"
}

function Test-Stage1 {
    Write-StageHeader "Stage 1: simulation smoke"
    $tb = Get-ChildItem -Path (Join-Path $RepoRoot "sim") -Filter "*_tb.v" -ErrorAction SilentlyContinue
    if (-not $tb) {
        Write-Host "SKIP: no testbench under sim/ (add sim/*_tb.v to enable)" -ForegroundColor Yellow
        return
    }
  # TODO: wire ModelSim/Questa or iverilog when toolchain is confirmed
    throw "Stage 1 not wired yet. Add sim runner here after SIM-F01."
}

function Test-Stage2 {
    Write-StageHeader "Stage 2: ISE compile"
    $iseDir = Join-Path $RepoRoot "ise"
    $xise = Get-ChildItem -Path $iseDir -Filter "*.xise" -ErrorAction SilentlyContinue
    $prj = Get-ChildItem -Path $iseDir -Filter "*.prj" -ErrorAction SilentlyContinue
    if (-not $xise -and -not $prj) {
        Write-Host "SKIP: no .xise/.prj under ise/ (create ISE project in HW-F01-S02)" -ForegroundColor Yellow
        return
    }
  # TODO: fuse or xflow -intstyle ise ...
    throw "Stage 2 not wired yet. Add ISE build after HW-F01-S03."
}

$stages = if ($Stage -ge 0) { @($Stage) } else { @(0, 1, 2) }

foreach ($s in $stages) {
    switch ($s) {
        0 { Test-Stage0 }
        1 { Test-Stage1 }
        2 { Test-Stage2 }
        default { throw "Unknown stage: $s (use 0, 1, or 2)" }
    }
}

Write-Host ""
Write-Host "verify.ps1 finished successfully." -ForegroundColor Green
