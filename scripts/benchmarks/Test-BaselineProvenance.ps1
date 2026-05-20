#Requires -Version 7.0
<#
.SYNOPSIS
    Validates benchmark baseline provenance per .claude/rules/benchmark-baselines.md
    (issue #26).

.DESCRIPTION
    Enforces two rejection conditions and one acceptance condition:
      - reject a baseline whose HostEnvironmentInfo.ProcessorName == "Unknown processor",
      - reject a baseline that has no sibling baseline.provenance.json,
      - accept a runner-captured baseline whose ProcessorName is a real processor
        and whose sibling baseline.provenance.json is present.

    The validator exposes a pure-logic seam so the rule can be unit-tested
    without filesystem I/O: callers pass the baseline JSON text, whether the
    sibling provenance file is present, and (optionally) the provenance JSON
    text. A thin file-reading wrapper (-BaselinePath) is provided for production
    use and resolves the same inputs from disk.

.PARAMETER BaselinePath
    Path to the baseline JSON file. When supplied, the script reads the baseline
    content and probes for a sibling baseline.provenance.json in the same
    directory. Mutually exclusive with -BaselineContent.

.PARAMETER BaselineContent
    The baseline JSON text. Used by the pure-logic seam.

.PARAMETER ProvenancePresent
    Whether a sibling baseline.provenance.json exists. Used by the pure-logic seam.

.PARAMETER ProvenanceContent
    Optional provenance JSON text used by the pure-logic seam.

.OUTPUTS
    A [pscustomobject] with IsValid ([bool]) and Reasons ([string[]]).
#>
[CmdletBinding(DefaultParameterSetName = 'Content')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
    [string]$BaselinePath,

    [Parameter(Mandatory = $true, ParameterSetName = 'Content')]
    [string]$BaselineContent,

    [Parameter(Mandatory = $false, ParameterSetName = 'Content')]
    [bool]$ProvenancePresent,

    [Parameter(Mandatory = $false, ParameterSetName = 'Content')]
    [string]$ProvenanceContent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSCmdlet.ParameterSetName -eq 'Path') {
    if (-not (Test-Path -LiteralPath $BaselinePath)) {
        throw "Test-BaselineProvenance: baseline file not found at '$BaselinePath'."
    }
    $BaselineContent = Get-Content -LiteralPath $BaselinePath -Raw
    $provenancePath = Join-Path (Split-Path -Parent $BaselinePath) 'baseline.provenance.json'
    $ProvenancePresent = Test-Path -LiteralPath $provenancePath
    if ($ProvenancePresent) {
        $ProvenanceContent = Get-Content -LiteralPath $provenancePath -Raw
    }
}

$reasons = [System.Collections.Generic.List[string]]::new()

$baseline = $null
try {
    $baseline = $BaselineContent | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Test-BaselineProvenance: malformed baseline JSON. $($_.Exception.Message)"
}

$processorName = $null
if ($null -ne $baseline -and
    $baseline.PSObject.Properties.Name -contains 'HostEnvironmentInfo' -and
    $null -ne $baseline.HostEnvironmentInfo -and
    $baseline.HostEnvironmentInfo.PSObject.Properties.Name -contains 'ProcessorName') {
    $processorName = [string]$baseline.HostEnvironmentInfo.ProcessorName
}

if ($processorName -eq 'Unknown processor') {
    $reasons.Add('HostEnvironmentInfo.ProcessorName is "Unknown processor"; baseline must be recaptured on the target runner class.')
}

if (-not $ProvenancePresent) {
    $reasons.Add('Sibling baseline.provenance.json is missing; baseline must be recaptured with provenance recorded.')
}
elseif (-not [string]::IsNullOrWhiteSpace($ProvenanceContent)) {
    # When provenance content is supplied, confirm the required fields are present.
    $provenance = $null
    try {
        $provenance = $ProvenanceContent | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $reasons.Add('Sibling baseline.provenance.json is malformed JSON.')
    }
    if ($null -ne $provenance) {
        foreach ($field in @('runner_class', 'host_signature', 'workflow_run_url')) {
            if ($provenance.PSObject.Properties.Name -notcontains $field -or
                [string]::IsNullOrWhiteSpace([string]$provenance.$field)) {
                $reasons.Add("Sibling baseline.provenance.json is missing required field '$field'.")
            }
        }
    }
}

[pscustomobject]@{
    IsValid = ($reasons.Count -eq 0)
    Reasons = $reasons.ToArray()
}
