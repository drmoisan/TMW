#Requires -Version 7.0
<#
.SYNOPSIS
  Generates synthetic regression fixtures for the benchmark comparator's self-validation suite.
.DESCRIPTION
  Reads artifacts/benchmarks/baseline.json and writes two derived fixtures next to the
  benchmark project so that scripts/benchmarks/compare-benchmarks.ps1 can be exercised
  against deterministic regression scenarios in CI:

    SyntheticLatencyRegressionFixture.json    Statistics.Median on InputNormalization_EdgePath multiplied by 2.0.
    SyntheticAllocationRegressionFixture.json BytesAllocatedPerOperation on InputNormalization_EdgePath multiplied by 1.105.

  The latency mutation targets Statistics.Median because the comparator reads Median (not P99)
  and applies a 25 ns absolute-delta floor in addition to a percentage threshold. A 2.0x multiplier
  on the InputNormalization_EdgePath baseline median (~65 ns) produces an absolute delta well above
  the 25 ns floor, ensuring the gate fires unambiguously.

  The fixtures are committed alongside the baseline so the self-validation tests
  are reproducible without re-running the BDN harness.
#>
[CmdletBinding()]
param(
    [string]$BaselinePath = 'artifacts/benchmarks/baseline.json',
    [string]$OutputDirectory = 'tests/TaskMaster.Benchmarks/Fixtures',
    [string]$T1BenchmarkSubstring = 'InputNormalization_EdgePath',
    [double]$LatencyMultiplier = 2.0,
    [string]$AllocationT1BenchmarkSubstring = 'InputNormalization_EdgePath',
    [double]$AllocationMultiplier = 1.105
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $BaselinePath)) {
    throw "Baseline not found: $BaselinePath"
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

function Copy-Report {
    [CmdletBinding()]
    [OutputType([object])]
    param([Parameter(Mandatory = $true)][string]$Path)

    $raw = Get-Content -LiteralPath $Path -Raw
    return ($raw | ConvertFrom-Json)
}

# Latency fixture.
$latency = Copy-Report -Path $BaselinePath
foreach ($bench in $latency.Benchmarks) {
    if ($bench.FullName -like "*${T1BenchmarkSubstring}*") {
        $bench.Statistics.Median = [double]$bench.Statistics.Median * $LatencyMultiplier
    }
}
$latencyPath = Join-Path $OutputDirectory 'SyntheticLatencyRegressionFixture.json'
$latency | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $latencyPath -Encoding UTF8
Write-Output ("Wrote {0} (Median +{1:P0} on {2})" -f $latencyPath, ($LatencyMultiplier - 1.0), $T1BenchmarkSubstring)

# Allocation fixture.
$alloc = Copy-Report -Path $BaselinePath
foreach ($bench in $alloc.Benchmarks) {
    if ($bench.FullName -like "*${AllocationT1BenchmarkSubstring}*") {
        $current = [double]$bench.Memory.BytesAllocatedPerOperation
        if ($current -le 0) { $current = 100.0 }
        $bench.Memory.BytesAllocatedPerOperation = [long][math]::Round($current * $AllocationMultiplier)
    }
}
$allocPath = Join-Path $OutputDirectory 'SyntheticAllocationRegressionFixture.json'
$alloc | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $allocPath -Encoding UTF8
Write-Output ("Wrote {0} (BytesAllocatedPerOperation +{1:P1} on {2})" -f $allocPath, ($AllocationMultiplier - 1.0), $AllocationT1BenchmarkSubstring)
