#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'compare-benchmarks.ps1' {
    BeforeAll {
        $script:ScriptPath = (Resolve-Path "$PSScriptRoot/../../../scripts/benchmarks/compare-benchmarks.ps1").Path
        # Dot-source the script directly so Pester code-coverage can attribute
        # executed lines to the script file. The script's top-level guard
        # ($MyInvocation.InvocationName -ne '.') skips the production exit call
        # under dot-source, leaving only the function definitions in scope.
        . $script:ScriptPath -BaselinePath '' -CurrentPath ''
    }

    Describe 'Get-PercentDelta' {
        It 'returns finite delta when baseline > 0' {
            (Get-PercentDelta -Baseline 100.0 -Current 110.0) | Should -BeExactly 10.0
        }
        It 'returns PositiveInfinity when baseline = 0 and current > 0' {
            (Get-PercentDelta -Baseline 0.0 -Current 5.0) | Should -Be ([double]::PositiveInfinity)
        }
        It 'returns 0.0 when baseline = 0 and current = 0' {
            (Get-PercentDelta -Baseline 0.0 -Current 0.0) | Should -BeExactly 0.0
        }
        It 'returns PositiveInfinity when baseline is negative' {
            (Get-PercentDelta -Baseline -1.0 -Current 5.0) | Should -Be ([double]::PositiveInfinity)
        }
    }

    Describe 'Read-BenchmarkReport' {
        It 'throws an exit-2 exception when the file is missing' {
            Mock Test-Path { return $false } -ParameterFilter { $LiteralPath -eq 'missing.json' }
            $err = $null
            try { Read-BenchmarkReport -Path 'missing.json' } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            [int]$err.Exception.Data['ExitCode'] | Should -Be 2
        }
        It 'throws an exit-2 exception when JSON is malformed' {
            Mock Test-Path { return $true }
            Mock Get-Content { return '{not json' } -ParameterFilter { $LiteralPath -eq 'bad.json' }
            $err = $null
            try { Read-BenchmarkReport -Path 'bad.json' } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            [int]$err.Exception.Data['ExitCode'] | Should -Be 2
        }
        It 'throws an exit-2 exception when Benchmarks array is absent' {
            Mock Test-Path { return $true }
            Mock Get-Content { return '{"OtherField": 1}' } -ParameterFilter { $LiteralPath -eq 'noarr.json' }
            $err = $null
            try { Read-BenchmarkReport -Path 'noarr.json' } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            [int]$err.Exception.Data['ExitCode'] | Should -Be 2
        }
    }

    Describe 'Invoke-CompareBenchmarksMain (script body)' {
        BeforeAll {
            # Helper to build a single-benchmark report.
            function script:New-FakeReport {
                param(
                    [string]$Id,
                    [double]$P99,
                    [double]$AllocBytes
                )
                return [pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = $Id
                            Statistics = [pscustomobject]@{
                                Percentiles = [pscustomobject]@{ P99 = $P99 }
                            }
                            Memory     = [pscustomobject]@{ BytesAllocatedPerOperation = $AllocBytes }
                        }
                    )
                }
            }
        }

        It 'emits SKIP_NO_BASELINE row and exits 0 when current id is not in baseline map' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return @() }
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'NewBench' -P99 1.0 -AllocBytes 100).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            $exitCode = [int]$output[-1]
            $rows = $output[0..($output.Count - 2)]
            $exitCode | Should -Be 0
            ($rows | Where-Object { "$_" -match 'SKIP_NO_BASELINE' }) | Should -Not -BeNullOrEmpty
        }

        It 'returns exit code 0 when all benchmarks pass thresholds' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport -Id 'B1' -P99 100.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'B1' -P99 102.0 -AllocBytes 1050).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 0
        }

        It 'returns exit code 1 when a benchmark regresses (FAIL_LATENCY)' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport -Id 'B1' -P99 100.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'B1' -P99 200.0 -AllocBytes 1050).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -Not -BeNullOrEmpty
        }

        It 'transitions verdict to FAIL_ALLOC when only allocation exceeds threshold' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport -Id 'B1' -P99 100.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'B1' -P99 102.0 -AllocBytes 2000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_ALLOC' -and "$_" -notmatch 'FAIL_LATENCY_AND_ALLOC' }) | Should -Not -BeNullOrEmpty
        }

        It 'transitions verdict to FAIL_LATENCY_AND_ALLOC when both exceed thresholds' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport -Id 'B1' -P99 100.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'B1' -P99 200.0 -AllocBytes 2000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY_AND_ALLOC' }) | Should -Not -BeNullOrEmpty
        }
    }

    Describe 'LatencyMinDeltaNs absolute-delta floor (AND semantics with LatencyThresholdPercent)' {
        BeforeAll {
            function script:New-FakeReport2 {
                param([string]$Id, [double]$P99, [double]$AllocBytes)
                return [pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = $Id
                            Statistics = [pscustomobject]@{
                                Percentiles = [pscustomobject]@{ P99 = $P99 }
                            }
                            Memory     = [pscustomobject]@{ BytesAllocatedPerOperation = $AllocBytes }
                        }
                    )
                }
            }
        }

        It 'returns PASS when relative delta trips (>5%) but absolute delta is below the 5 ns floor (default)' {
            # Baseline 25 ns -> current 27 ns: 8% relative, but only 2 ns absolute.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -P99 25.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -P99 27.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 0
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -BeNullOrEmpty
            ($output | Where-Object { "$_" -match ', PASS\s*$' }) | Should -Not -BeNullOrEmpty
        }

        It 'returns FAIL_LATENCY when both relative delta (>5%) and absolute delta (>5 ns) trip' {
            # Baseline 125 ns -> current 135 ns: 8% relative, 10 ns absolute.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -P99 125.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -P99 135.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' -and "$_" -notmatch 'FAIL_LATENCY_AND_ALLOC' }) | Should -Not -BeNullOrEmpty
        }

        It 'returns PASS when only the absolute floor trips but the relative delta stays at or below 5%' {
            # Baseline 10000 ns -> current 10100 ns: 1% relative, 100 ns absolute.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -P99 10000.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -P99 10100.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 0
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -BeNullOrEmpty
        }

        It 'uses the default LatencyMinDeltaNs of 5.0 when the caller omits it' {
            # 8% relative, 4 ns absolute -> below the default 5 ns floor -> PASS.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -P99 50.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -P99 54.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 0
        }

        It 'propagates a custom LatencyMinDeltaNs through Invoke-CompareBenchmarksMain' {
            # 8% relative, 4 ns absolute. Default floor (5) -> PASS; lowered floor (1) -> FAIL_LATENCY.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -P99 50.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -P99 54.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json' -LatencyMinDeltaNs 1.0)
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -Not -BeNullOrEmpty
        }
    }
}
