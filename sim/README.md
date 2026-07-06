# Simulation setup

## Icarus Verilog (installed)

| Item | Path |
|------|------|
| Install dir | `%LOCALAPPDATA%\iverilog` |
| Binaries | `%LOCALAPPDATA%\iverilog\bin\iverilog.exe`, `vvp.exe` |
| User PATH | Added automatically on 2026-07-06 |

Installer source: [bleyer.org/icarus](https://bleyer.org/icarus/) (`iverilog-v12-20220611-x64_setup.exe`)

**New terminal:** close and reopen PowerShell so `iverilog` is on PATH, or run:

```powershell
$env:Path += ";$env:LOCALAPPDATA\iverilog\bin"
```

## Run tests

```powershell
.\sim\run_tb.ps1
# or
.\scripts\verify.ps1 -Stage 1
```
