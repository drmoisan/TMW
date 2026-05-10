#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'apply-branch-protection.ps1' {
    BeforeAll {
        $script:UnderTest = (Resolve-Path "$PSScriptRoot/../../.github/scripts/apply-branch-protection.ps1").Path
        . $script:UnderTest
    }

    It 'builds repository settings that allow merge commits' {
        $fieldValues = @(Get-RepositoryMergeSettingsFieldList)

        $fieldValues | Should -Contain 'allow_merge_commit=true'
    }

    It 'builds a main-branch ruleset without reviewer or linear-history rules' {
        $fieldValues = @(Get-MainBranchRulesetFieldList -RulesetName 'Main branch PR governance' -BranchRef 'refs/heads/main')
        $requiredChecks = @($fieldValues | Where-Object { $_.StartsWith('rules[][parameters][required_status_checks][][context]=') })

        $fieldValues | Should -Contain 'name=Main branch PR governance'
        $fieldValues | Should -Contain 'target=branch'
        $fieldValues | Should -Contain 'enforcement=active'
        $fieldValues | Should -Contain 'conditions[ref_name][include][]=refs/heads/main'
        $fieldValues | Should -Contain 'rules[][type]=required_status_checks'
        $fieldValues | Should -Contain 'rules[][parameters][strict_required_status_checks_policy]=true'
        $fieldValues | Should -Not -Contain 'rules[][type]=pull_request'
        ($fieldValues | Where-Object { $_ -like '*required_approving_review_count*' }).Count | Should -Be 0
        ($fieldValues | Where-Object { $_ -like '*required_linear_history*' }).Count | Should -Be 0
        $requiredChecks | Should -Be @(
            'rules[][parameters][required_status_checks][][context]=tier-classification',
            'rules[][parameters][required_status_checks][][context]=stage-1-format',
            'rules[][parameters][required_status_checks][][context]=stage-2-lint',
            'rules[][parameters][required_status_checks][][context]=stage-3-typecheck',
            'rules[][parameters][required_status_checks][][context]=stage-4-architecture',
            'rules[][parameters][required_status_checks][][context]=stage-5-test',
            'rules[][parameters][required_status_checks][][context]=stage-6-contract',
            'rules[][parameters][required_status_checks][][context]=stage-7-integration'
        )
    }

    It 'matches an existing managed ruleset by name and branch ref' {
        $rulesets = @(
            [pscustomobject]@{
                id   = 5
                name = 'Other ruleset'
            },
            [pscustomobject]@{
                id   = 9
                name = 'Main branch PR governance'
            }
        )

        $rulesetId = Get-ManagedRepositoryRulesetId -Rulesets $rulesets -RulesetName 'Main branch PR governance'

        $rulesetId | Should -Be 9
    }

    It 'creates a repository ruleset and removes legacy branch protection when needed' {
        Mock Invoke-GitHubApiRequest {
            param(
                [string]$Method,
                [string]$Endpoint,
                [string[]]$FieldValues,
                [object]$Body,
                [switch]$IgnoreNotFound
            )

            $null = $FieldValues, $Body, $IgnoreNotFound

            switch ("$Method $Endpoint") {
                'PATCH repos/drmoisan/TMW' {
                    return [pscustomobject]@{ allow_merge_commit = $true }
                }
                'GET repos/drmoisan/TMW/branches/main/protection' {
                    return [pscustomobject]@{ url = 'legacy-protection' }
                }
                'DELETE repos/drmoisan/TMW/branches/main/protection' {
                    return $null
                }
                'GET repos/drmoisan/TMW/rulesets' {
                    return @()
                }
                'POST repos/drmoisan/TMW/rulesets' {
                    return [pscustomobject]@{ id = 17 }
                }
                default {
                    throw "Unexpected call: $Method $Endpoint"
                }
            }
        }

        $exitCode = Invoke-RepositoryGovernanceRulesetSync -Owner 'drmoisan' -Repo 'TMW' -Branch 'main' -RulesetName 'Main branch PR governance'

        $exitCode | Should -Be 0
        Assert-MockCalled Invoke-GitHubApiRequest -Times 1 -ParameterFilter { $Method -eq 'PATCH' -and $Endpoint -eq 'repos/drmoisan/TMW' -and $FieldValues -contains 'allow_merge_commit=true' }
        Assert-MockCalled Invoke-GitHubApiRequest -Times 1 -ParameterFilter { $Method -eq 'DELETE' -and $Endpoint -eq 'repos/drmoisan/TMW/branches/main/protection' }
        Assert-MockCalled Invoke-GitHubApiRequest -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Endpoint -eq 'repos/drmoisan/TMW/rulesets' -and $FieldValues -contains 'name=Main branch PR governance' }
    }

    It 'updates the managed ruleset and skips deletion when legacy protection is absent' {
        Mock Invoke-GitHubApiRequest {
            param(
                [string]$Method,
                [string]$Endpoint,
                [string[]]$FieldValues,
                [object]$Body,
                [switch]$IgnoreNotFound
            )

            $null = $FieldValues, $Body, $IgnoreNotFound

            switch ("$Method $Endpoint") {
                'PATCH repos/drmoisan/TMW' {
                    return [pscustomobject]@{ allow_merge_commit = $true }
                }
                'GET repos/drmoisan/TMW/branches/main/protection' {
                    return $null
                }
                'GET repos/drmoisan/TMW/rulesets' {
                    return @(
                        [pscustomobject]@{
                            id   = 42
                            name = 'Main branch PR governance'
                        }
                    )
                }
                'PUT repos/drmoisan/TMW/rulesets/42' {
                    return [pscustomobject]@{ id = 42 }
                }
                default {
                    throw "Unexpected call: $Method $Endpoint"
                }
            }
        }

        $exitCode = Invoke-RepositoryGovernanceRulesetSync -Owner 'drmoisan' -Repo 'TMW' -Branch 'main' -RulesetName 'Main branch PR governance'

        $exitCode | Should -Be 0
        Assert-MockCalled Invoke-GitHubApiRequest -Times 0 -ParameterFilter { $Method -eq 'DELETE' -and $Endpoint -eq 'repos/drmoisan/TMW/branches/main/protection' }
        Assert-MockCalled Invoke-GitHubApiRequest -Times 1 -ParameterFilter { $Method -eq 'PUT' -and $Endpoint -eq 'repos/drmoisan/TMW/rulesets/42' -and $FieldValues -contains 'name=Main branch PR governance' }
    }
}