# Edit scripts/powershell/PoshQC/settings/pester.runsettings.psd1

Timestamp: 2026-05-18T22-40
Command: Edit tool (remove 'scripts/benchmarks/compare-benchmarks.ps1' and 'scripts/benchmarks/enrich-bdn-report.ps1' from CodeCoverage.Path); Select-String -Pattern 'compare-benchmarks|enrich-bdn-report'; Import-PowerShellDataFile
EXIT_CODE: 0
Output Summary: Two entries removed from CodeCoverage.Path; `make-synthetic-fixtures.ps1` and `parse-cobertura.ps1` retained. Grep returned 0 matches. Import-PowerShellDataFile parsed successfully.

## Diff (logical)
Removed lines:
```
            'scripts/benchmarks/compare-benchmarks.ps1'
            'scripts/benchmarks/enrich-bdn-report.ps1'
```
