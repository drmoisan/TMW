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
            'scripts/benchmarks/compare-benchmarks.ps1'
            'scripts/benchmarks/enrich-bdn-report.ps1'
            'scripts/benchmarks/make-synthetic-fixtures.ps1'
            'scripts/benchmarks/parse-cobertura.ps1'
        )
        UseBreakpoints        = $false
        CoveragePercentTarget = 0
    }
}
