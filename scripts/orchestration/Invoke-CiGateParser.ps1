#Requires -Version 7.0
<#
.SYNOPSIS
    Parses `gh pr checks --required --json` output and emits the ci_gate object
    used by the orchestrate skill S9 CI green gate (issue #26).

.DESCRIPTION
    Consumes the JSON array produced by `gh pr checks --required --json
    bucket,name,state,link,workflow` and derives the ci_gate object defined in
    .claude/skills/orchestrate/SKILL.md. The conclusion is:
      - 'success' when every required check is in the 'pass' bucket,
      - 'failure' when any required check is in the 'fail' or 'cancel' bucket,
      - 'pending' when no check failed but at least one is still pending.

    The script accepts JSON as text so it is unit-testable without invoking gh.
    A failure precedence over pending matches branch-protection semantics: a
    failed required check is conclusive regardless of other pending checks.

.PARAMETER ChecksJson
    The raw JSON text emitted by `gh pr checks --required --json ...`.

.PARAMETER HeadSha
    The PR head SHA the checks were observed against.

.PARAMETER RunId
    The GitHub Actions run id for the PR Pipeline.

.PARAMETER RunUrl
    The URL of the PR Pipeline run.

.PARAMETER NowProvider
    Optional clock seam returning a DateTimeOffset for verified_at. Defaults to
    the current UTC time. Injected by tests for determinism.

.OUTPUTS
    A [pscustomobject] with head_sha, pr_pipeline_run_id, pr_pipeline_run_url,
    conclusion, and verified_at.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ChecksJson,

    [Parameter(Mandatory = $true)]
    [string]$HeadSha,

    [Parameter(Mandatory = $true)]
    [string]$RunId,

    [Parameter(Mandatory = $true)]
    [string]$RunUrl,

    [Parameter(Mandatory = $false)]
    [scriptblock]$NowProvider = { [System.DateTimeOffset]::UtcNow }
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$checks = $null
try {
    $checks = $ChecksJson | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Invoke-CiGateParser: malformed JSON input for required checks. $($_.Exception.Message)"
}

# Normalize to an array; ConvertFrom-Json returns a scalar for a single object.
if ($null -eq $checks) {
    $checkList = @()
}
elseif ($checks -is [System.Array]) {
    $checkList = $checks
}
else {
    $checkList = @($checks)
}

if ($checkList.Count -eq 0) {
    throw 'Invoke-CiGateParser: the required-checks list is empty; cannot derive a CI conclusion.'
}

$anyFailed = $false
$anyPending = $false
foreach ($check in $checkList) {
    $bucket = ''
    if ($check.PSObject.Properties.Name -contains 'bucket' -and $null -ne $check.bucket) {
        $bucket = [string]$check.bucket
    }
    switch ($bucket.ToLowerInvariant()) {
        'pass' { continue }
        'skipping' { continue }
        'fail' { $anyFailed = $true }
        'cancel' { $anyFailed = $true }
        'pending' { $anyPending = $true }
        default { $anyPending = $true }
    }
}

$conclusion = if ($anyFailed) { 'failure' }
elseif ($anyPending) { 'pending' }
else { 'success' }

$verifiedAt = (& $NowProvider).ToString('o')

[pscustomobject]@{
    head_sha            = $HeadSha
    pr_pipeline_run_id  = $RunId
    pr_pipeline_run_url = $RunUrl
    conclusion          = $conclusion
    verified_at         = $verifiedAt
}
