#Requires -Version 7.0
<#
.SYNOPSIS
    Implements the feature-review policy rule "modified-workflow-needs-green-run"
    (issue #26, spec.md AC6).

.DESCRIPTION
    Given the list of changed files on the branch and whether green workflow-run
    evidence against the branch head is present, decides whether the policy audit
    must emit a Blocking finding.

    The rule fires (IsBlocking = $true) when the changed-file set includes any
    path matching one of the trigger globs and no green-run evidence is present:
      - .github/workflows/**
      - scripts/benchmarks/**
      - .github/actions/**

    A green workflow_dispatch run against the branch head satisfies the evidence
    requirement equally to a PR-context run; the caller passes the result of that
    determination via -GreenRunEvidencePresent.

.PARAMETER ChangedFiles
    The repo-relative paths of files changed on the branch (forward-slash form).

.PARAMETER GreenRunEvidencePresent
    Whether evidence of a green workflow run (PR-context or workflow_dispatch)
    against the branch head is present in the remediation inputs.

.OUTPUTS
    A [pscustomobject] with IsBlocking ([bool]) and MatchedPaths ([string[]]).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [string[]]$ChangedFiles,

    [Parameter(Mandatory = $true)]
    [bool]$GreenRunEvidencePresent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$triggerPrefixes = @(
    '.github/workflows/',
    'scripts/benchmarks/',
    '.github/actions/'
)

$matched = [System.Collections.Generic.List[string]]::new()
foreach ($file in $ChangedFiles) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    $normalized = $file.Replace('\', '/')
    foreach ($prefix in $triggerPrefixes) {
        if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $matched.Add($normalized)
            break
        }
    }
}

$isBlocking = ($matched.Count -gt 0) -and (-not $GreenRunEvidencePresent)

[pscustomobject]@{
    IsBlocking   = $isBlocking
    MatchedPaths = $matched.ToArray()
}
