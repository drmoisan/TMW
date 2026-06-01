#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'validate-task-researcher-output.ps1' {
    BeforeAll {
        # Dot-source the script in dot-import mode so its functions are available
        # without executing the bottom-of-file invocation block.
        $scriptPath = (Resolve-Path "$PSScriptRoot/../../.claude/hooks/validate-task-researcher-output.ps1").Path
        . $scriptPath
    }

    Context 'Test-AutomationFeasibilitySection' {
        It 'blocks an applicable research artifact that is missing the section' {
            # AC-9: applicable (filename token) but no ## Automation Feasibility section.
            $path = 'artifacts/research/2026-06-01T13-50-autonomous-execution-human-runbooks-research.md'
            $body = "# Research`n`n## Findings`n`nSome content without the required section."
            $seam = { param($Path) $null = $Path; $body }
            $result = Test-AutomationFeasibilitySection -ResearchFilePath $path -AgentOutput 'output' -ReadFileContent $seam
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match 'Automation Feasibility'
        }

        It 'passes an applicable research artifact that contains the section' {
            # AC-9: applicable and the ## Automation Feasibility section is present.
            $path = 'artifacts/research/2026-06-01T13-50-autonomous-execution-human-runbooks-research.md'
            $body = "# Research`n`n## Automation Feasibility`n`nAll steps are automatable via az CLI."
            $seam = { param($Path) $null = $Path; $body }
            $result = Test-AutomationFeasibilitySection -ResearchFilePath $path -AgentOutput 'output' -ReadFileContent $seam
            $result.Ok | Should -BeTrue
            $result.Message | Should -BeNullOrEmpty
        }

        It 'passes a non-applicable research artifact (no autonomous-execution token)' {
            # AC-9: non-applicable artifacts are unaffected; the read seam is not consulted.
            $path = 'artifacts/research/2026-06-01T10-00-some-other-topic-research.md'
            $seam = { param($Path) $null = $Path; throw 'read seam should not be called for non-applicable artifacts' }
            $result = Test-AutomationFeasibilitySection -ResearchFilePath $path -AgentOutput 'unrelated research output' -ReadFileContent $seam
            $result.Ok | Should -BeTrue
            $result.Message | Should -BeNullOrEmpty
        }

        It 'detects applicability from the agent output token when the filename does not match' {
            $path = 'artifacts/research/2026-06-01T10-00-some-other-topic-research.md'
            $body = "# Research`n`nNo feasibility section here."
            $seam = { param($Path) $null = $Path; $body }
            $result = Test-AutomationFeasibilitySection -ResearchFilePath $path -AgentOutput 'this covers human-interaction dependencies' -ReadFileContent $seam
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match 'Automation Feasibility'
        }

        It 'blocks an applicable artifact whose body is empty' {
            $path = 'artifacts/research/2026-06-01T13-50-autonomous-execution-human-runbooks-research.md'
            $seam = { param($Path) $null = $Path; '' }
            $result = Test-AutomationFeasibilitySection -ResearchFilePath $path -AgentOutput 'output' -ReadFileContent $seam
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match 'empty'
        }
    }

    Context 'Invoke-TaskResearcherOutputValidation automation-feasibility wiring' {
        BeforeEach {
            # Mock the filesystem-existence boundary so the path resolves without
            # touching disk. Registered before the code under test runs.
            Mock Test-ResearchFile {
                param([string] $Path)
                $null = $Path
                return $true
            }
        }

        It 'blocks when an applicable research artifact lacks the feasibility section' {
            # AC-9 wiring path: the hook surfaces the feasibility block message.
            $path = 'artifacts/research/2026-06-01T13-50-autonomous-execution-human-runbooks-research.md'
            Mock Get-Content {
                param($LiteralPath, [switch] $Raw, $ErrorAction)
                $null = $LiteralPath; $null = $Raw; $null = $ErrorAction
                return "# Research`n`nNo feasibility section."
            }
            $payload = (@{ output = "research-path: $path" } | ConvertTo-Json -Compress)
            $result = Invoke-TaskResearcherOutputValidation -RawPayload $payload
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match 'Automation Feasibility'
        }

        It 'passes when an applicable research artifact contains the feasibility section' {
            $path = 'artifacts/research/2026-06-01T13-50-autonomous-execution-human-runbooks-research.md'
            Mock Get-Content {
                param($LiteralPath, [switch] $Raw, $ErrorAction)
                $null = $LiteralPath; $null = $Raw; $null = $ErrorAction
                return "# Research`n`n## Automation Feasibility`n`nAutomatable."
            }
            $payload = (@{ output = "research-path: $path" } | ConvertTo-Json -Compress)
            $result = Invoke-TaskResearcherOutputValidation -RawPayload $payload
            $result.Ok | Should -BeTrue
            $result.Message | Should -BeNullOrEmpty
        }
    }
}
