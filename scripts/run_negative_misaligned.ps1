param(
    [int]$Seed = 1
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
$output = & vsim -c lsu_slice_tb_misaligned_neg -sv_seed $Seed -do $do 2>&1
$text = ($output | Out-String)
$log = Join-Path $Root 'out\misaligned_neg.log'
$text | Set-Content -LiteralPath $log -Encoding ascii

$hasMisalign = $text -match 'misaligned memory access'
$hasError = $text -match '\*\* Error:'

Write-Host "Negative test log: $log"

if ($hasMisalign -or $hasError) {
    Write-Host 'NEGATIVE TEST RESULT: PASS (misalignment detected)'
    exit 0
}

Write-Host 'NEGATIVE TEST RESULT: FAIL (no misalignment/ error observed)'
exit 1
