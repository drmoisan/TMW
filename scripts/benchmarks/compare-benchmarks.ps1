#Requires -Version 7.0
<#
.SYNOPSIS
  Compares a current BenchmarkDotNet (BDN) report against a committed baseline
  and exits non-zero when a regression exceeds configured thresholds.
.DESCRIPTION
  Stage 10 (benchmark regression) of the PR pipeline invokes this script with
  the committed baseline at artifacts/benchmarks/baseline.json and the current
  PR run's *-report-full.json. The script emits one diff row per benchmark id
  to stdout and exits:

    0  All benchmarked ids pass the thresholds.
    1  At least one benchmark regressed beyond the thresholds.
    2  An input file is missing or malformed.

  Schema fields consumed per artifacts/benchmarks/README.md:
    FullName                                  -> benchmark id
    Statistics.Percentiles.P99                -> p99 latency (ns)
    Memory.BytesAllocatedPerOperation         -> allocated bytes per op
.PARAMETER BaselinePath
  Path to the committed BDN baseline JSON.
.PARAMETER CurrentPath
  Path to the current run's BDN *-report-full.json.
.PARAMETER T1BenchmarkIdPattern
  Substring used to mark a benchmark id as a T1 hot path. When the FullName
  contains this substring the p99 threshold is applied. Default: empty string
  meaning every benchmark is considered T1 (conservative).
.PARAMETER LatencyThresholdPercent
  Maximum permitted p99 latency regression on T1 benchmarks. Default 5.
.PARAMETER LatencyMinDeltaNs
  Absolute p99 delta floor (nanoseconds) used in AND-combination with
  LatencyThresholdPercent. A T1 benchmark is reported as FAIL_LATENCY only when
  both the relative regression exceeds LatencyThresholdPercent AND the absolute
  delta (current minus baseline, in ns) exceeds LatencyMinDeltaNs. Default 5.0 ns.
  This suppresses false positives from CI runner timing jitter on very fast
  (sub-100 ns) benchmarks where a few ns of noise can cross the 5% relative line.
.PARAMETER AllocationThresholdPercent
  Maximum permitted allocation regression on any benchmark. Default 10.
#>
[CmdletBinding()]
param(
    [string]$BaselinePath,
    [string]$CurrentPath,
    [string]$T1BenchmarkIdPattern = '',
    [double]$LatencyThresholdPercent = 5.0,
    [double]$LatencyMinDeltaNs = 5.0,
    [double]$AllocationThresholdPercent = 10.0
)

$ErrorActionPreference = 'Stop'

function Read-BenchmarkReport {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        [Console]::Error.WriteLine("Benchmark report not found: $Path")
        $ex = [System.Management.Automation.RuntimeException]::new("Benchmark report not found: $Path")
        $ex.Data['ExitCode'] = 2
        throw $ex
    }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw
        $json = $raw | ConvertFrom-Json
    }
    catch {
        [Console]::Error.WriteLine("Failed to parse JSON at $Path : $_")
        $ex = [System.Management.Automation.RuntimeException]::new("Failed to parse JSON at $Path : $_")
        $ex.Data['ExitCode'] = 2
        throw $ex
    }
    if ($null -eq $json.Benchmarks) {
        [Console]::Error.WriteLine("Report at $Path has no Benchmarks array.")
        $ex = [System.Management.Automation.RuntimeException]::new("Report at $Path has no Benchmarks array.")
        $ex.Data['ExitCode'] = 2
        throw $ex
    }
    return $json.Benchmarks
}

function Get-PercentDelta {
    [CmdletBinding()]
    [OutputType([double])]
    param([double]$Baseline, [double]$Current)

    if ($Baseline -le 0) {
        if ($Current -le 0) { return 0.0 }
        # Baseline is zero/negative; any positive current is treated as +infinity
        # but reported as a finite large number so the threshold trips deterministically.
        return [double]::PositiveInfinity
    }
    return (($Current - $Baseline) / $Baseline) * 100.0
}

