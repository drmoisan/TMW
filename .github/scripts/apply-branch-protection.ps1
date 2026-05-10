#Requires -Version 7.0
<#
.SYNOPSIS
  Applies the documented branch protection rule on main via the gh CLI.
.DESCRIPTION
  Calls `gh api -X PUT repos/<owner>/<repo>/branches/<branch>/protection` with the
  eight required status check contexts and supporting protection settings defined
  in docs/branch-protection.md. Idempotent: re-applying yields the same final state.
.PARAMETER Owner
  Repository owner (default: drmoisan).
.PARAMETER Repo
  Repository name (default: TMW).
.PARAMETER Branch
  Protected branch name (default: main).
.EXAMPLE
  pwsh -NoProfile -File .github/scripts/apply-branch-protection.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Owner = 'drmoisan',
    [string]$Repo = 'TMW',
    [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'

$contexts = @(
    'tier-classification',
    'stage-1-format',
    'stage-2-lint',
    'stage-3-typecheck',
    'stage-4-architecture',
    'stage-5-test',
    'stage-6-contract',
    'stage-7-integration'
)

$endpoint = "repos/$Owner/$Repo/branches/$Branch/protection"

$body = [ordered]@{
    required_status_checks        = [ordered]@{
        strict   = $true
        contexts = $contexts
    }
    enforce_admins                = $true
    required_pull_request_reviews = [ordered]@{
        required_approving_review_count = 1
        dismiss_stale_reviews           = $true
    }
    required_linear_history       = $true
    restrictions                  = $null
    allow_force_pushes            = $false
    allow_deletions               = $false
}

$json = $body | ConvertTo-Json -Depth 6 -Compress

if ($PSCmdlet.ShouldProcess($endpoint, 'PUT branch protection')) {
    $json | & gh api -X PUT $endpoint --input -
    if ($LASTEXITCODE -ne 0) {
        throw "gh api PUT $endpoint failed with exit code $LASTEXITCODE"
    }
    Write-Output "Branch protection applied: $endpoint"
}

