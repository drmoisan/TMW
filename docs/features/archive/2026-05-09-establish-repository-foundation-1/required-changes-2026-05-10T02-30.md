---
artifact: required-changes
feature: 2026-05-09-establish-repository-foundation-1
issue: 1
plan-under-validation: docs/features/active/2026-05-09-establish-repository-foundation-1/remediation-plan.2026-05-10T02-00.md
timestamp: 2026-05-10T02-30
preflight-result: REVISIONS REQUIRED
---

# Required Changes — Preflight Validation of remediation-plan.2026-05-10T02-00.md

Preflight outcome: `PREFLIGHT: REVISIONS REQUIRED`.

The plan passes special checks A, B, D, E, and F, but fails special check C in
a narrow but consequential way: the verbatim-mandated rewritten body of
`tests/powershell/validate-quality-tiers.Tests.ps1` in `[P4-T12]` contains
self-contradictory dead code that will fail the same task's acceptance gate
(PSScriptAnalyzer clean) and will produce a misleading test helper.

## Gap 1 — `[P4-T12]` rewritten test body has dead/contradictory code in `Invoke-Validator`

**Location:** `[P4-T12]` rewritten body of
`tests/powershell/validate-quality-tiers.Tests.ps1`, inside the
`Invoke-Validator` helper function (lines 498–503 of the plan code block):

```powershell
if ([string]::IsNullOrEmpty($RepoRoot)) {
    $stdout = Invoke-QualityTiersValidation -ConfigPath $ConfigPath 6>&1
    $code = $LASTEXITCODE
    # Invoke-QualityTiersValidation returns an int; capture it directly:
    $code = Invoke-QualityTiersValidation -ConfigPath $ConfigPath
}
```

**Problems:**

1. The function is invoked twice in the no-`RepoRoot` branch. The first
   invocation's return value is captured into `$stdout` (with a stream
   redirection that does not match the function's actual output behavior),
   then immediately discarded. The second invocation is the one whose result
   is used. This violates determinism intent and runs the unit-under-test
   twice per test, which can mask side effects (e.g., the `Get-ChildItem`
   inventory branch when `RepoRoot` falls back to its default `Resolve-Path`
   value walking the live repo).
2. `$LASTEXITCODE` after a PowerShell function call is not the function's
   return value; it is whatever the previous external-process exit code was.
   The line `$code = $LASTEXITCODE` is misleading and immediately overwritten.
3. PSScriptAnalyzer rule `PSUseDeclaredVarsMoreThanAssignments` will flag
   `$stdout` as assigned but never used. `[P4-T12]` acceptance requires
   "format and analyze gates exit 0; no new diagnostics", so the verbatim
   body fails its own acceptance criterion on first run.
4. The `6>&1` stream merge is inappropriate for a function that returns
   `[int]` via `return`; information stream `6` is the host-information
   stream, unrelated to function return values.

**Required plan delta** — replace the four lines above with the single
correct invocation that already exists in the `else` branch pattern:

```powershell
if ([string]::IsNullOrEmpty($RepoRoot)) {
    $code = Invoke-QualityTiersValidation -ConfigPath $ConfigPath
}
else {
    $code = Invoke-QualityTiersValidation -ConfigPath $ConfigPath -RepoRoot $RepoRoot
}
```

After the fix, `Invoke-Validator` invokes the unit-under-test exactly once
per call, captures its `[int]` return directly, and produces no
`PSUseDeclaredVarsMoreThanAssignments` diagnostic.

No other content of `[P4-T12]` needs to change. The acceptance criterion
("file written verbatim; format and analyze gates exit 0") becomes
satisfiable with the corrected verbatim body.

## All other checks — pass

- A. Logic preservation in refactored bodies of
  `.githooks/check-conventional-commit.ps1` and
  `.github/scripts/validate-quality-tiers.ps1`: spot-checked against on-disk
  files at branch tip; every parameter handling, exit-code branch, message
  text, and regex pattern is preserved. The optional `-RepoRoot` parameter
  on `Invoke-QualityTiersValidation` defaults to the same `Resolve-Path`
  expression the original script computed inline, so CLI behavior is
  unchanged.
- B. Script-body guard `if ($MyInvocation.InvocationName -ne '.') { exit ... }`
  is present in both refactored script bodies.
- C. No `& pwsh -NoProfile -File` invocations remain in the rewritten test
  bodies. Both rewritten suites call the new advanced functions in-process.
  (Sub-issue noted in Gap 1 is about a different defect, not subprocess
  re-introduction.)
- D. Test scenario coverage in the rewrites is at least equal to the live
  test files: check-conventional-commit retains all 12 It blocks across
  Contexts (missing, empty/comment-only ×3, invalid ×2, valid ×6 including
  the foreach over 9 allowed types); validate-quality-tiers retains all 7
  It blocks (exit 2, 3, 4, 5, 6, live = 0, t1..t4 acceptance). No scenario
  regression.
- E. Branch-coverage policy language ("deferred per Pester JaCoCo writer
  limitation") appears consistently in `[P4-T13]`, `[P4-T8]` wrap-up,
  `[P7-T3]` pass criterion, the RP-6 AC R1 checkoff updates, and the Plan
  Coherence Self-Check. No spot demands a numeric branch% >= 75 assertion.
- F. No edits to `lefthook.yml` or `.github/workflows/*.yml`. `[P4-T14]`
  is verification-only and explicitly states "do not silently edit lefthook
  or CI in this pass".

## Counts

- Carried-over completed tasks (P0..P5 plus P4 T1..T7 + T5a):
  3 + 3 + 2 + 2 + 7 + 2 = 19.
- New / pending tasks (P4-T9..T14, P4-T8 wrap-up, P6-T1, P7-T1..T3): 11.
- Total tasks in plan: 30.

## Action

Apply the delta in Gap 1 to `[P4-T12]` only, write the corrected plan to the
same file path
(`docs/features/active/2026-05-09-establish-repository-foundation-1/remediation-plan.2026-05-10T02-00.md`),
and re-run preflight validation.
