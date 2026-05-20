# Regression (expect-fail) — baseline-provenance validator (P1-T2)

Timestamp: 2026-05-19T10-15

Command: Invoke-Pester (Run.Path = tests/pester/benchmarks/BaselineProvenance.Tests.ps1, Run.Exit = $true)

EXIT_CODE: 3 (non-zero; 3 tests failed)

Output Summary:
- Tests Passed: 0, Failed: 3.
- Test file: tests/pester/benchmarks/BaselineProvenance.Tests.ps1 covers the three spec.md AC12 scenarios:
  1. reject ProcessorName == "Unknown processor" (negative) -> FAILED
  2. reject missing sibling baseline.provenance.json (negative) -> FAILED
  3. accept runner-captured baseline with valid provenance (positive) -> FAILED
- Documented fail-before reason: all three assertions fail with CommandNotFoundException because scripts/benchmarks/Test-BaselineProvenance.ps1 does not yet exist (Phase 5 delivers it).
- Test design note: the validator exposes a pure-logic seam (-BaselineContent / -ProvenancePresent / -ProvenanceContent) so the rule logic is exercised without temp files, per .claude/rules/general-unit-test.md.
- This is the expected [expect-fail] outcome: failures are attributable to the absent target script, not to harness errors.
