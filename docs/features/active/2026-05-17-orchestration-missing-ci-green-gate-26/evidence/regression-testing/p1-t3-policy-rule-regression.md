# Regression (expect-fail) — modified-workflow-needs-green-run rule (P1-T3)

Timestamp: 2026-05-19T10-15

Command: Invoke-Pester (Run.Path = tests/pester/feature-review/ModifiedWorkflowNeedsGreenRun.Tests.ps1, Run.Exit = $true)

EXIT_CODE: 5 (non-zero; 5 tests failed)

Output Summary:
- Tests Passed: 0, Failed: 5.
- Test file: tests/pester/feature-review/ModifiedWorkflowNeedsGreenRun.Tests.ps1 covers the spec.md AC6 rule logic:
  1. .github/workflows change without evidence -> Blocking (FAILED)
  2. scripts/benchmarks change without evidence -> Blocking (FAILED)
  3. .github/actions change without evidence -> Blocking (FAILED)
  4. trigger-path change WITH green-run evidence -> not Blocking (FAILED)
  5. no trigger-path change -> not Blocking (FAILED)
- Documented fail-before reason: all five assertions fail with CommandNotFoundException because scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 does not yet exist. This validator implements the rule logic that the feature-review-workflow SKILL documents (Phase 4) and is the executable target for P5-T5. Its creation in Phase 5 is the mechanically-necessary step to make P5-T5 pass.
- This is the expected [expect-fail] outcome: failures are attributable to the absent target script, not to harness errors.
