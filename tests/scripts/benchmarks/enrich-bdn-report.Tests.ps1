#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'enrich-bdn-report.ps1' {
    BeforeAll {
        $script:ScriptPath = (Resolve-Path "$PSScriptRoot/../../../scripts/benchmarks/enrich-bdn-report.ps1").Path
        . (Resolve-Path "$PSScriptRoot/_helpers/Import-ScriptFunctions.ps1").Path
        $sb = Get-ScriptFunctionsScriptBlock -Path $script:ScriptPath -FunctionName 'Get-Percentile'
        . $sb
    }

    Describe 'Get-Percentile' {
        It 'returns the single value for a one-element set' {
            (Get-Percentile -Values @(42.5) -Percentile 99) | Should -BeExactly 42.5
        }
        It 'computes linear interpolation correctly for a known fixture' {
            $values = [double[]](1..100)
            # P99 on [1..100] using linear interpolation: rank = 0.99 * 99 = 98.01
            # lower=98 (value 99), upper=99 (value 100); 99 * 0.99 + 100 * 0.01 = 99.01
            (Get-Percentile -Values $values -Percentile 99) | Should -BeExactly 99.01
        }
        It 'throws when given an empty value set' {
            { Get-Percentile -Values ([double[]]@()) -Percentile 99 } | Should -Throw
        }
        It 'returns the boundary value when rank is exactly an integer' {
            # P0 on [1,2,3,4,5] -> rank = 0; lower=upper=0; returns sorted[0] = 1
            (Get-Percentile -Values @(1.0, 2.0, 3.0, 4.0, 5.0) -Percentile 0) | Should -BeExactly 1.0
        }
    }

    Describe 'enrich-bdn-report script body' {
        It 'enriches a benchmark JSON missing P99 and writes it back' {
            $payload = [pscustomobject]@{
                Benchmarks = @(
                    [pscustomobject]@{
                        Statistics = [pscustomobject]@{
                            Percentiles    = [pscustomobject]@{ P0 = 0; P95 = 95.0 }
                            OriginalValues = @(1.0, 50.0, 100.0)
                        }
                    }
                )
            }
            $payloadJson = $payload | ConvertTo-Json -Depth 100
            $sink = [System.Collections.Generic.List[object]]::new()

            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*fake.json*' } -MockWith { return $payloadJson }
            Mock -CommandName Set-Content -ParameterFilter { $LiteralPath -like '*fake.json*' } -MockWith {
                $sink.Add(@{ Path = $LiteralPath; Content = $Value })
            }

            & $script:ScriptPath -Path 'fake.json'

            $sink.Count | Should -Be 1
            $sink[0].Content | Should -Match '"P99"'
        }

        It 'throws when input JSON has no Benchmarks array' {
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*noarr.json*' } -MockWith { return '{"Other": 1}' }
            { & $script:ScriptPath -Path 'noarr.json' } | Should -Throw
        }

        It 'skips benchmarks with null Statistics' {
            $payload = [pscustomobject]@{
                Benchmarks = @(
                    [pscustomobject]@{ Statistics = $null },
                    [pscustomobject]@{
                        Statistics = [pscustomobject]@{
                            Percentiles    = [pscustomobject]@{ P0 = 0 }
                            OriginalValues = @(1.0, 50.0, 100.0)
                        }
                    }
                )
            }
            $payloadJson = $payload | ConvertTo-Json -Depth 100
            $sink = [System.Collections.Generic.List[object]]::new()
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*nullstats.json*' } -MockWith { return $payloadJson }
            Mock -CommandName Set-Content -ParameterFilter { $LiteralPath -like '*nullstats.json*' } -MockWith {
                $sink.Add(@{ Path = $LiteralPath; Content = $Value })
            }
            & $script:ScriptPath -Path 'nullstats.json'
            $sink.Count | Should -Be 1
        }

        It 'overwrites existing P99 in place when -Force is supplied' {
            $payload = [pscustomobject]@{
                Benchmarks = @(
                    [pscustomobject]@{
                        Statistics = [pscustomobject]@{
                            Percentiles    = [pscustomobject]@{ P0 = 0; P99 = 999.0 }
                            OriginalValues = @(1.0, 50.0, 100.0)
                        }
                    }
                )
            }
            $payloadJson = $payload | ConvertTo-Json -Depth 100
            $sink = [System.Collections.Generic.List[object]]::new()
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*force.json*' } -MockWith { return $payloadJson }
            Mock -CommandName Set-Content -ParameterFilter { $LiteralPath -like '*force.json*' } -MockWith {
                $sink.Add(@{ Path = $LiteralPath; Content = $Value })
            }
            & $script:ScriptPath -Path 'force.json' -Force
            $sink.Count | Should -Be 1
            $sink[0].Content | Should -Not -Match '"P99":\s*999'
        }

        It 'propagates a file-missing failure' {
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*missing*' } -MockWith {
                throw [System.IO.FileNotFoundException]::new('not there')
            }
            { & $script:ScriptPath -Path 'missing.json' } | Should -Throw
        }

        It 'is idempotent when input already has P99 and -Force is not supplied' {
            $payload = [pscustomobject]@{
                Benchmarks = @(
                    [pscustomobject]@{
                        Statistics = [pscustomobject]@{
                            Percentiles    = [pscustomobject]@{ P0 = 0; P95 = 95.0; P99 = 123.456 }
                            OriginalValues = @(1.0, 50.0, 100.0)
                        }
                    }
                )
            }
            $payloadJson = $payload | ConvertTo-Json -Depth 100
            $sink = [System.Collections.Generic.List[object]]::new()

            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*idempotent.json*' } -MockWith { return $payloadJson }
            Mock -CommandName Set-Content -ParameterFilter { $LiteralPath -like '*idempotent.json*' } -MockWith {
                $sink.Add(@{ Path = $LiteralPath; Content = $Value })
            }

            & $script:ScriptPath -Path 'idempotent.json'
            & $script:ScriptPath -Path 'idempotent.json'

            $sink.Count | Should -Be 2
            $sink[0].Content | Should -Match '"P99":\s*123\.456'
            $sink[1].Content | Should -Be $sink[0].Content
        }
    }
}
