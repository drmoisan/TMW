#Requires -Version 7.0
<#
.SYNOPSIS
  Enriches a BenchmarkDotNet full-report JSON file with a computed P99 percentile.
.DESCRIPTION
  BenchmarkDotNet's JsonExporter.Full emits Statistics.Percentiles with P0/P25/P50/
  P67/P80/P85/P90/P95/P100 but not P99. The benchmark regression comparator in
  scripts/benchmarks/compare-benchmarks.ps1 consumes Statistics.Percentiles.P99 per
  the schema documented in artifacts/benchmarks/README.md. This script computes P99
  from Statistics.OriginalValues using linear interpolation and writes the field back
  into the JSON so the downstream contract is preserved.

  The script is idempotent: if P99 is already present and the input flag -Force is
  not supplied, the existing value is left in place.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Get-Percentile {
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory = $true)][double[]]$Values,
        [Parameter(Mandatory = $true)][ValidateRange(0, 100)][double]$Percentile
    )

    if ($Values.Count -eq 0) {
        throw "Cannot compute percentile from empty value set."
    }

    $sorted = [double[]]($Values | Sort-Object)
    if ($sorted.Count -eq 1) {
        return $sorted[0]
    }

    $rank = ($Percentile / 100.0) * ($sorted.Count - 1)
    $lower = [math]::Floor($rank)
    $upper = [math]::Ceiling($rank)
    if ($lower -eq $upper) {
        return $sorted[[int]$lower]
    }
    $weight = $rank - $lower
    return $sorted[[int]$lower] * (1.0 - $weight) + $sorted[[int]$upper] * $weight
}

$json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
if ($null -eq $json.Benchmarks) {
    throw "Input JSON has no Benchmarks array: $Path"
}

$updated = 0
foreach ($bench in $json.Benchmarks) {
    $stats = $bench.Statistics
    if ($null -eq $stats) {
        continue
    }
    $hasP99 = $stats.Percentiles.PSObject.Properties.Name -contains 'P99'
    if ($hasP99 -and -not $Force) {
        continue
    }
    $values = [double[]]@($stats.OriginalValues)
    $p99 = Get-Percentile -Values $values -Percentile 99
    if ($hasP99) {
        $stats.Percentiles.P99 = $p99
    }
    else {
        $stats.Percentiles | Add-Member -NotePropertyName 'P99' -NotePropertyValue $p99 -Force
    }
    $updated++
}

if ($PSCmdlet.ShouldProcess($Path, "Write enriched BDN report with $updated P99 entries")) {
    $json | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8
    Write-Output ("Enriched {0} benchmark entries with P99 in {1}" -f $updated, $Path)
}
