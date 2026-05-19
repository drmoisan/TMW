# Pre-Edit Snapshots

Timestamp: 2026-05-18T22-05
Command: Get-FileHash -Algorithm SHA256 and Get-Content -Raw (per file)
EXIT_CODE: 0
Output Summary: Snapshots of four files prior to Phase 4 edits.

## .github/workflows/pr-pipeline.yml
SHA256: E9761AA2BCA5CAEB4A74B177F99F2D75538E5A5C3BD2920E2B1600D279BDD440

Excerpt (lines 62-78):
```
  stage-e2e-smoke:
    needs: [stage-7-integration]
    if: contains(github.event.pull_request.labels.*.name, 'e2e:run')
    uses: ./.github/workflows/_stage-e2e-smoke.yml
    secrets: inherit

  stage-10-benchmark-regression:
    needs: [stage-7-integration]
    uses: ./.github/workflows/_stage-10-benchmark-regression.yml

  benchmark-gate-self-validation:
    needs: [stage-7-integration]
    uses: ./.github/workflows/_benchmark-gate-self-validation.yml

  secret-scan:
    uses: ./.github/workflows/_secret-scan.yml
```

## .claude/rules/quality-tiers.md
SHA256: 79E23D7B1F435018E9CE8977AF6B644AE18EAC0C5AA84C5DA249153DBA19D462

Excerpt (lines 39-48):
```
| Gate | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Untyped escape hatches (`any`/`dynamic`) | 0 | 0 | <= 5 per file, justified | unlimited |
| Property test density | >= 1 per pure function | >= 1 per pure function | none | none |
| Mutation score | >= 75% | trend-only | none | none |
| Contract breaking changes | major bump required | major bump required | n/a | n/a |
| Benchmark p99 regression | < 5% | < 10% | none | none |
| Determinism (retry rate) | < 0.5% | < 1% | < 2% | n/a |
| Golden tests | required for classifier-output modules | optional | none | none |
| Full E2E suite scope | all critical paths | core paths | adapter smoke | none |
```

## .claude/rules/general-code-change.md
SHA256: 164441C45CC1EA0C6C0B25DA4FB9AE3D246E10936D7D0C8BAE40259FC66BA87B

Excerpt (line 45):
```
Mutation testing, golden tests, and benchmark regression run in pre-merge or nightly pipelines, not the per-commit loop.
```

## scripts/powershell/PoshQC/settings/pester.runsettings.psd1
SHA256: A059ED8831E123945CF0591D44D584741534C6ED54510BE635D1232114CABDBC

Full file (30 lines):
```
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
```
