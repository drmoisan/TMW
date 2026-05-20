# Code Review — orchestration-missing-ci-green-gate (Issue #26)

- Date: 2026-05-19T22-11
- Base: main @ b25e678bd82312301eaad971b1a04173915e2314
- Head: cdba24d9ea33bd2901c88be9745331eb178a9b5d
- Scope: PowerShell validators and Pester tests; skill and rule Markdown changes.

## Executive Summary

The three new PowerShell validators are small, single-purpose, and follow the repository's seam guidance: pure logic is separated from I/O so each script is unit-testable without invoking `gh` or touching the filesystem. Strict mode and stop-on-error are set consistently, and error paths throw specific messages. Test coverage is thorough (100% line on production scripts, both arms of every conditional exercised). No blocking code-quality defects were found. The findings below are minor or advisory; none block merge on code-quality grounds. The only merge-blocking item for this branch is the policy-level `modified-workflow-needs-green-run` finding documented in the policy audit, which is cleared by a green run rather than a code change.

The Markdown deliverables (orchestrate S9 step, checkpoint schema, fifth PR-gate condition, the feature-review policy rule, and the two new rule files) are accurate to the spec and internally consistent.

## Findings Table

| Severity | File | Location | Finding | Recommendation | Rationale | Evidence |
|---|---|---|---|---|---|---|
| Info | scripts/orchestration/Invoke-CiGateParser.ps1 | L90-97 (bucket switch) | An unrecognized bucket value is mapped to `pending`, which keeps S9 polling rather than failing closed. For a required-checks gate, an unknown state is arguably safer treated as non-success-but-not-pass. Current behavior is documented and tested (`unknown bucket -> pending`). | Consider whether an unknown bucket should be `failure` (fail-closed) instead of `pending` to avoid an indefinite poll on an unexpected `gh` schema change. At minimum, ensure the S9 poll timeout (documented in the orchestrate SKILL) bounds this case. | The orchestrate SKILL already bounds pending via a poll timeout that converts to `failed_remediation_required`, so the risk is mitigated; this is a design observation, not a defect. | Invoke-CiGateParser.ps1 L94-97; orchestrate SKILL S9 step 4 (poll timeout). |
| Info | scripts/orchestration/Invoke-CiGateParser.ps1 | L90-92 (`skipping` -> continue) | A `skipping` bucket is treated as pass-equivalent (does not block success). This matches GitHub's semantics where skipped required checks do not fail a PR, but it is an implicit policy choice. | Add a one-line comment stating that `skipping` is intentionally pass-equivalent per branch-protection semantics. | Improves maintainability; reviewers otherwise have to infer the intent. | Invoke-CiGateParser.ps1 L91-92. |
| Info | scripts/benchmarks/Test-BaselineProvenance.ps1 | L92-108 | Provenance field validation only runs when `ProvenanceContent` is supplied. In the Content parameter set a caller can pass `ProvenancePresent=$true` with empty `ProvenanceContent`, and the required-field check is skipped. This is exercised correctly via the Path set (which always reads content), and is a deliberate seam for the pure-logic path. | Optionally document that an empty `ProvenanceContent` with `ProvenancePresent=$true` validates presence only, not field completeness. | The Path (production) path always supplies content, so production behavior is complete; the gap is only in the test-only seam. | Test-BaselineProvenance.ps1 L92; tests cover both present-with-content and missing cases. |
| Info | scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 | L45-61 | Trigger matching uses `StartsWith` on normalized prefixes. This correctly matches the three glob roots and is case-insensitive. Paths are normalized from backslash to forward slash before comparison. | None required. Behavior matches the rule globs precisely. | Confirms the rule fires on exactly the intended path roots and not on lookalikes. | Independent run: matched `scripts/benchmarks/Test-BaselineProvenance.ps1` on this branch's diff. |
| Info | tests/pester/benchmarks/BaselineProvenance.Tests.ps1 | L107-127 | Path-set tests mock `Test-Path`/`Get-Content`. This complies with the no-temp-files rule and the mocking guidance (filesystem adapters mocked, not executables). Mock parameter filters use `"$LiteralPath"` string coercion. | None required. | Confirms determinism and Test Explorer parity without temp files. | tests pass (26/26). |

## Strengths

- Clean separation of pure logic from I/O across all three validators, enabling deterministic unit tests without `gh` or temp files.
- Consistent use of `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`, and specific `throw` messages.
- Comprehensive scenario coverage including error paths (malformed JSON, empty list) and edge cases (single-object normalization, unknown bucket, partial provenance fields).
- The `NowProvider` clock seam in the parser makes `verified_at` deterministic and is tested explicitly.

## Merge-Blocking Code Findings

None on code-quality grounds. The branch's single Blocking item is the policy-level `modified-workflow-needs-green-run` finding (see policy-audit.2026-05-19T22-11.md and remediation-inputs.2026-05-19T22-11.md), which requires a green run against the head SHA and is not addressed by a code change.
