param(
    [int]$Seeds = 20,
    [int]$NumOps = 500,
    [int]$StartSeed = 1
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

$results = @()
$passCount = 0
$failCount = 0

for ($i = 0; $i -lt $Seeds; $i++) {
    $seed = $StartSeed + $i
    $logPath = Join-Path $Root ("out\seed_{0}.log" -f $seed)
    $cmd = "run -all; quit -f"

    $output = & vsim -c lsu_slice_tb_v2 -sv_seed $seed +SEED=$seed +NUM_OPS=$NumOps -do $cmd 2>&1
    $outputText = ($output | Out-String)
    $outputText | Set-Content -LiteralPath $logPath -Encoding ascii

    $isPass = $outputText -match 'LSU_V2 PASSED'
    $scoreLine = ($output | Where-Object { $_ -match 'SCOREBOARD total=' } | Select-Object -Last 1)
    $covLine = ($output | Where-Object { $_ -match 'COVERAGE issue_cov=' } | Select-Object -Last 1)

    if ($isPass) {
        $status = 'PASS'
        $passCount++
    } else {
        $status = 'FAIL'
        $failCount++
    }

    $results += [pscustomobject]@{
        Seed = $seed
        Status = $status
        Scoreboard = $scoreLine
        Coverage = $covLine
        Log = $logPath
    }

    Write-Host ("Seed {0}: {1}" -f $seed, $status)
}

$csvPath = Join-Path $Root 'out\regression_summary.csv'
$results | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding ascii

Write-Host "========================================="
Write-Host ("Regression Done: PASS={0}, FAIL={1}" -f $passCount, $failCount)
Write-Host ("Summary CSV: {0}" -f $csvPath)
Write-Host "========================================="

if ($failCount -ne 0) {
    exit 1
}
