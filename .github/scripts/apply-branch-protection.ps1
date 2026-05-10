#Requires -Version 7.0
<#
.SYNOPSIS
  Applies the documented repository ruleset and merge settings on main via the gh CLI.
.DESCRIPTION
  Enables merge commits at the repository level, removes the legacy branch-based
  protection rule for the target branch, and creates or updates the repository
  ruleset that enforces the required PR status checks for `main`.
.PARAMETER Owner
  Repository owner (default: drmoisan).
.PARAMETER Repo
  Repository name (default: TMW).
.PARAMETER Branch
  Branch name governed by the repository ruleset (default: main).
.PARAMETER RulesetName
  Repository ruleset name managed by this script.
.EXAMPLE
  pwsh -NoProfile -File .github/scripts/apply-branch-protection.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Owner = 'drmoisan',
    [string]$Repo = 'TMW',
    [string]$Branch = 'main',
    [string]$RulesetName = 'Main branch PR governance'
)

$ErrorActionPreference = 'Stop'
$script:GitHubApiVersion = '2026-03-10'

function Get-RequiredStatusCheckContextList {
    [CmdletBinding()]
    param()

    return @(
        'tier-classification',
        'stage-1-format',
        'stage-2-lint',
        'stage-3-typecheck',
        'stage-4-architecture',
        'stage-5-test',
        'stage-6-contract',
        'stage-7-integration'
    )
}

function Get-RepositoryMergeSettingsFieldList {
    [CmdletBinding()]
    param()

    return @(
        'allow_merge_commit=true'
    )
}

function Get-MainBranchRulesetFieldList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RulesetName,

        [Parameter(Mandatory = $true)]
        [string]$BranchRef
    )

    $fieldValues = @(
        "name=$RulesetName",
        'target=branch',
        'enforcement=active',
        "conditions[ref_name][include][]=$BranchRef",
        'rules[][type]=required_status_checks',
        'rules[][parameters][strict_required_status_checks_policy]=true'
    )

    foreach ($context in (Get-RequiredStatusCheckContextList)) {
        $fieldValues += "rules[][parameters][required_status_checks][][context]=$context"
    }

    return $fieldValues
}

function Invoke-GitHubApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $false)]
        [string[]]$FieldValues,

        [Parameter(Mandatory = $false)]
        [object]$Body,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreNotFound
    )

    $ghArgs = @(
        'api',
        '-X', $Method,
        '-H', 'Accept: application/vnd.github+json',
        '-H', "X-GitHub-Api-Version: $script:GitHubApiVersion",
        $Endpoint
    )

    foreach ($fieldValue in $FieldValues) {
        $ghArgs += '-f'
        $ghArgs += $fieldValue
    }

    if ($PSBoundParameters.ContainsKey('Body')) {
        $json = $Body | ConvertTo-Json -Depth 12 -Compress
        $output = $json | & gh @ghArgs --input - 2>&1
    }
    else {
        $output = & gh @ghArgs 2>&1
    }

    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String).Trim()
    if ($exitCode -ne 0) {
        if ($IgnoreNotFound.IsPresent -and $text -match '\b404\b') {
            return $null
        }

        throw "gh api $Method $Endpoint failed with exit code $exitCode. Output: $text"
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    try {
        return $text | ConvertFrom-Json -Depth 100
    }
    catch {
        return $text
    }
}

function Get-ManagedRepositoryRulesetId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Rulesets,

        [Parameter(Mandatory = $true)]
        [string]$RulesetName
    )

    foreach ($ruleset in $Rulesets) {
        if ($ruleset.name -ne $RulesetName) {
            continue
        }

        return [int]$ruleset.id
    }

    return $null
}

function Invoke-RepositoryGovernanceRulesetSync {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [Parameter(Mandatory = $true)]
        [string]$Branch,

        [Parameter(Mandatory = $true)]
        [string]$RulesetName
    )

    $repoEndpoint = "repos/$Owner/$Repo"
    $legacyProtectionEndpoint = "repos/$Owner/$Repo/branches/$Branch/protection"
    $rulesetsEndpoint = "repos/$Owner/$Repo/rulesets"
    $branchRef = "refs/heads/$Branch"

    if ($PSCmdlet.ShouldProcess($repoEndpoint, 'PATCH repository merge settings')) {
        [void](Invoke-GitHubApiRequest -Method PATCH -Endpoint $repoEndpoint -FieldValues (Get-RepositoryMergeSettingsFieldList))
    }

    $legacyProtection = Invoke-GitHubApiRequest -Method GET -Endpoint $legacyProtectionEndpoint -IgnoreNotFound
    if ($null -ne $legacyProtection -and $PSCmdlet.ShouldProcess($legacyProtectionEndpoint, 'DELETE legacy branch protection rule')) {
        [void](Invoke-GitHubApiRequest -Method DELETE -Endpoint $legacyProtectionEndpoint)
    }

    $rulesetFieldValues = Get-MainBranchRulesetFieldList -RulesetName $RulesetName -BranchRef $branchRef
    $rulesets = @(Invoke-GitHubApiRequest -Method GET -Endpoint $rulesetsEndpoint)
    $managedRulesetId = Get-ManagedRepositoryRulesetId -Rulesets $rulesets -RulesetName $RulesetName

    if ($null -ne $managedRulesetId) {
        $rulesetEndpoint = "$rulesetsEndpoint/$managedRulesetId"
        if ($PSCmdlet.ShouldProcess($rulesetEndpoint, 'PUT repository ruleset')) {
            [void](Invoke-GitHubApiRequest -Method PUT -Endpoint $rulesetEndpoint -FieldValues $rulesetFieldValues)
        }
    }
    elseif ($PSCmdlet.ShouldProcess($rulesetsEndpoint, 'POST repository ruleset')) {
        [void](Invoke-GitHubApiRequest -Method POST -Endpoint $rulesetsEndpoint -FieldValues $rulesetFieldValues)
    }

    Write-Verbose "Repository governance ruleset applied for branch '$Branch'."
    return 0
}

if ($MyInvocation.InvocationName -ne '.') {
    exit (Invoke-RepositoryGovernanceRulesetSync -Owner $Owner -Repo $Repo -Branch $Branch -RulesetName $RulesetName)
}

