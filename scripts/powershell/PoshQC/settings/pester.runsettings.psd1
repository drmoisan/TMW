@{
    Run          = @{
        Path = @('tests/scripts/benchmarks')
        Exit = $true
    }
    Should       = @{
        ErrorAction = 'Stop'
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
    TestResult   = @{
        Enabled      = $true
        OutputFormat = 'JUnitXml'
        OutputPath   = 'artifacts/pester/pester-junit.xml'
    }
    CodeCoverage = @{
        Enabled               = $true
        OutputFormat          = 'JaCoCo'
        OutputPath            = 'artifacts/pester/powershell-coverage.xml'
        Path                  = @(
            'scripts/benchmarks/parse-cobertura.ps1'
        )
        UseBreakpoints        = $false
        CoveragePercentTarget = 0
    }
}
