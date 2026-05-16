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
        It 'writes a latency fixture with P99 multiplied by 1.10 for the Classify_Command benchmark' {
            $payloadJson = ([pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = 'TaskMaster.Benchmarks.Classify_Command_Hot'
                            Statistics = [pscustomobject]@{ Percentiles = [pscustomobject]@{ P99 = 100.0 } }
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
            $matchingBench = $obj.Benchmarks | Where-Object { $_.FullName -like '*Classify_Command*' } | Select-Object -First 1
            $actualP99 = [double]$matchingBench.Statistics.Percentiles.P99
            [math]::Abs($actualP99 - 110.0) | Should -BeLessThan 0.0001
        }

        It 'writes an allocation fixture with BytesAllocatedPerOperation multiplied by 1.105 (rounded) for InputNormalization_EdgePath' {
            $payloadJson = ([pscustomobject]@{
                    Benchmarks = @(
                        [pscustomobject]@{
                            FullName   = 'TaskMaster.Benchmarks.InputNormalization_EdgePath_X'
                            Statistics = [pscustomobject]@{ Percentiles = [pscustomobject]@{ P99 = 50.0 } }
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
