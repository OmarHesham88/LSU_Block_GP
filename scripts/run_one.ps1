param(
    [int]$Seed = 1,
    [int]$NumOps = 500,
    [switch]$Gui
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Root

if (-not (Test-Path -LiteralPath '.\work')) {
    vlib work | Out-Host
}

vlog -sv -f .\vortex_lsu_slice_stub.f | Out-Host
if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed"
}

$do = 'run -all; quit -f'
if ($Gui) {
    vsim lsu_slice_tb_v2 -sv_seed $Seed +SEED=$Seed +NUM_OPS=$NumOps
} else {
    vsim -c lsu_slice_tb_v2 -sv_seed $Seed +SEED=$Seed +NUM_OPS=$NumOps -do $do | Out-Host
}

if ($LASTEXITCODE -ne 0) {
    throw "Simulation failed"
}
