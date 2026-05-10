#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'validate-feature-review-coverage.ps1' {
    BeforeAll {
        # Dot-source the script in dot-import mode so its functions are available
        # without executing the bottom-of-file invocation block.
        $scriptPath = (Resolve-Path "$PSScriptRoot/../../.claude/hooks/validate-feature-review-coverage.ps1").Path
        . $scriptPath
    }

    Context 'Get-LcovRepoCoverage' {
        It 'returns null when the file does not exist' {
            Get-LcovRepoCoverage -Path (Join-Path -Path $TestDrive -ChildPath 'absent.info') | Should -BeNullOrEmpty
        }

        It 'computes percent from LF/LH counters' {
            $p = Join-Path -Path $TestDrive -ChildPath 'lcov-line.info'
            Set-Content -Path $p -Value @"
TN:
SF:src/a.ts
LF:100
LH:90
end_of_record
SF:src/b.ts
LF:100
LH:80
end_of_record
"@
            Get-LcovRepoCoverage -Path $p | Should -Be 85.0
        }

        It 'returns null when LF total is 0' {
            $p = Join-Path -Path $TestDrive -ChildPath 'lcov-zero.info'
            Set-Content -Path $p -Value "SF:x`nLF:0`nLH:0`nend_of_record"
            Get-LcovRepoCoverage -Path $p | Should -BeNullOrEmpty
        }
    }

    Context 'Get-LcovBranchCoverage' {
        It 'returns null when the file does not exist' {
            Get-LcovBranchCoverage -Path (Join-Path -Path $TestDrive -ChildPath 'absent.info') | Should -BeNullOrEmpty
        }

        It 'computes percent from BRF/BRH counters' {
            $p = Join-Path -Path $TestDrive -ChildPath 'lcov-branch.info'
            Set-Content -Path $p -Value @"
SF:src/a.ts
BRF:40
BRH:30
end_of_record
SF:src/b.ts
BRF:60
BRH:45
end_of_record
"@
            Get-LcovBranchCoverage -Path $p | Should -Be 75.0
        }

        It 'returns null when BRF total is 0' {
            $p = Join-Path -Path $TestDrive -ChildPath 'lcov-branch-zero.info'
            Set-Content -Path $p -Value "SF:x`nBRF:0`nBRH:0`nend_of_record"
            Get-LcovBranchCoverage -Path $p | Should -BeNullOrEmpty
        }
    }

    Context 'Get-JacocoRepoCoverage' {
        It 'computes line percent from JaCoCo counters' {
            $p = Join-Path -Path $TestDrive -ChildPath 'jacoco.xml'
            Set-Content -Path $p -Value @'
<?xml version="1.0"?>
<report>
  <package>
    <counter type="LINE" missed="15" covered="85"/>
    <counter type="BRANCH" missed="25" covered="75"/>
  </package>
</report>
'@
            Get-JacocoRepoCoverage -Path $p | Should -Be 85.0
        }

        It 'returns null on missing file' {
            Get-JacocoRepoCoverage -Path (Join-Path -Path $TestDrive -ChildPath 'absent.xml') | Should -BeNullOrEmpty
        }
    }

    Context 'Get-JacocoBranchCoverage' {
        It 'computes branch percent from JaCoCo counters' {
            $p = Join-Path -Path $TestDrive -ChildPath 'jacoco-branch.xml'
            Set-Content -Path $p -Value @'
<?xml version="1.0"?>
<report>
  <package>
    <counter type="LINE" missed="10" covered="90"/>
    <counter type="BRANCH" missed="25" covered="75"/>
  </package>
</report>
'@
            Get-JacocoBranchCoverage -Path $p | Should -Be 75.0
        }

        It 'returns null when BRANCH counter is absent' {
            $p = Join-Path -Path $TestDrive -ChildPath 'jacoco-noblanch.xml'
            Set-Content -Path $p -Value '<?xml version="1.0"?><report><package><counter type="LINE" missed="0" covered="10"/></package></report>'
            Get-JacocoBranchCoverage -Path $p | Should -BeNullOrEmpty
        }
    }

    Context 'Get-LanguageBranchCoverage dispatch' {
        It 'returns null for an unknown language' {
            Get-LanguageBranchCoverage -Language 'Rust' | Should -BeNullOrEmpty
        }
    }

    Context 'Test-LanguageCoverageRow' {
        It 'returns Ok=true when language line at exactly 85% and branch at exactly 75%' {
            $audit = "PowerShell coverage row PASS - line 85.00%, branch 75.00%"
            $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 85.0 -BranchPct 75.0
            $r.Ok | Should -BeTrue
        }

        It 'returns Ok=false when language is not mentioned' {
            $audit = "TypeScript coverage row PASS"
            $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 80.0
            $r.Ok | Should -BeFalse
            $r.Reason | Should -Match 'does not mention PowerShell'
        }

        It 'returns Ok=false when language is mentioned but no coverage row exists' {
            $audit = "PowerShell scripts have been added"
            $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 80.0
            $r.Ok | Should -BeFalse
            $r.Reason | Should -Match 'no coverage-scoped row'
        }

        It 'rejects scope-narrowing language on coverage rows' {
            $audit = "PowerShell coverage informational only"
            $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 80.0
            $r.Ok | Should -BeFalse
            $r.Reason | Should -Match 'narrows scope'
        }

        It 'returns Ok=false when no PASS/FAIL on coverage row' {
            $audit = "PowerShell coverage row noted"
            $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 80.0
            $r.Ok | Should -BeFalse
            $r.Reason | Should -Match 'PASS nor a FAIL'
        }

        It 'returns Ok=false when repo-wide line coverage 84% but no FAIL on row' {
            $audit = "PowerShell coverage row PASS - line 84%"
            $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 84.0 -BranchPct 80.0
            $r.Ok | Should -BeFalse
            $r.Reason | Should -Match '85% line coverage floor'
        }

        It 'accepts repo-wide line 84% when FAIL is present on coverage row' {
            $audit = "PowerShell coverage row FAIL - line 84%"
            $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 84.0 -BranchPct 80.0
            $r.Ok | Should -BeTrue
        }

        It 'returns Ok=false when branch coverage is 74% (below 75% floor)' {
            $audit = "PowerShell coverage row PASS - line 90%, branch 74%"
            $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 74.0
            $r.Ok | Should -BeFalse
            $r.Reason | Should -Match '75% branch coverage floor'
        }

        It 'accepts branch coverage at exactly 75% (boundary)' {
            $audit = "PowerShell coverage row PASS - line 90%, branch 75%"
            $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 75.0
            $r.Ok | Should -BeTrue
        }

        It 'works for each language label set' {
            foreach ($pair in @(
                    @{ L = 'TypeScript'; T = 'TypeScript coverage row PASS' },
                    @{ L = 'Python'; T = 'pytest coverage row PASS' },
                    @{ L = 'CSharp'; T = '.NET coverage row PASS' }
                )) {
                $r = Test-LanguageCoverageRow -AuditText $pair.T -Language $pair.L -RepoWidePct 90.0 -BranchPct 80.0
                $r.Ok | Should -BeTrue -Because "language $($pair.L) label set must match"
            }
        }
    }

    Context 'Invoke-FeatureReviewCoverageValidation entrypoint' {
        BeforeAll {
            # Build canonical artifact text fixtures once for reuse. Use here-strings
            # so no temp files outside $TestDrive are created.
            $script:Folder    = '2026-05-09-establish-repository-foundation-1'
            $script:Timestamp = '2026-05-09T18-00'
            $script:PolicyDir = "docs/features/active/$script:Folder"

            # Helper to fabricate the JSON payload that the entrypoint expects.
            # The function name uses the approved verb 'New-' but performs no system
            # state change; it only constructs an in-memory JSON string. Suppress
            # PSUseShouldProcessForStateChangingFunctions on this helper.
            function New-Payload {
                [CmdletBinding()]
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
                param([string]$Output)
                return (@{ output = $Output } | ConvertTo-Json -Depth 4 -Compress)
            }
        }

        It 'returns Ok=false when RawPayload is null' {
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload $null
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'CLAUDE_HOOK_INPUT is empty'
        }

        It 'returns Ok=false when RawPayload is empty string' {
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload ''
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'CLAUDE_HOOK_INPUT is empty'
        }

        It 'returns Ok=false when RawPayload is whitespace' {
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload "   `t  "
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'CLAUDE_HOOK_INPUT is empty'
        }

        It 'returns Ok=false when RawPayload is malformed JSON' {
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload '{ this is not json'
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'failed to parse CLAUDE_HOOK_INPUT as JSON'
        }

        It 'returns Ok=false when output property is absent' {
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (@{ unrelated = 'x' } | ConvertTo-Json -Compress)
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'agent output is empty'
        }

        It 'returns Ok=false when output property is empty string' {
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output '')
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'agent output is empty'
        }

        It 'returns Ok=false when output is whitespace only' {
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output "   `n  ")
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'agent output is empty'
        }

        It 'returns Ok=false with policy-audit-path-specific error when token absent' {
            $output = @"
code-review-path: $script:PolicyDir/code-review.$script:Timestamp.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
"@
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'missing policy-audit-path'
        }

        It 'returns Ok=false with code-review-path-specific error when token absent' {
            $output = @"
policy-audit-path: $script:PolicyDir/policy-audit.$script:Timestamp.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
"@
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'missing code-review-path'
        }

        It 'returns Ok=false with feature-audit-path-specific error when token absent' {
            $output = @"
policy-audit-path: $script:PolicyDir/policy-audit.$script:Timestamp.md
code-review-path: $script:PolicyDir/code-review.$script:Timestamp.md
"@
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'missing feature-audit-path'
        }

        It 'rejects an artifact path outside docs/features/active' {
            $output = @"
policy-audit-path: artifacts/policy-audit.$script:Timestamp.md
code-review-path: $script:PolicyDir/code-review.$script:Timestamp.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
"@
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'is outside the required docs/features/active'
        }

        It 'rejects mismatched timestamp between policy-audit and code-review' {
            # All three paths are canonical-form, but code-review's timestamp differs.
            # The policy-audit path will be rejected first because the underlying file
            # does not exist; assert the error message surfaces that the artifact was
            # advertised but not present, exercising the file-existence branch.
            $output = @"
policy-audit-path: $script:PolicyDir/policy-audit.$script:Timestamp.md
code-review-path: $script:PolicyDir/code-review.2026-01-01T00-00.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
"@
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
            $r.Ok | Should -BeFalse
            # The non-existent paths trigger the "no file exists at that location" branch.
            $r.Message | Should -Match 'no file exists at that location'
        }

        It 'rejects a remediation-inputs path outside docs/features/active' {
            $output = @"
policy-audit-path: $script:PolicyDir/policy-audit.$script:Timestamp.md
code-review-path: $script:PolicyDir/code-review.$script:Timestamp.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
remediation-inputs-path: artifacts/remediation-inputs.$script:Timestamp.md
"@
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'remediation-inputs-path .* is outside the required docs/features/active'
        }

        It 'reports file-not-found when an advertised artifact has a canonical path but no file exists' {
            # Use a clearly nonexistent feature folder to exercise the
            # "no file exists at that location" branch deterministically.
            $ghostFolder = 'docs/features/active/2099-01-01-nonexistent-fixture-issue1'
            $ghostTs = '2099-01-01T00-00'
            $output = @"
policy-audit-path: $ghostFolder/policy-audit.$ghostTs.md
code-review-path: $ghostFolder/code-review.$ghostTs.md
feature-audit-path: $ghostFolder/feature-audit.$ghostTs.md
"@
            $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
            $r.Ok | Should -BeFalse
            $r.Message | Should -Match 'no file exists at that location'
        }

        Context 'with on-disk fixture artifacts under TestDrive-mirroring layout' {
            BeforeAll {
                # Build a self-contained fixture tree under TestDrive that mirrors
                # docs/features/active/<folder>/ so that Get-ArtifactFileContent
                # resolves real files. The entrypoint resolves paths relative to the
                # current working directory; Push-Location to TestDrive for the
                # duration of these tests.
                $script:FixRoot = Join-Path $TestDrive 'repo'
                $script:FixFolder = Join-Path $script:FixRoot 'docs/features/active/fixture-feature-issue1'
                New-Item -ItemType Directory -Path $script:FixFolder -Force | Out-Null
                $script:FixTs = '2026-05-09T18-00'
                $script:PolicyAuditFix = "$script:FixFolder/policy-audit.$script:FixTs.md"
                $script:CodeReviewFix  = "$script:FixFolder/code-review.$script:FixTs.md"
                $script:FeatureAuditFix = "$script:FixFolder/feature-audit.$script:FixTs.md"

                $policyText = @"
# Policy Audit
PowerShell coverage row PASS - line 90%, branch 80%
"@
                Set-Content -Path $script:PolicyAuditFix -Value $policyText
                Set-Content -Path $script:CodeReviewFix  -Value '# Code Review'
                Set-Content -Path $script:FeatureAuditFix -Value '# Feature Audit'
            }

            BeforeEach {
                Push-Location -LiteralPath $script:FixRoot
            }

            AfterEach {
                Pop-Location
            }

            It 'returns Ok=true when no PR summary file exists (no changed languages)' {
                $rel = 'docs/features/active/fixture-feature-issue1'
                $output = @"
policy-audit-path: $rel/policy-audit.$script:FixTs.md
code-review-path: $rel/code-review.$script:FixTs.md
feature-audit-path: $rel/feature-audit.$script:FixTs.md
"@
                $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
                $r.Ok | Should -BeTrue
                $r.Message | Should -BeNullOrEmpty
            }

            It 'reports mismatched timestamp between policy-audit and code-review' {
                # Create a code-review file with a different timestamp.
                $altTs = '2026-05-09T19-00'
                $altCr = "$script:FixFolder/code-review.$altTs.md"
                Set-Content -Path $altCr -Value '# Code Review (alt)'
                $rel = 'docs/features/active/fixture-feature-issue1'
                $output = @"
policy-audit-path: $rel/policy-audit.$script:FixTs.md
code-review-path: $rel/code-review.$altTs.md
feature-audit-path: $rel/feature-audit.$script:FixTs.md
"@
                $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
                $r.Ok | Should -BeFalse
                $r.Message | Should -Match 'must share the same feature folder and timestamp'
            }

            It 'enumerates changed languages from artifacts/pr_context.summary.txt and validates coverage rows' {
                # Create a pr_context.summary.txt under the fixture working dir that
                # advertises a single PowerShell change. Provide a JaCoCo coverage
                # XML at the path the language dispatcher expects so the row passes.
                $prCtxDir = Join-Path $script:FixRoot 'artifacts'
                New-Item -ItemType Directory -Path $prCtxDir -Force | Out-Null
                Set-Content -Path (Join-Path $prCtxDir 'pr_context.summary.txt') -Value '  - .githooks/example.ps1 (+10/-2)'

                $pesterDir = Join-Path $script:FixRoot 'artifacts/pester'
                New-Item -ItemType Directory -Path $pesterDir -Force | Out-Null
                $jacoco = @'
<?xml version="1.0"?>
<report>
  <package>
    <counter type="LINE" missed="10" covered="90"/>
    <counter type="BRANCH" missed="20" covered="80"/>
  </package>
</report>
'@
                Set-Content -Path (Join-Path $pesterDir 'powershell-coverage.xml') -Value $jacoco

                $rel = 'docs/features/active/fixture-feature-issue1'
                $output = @"
policy-audit-path: $rel/policy-audit.$script:FixTs.md
code-review-path: $rel/code-review.$script:FixTs.md
feature-audit-path: $rel/feature-audit.$script:FixTs.md
"@
                $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
                $r.Ok | Should -BeTrue
            }

            It 'returns Ok=false when policy-audit lacks a PowerShell coverage row but PR summary lists a .ps1 change' {
                # Replace policy-audit content with text that does NOT mention PowerShell.
                Set-Content -Path $script:PolicyAuditFix -Value '# Policy Audit (no language rows)'

                $prCtxDir = Join-Path $script:FixRoot 'artifacts'
                New-Item -ItemType Directory -Path $prCtxDir -Force | Out-Null
                Set-Content -Path (Join-Path $prCtxDir 'pr_context.summary.txt') -Value '  - .githooks/example.ps1 (+10/-2)'

                $rel = 'docs/features/active/fixture-feature-issue1'
                $output = @"
policy-audit-path: $rel/policy-audit.$script:FixTs.md
code-review-path: $rel/code-review.$script:FixTs.md
feature-audit-path: $rel/feature-audit.$script:FixTs.md
"@
                $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
                $r.Ok | Should -BeFalse
                $r.Message | Should -Match 'coverage validation failed against branch diff'
                $r.Message | Should -Match 'does not mention PowerShell'
            }
        }
    }
}
