#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

# Regression tests for the feature-review policy rule
# "modified-workflow-needs-green-run" (issue #26, spec.md AC6). The rule emits a
# Blocking finding when the branch diff modifies any path matching
# .github/workflows/**, scripts/benchmarks/**, or .github/actions/** unless green
# workflow-run evidence against the branch head is present. Authored before
# implementation (Phase 1, [expect-fail]); expected to pass after Phase 5
# delivers scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1.

Describe 'Test-ModifiedWorkflowNeedsGreenRun.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '../../../scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1'
    }

    Context 'trigger path modified without green-run evidence' {
        It 'emits a Blocking finding for a .github/workflows change with no evidence' {
            $result = & $script:ScriptPath `
                -ChangedFiles @('.github/workflows/pr-pipeline.yml', 'README.md') `
                -GreenRunEvidencePresent $false
            $result.IsBlocking | Should -BeTrue
        }

        It 'emits a Blocking finding for a scripts/benchmarks change with no evidence' {
            $result = & $script:ScriptPath `
                -ChangedFiles @('scripts/benchmarks/parse-cobertura.ps1') `
                -GreenRunEvidencePresent $false
            $result.IsBlocking | Should -BeTrue
        }

        It 'emits a Blocking finding for a .github/actions change with no evidence' {
            $result = & $script:ScriptPath `
                -ChangedFiles @('.github/actions/setup/action.yml') `
                -GreenRunEvidencePresent $false
            $result.IsBlocking | Should -BeTrue
        }
    }

    Context 'trigger path modified with green-run evidence' {
        It 'does not emit a Blocking finding when evidence is present' {
            $result = & $script:ScriptPath `
                -ChangedFiles @('.github/workflows/pr-pipeline.yml') `
                -GreenRunEvidencePresent $true
            $result.IsBlocking | Should -BeFalse
        }
    }

    Context 'no trigger path modified' {
        It 'does not emit a Blocking finding when no trigger path changed' {
            $result = & $script:ScriptPath `
                -ChangedFiles @('docs/readme.md', 'src/app.ts') `
                -GreenRunEvidencePresent $false
            $result.IsBlocking | Should -BeFalse
        }
    }
}
