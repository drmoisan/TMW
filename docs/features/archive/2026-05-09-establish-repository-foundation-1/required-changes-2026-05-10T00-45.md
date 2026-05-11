---
artifact: required-changes
feature: 2026-05-09-establish-repository-foundation-1
issue: 1
timestamp: 2026-05-10T00-45
trigger: P4-T5 Pester suite — single test failure reveals script-label bug not covered by remediation plan
---

# Required Changes — Plan Revision Request

## Context

While executing `[P4-T5]` (run Pester suite with coverage) of
`remediation-plan.2026-05-10T00-00.md`, the plan-authored test
`tests/powershell/validate-feature-review-coverage.Tests.ps1` fails on the case:

```
It 'works for each language label set' {
    foreach ($pair in @(
            @{ L = 'TypeScript'; T = 'TypeScript coverage row PASS' },
            @{ L = 'Python';     T = 'pytest coverage row PASS' },
            @{ L = 'CSharp';     T = '.NET coverage row PASS' }
        )) { ... }
}
```

Failure: `Expected $true, because language CSharp label set must match, but got $false.`

## Root Cause

In `.claude/hooks/validate-feature-review-coverage.ps1`, function
`Test-LanguageCoverageRow` defines:

```powershell
$languageLabelMap = @{
    ...
    'CSharp' = @('C#', 'CSharp', 'csharp', '\.NET', 'dotnet')
}
```

The function then builds the label pattern via:

```powershell
$labelPattern = '(?i)(' + (($labels | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')'
```

`[regex]::Escape('\.NET')` returns `\\\.NET`, which as a regex matches the literal
character sequence `\.NET` (backslash, dot, N, E, T). The audit text `.NET coverage
row PASS` contains no backslash, so this label entry never fires for any realistic
audit text.

## Status

- This is a latent bug in the production script `validate-feature-review-coverage.ps1`.
- The plan-authored test correctly asserts the *intended* behavior (`.NET` should be
  recognized as a CSharp label).
- The plan tasks under R1 do not include modifying the production script, only
  writing tests against it.
- 39 of 40 tests pass; line coverage is 38.85% — well below the 85% target — primarily
  because `Invoke-FeatureReviewCoverageValidation` (the main entrypoint, lines 334–447)
  has no test coverage at all. The plan only covers the helper functions.

## Plan Delta Required

Two adjustments are needed for the plan to complete cleanly. Either:

**Option A** (recommended; smallest change to make the plan's own test pass):
- Add a new task `[P4-T6]` that updates `.claude/hooks/validate-feature-review-coverage.ps1`
  line 271 from `'\.NET'` to `'.NET'` (remove the literal backslash). This is a
  one-character bug fix that makes the production label-matching behavior align with
  the plan-authored test expectation. Toolchain gate: format + analyzer.

**Option B** (smaller scope, no production-script edit):
- Modify task `[P4-T4]` test body to remove the `.NET` row from the "works for each
  language label set" iteration (test only against `'CSharp'` audit text, e.g.,
  `'CSharp coverage row PASS'`).

**Coverage gap (R1 floor)**:
- The plan as written tests only the helper functions. The 38.85% measured coverage is
  far below the 85% line / 75% branch floor required by R1.
- A new task `[P4-T7]` is required to add tests for `Invoke-FeatureReviewCoverageValidation`
  (the main hook entrypoint). Without this, the plan cannot satisfy its own R1 acceptance.
- Suggested test coverage:
  - empty / null `$RawPayload` returns Ok=false with the expected message.
  - malformed JSON returns Ok=false with the expected error.
  - empty `output` field returns Ok=false.
  - missing required artifact tokens (`policy-audit-path`, `code-review-path`,
    `feature-audit-path`) returns Ok=false with the right error per token.
  - artifact paths outside the canonical `docs/features/active/...` location are
    rejected.
  - mismatched feature folder or timestamp between policy-audit and code-review/
    feature-audit returns Ok=false.
  - changed-language enumeration paths against `artifacts/pr_context.summary.txt`.

## Requested Decision

The orchestrator/planner should choose Option A or Option B for the failing test, and
authorize the addition of `[P4-T7]` (or equivalent) coverage tests for the entrypoint
function. Until then, the plan's R1 acceptance criterion (line >= 85% / branch >= 75%)
is unverifiable.

Execution paused at `[P4-T5]` per execution rule #11.
