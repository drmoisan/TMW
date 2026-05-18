#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'parse-cobertura.ps1' {
    BeforeAll {
        $script:ScriptPath = (Resolve-Path "$PSScriptRoot/../../../scripts/benchmarks/parse-cobertura.ps1").Path

        function script:New-FakeFileInfo {
            param([string]$Directory, [string]$FullName)
            return [pscustomobject]@{
                FullName  = $FullName
                Directory = [pscustomobject]@{ Name = $Directory }
            }
        }
    }

    Describe 'parse-cobertura script body' {
        It 'throws when XML content is malformed' {
            Mock -CommandName Get-ChildItem -MockWith {
                return , (New-FakeFileInfo -Directory 'bad' -FullName 'C:/tmp/bad/coverage.cobertura.xml')
            }
            Mock -CommandName Get-Content -MockWith { return '<not-xml' }
            { & $script:ScriptPath -Path 'C:/tmp' } | Should -Throw
        }

        It 'defaults numeric attributes to 0 when line/branch rate attributes are absent' {
            $xmlContent = '<?xml version="1.0"?><coverage version="1.0"></coverage>'
            Mock -CommandName Get-ChildItem -MockWith {
                return , (New-FakeFileInfo -Directory 'empty' -FullName 'C:/tmp/empty/coverage.cobertura.xml')
            }
            Mock -CommandName Get-Content -MockWith { return $xmlContent }
            $output = & $script:ScriptPath -Path 'C:/tmp'
            ($output | Where-Object { "$_" -match 'AGGREGATE.*lines-covered=0/0.*branches-covered=0/0' }) | Should -Not -BeNullOrEmpty
        }

        It 'aggregates lines and branches across multiple cobertura files' {
            $xmlA = '<?xml version="1.0"?><coverage lines-covered="10" lines-valid="20" branches-covered="30" branches-valid="40"></coverage>'
            $xmlB = '<?xml version="1.0"?><coverage lines-covered="30" lines-valid="40" branches-covered="34" branches-valid="48"></coverage>'
            $xmlC = '<?xml version="1.0"?><coverage lines-covered="5" lines-valid="16" branches-covered="4" branches-valid="8"></coverage>'

            Mock -CommandName Get-ChildItem -MockWith {
                return @(
                    (New-FakeFileInfo -Directory 'A' -FullName 'C:/tmp/A/coverage.cobertura.xml'),
                    (New-FakeFileInfo -Directory 'B' -FullName 'C:/tmp/B/coverage.cobertura.xml'),
                    (New-FakeFileInfo -Directory 'C' -FullName 'C:/tmp/C/coverage.cobertura.xml')
                )
            }
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*/A/*' } -MockWith { return $xmlA }
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*/B/*' } -MockWith { return $xmlB }
            Mock -CommandName Get-Content -ParameterFilter { $LiteralPath -like '*/C/*' } -MockWith { return $xmlC }

            $output = & $script:ScriptPath -Path 'C:/tmp'
            # Aggregates: lines=45/76, branches=68/96
            ($output | Where-Object { "$_" -match 'AGGREGATE.*lines-covered=45/76.*branches-covered=68/96' }) | Should -Not -BeNullOrEmpty
        }
    }
}