function Invoke-CompareBenchmarksMain {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)][string]$BaselinePath,
        [Parameter(Mandatory = $true)][string]$CurrentPath,
        [string]$T1BenchmarkIdPattern = '',
        [double]$LatencyThresholdPercent = 5.0,
        [double]$LatencyMinDeltaNs = 5.0,
        [double]$AllocationThresholdPercent = 10.0
    )

    try {
        $baselineBenchmarks = Read-BenchmarkReport -Path $BaselinePath
        $currentBenchmarks = Read-BenchmarkReport -Path $CurrentPath
    }
    catch {
        if ($_.Exception.Data['ExitCode']) {
            return [int]$_.Exception.Data['ExitCode']
        }
        throw
    }

    # Build lookup by FullName.
    $baselineMap = @{}
    foreach ($b in $baselineBenchmarks) {
        $baselineMap[$b.FullName] = $b
    }

    $anyRegression = $false
    Write-Output 'id, p99_baseline_ns, p99_current_ns, p99_delta_pct, alloc_baseline_b, alloc_current_b, alloc_delta_pct, verdict'

    foreach ($cur in $currentBenchmarks) {
        $id = [string]$cur.FullName
        if (-not $baselineMap.ContainsKey($id)) {
            Write-Output ("{0}, NA, NA, NA, NA, NA, NA, SKIP_NO_BASELINE" -f $id)
            continue
        }
        $base = $baselineMap[$id]

        $p99Baseline = [double]$base.Statistics.Percentiles.P99
        $p99Current = [double]$cur.Statistics.Percentiles.P99
        $allocBaseline = [double]$base.Memory.BytesAllocatedPerOperation
        $allocCurrent = [double]$cur.Memory.BytesAllocatedPerOperation

        $p99Delta = Get-PercentDelta -Baseline $p99Baseline -Current $p99Current
        $allocDelta = Get-PercentDelta -Baseline $allocBaseline -Current $allocCurrent

        $isT1 = ($T1BenchmarkIdPattern -ne '') -and ($id -like "*${T1BenchmarkIdPattern}*")
        if ($T1BenchmarkIdPattern -eq '') { $isT1 = $true }

        $p99AbsoluteDeltaNs = $p99Current - $p99Baseline

        $verdict = 'PASS'
        if ($isT1 -and ($p99Delta -gt $LatencyThresholdPercent) -and ($p99AbsoluteDeltaNs -gt $LatencyMinDeltaNs)) {
            $verdict = 'FAIL_LATENCY'
            $anyRegression = $true
        }
        if ($allocDelta -gt $AllocationThresholdPercent) {
            $verdict = if ($verdict -eq 'PASS') { 'FAIL_ALLOC' } else { 'FAIL_LATENCY_AND_ALLOC' }
            $anyRegression = $true
        }

        $row = "{0}, {1:F4}, {2:F4}, {3:F2}, {4:F0}, {5:F0}, {6:F2}, {7}" -f `
            $id, $p99Baseline, $p99Current, $p99Delta, $allocBaseline, $allocCurrent, $allocDelta, $verdict
        Write-Output $row
    }

    if ($anyRegression) { return 1 } else { return 0 }
}

# Top-level entrypoint: only execute when the script is run directly (not when dot-sourced
# by test helpers). $MyInvocation.InvocationName is the script path when run directly.
#
# Invoke-CompareBenchmarksMain emits the diff rows via Write-Output and returns the
# exit code as its final pipeline value. Collect the whole pipeline, echo the rows
# to the host for log visibility, and pass only the integer return to `exit` — passing
# the entire array would coerce to the first (string) element and silently yield 0.
if ($MyInvocation.InvocationName -ne '.') {
    $output = @(Invoke-CompareBenchmarksMain `
            -BaselinePath $BaselinePath `
            -CurrentPath $CurrentPath `
            -T1BenchmarkIdPattern $T1BenchmarkIdPattern `
            -LatencyThresholdPercent $LatencyThresholdPercent `
            -LatencyMinDeltaNs $LatencyMinDeltaNs `
            -AllocationThresholdPercent $AllocationThresholdPercent)
    if ($output.Count -gt 1) {
        $output[0..($output.Count - 2)] | ForEach-Object { Write-Host $_ }
    }
    exit ([int]$output[-1])
}
