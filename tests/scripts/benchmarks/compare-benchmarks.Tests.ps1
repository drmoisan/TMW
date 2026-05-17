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
                    [double]$Median,
                    [double]$AllocBytes
                )
                return [pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = $Id
                            Statistics = [pscustomobject]@{
                                Median      = $Median
                                Percentiles = [pscustomobject]@{ P99 = $Median }
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
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'NewBench' -Median 1.0 -AllocBytes 100).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            $exitCode = [int]$output[-1]
            $rows = $output[0..($output.Count - 2)]
            $exitCode | Should -Be 0
            ($rows | Where-Object { "$_" -match 'SKIP_NO_BASELINE' }) | Should -Not -BeNullOrEmpty
        }

        It 'returns exit code 0 when all benchmarks pass thresholds' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport -Id 'B1' -Median 100.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'B1' -Median 102.0 -AllocBytes 1050).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 0
        }

        It 'returns exit code 1 when a benchmark regresses (FAIL_LATENCY)' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport -Id 'B1' -Median 100.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'B1' -Median 200.0 -AllocBytes 1050).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -Not -BeNullOrEmpty
        }

        It 'transitions verdict to FAIL_ALLOC when only allocation exceeds threshold' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport -Id 'B1' -Median 100.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'B1' -Median 102.0 -AllocBytes 2000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_ALLOC' -and "$_" -notmatch 'FAIL_LATENCY_AND_ALLOC' }) | Should -Not -BeNullOrEmpty
        }

        It 'transitions verdict to FAIL_LATENCY_AND_ALLOC when both exceed thresholds' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport -Id 'B1' -Median 100.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport -Id 'B1' -Median 200.0 -AllocBytes 2000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY_AND_ALLOC' }) | Should -Not -BeNullOrEmpty
        }
    }

    Describe 'LatencyMinDeltaNs absolute-delta floor (AND semantics with LatencyThresholdPercent)' {
        BeforeAll {
            function script:New-FakeReport2 {
                param([string]$Id, [double]$Median, [double]$AllocBytes)
                return [pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = $Id
                            Statistics = [pscustomobject]@{
                                Median      = $Median
                                Percentiles = [pscustomobject]@{ P99 = $Median }
                            }
                            Memory     = [pscustomobject]@{ BytesAllocatedPerOperation = $AllocBytes }
                        }
                    )
                }
            }
        }

        It 'returns PASS when relative delta trips (>5%) but absolute delta is below the 25 ns floor (default)' {
            # Baseline 25 ns -> current 27 ns: 8% relative, but only 2 ns absolute.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -Median 25.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -Median 27.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 0
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -BeNullOrEmpty
            ($output | Where-Object { "$_" -match ', PASS\s*$' }) | Should -Not -BeNullOrEmpty
        }

        It 'returns FAIL_LATENCY when both relative delta (>5%) and absolute delta (>25 ns) trip' {
            # Baseline 500 ns -> current 530 ns: 6% relative, 30 ns absolute.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -Median 500.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -Median 530.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' -and "$_" -notmatch 'FAIL_LATENCY_AND_ALLOC' }) | Should -Not -BeNullOrEmpty
        }

        It 'returns PASS when only the absolute floor trips but the relative delta stays at or below 5%' {
            # Baseline 10000 ns -> current 10100 ns: 1% relative, 100 ns absolute.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -Median 10000.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -Median 10100.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 0
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -BeNullOrEmpty
        }

        It 'uses the default LatencyMinDeltaNs of 25.0 when the caller omits it' {
            # 20% relative, 10 ns absolute -> below the default 25 ns floor -> PASS.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -Median 50.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -Median 60.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 0
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -BeNullOrEmpty
        }

        It 'propagates a custom LatencyMinDeltaNs through Invoke-CompareBenchmarksMain' {
            # 20% relative, 10 ns absolute. Default floor (25) -> PASS; lowered floor (5) -> FAIL_LATENCY.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport2 -Id 'B1' -Median 50.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport2 -Id 'B1' -Median 60.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json' -LatencyMinDeltaNs 5.0)
            [int]$output[-1] | Should -Be 1
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -Not -BeNullOrEmpty
        }
    }

    Describe 'Statistic source (Median vs Percentiles.P99)' {
        BeforeAll {
            function script:New-FakeReport3 {
                param([string]$Id, [double]$Median, [double]$P99, [double]$AllocBytes)
                return [pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = $Id
                            Statistics = [pscustomobject]@{
                                Median      = $Median
                                Percentiles = [pscustomobject]@{ P99 = $P99 }
                            }
                            Memory     = [pscustomobject]@{ BytesAllocatedPerOperation = $AllocBytes }
                        }
                    )
                }
            }
        }

        It 'compares Statistics.Median and ignores Statistics.Percentiles.P99' {
            # Median delta: 100 -> 105 (5 ns absolute, 5% relative) -> PASS under default
            # threshold (5% AND 25 ns floor): 5 ns < 25 ns floor.
            # If the comparator instead used P99: 1000 -> 1100 (100 ns absolute, 10% relative)
            # -> would trip both conditions and FAIL_LATENCY.
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport3 -Id 'B1' -Median 100.0 -P99 1000.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport3 -Id 'B1' -Median 105.0 -P99 1100.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            [int]$output[-1] | Should -Be 0
            ($output | Where-Object { "$_" -match 'FAIL_LATENCY' }) | Should -BeNullOrEmpty
        }

        It 'emits a CSV header that names median columns and contains no p99 substring' {
            Mock Read-BenchmarkReport {
                if ($Path -eq 'base.json') { return , (New-FakeReport3 -Id 'B1' -Median 100.0 -P99 1000.0 -AllocBytes 1000).Benchmarks[0] }
                if ($Path -eq 'cur.json') { return , (New-FakeReport3 -Id 'B1' -Median 100.0 -P99 1000.0 -AllocBytes 1000).Benchmarks[0] }
            }
            $output = @(Invoke-CompareBenchmarksMain -BaselinePath 'base.json' -CurrentPath 'cur.json')
            $header = [string]$output[0]
            $header | Should -Match 'median_baseline_ns'
            $header | Should -Match 'median_current_ns'
            $header | Should -Match 'median_delta_pct'
            $header | Should -Not -Match 'p99_'
        }
    }
}
