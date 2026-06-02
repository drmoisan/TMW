#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'validate-orchestrator-output.ps1' {
    BeforeAll {
        # Dot-source the script in dot-import mode so its functions are available
        # without executing the bottom-of-file invocation block.
        $scriptPath = (Resolve-Path "$PSScriptRoot/../../.claude/hooks/validate-orchestrator-output.ps1").Path
        . $scriptPath
    }

    Context 'Test-HumanInteractionShape' {
        It 'returns Ok = $true when human_interaction is $null (absent)' {
            # AC-5: a checkpoint with no human_interaction key passes the gate.
            $result = Test-HumanInteractionShape -HumanInteraction $null
            $result.Ok | Should -BeTrue
            $result.Message | Should -BeNullOrEmpty
        }

        It 'blocks when requirements array is missing' {
            $hi = [pscustomobject]@{ note = 'no requirements key' }
            $result = Test-HumanInteractionShape -HumanInteraction $hi
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match "requirements' array is missing"
        }

        It 'blocks when a requirement has no resolved response' {
            # AC-6: unresolved response blocks DONE.
            $req = [pscustomobject]@{
                id                  = 'hi-1'
                description         = 'needs a response'
                discovered_at_stage = 'research'
                response            = ''
            }
            $hi = [pscustomobject]@{ requirements = @($req) }
            $result = Test-HumanInteractionShape -HumanInteraction $hi
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match 'no resolved'
        }

        It 'blocks when a requirement response is outside the enum' {
            # AC-6: out-of-enum response blocks DONE.
            $req = [pscustomobject]@{
                id                  = 'hi-1'
                description         = 'bad response'
                discovered_at_stage = 'research'
                response            = 'maybe'
            }
            $hi = [pscustomobject]@{ requirements = @($req) }
            $result = Test-HumanInteractionShape -HumanInteraction $hi
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match 'outside the allowed set'
        }

        It 'blocks when any requirement response is halt' {
            # AC-7: a halt response blocks DONE.
            $req = [pscustomobject]@{
                id                  = 'hi-1'
                description         = 'halted'
                discovered_at_stage = 'research'
                response            = 'halt'
            }
            $hi = [pscustomobject]@{ requirements = @($req) }
            $result = Test-HumanInteractionShape -HumanInteraction $hi
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match "'halt'"
        }

        It 'blocks when an exception has a missing/empty runbook_path' {
            # AC-8: exception with no runbook_path blocks DONE.
            $req = [pscustomobject]@{
                id                  = 'hi-1'
                description         = 'exception without runbook'
                discovered_at_stage = 'research'
                response            = 'exception'
                runbook_path        = ''
            }
            $hi = [pscustomobject]@{ requirements = @($req) }
            $result = Test-HumanInteractionShape -HumanInteraction $hi
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match 'no non-empty'
        }

        It 'blocks when an exception runbook_path file does not exist (via FileExistsCheck seam)' {
            # AC-8: exception referencing a non-existent runbook file blocks DONE.
            $req = [pscustomobject]@{
                id                  = 'hi-1'
                description         = 'exception with missing file'
                discovered_at_stage = 'research'
                response            = 'exception'
                runbook_path        = 'docs/features/x/runbooks/missing.runbook.md'
            }
            $hi = [pscustomobject]@{ requirements = @($req) }
            $seam = { param($Path) $null = $Path; $false }
            $result = Test-HumanInteractionShape -HumanInteraction $hi -FileExistsCheck $seam
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match 'no file exists'
        }

        It 'passes when an exception runbook_path file exists (via FileExistsCheck seam)' {
            # AC-8: exception backed by an existing runbook file passes the gate.
            $req = [pscustomobject]@{
                id                  = 'hi-1'
                description         = 'exception with present file'
                discovered_at_stage = 'research'
                response            = 'exception'
                runbook_path        = 'docs/features/x/runbooks/present.runbook.md'
            }
            $hi = [pscustomobject]@{ requirements = @($req) }
            $seam = { param($Path) $null = $Path; $true }
            $result = Test-HumanInteractionShape -HumanInteraction $hi -FileExistsCheck $seam
            $result.Ok | Should -BeTrue
            $result.Message | Should -BeNullOrEmpty
        }

        It 'passes when a scope_change requirement is resolved' {
            # A resolved scope_change requirement does not block.
            $req = [pscustomobject]@{
                id                  = 'hi-1'
                description         = 'rescoped to az cli'
                discovered_at_stage = 'pre-kickoff'
                response            = 'scope_change'
            }
            $hi = [pscustomobject]@{ requirements = @($req) }
            $result = Test-HumanInteractionShape -HumanInteraction $hi
            $result.Ok | Should -BeTrue
            $result.Message | Should -BeNullOrEmpty
        }

        It 'passes when the requirements array is empty' {
            $hi = [pscustomobject]@{ requirements = @() }
            $result = Test-HumanInteractionShape -HumanInteraction $hi
            $result.Ok | Should -BeTrue
            $result.Message | Should -BeNullOrEmpty
        }
    }

    Context 'Invoke-OrchestratorOutputValidation human_interaction wiring' {
        BeforeEach {
            # Mock the filesystem-read boundary so the checkpoint content is
            # injected without temp files. Registered before code under test runs.
            Mock Get-CheckpointFileContent {
                param([string] $Path)
                $null = $Path
                return @{ Exists = $true; Content = $script:checkpointJson }
            }
        }

        It 'blocks DONE when a checkpoint human_interaction requirement is a halt' {
            # AC-7 wiring path: completion gate returns the halt block message.
            $script:checkpointJson = @'
{
  "objective": "do the thing",
  "completed_steps": ["S0"],
  "next_step": "S1",
  "last_updated": "2026-06-01T14-22",
  "human_interaction": {
    "requirements": [
      { "id": "hi-1", "description": "halted", "discovered_at_stage": "research", "response": "halt" }
    ]
  }
}
'@
            $payload = '{"output":"final summary"}'
            $result = Invoke-OrchestratorOutputValidation -RawPayload $payload
            $result.Ok | Should -BeFalse
            $result.Message | Should -Match "'halt'"
        }

        It 'allows DONE when the checkpoint has no human_interaction key (backward compatibility)' {
            # AC-5 wiring path: absent human_interaction passes the gate.
            $script:checkpointJson = @'
{
  "objective": "do the thing",
  "completed_steps": ["S0"],
  "next_step": "S1",
  "last_updated": "2026-06-01T14-22"
}
'@
            $payload = '{"output":"final summary"}'
            $result = Invoke-OrchestratorOutputValidation -RawPayload $payload
            $result.Ok | Should -BeTrue
            $result.Message | Should -BeNullOrEmpty
        }
    }
}
