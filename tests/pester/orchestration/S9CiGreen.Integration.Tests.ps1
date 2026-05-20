#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

# Integration test for the orchestrate skill S9 CI green gate path (issue #26).
# Exercises the documented S9 mechanics end-to-end against fixture `gh pr checks`
# output: a fixture gh-JSON payload is passed through
# scripts/orchestration/Invoke-CiGateParser.ps1 to produce the ci_gate object,
# then the fifth PR Creation Gate condition is evaluated. Per
# .claude/rules/powershell.md the gh executable is invoked through a wrapper
# function seam (Invoke-GhExe) which is mocked here; gh itself is never called.

Describe 'S9 CI green gate (integration against fixture gh output)' {
    BeforeAll {
        $script:ParserPath = Join-Path $PSScriptRoot '../../../scripts/orchestration/Invoke-CiGateParser.ps1'

        # Wrapper seam over the gh executable. Production code would call
        # `gh @GhArgs`; tests mock this wrapper so no live gh call occurs.
        function script:Invoke-GhExe {
            param([string[]]$GhArgs)
            throw "Invoke-GhExe must be mocked in tests. Received: $($GhArgs -join ' ')"
        }

        # Evaluate PR Creation Gate condition 5: ci_gate.conclusion == success AND
        # ci_gate.head_sha == current head SHA.
        function script:Test-PrGateCondition5 {
            param($CiGate, [string]$CurrentHeadSha)
            return ($CiGate.conclusion -eq 'success') -and ($CiGate.head_sha -eq $CurrentHeadSha)
        }

        $script:GreenChecksJson = @'
[
  { "name": "build", "bucket": "pass", "state": "SUCCESS", "link": "https://github.com/drmoisan/TMW/actions/runs/777/job/1" },
  { "name": "test",  "bucket": "pass", "state": "SUCCESS", "link": "https://github.com/drmoisan/TMW/actions/runs/777/job/2" }
]
'@
        $script:RedChecksJson = @'
[
  { "name": "build", "bucket": "pass", "state": "SUCCESS",  "link": "https://github.com/drmoisan/TMW/actions/runs/778/job/1" },
  { "name": "test",  "bucket": "fail", "state": "FAILURE",  "link": "https://github.com/drmoisan/TMW/actions/runs/778/job/2" }
]
'@
    }

    Context 'green PR Pipeline against the live head SHA' {
        It 'parses fixture gh output, records a success ci_gate, and opens the PR gate' {
            Mock -CommandName Invoke-GhExe -MockWith { return $script:GreenChecksJson }

            $headSha = 'deadbeefcafe'
            $checksJson = Invoke-GhExe -GhArgs @('pr', 'checks', '--required', '--json', 'bucket,name,state,link')

            $fixedNow = { [System.DateTimeOffset]::new(2026, 5, 19, 10, 15, 0, [TimeSpan]::Zero) }
            $ciGate = & $script:ParserPath -ChecksJson $checksJson `
                -HeadSha $headSha -RunId '777' -RunUrl 'https://github.com/drmoisan/TMW/actions/runs/777' `
                -NowProvider $fixedNow

            $ciGate.conclusion | Should -Be 'success'
            $ciGate.head_sha | Should -Be $headSha
            (Test-PrGateCondition5 -CiGate $ciGate -CurrentHeadSha $headSha) | Should -BeTrue
            Should -Invoke Invoke-GhExe -Times 1 -Exactly
        }
    }

    Context 'failing PR Pipeline against the live head SHA' {
        It 'records a failure ci_gate and keeps the PR gate closed' {
            Mock -CommandName Invoke-GhExe -MockWith { return $script:RedChecksJson }

            $headSha = 'deadbeefcafe'
            $checksJson = Invoke-GhExe -GhArgs @('pr', 'checks', '--required', '--json', 'bucket,name,state,link')
            $ciGate = & $script:ParserPath -ChecksJson $checksJson `
                -HeadSha $headSha -RunId '778' -RunUrl 'https://github.com/drmoisan/TMW/actions/runs/778'

            $ciGate.conclusion | Should -Be 'failure'
            (Test-PrGateCondition5 -CiGate $ciGate -CurrentHeadSha $headSha) | Should -BeFalse
        }
    }

    Context 'head SHA mismatch (stale verification)' {
        It 'keeps the PR gate closed when ci_gate.head_sha != current head SHA' {
            Mock -CommandName Invoke-GhExe -MockWith { return $script:GreenChecksJson }

            $checksJson = Invoke-GhExe -GhArgs @('pr', 'checks', '--required', '--json', 'bucket,name,state,link')
            $ciGate = & $script:ParserPath -ChecksJson $checksJson `
                -HeadSha 'oldsha111' -RunId '777' -RunUrl 'https://github.com/drmoisan/TMW/actions/runs/777'

            # ci_gate verified an older SHA; current branch head advanced.
            (Test-PrGateCondition5 -CiGate $ciGate -CurrentHeadSha 'newsha222') | Should -BeFalse
        }
    }
}
