# Baseline PowerShell Toolchain (scoped: scripts/benchmarks + tests/scripts/benchmarks)

Timestamp: 2026-05-18T22-05

## Step 1 — Format (PoshQC)
Command: mcp__drm-copilot__run_poshqc_format (scan_folders: ["tests/scripts/benchmarks","scripts/benchmarks"])
EXIT_CODE: 0
Output Summary: Format pass; no files reformatted.

## Step 2 — Analyze (PoshQC / PSScriptAnalyzer)
Command: mcp__drm-copilot__run_poshqc_analyze (scan_folders: ["tests/scripts/benchmarks","scripts/benchmarks"])
EXIT_CODE: 1
Output Summary: PSScriptAnalyzer reported 2 Warning issue(s), both in scripts/benchmarks/compare-benchmarks.ps1 (slated for deletion in Phase 2). Baseline issues:
- PSAvoidUsingWriteHost, Warning, compare-benchmarks.ps1 line 189: File uses Write-Host.
- PSUseBOMForUnicodeEncodedFile, Warning, compare-benchmarks.ps1: Missing BOM encoding for non-ASCII encoded file.
Both findings will be eliminated by the planned deletion of compare-benchmarks.ps1 in Phase 2.

## Step 3 — Test (PoshQC / Pester) with coverage
Command: mcp__drm-copilot__run_poshqc_test (scan_folders: ["tests/scripts/benchmarks"])
EXIT_CODE: 0
Output Summary: 37 tests passed, 0 failures, 0 errors, time=2.706s.
Coverage report (artifacts/pester/powershell-coverage.xml) emitted by PoshQC reports against repo-wide scope (its bundled CodeCoverage.Path, not the runsettings file): INSTRUCTION covered=0 missed=433; LINE covered=0 missed=284; METHOD covered=0 missed=18; CLASS covered=0 missed=5. This 0% reading is a baseline artifact of PoshQC's coverage scope and is pre-existing — not introduced by this plan.
