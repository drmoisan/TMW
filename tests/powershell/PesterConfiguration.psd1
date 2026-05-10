@{
    Run          = @{
        Path = @(
            'tests/powershell/check-conventional-commit.Tests.ps1',
            'tests/powershell/validate-quality-tiers.Tests.ps1',
            'tests/powershell/validate-feature-review-coverage.Tests.ps1'
        )
        Exit = $true
    }
    CodeCoverage = @{
        Enabled               = $true
        Path                  = @(
            '.githooks/check-conventional-commit.ps1',
            '.github/scripts/validate-quality-tiers.ps1',
            '.claude/hooks/validate-feature-review-coverage.ps1'
        )
        OutputFormat          = 'JaCoCo'
        OutputPath            = 'artifacts/pester/powershell-coverage.xml'
        CoveragePercentTarget = 85
        UseBreakpoints        = $false
    }
    TestResult   = @{
        Enabled      = $true
        OutputPath   = 'artifacts/pester/powershell-tests.xml'
        OutputFormat = 'NUnitXml'
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
}
