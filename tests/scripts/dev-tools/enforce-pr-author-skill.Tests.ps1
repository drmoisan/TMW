#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'enforce-pr-author-skill.ps1' {
    BeforeAll {
        $script:UnderTest = (Resolve-Path "$PSScriptRoot/../../../.claude/hooks/enforce-pr-author-skill.ps1").Path
        . $script:UnderTest
    }

    Context 'tool input parsing' {
        It 'allows when CLAUDE_TOOL_INPUT is empty' {
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw ''
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows when JSON has no command field' {
            $json = '{"other":"value"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'throws on malformed JSON so the hook exits 1' {
            { Invoke-PrAuthorSkillDecision -ToolInputRaw '{not-json' } | Should -Throw
        }
    }

    Context 'gh pr create - inline body (Case A)' {
        BeforeEach {
            Mock -CommandName Get-PrContextArtifactExistence -MockWith { $true }
        }

        It 'blocks gh pr create --body "inline string"' {
            $json = '{"command":"gh pr create --title \"foo\" --body \"inline string\""}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'PR_AUTHOR_SKILL_BLOCKED'
        }

        It "blocks gh pr create --body='inline' (equals-sign form)" {
            $json = '{"command":"gh pr create --title \"foo\" --body=''inline text''"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'PR_AUTHOR_SKILL_BLOCKED'
        }
    }

    Context 'gh pr create - missing body (Case B)' {
        BeforeEach {
            Mock -CommandName Get-PrContextArtifactExistence -MockWith { $true }
        }

        It 'blocks gh pr create with no body flags' {
            $json = '{"command":"gh pr create"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'PR_AUTHOR_SKILL_BLOCKED'
            $decision['reason'] | Should -Match '--body-file'
        }

        It 'blocks gh pr create --title foo with no body flags' {
            $json = '{"command":"gh pr create --title \"my feature\""}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'PR_AUTHOR_SKILL_BLOCKED'
            $decision['reason'] | Should -Match '--body-file'
        }
    }

    Context 'gh pr create/edit - missing context artifact (Case C)' {
        BeforeEach {
            Mock -CommandName Get-PrContextArtifactExistence -MockWith { $false }
        }

        It 'blocks gh pr create --body-file artifacts/pr_body_12.md when context is absent' {
            $json = '{"command":"gh pr create --title \"foo\" --body-file artifacts/pr_body_12.md"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'PR_CONTEXT_MISSING'
            $decision['reason'] | Should -Match 'collect_pr_context'
        }

        It 'blocks gh pr edit --body-file artifacts/pr_body_12.md when context is absent' {
            $json = '{"command":"gh pr edit 42 --body-file artifacts/pr_body_12.md"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'PR_CONTEXT_MISSING'
            $decision['reason'] | Should -Match 'collect_pr_context'
        }
    }

    Context 'allowed commands' {
        BeforeEach {
            Mock -CommandName Get-PrContextArtifactExistence -MockWith { $true }
        }

        It 'allows gh pr create --body-file artifacts/pr_body_12.md when context exists' {
            $json = '{"command":"gh pr create --title \"foo\" --body-file artifacts/pr_body_12.md"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows gh pr edit --body-file artifacts/pr_body_12.md when context exists' {
            $json = '{"command":"gh pr edit 42 --body-file artifacts/pr_body_12.md"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows gh pr edit --title "new title" (no body flag)' {
            $json = '{"command":"gh pr edit 42 --title \"new title\""}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows gh pr edit --add-label bug (no body flag)' {
            $json = '{"command":"gh pr edit 42 --add-label bug"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows gh pr view 13' {
            $json = '{"command":"gh pr view 13"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows gh pr list' {
            $json = '{"command":"gh pr list"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows gh pr merge' {
            $json = '{"command":"gh pr merge 42 --squash"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows gh pr checkout 13' {
            $json = '{"command":"gh pr checkout 13"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows gh issue create (not guarded by this hook)' {
            $json = '{"command":"gh issue create --title foo"}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }
    }

    Context 'Get-PrAuthorBypassReason helper' {
        It 'returns null for allowed command' {
            $result = Get-PrAuthorBypassReason -CommandText 'gh pr create --body-file artifacts/pr_body_1.md' -ContextExists $true
            $result | Should -BeNullOrEmpty
        }

        It 'returns PR_AUTHOR_SKILL_BLOCKED for inline --body' {
            $result = Get-PrAuthorBypassReason -CommandText 'gh pr create --body "some text"' -ContextExists $true
            $result | Should -Match 'PR_AUTHOR_SKILL_BLOCKED'
        }

        It 'returns PR_CONTEXT_MISSING when --body-file present but context absent' {
            $result = Get-PrAuthorBypassReason -CommandText 'gh pr create --body-file artifacts/pr_body_1.md' -ContextExists $false
            $result | Should -Match 'PR_CONTEXT_MISSING'
        }
    }

    Context 'Test-PrAuthorBypassRequired helper' {
        It 'returns false for an allowed command' {
            Test-PrAuthorBypassRequired -CommandText 'gh pr create --body-file artifacts/pr_body_1.md' -ContextExists $true |
                Should -BeFalse
        }

        It 'returns true for a blocked command (inline --body)' {
            Test-PrAuthorBypassRequired -CommandText 'gh pr create --body "text"' -ContextExists $true |
                Should -BeTrue
        }

        It 'returns true when context is missing for --body-file command' {
            Test-PrAuthorBypassRequired -CommandText 'gh pr edit 5 --body-file artifacts/pr_body_1.md' -ContextExists $false |
                Should -BeTrue
        }
    }

    Context 'Get-PrContextArtifactExistence real Test-Path wrapper' {
        It 'returns a boolean result without throwing' {
            $result = Get-PrContextArtifactExistence
            $result | Should -BeOfType [bool]
        }
    }

    Context 'Invoke-PrAuthorSkillDecision without mock (real context lookup)' {
        It 'blocks gh pr create with no body flags regardless of context artifact' {
            $json = '{"command":"gh pr create --title \"foo\""}'
            $decision = Invoke-PrAuthorSkillDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'PR_AUTHOR_SKILL_BLOCKED'
        }
    }

    Context 'script entrypoint (end-to-end)' {
        BeforeAll {
            $script:HookPath = (Resolve-Path "$PSScriptRoot/../../../.claude/hooks/enforce-pr-author-skill.ps1").Path
        }

        It 'allows when CLAUDE_TOOL_INPUT is empty (exit 0, allow)' {
            $prev = $env:CLAUDE_TOOL_INPUT
            try {
                $env:CLAUDE_TOOL_INPUT = ''
                $out = & pwsh -NoProfile -File $script:HookPath
                $LASTEXITCODE | Should -Be 0
                ($out | ConvertFrom-Json).decision | Should -Be 'allow'
            } finally {
                $env:CLAUDE_TOOL_INPUT = $prev
            }
        }

        It 'blocks gh pr create inline --body end-to-end (exit 0, block, PR_AUTHOR_SKILL_BLOCKED)' {
            $prev = $env:CLAUDE_TOOL_INPUT
            try {
                $env:CLAUDE_TOOL_INPUT = '{"command":"gh pr create --title \"foo\" --body \"inline\""}'
                $out = & pwsh -NoProfile -File $script:HookPath
                $LASTEXITCODE | Should -Be 0
                $parsed = $out | ConvertFrom-Json
                $parsed.decision | Should -Be 'block'
                $parsed.reason | Should -Match 'PR_AUTHOR_SKILL_BLOCKED'
            } finally {
                $env:CLAUDE_TOOL_INPUT = $prev
            }
        }

        It 'exits 1 on malformed JSON' {
            $prev = $env:CLAUDE_TOOL_INPUT
            try {
                $env:CLAUDE_TOOL_INPUT = '{not-json'
                $null = & pwsh -NoProfile -File $script:HookPath 2>&1
                $LASTEXITCODE | Should -Be 1
            } finally {
                $env:CLAUDE_TOOL_INPUT = $prev
            }
        }
    }
}
