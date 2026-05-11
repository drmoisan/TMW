#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'enforce-feature-folder-order.ps1' {
    BeforeAll {
        $script:UnderTest = (Resolve-Path "$PSScriptRoot/../../../.claude/hooks/enforce-feature-folder-order.ps1").Path
        . $script:UnderTest
    }

    Context 'tool input parsing' {
        It 'allows when CLAUDE_TOOL_INPUT is empty' {
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw ''
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows when file_path is missing' {
            $json = '{"other":"value"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows when file_path is not a plan.md path' {
            $json = '{"file_path":"docs/features/active/foo/issue.md"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'allows for plan.md outside docs/features' {
            $json = '{"file_path":"some/other/dir/plan.md"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'throws on malformed JSON so the hook exits 1' {
            { Invoke-FeatureFolderOrderDecision -ToolInputRaw '{not-json' } | Should -Throw
        }
    }

    Context 'plan.md in a feature folder' {
        It 'allows when all three sibling files exist' {
            Mock -CommandName Get-FeatureFolderFileExistence -MockWith { $true }
            $json = '{"file_path":"docs/features/active/2026-01-01-foo-1/plan.md"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'allow'
        }

        It 'blocks when issue.md is missing' {
            Mock -CommandName Get-FeatureFolderFileExistence -MockWith {
                param([string]$Path)
                return -not ($Path -match '/issue\.md$')
            }
            $json = '{"file_path":"docs/features/active/2026-01-01-foo-1/plan.md"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'issue\.md'
        }

        It 'blocks when spec.md is missing' {
            Mock -CommandName Get-FeatureFolderFileExistence -MockWith {
                param([string]$Path)
                return -not ($Path -match '/spec\.md$')
            }
            $json = '{"file_path":"docs/features/active/2026-01-01-foo-1/plan.md"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'spec\.md'
        }

        It 'blocks when user-story.md is missing' {
            Mock -CommandName Get-FeatureFolderFileExistence -MockWith {
                param([string]$Path)
                return -not ($Path -match '/user-story\.md$')
            }
            $json = '{"file_path":"docs/features/active/2026-01-01-foo-1/plan.md"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'user-story\.md'
        }

        It 'block reason names all missing files when multiple are absent' {
            Mock -CommandName Get-FeatureFolderFileExistence -MockWith { $false }
            $json = '{"file_path":"docs/features/active/2026-01-01-foo-1/plan.md"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
            $decision['reason'] | Should -Match 'issue\.md'
            $decision['reason'] | Should -Match 'spec\.md'
            $decision['reason'] | Should -Match 'user-story\.md'
            $decision['reason'] | Should -Match 'prd-feature'
        }

        It 'normalizes backslashes in the file_path' {
            Mock -CommandName Get-FeatureFolderFileExistence -MockWith { $false }
            $json = '{"file_path":"docs\\features\\active\\2026-01-01-foo-1\\plan.md"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
        }

        It 'handles archive feature folders too' {
            Mock -CommandName Get-FeatureFolderFileExistence -MockWith { $false }
            $json = '{"file_path":"docs/features/archive/2025-12-01-old-1/plan.md"}'
            $decision = Invoke-FeatureFolderOrderDecision -ToolInputRaw $json
            $decision['decision'] | Should -Be 'block'
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

        It 'emits a block decision JSON when prerequisites are missing' {
            $prev = $env:CLAUDE_TOOL_INPUT
            try {
                # Point at a non-existent feature folder so Test-Path returns false
                $env:CLAUDE_TOOL_INPUT = '{"file_path":"docs/features/active/__nonexistent_feature_for_test__/plan.md"}'
                $output = & $script:UnderTest
                $output | Should -Match '"decision"\s*:\s*"block"'
                $output | Should -Match 'FEATURE_FOLDER_ORDER_BLOCKED'
            }
            finally {
                $env:CLAUDE_TOOL_INPUT = $prev
            }
        }

        It 'real Test-Path wrapper returns $false for a nonexistent path' {
            (Get-FeatureFolderFileExistence -Path 'C:/__nonexistent_path_for_test__.md') | Should -BeFalse
        }
    }

    Context 'Test-IsFeaturePlanPath' {
        It 'recognizes a canonical active plan.md path' {
            (Test-IsFeaturePlanPath -NormalizedPath 'docs/features/active/foo/plan.md') | Should -BeTrue
        }
        It 'recognizes a canonical archive plan.md path' {
            (Test-IsFeaturePlanPath -NormalizedPath 'docs/features/archive/foo/plan.md') | Should -BeTrue
        }
        It 'rejects non-plan files' {
            (Test-IsFeaturePlanPath -NormalizedPath 'docs/features/active/foo/issue.md') | Should -BeFalse
        }
        It 'rejects paths outside docs/features' {
            (Test-IsFeaturePlanPath -NormalizedPath 'other/plan.md') | Should -BeFalse
        }
    }
}
