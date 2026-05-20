# P5-T4 — Provenance regression passes after implementation

Timestamp: 2026-05-19T10-15

Command: Invoke-Pester (Run.Path = tests/pester/benchmarks/BaselineProvenance.Tests.ps1, Run.Exit = $true)

EXIT_CODE: 0

Output Summary:
- Passed=3 Failed=0 Total=3.
- All three spec.md AC12 scenarios pass: reject ProcessorName == "Unknown processor" (negative), reject missing sibling baseline.provenance.json (negative), accept runner-captured baseline with valid provenance (positive).
- Confirms scripts/benchmarks/Test-BaselineProvenance.ps1 satisfies the provenance contract.
- Fail-before evidence: docs/.../evidence/regression-testing/p1-t2-provenance-regression.md (EXIT_CODE 3).
