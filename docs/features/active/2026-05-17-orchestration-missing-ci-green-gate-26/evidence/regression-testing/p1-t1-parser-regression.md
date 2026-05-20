# Regression (expect-fail) — CI-gate parser (P1-T1)

Timestamp: 2026-05-19T10-15

Command: Invoke-Pester (Run.Path = tests/pester/orchestration/CiGate.Parser.Tests.ps1, Run.Exit = $true)

EXIT_CODE: 3 (non-zero; 3 tests failed)

Output Summary:
- Tests Passed: 2, Failed: 3.
- Test file: tests/pester/orchestration/CiGate.Parser.Tests.ps1 covers the five spec.md AC10 scenarios:
  1. all required checks success (positive) -> FAILED
  2. one required check failed (negative) -> FAILED
  3. one required check in progress (negative) -> FAILED
  4. malformed JSON input (error path) -> passed (throws)
  5. empty checks list (error path) -> passed (throws)
- Documented fail-before reason: the three behavioral assertions fail with CommandNotFoundException because scripts/orchestration/Invoke-CiGateParser.ps1 does not yet exist (Phase 5 delivers it). The two error-path assertions pass coincidentally because invoking a non-existent script also throws; after Phase 5 they will assert the implemented throw behavior.
- This is the expected [expect-fail] outcome: the suite is not green prior to implementation, and the failures are attributable to the absent target script, not to harness errors.
