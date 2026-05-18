#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'make-synthetic-fixtures.ps1' {
    BeforeAll {
        $script:ScriptPath = (Resolve-Path "$PSScriptRoot/../../../scripts/benchmarks/make-synthetic-fixtures.ps1").Path
        . (Resolve-Path "$PSScriptRoot/_helpers/Import-ScriptFunctions.ps1").Path
        $sb = Get-ScriptFunctionsScriptBlock -Path $script:ScriptPath -FunctionName 'Copy-Report'
        . $sb
    }

    Describe 'Copy-Report' {
        It 'returns a deserialized object whose Benchmarks array matches source JSON' {
            $payload = '{"Benchmarks": [{"FullName": "X", "value": 1}, {"FullName": "Y", "value": 2}]}'
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -eq 'src.json' } -MockWith { return $payload }
            $result = Copy-Report -Path 'src.json'
            $result.Benchmarks.Count | Should -Be 2
            $result.Benchmarks[0].FullName | Should -Be 'X'
            $result.Benchmarks[1].value | Should -Be 2
        }
    }

    Describe 'make-synthetic-fixtures script body' {
        It 'writes a latency fixture with Median multiplied by 2.0 for the InputNormalization_EdgePath benchmark' {
            $payloadJson = ([pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = 'TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath'
                            Statistics = [pscustomobject]@{
                                Median      = 65.0
                                Percentiles = [pscustomobject]@{ P99 = 70.0 }
                            }
                            Memory     = [pscustomobject]@{ BytesAllocatedPerOperation = 1000 }
                        }
                    )
                } | ConvertTo-Json -Depth 100)

            $sink = [System.Collections.Generic.List[object]]::new()

            Mock -CommandName Test-Path -MockWith { return $true }
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*baseline.json*' } -MockWith { return $payloadJson }
            Mock -CommandName New-Item -MockWith { return $null }
            Mock -CommandName Set-Content -MockWith {
                $sink.Add(@{ Path = [string]$LiteralPath; Content = $Value })
            }

            & $script:ScriptPath -BaselinePath 'baseline.json' -OutputDirectory 'out'

            $latencyEntry = $sink | Where-Object { $_.Path -like '*SyntheticLatencyRegressionFixture.json' } | Select-Object -First 1
            $latencyEntry | Should -Not -BeNullOrEmpty
            $obj = $latencyEntry.Content | ConvertFrom-Json
            $matchingBench = $obj.Benchmarks | Where-Object { $_.FullName -like '*InputNormalization_EdgePath*' } | Select-Object -First 1
            $actualMedian = [double]$matchingBench.Statistics.Median
            [math]::Abs($actualMedian - 130.0) | Should -BeLessThan 0.0001
            # P99 must remain untouched on the targeted benchmark so the report stays a valid BDN shape.
            $actualP99 = [double]$matchingBench.Statistics.Percentiles.P99
            [math]::Abs($actualP99 - 70.0) | Should -BeLessThan 0.0001
        }

        It 'preserves Median on non-targeted benchmarks in the latency fixture' {
            $payloadJson = ([pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = 'TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath'
                            Statistics = [pscustomobject]@{
                                Median      = 65.0
                                Percentiles = [pscustomobject]@{ P99 = 70.0 }
                            }
                            Memory     = [pscustomobject]@{ BytesAllocatedPerOperation = 1000 }
                        },
                        [pscustomobject]@{
                            FullName   = 'TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command'
                            Statistics = [pscustomobject]@{
                                Median      = 15.0
                                Percentiles = [pscustomobject]@{ P99 = 16.0 }
                            }
                            Memory     = [pscustomobject]@{ BytesAllocatedPerOperation = 500 }
                        }
                    )
                } | ConvertTo-Json -Depth 100)

            $sink = [System.Collections.Generic.List[object]]::new()

            Mock -CommandName Test-Path -MockWith { return $true }
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*baseline.json*' } -MockWith { return $payloadJson }
            Mock -CommandName New-Item -MockWith { return $null }
            Mock -CommandName Set-Content -MockWith {
                $sink.Add(@{ Path = [string]$LiteralPath; Content = $Value })
            }

            & $script:ScriptPath -BaselinePath 'baseline.json' -OutputDirectory 'out'

            $latencyEntry = $sink | Where-Object { $_.Path -like '*SyntheticLatencyRegressionFixture.json' } | Select-Object -First 1
            $latencyEntry | Should -Not -BeNullOrEmpty
            $obj = $latencyEntry.Content | ConvertFrom-Json
            $nonTargeted = $obj.Benchmarks | Where-Object { $_.FullName -like '*Classify_Command*' } | Select-Object -First 1
            [double]$nonTargeted.Statistics.Median | Should -Be 15.0
        }

        It 'honors an explicit -T1BenchmarkSubstring override and an explicit -LatencyMultiplier override' {
            $payloadJson = ([pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = 'TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command'
                            Statistics = [pscustomobject]@{
                                Median      = 15.0
                                Percentiles = [pscustomobject]@{ P99 = 16.0 }
                            }
                            Memory     = [pscustomobject]@{ BytesAllocatedPerOperation = 500 }
                        }
                    )
                } | ConvertTo-Json -Depth 100)

            $sink = [System.Collections.Generic.List[object]]::new()

            Mock -CommandName Test-Path -MockWith { return $true }
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*baseline.json*' } -MockWith { return $payloadJson }
            Mock -CommandName New-Item -MockWith { return $null }
            Mock -CommandName Set-Content -MockWith {
                $sink.Add(@{ Path = [string]$LiteralPath; Content = $Value })
            }

            & $script:ScriptPath -BaselinePath 'baseline.json' -OutputDirectory 'out' -T1BenchmarkSubstring 'Classify_Command' -LatencyMultiplier 3.0

            $latencyEntry = $sink | Where-Object { $_.Path -like '*SyntheticLatencyRegressionFixture.json' } | Select-Object -First 1
            $latencyEntry | Should -Not -BeNullOrEmpty
            $obj = $latencyEntry.Content | ConvertFrom-Json
            $matchingBench = $obj.Benchmarks | Where-Object { $_.FullName -like '*Classify_Command*' } | Select-Object -First 1
            [double]$matchingBench.Statistics.Median | Should -Be 45.0
        }

        It 'writes an allocation fixture with BytesAllocatedPerOperation multiplied by 1.105 (rounded) for InputNormalization_EdgePath' {
            $payloadJson = ([pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = 'TaskMaster.Benchmarks.InputNormalization_EdgePath_X'
                            Statistics = [pscustomobject]@{
                                Median      = 50.0
                                Percentiles = [pscustomobject]@{ P99 = 50.0 }
                            }
                            Memory     = [pscustomobject]@{ BytesAllocatedPerOperation = 1000 }
                        }
                    )
                } | ConvertTo-Json -Depth 100)

            $sink = [System.Collections.Generic.List[object]]::new()

            Mock -CommandName Test-Path -MockWith { return $true }
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*baseline.json*' } -MockWith { return $payloadJson }
            Mock -CommandName New-Item -MockWith { return $null }
            Mock -CommandName Set-Content -MockWith {
                $sink.Add(@{ Path = [string]$LiteralPath; Content = $Value })
            }

            & $script:ScriptPath -BaselinePath 'baseline.json' -OutputDirectory 'out'

            $allocEntry = $sink | Where-Object { $_.Path -like '*SyntheticAllocationRegressionFixture.json' } | Select-Object -First 1
            $allocEntry | Should -Not -BeNullOrEmpty
            $obj = $allocEntry.Content | ConvertFrom-Json
            $matchingBench = $obj.Benchmarks | Where-Object { $_.FullName -like '*InputNormalization_EdgePath*' } | Select-Object -First 1
            [long]$matchingBench.Memory.BytesAllocatedPerOperation | Should -Be 1105
        }
    }
}
