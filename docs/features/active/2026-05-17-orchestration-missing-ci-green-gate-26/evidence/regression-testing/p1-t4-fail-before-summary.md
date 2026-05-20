# Fail-Before Summary (P1-T4)

Timestamp: 2026-05-19T10-15

Purpose: Confirm all three Phase 1 regression suites fail for the documented reason (target script/behavior absent), not for unrelated harness errors.

| Regression suite | Path | Failed/Total | Documented reason | Harness-error? |
|---|---|---|---|---|
| CI-gate parser | tests/pester/orchestration/CiGate.Parser.Tests.ps1 | 3/5 | scripts/orchestration/Invoke-CiGateParser.ps1 absent (CommandNotFoundException) | No |
| Baseline provenance | tests/pester/benchmarks/BaselineProvenance.Tests.ps1 | 3/3 | scripts/benchmarks/Test-BaselineProvenance.ps1 absent (CommandNotFoundException) | No |
| modified-workflow-needs-green-run | tests/pester/feature-review/ModifiedWorkflowNeedsGreenRun.Tests.ps1 | 5/5 | scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 absent (CommandNotFoundException) | No |

Analysis:
- Every failure is a CommandNotFoundException raised when invoking a target script that does not yet exist. No failure is caused by Pester discovery errors, syntax errors in the test files, or environment misconfiguration.
- The parser suite's two error-path tests (malformed JSON, empty checks) pass coincidentally because invoking a missing script also throws; after Phase 5 they will assert the implemented validator's throw behavior. The three behavioral assertions in that suite fail as expected.
- The provenance and policy-rule suites fail entirely, as expected before implementation.
- All test files parse and load successfully (Pester enumerated the It blocks), confirming the failures are behavioral/absence failures, not harness failures.

Conclusion: The fail-before condition is satisfied for all three [expect-fail] suites. Implementation in Phases 2-5 is expected to turn each suite green.
