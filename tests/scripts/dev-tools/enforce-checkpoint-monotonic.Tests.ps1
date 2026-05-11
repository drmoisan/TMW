#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'enforce-checkpoint-monotonic.ps1' {
    BeforeAll {
        $script:UnderTest = (Resolve-Path "$PSScriptRoot/../../../.claude/hooks/enforce-checkpoint-monotonic.ps1").Path
        . $script:UnderTest
    }

    Context 'tool input parsing' {
        It 'allows when CLAUDE_TOOL_INPUT is empty' {
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw '')['decision'] | Should -Be 'allow'
        }

        It 'allows when file_path is missing' {
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw '{"content":"{}"}')['decision'] | Should -Be 'allow'
        }

        It 'allows when path is not the checkpoint' {
            $json = '{"file_path":"some/other.json","content":"{\"completed_steps\":[\"S1\"]}"}'
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw $json)['decision'] | Should -Be 'allow'
        }

        It 'throws on malformed JSON so the hook exits 1' {
            { Invoke-CheckpointMonotonicDecision -ToolInputRaw '{not-json' } | Should -Throw
        }
    }

    Context 'Edit tool calls (no full content)' {
        It 'allows an Edit-style call that only supplies old_string/new_string' {
            $json = '{"file_path":"artifacts/orchestration/orchestrator-state.json","old_string":"a","new_string":"b"}'
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw $json)['decision'] | Should -Be 'allow'
        }
    }

    Context 'Write tool calls' {
        It 'allows when content has no completed_steps field' {
            $content = '{"objective":"x"}'
            $json = (@{ file_path = 'artifacts/orchestration/orchestrator-state.json'; content = $content } | ConvertTo-Json -Compress)
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw $json)['decision'] | Should -Be 'allow'
        }

        It 'allows when steps are in canonical order' {
            $content = '{"completed_steps":["S0_startup_checks","S1_change_budget_estimation","S3_promotion_potential","S4_atomic_planning","S5_atomic_execution","S12_complete"]}'
            $json = (@{ file_path = 'artifacts/orchestration/orchestrator-state.json'; content = $content } | ConvertTo-Json -Compress)
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw $json)['decision'] | Should -Be 'allow'
        }

        It 'allows when a single canonical step is present' {
            $content = '{"completed_steps":["S0_startup_checks"]}'
            $json = (@{ file_path = 'artifacts/orchestration/orchestrator-state.json'; content = $content } | ConvertTo-Json -Compress)
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw $json)['decision'] | Should -Be 'allow'
        }

        It 'allows non-canonical informational entries' {
            $content = '{"completed_steps":["S0_startup_checks","informational_note","S4_atomic_planning"]}'
            $json = (@{ file_path = 'artifacts/orchestration/orchestrator-state.json'; content = $content } | ConvertTo-Json -Compress)
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw $json)['decision'] | Should -Be 'allow'
        }

        It 'blocks when later step appears before earlier step' {
            $content = '{"completed_steps":["S5_atomic_execution","S4_atomic_planning"]}'
            $json = (@{ file_path = 'artifacts/orchestration/orchestrator-state.json'; content = $content } | ConvertTo-Json -Compress)
            $decision = Invoke-CheckpointMonotonicDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'S5_atomic_execution'
            $decision['reason'] | Should -Match 'S4_atomic_planning'
        }

        It 'allows out-of-order when rollback_history is non-empty' {
            $content = '{"completed_steps":["S5_atomic_execution","S4_atomic_planning"],"rollback_history":[{"step":"S5_atomic_execution","reason":"reset"}]}'
            $json = (@{ file_path = 'artifacts/orchestration/orchestrator-state.json'; content = $content } | ConvertTo-Json -Compress)
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw $json)['decision'] | Should -Be 'allow'
        }

        It 'allows when content itself is not valid JSON (defers to downstream tools)' {
            $json = (@{ file_path = 'artifacts/orchestration/orchestrator-state.json'; content = '{broken' } | ConvertTo-Json -Compress)
            (Invoke-CheckpointMonotonicDecision -ToolInputRaw $json)['decision'] | Should -Be 'allow'
        }
    }

    Context 'Entrypoint (script body)' {
        It 'emits an allow decision JSON when CLAUDE_TOOL_INPUT is empty' {
            $prev = $env:CLAUDE_TOOL_INPUT
            try {
                $env:CLAUDE_TOOL_INPUT = ''
                $output = & $script:UnderTest
                $output | Should -Match '"decision"\s*:\s*"allow"'
            }
            finally {
                $env:CLAUDE_TOOL_INPUT = $prev
            }
        }

        It 'emits a block decision JSON when steps are out of order' {
            $prev = $env:CLAUDE_TOOL_INPUT
            try {
                $content = '{"completed_steps":["S5_atomic_execution","S4_atomic_planning"]}'
                $payload = (@{ file_path = 'artifacts/orchestration/orchestrator-state.json'; content = $content } | ConvertTo-Json -Compress)
                $env:CLAUDE_TOOL_INPUT = $payload
                $output = & $script:UnderTest
                $output | Should -Match '"decision"\s*:\s*"block"'
                $output | Should -Match 'CHECKPOINT_ORDER_BLOCKED'
            }
            finally {
                $env:CLAUDE_TOOL_INPUT = $prev
            }
        }
    }

    Context 'Get-CanonicalStepIndex' {
        It 'returns -1 for non-canonical entries' {
            Get-CanonicalStepIndex -StepEntry 'noise' | Should -Be -1
        }
        It 'matches exact prefix' {
            Get-CanonicalStepIndex -StepEntry 'S0_startup_checks' | Should -Be 0
        }
        It 'matches S3_promotion variant via underscore suffix' {
            Get-CanonicalStepIndex -StepEntry 'S3_promotion_issue' | Should -BeGreaterThan 0
        }
        It 'returns ascending indices for S4 vs S5' {
            $a = Get-CanonicalStepIndex -StepEntry 'S4_atomic_planning'
            $b = Get-CanonicalStepIndex -StepEntry 'S5_atomic_execution'
            $b | Should -BeGreaterThan $a
        }
    }

    Context 'Get-OutOfOrderPair' {
        It 'returns $null when order is canonical' {
            Get-OutOfOrderPair -CompletedSteps @('S0_startup_checks', 'S1_change_budget_estimation') | Should -BeNullOrEmpty
        }
        It 'returns a pair when order is violated' {
            $pair = Get-OutOfOrderPair -CompletedSteps @('S5_atomic_execution', 'S4_atomic_planning')
            $pair.EarlierEntry | Should -Be 'S5_atomic_execution'
            $pair.LaterEntry  | Should -Be 'S4_atomic_planning'
        }
    }
}
