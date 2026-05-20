#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

# Regression tests for the S9 ci-gate parser (issue #26).
# The parser consumes `gh pr checks --required --json` output and emits the
# `ci_gate` object defined in spec.md AC2. These tests are authored before the
# implementation exists (Phase 1, [expect-fail]) and are expected to pass after
# Phase 5 delivers scripts/orchestration/Invoke-CiGateParser.ps1.

Describe 'Invoke-CiGateParser.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '../../../scripts/orchestration/Invoke-CiGateParser.ps1'

        # gh pr checks --required --json bucket,name,state,link,workflow returns a
        # JSON array. Each element has a `bucket` (pass|fail|pending|skipping|cancel)
        # and a `name`. The parser derives ci_gate.conclusion from the buckets.
        function script:Get-AllSuccessJson {
            return @'
[
  { "name": "build", "bucket": "pass", "state": "SUCCESS", "link": "https://example/1" },
  { "name": "test",  "bucket": "pass", "state": "SUCCESS", "link": "https://example/2" }
]
'@
        }
        function script:Get-OneFailedJson {
            return @'
[
  { "name": "build", "bucket": "pass", "state": "SUCCESS", "link": "https://example/1" },
  { "name": "test",  "bucket": "fail", "state": "FAILURE", "link": "https://example/2" }
]
'@
        }
        function script:Get-OneInProgressJson {
            return @'
[
  { "name": "build", "bucket": "pass",    "state": "SUCCESS",     "link": "https://example/1" },
  { "name": "test",  "bucket": "pending", "state": "IN_PROGRESS", "link": "https://example/2" }
]
'@
        }
    }

    Context 'positive: all required checks succeed' {
        It 'emits ci_gate with conclusion success and the provided head SHA' {
            $result = & $script:ScriptPath -ChecksJson (Get-AllSuccessJson) `
                -HeadSha 'abc123' -RunId '999' -RunUrl 'https://example/run/999'
            $result.conclusion | Should -Be 'success'
            $result.head_sha | Should -Be 'abc123'
            $result.pr_pipeline_run_id | Should -Be '999'
            $result.pr_pipeline_run_url | Should -Be 'https://example/run/999'
            $result.verified_at | Should -Not -BeNullOrEmpty
        }
    }

    Context 'negative: one required check failed' {
        It 'emits ci_gate with conclusion failure' {
            $result = & $script:ScriptPath -ChecksJson (Get-OneFailedJson) `
                -HeadSha 'abc123' -RunId '999' -RunUrl 'https://example/run/999'
            $result.conclusion | Should -Be 'failure'
        }
    }

    Context 'negative: one required check in progress' {
        It 'emits ci_gate with conclusion pending' {
            $result = & $script:ScriptPath -ChecksJson (Get-OneInProgressJson) `
                -HeadSha 'abc123' -RunId '999' -RunUrl 'https://example/run/999'
            $result.conclusion | Should -Be 'pending'
        }
    }

    Context 'negative: a required check was cancelled' {
        It 'treats a cancelled required check as failure' {
            $json = @'
[
  { "name": "build", "bucket": "pass",   "state": "SUCCESS",   "link": "https://example/1" },
  { "name": "test",  "bucket": "cancel", "state": "CANCELLED",  "link": "https://example/2" }
]
'@
            $result = & $script:ScriptPath -ChecksJson $json `
                -HeadSha 'abc123' -RunId '999' -RunUrl 'https://example/run/999'
            $result.conclusion | Should -Be 'failure'
        }
    }

    Context 'edge: a single check object (not an array)' {
        It 'normalizes a single passing check object to success' {
            $json = '{ "name": "build", "bucket": "pass", "state": "SUCCESS", "link": "https://example/1" }'
            $result = & $script:ScriptPath -ChecksJson $json `
                -HeadSha 'abc123' -RunId '999' -RunUrl 'https://example/run/999'
            $result.conclusion | Should -Be 'success'
        }
    }

    Context 'edge: an unrecognized bucket value' {
        It 'treats an unknown bucket as pending' {
            $json = '[ { "name": "build", "bucket": "mystery", "state": "?", "link": "https://example/1" } ]'
            $result = & $script:ScriptPath -ChecksJson $json `
                -HeadSha 'abc123' -RunId '999' -RunUrl 'https://example/run/999'
            $result.conclusion | Should -Be 'pending'
        }
    }

    Context 'determinism: NowProvider seam controls verified_at' {
        It 'uses the injected clock for verified_at' {
            $fixed = [System.DateTimeOffset]::new(2026, 5, 19, 10, 15, 0, [TimeSpan]::Zero)
            $result = & $script:ScriptPath -ChecksJson (Get-AllSuccessJson) `
                -HeadSha 'abc123' -RunId '999' -RunUrl 'https://example/run/999' `
                -NowProvider { $fixed }
            $result.verified_at | Should -Be $fixed.ToString('o')
        }
    }

    Context 'error path: malformed JSON' {
        It 'throws on malformed JSON input' {
            { & $script:ScriptPath -ChecksJson '[ this is not json' `
                    -HeadSha 'abc123' -RunId '999' -RunUrl 'https://example/run/999' } |
                Should -Throw
        }
    }

    Context 'error path: empty checks list' {
        It 'throws when the required-checks list is empty' {
            { & $script:ScriptPath -ChecksJson '[]' `
                    -HeadSha 'abc123' -RunId '999' -RunUrl 'https://example/run/999' } |
                Should -Throw
        }
    }
}
