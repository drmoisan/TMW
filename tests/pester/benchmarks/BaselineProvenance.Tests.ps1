#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

# Regression tests for the baseline-provenance validator (issue #26, spec.md
# AC11/AC12). The validator enforces .claude/rules/benchmark-baselines.md:
# reject HostEnvironmentInfo.ProcessorName == "Unknown processor", reject a
# baseline missing a sibling baseline.provenance.json, accept a runner-captured
# baseline with valid provenance. Authored before implementation (Phase 1,
# [expect-fail]); expected to pass after Phase 5 delivers
# scripts/benchmarks/Test-BaselineProvenance.ps1.
#
# Per .claude/rules/general-unit-test.md, tests must not create temp files. The
# validator exposes a pure-logic seam (-BaselineContent / -ProvenanceContent /
# -ProvenancePresent) so the rule logic is exercised without filesystem I/O.

Describe 'Test-BaselineProvenance.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '../../../scripts/benchmarks/Test-BaselineProvenance.ps1'

        function script:Get-UnknownProcessorBaseline {
            return @'
{ "HostEnvironmentInfo": { "ProcessorName": "Unknown processor" } }
'@
        }
        function script:Get-RunnerBaseline {
            return @'
{ "HostEnvironmentInfo": { "ProcessorName": "Intel Xeon Platinum 8370C" } }
'@
        }
        function script:Get-ValidProvenance {
            return @'
{
  "runner_class": "windows-latest",
  "host_signature": "github-hosted-2-core",
  "workflow_run_url": "https://github.com/drmoisan/TMW/actions/runs/123"
}
'@
        }
    }

    Context 'negative: ProcessorName is "Unknown processor"' {
        It 'returns IsValid false and a processor-name reason' {
            $result = & $script:ScriptPath `
                -BaselineContent (Get-UnknownProcessorBaseline) `
                -ProvenancePresent $true `
                -ProvenanceContent (Get-ValidProvenance)
            $result.IsValid | Should -BeFalse
            ($result.Reasons -join ';') | Should -Match 'Unknown processor'
        }
    }

    Context 'negative: sibling baseline.provenance.json missing' {
        It 'returns IsValid false and a missing-provenance reason' {
            $result = & $script:ScriptPath `
                -BaselineContent (Get-RunnerBaseline) `
                -ProvenancePresent $false
            $result.IsValid | Should -BeFalse
            ($result.Reasons -join ';') | Should -Match 'provenance'
        }
    }

    Context 'positive: runner-captured baseline with valid provenance' {
        It 'returns IsValid true with no reasons' {
            $result = & $script:ScriptPath `
                -BaselineContent (Get-RunnerBaseline) `
                -ProvenancePresent $true `
                -ProvenanceContent (Get-ValidProvenance)
            $result.IsValid | Should -BeTrue
            $result.Reasons.Count | Should -Be 0
        }
    }

    Context 'negative: provenance present but missing a required field' {
        It 'returns IsValid false and names the missing field' {
            $partialProvenance = '{ "runner_class": "windows-latest", "host_signature": "sig" }'
            $result = & $script:ScriptPath `
                -BaselineContent (Get-RunnerBaseline) `
                -ProvenancePresent $true `
                -ProvenanceContent $partialProvenance
            $result.IsValid | Should -BeFalse
            ($result.Reasons -join ';') | Should -Match 'workflow_run_url'
        }
    }

    Context 'negative: provenance present but malformed JSON' {
        It 'returns IsValid false with a malformed-provenance reason' {
            $result = & $script:ScriptPath `
                -BaselineContent (Get-RunnerBaseline) `
                -ProvenancePresent $true `
                -ProvenanceContent '{ not json'
            $result.IsValid | Should -BeFalse
            ($result.Reasons -join ';') | Should -Match 'malformed'
        }
    }

    Context 'error path: malformed baseline JSON' {
        It 'throws on malformed baseline content' {
            { & $script:ScriptPath -BaselineContent '{ broken' -ProvenancePresent $true } |
                Should -Throw
        }
    }

    Context 'Path parameter set (file-reading wrapper)' {
        It 'reads baseline and sibling provenance from disk and validates' {
            # Mock the filesystem adapters so no temp files are created, per
            # .claude/rules/general-unit-test.md.
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Get-Content -ParameterFilter { "$LiteralPath" -like '*baseline.provenance.json' } `
                -MockWith { return (Get-ValidProvenance) }
            Mock -CommandName Get-Content -ParameterFilter { "$LiteralPath" -notlike '*baseline.provenance.json' } `
                -MockWith { return (Get-RunnerBaseline) }

            $result = & $script:ScriptPath -BaselinePath 'C:/fake/baseline.json'
            $result.IsValid | Should -BeTrue
        }

        It 'throws when the baseline path does not exist' {
            Mock -CommandName Test-Path -MockWith { $false }
            { & $script:ScriptPath -BaselinePath 'C:/missing/baseline.json' } | Should -Throw
        }

        It 'flags missing sibling provenance when only the baseline exists' {
            Mock -CommandName Test-Path -ParameterFilter { "$LiteralPath" -like '*baseline.provenance.json' } `
                -MockWith { $false }
            Mock -CommandName Test-Path -ParameterFilter { "$LiteralPath" -notlike '*baseline.provenance.json' } `
                -MockWith { $true }
            Mock -CommandName Get-Content -MockWith { return (Get-RunnerBaseline) }

            $result = & $script:ScriptPath -BaselinePath 'C:/fake/baseline.json'
            $result.IsValid | Should -BeFalse
            ($result.Reasons -join ';') | Should -Match 'provenance'
        }
    }
}
