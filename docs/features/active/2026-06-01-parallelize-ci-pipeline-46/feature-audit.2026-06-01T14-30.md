# Feature Audit: parallelize-ci-pipeline (Issue #46)

**Audit Date:** 2026-06-01
**Feature Folder:** `docs/features/active/2026-06-01-parallelize-ci-pipeline-46`
**Base Branch:** `main` (commit `ff6aa007fefcd24ff18b96240525d7c9bafd7d18`)
**Head Branch:** `TMW-wt-2026-06-01-09-51` (commit `736b4202d118eb326f8a21f9456b4527c69f967b`)
**Work Mode:** `full-feature`
**Audit Type:** Initial acceptance review

---

## Scope and Baseline

- **Base branch:** `main` (commit `ff6aa007fefcd24ff18b96240525d7c9bafd7d18`)
- **Head branch/commit:** `TMW-wt-2026-06-01-09-51` (commit `736b4202d118eb326f8a21f9456b4527c69f967b`)
- **Merge base:** `ff6aa007fefcd24ff18b96240525d7c9bafd7d18`
- **Evidence sources:**
  - Primary: `artifacts/pr_context.summary.txt`
  - Secondary baseline diff: `artifacts/pr_context.appendix.txt`
  - Feature evidence: `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/**`
  - Additional evidence: `git diff ff6aa00..736b420`; current `.github/workflows/pr-pipeline.yml`; `Test-ModifiedWorkflowNeedsGreenRun.ps1` output; `gh run list`.
- **Feature folder used:** `docs/features/active/2026-06-01-parallelize-ci-pipeline-46`
- **Requirements source:** `spec.md` (Definition of Done) and `user-story.md` (Acceptance Criteria) — both authoritative under `full-feature`.
- **Work mode resolution note:** `issue.md` line 11 declares `- Work Mode: full-feature`. Under `full-feature`, AC sources are `spec.md` and `user-story.md`. `issue.md` "Acceptance Criteria (early draft)" is explicitly labeled a draft and is not the authoritative source for `full-feature`.
- **Scope note:** Scope is the full branch diff against `main`. The diff is a `needs:`-graph-only change to `pr-pipeline.yml` plus a one-line README description update, with feature scoping docs and evidence. No coverage-bearing source changed. The authoritative green branch-head run is produced by the orchestrator S9 gate after PR creation and is not yet present.

---

## Acceptance Criteria Inventory

**Authoritative AC source files for this run:**
- `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/spec.md` — Definition of Done (primary, checkbox-backed)
- `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/user-story.md` — Acceptance Criteria (primary, checkbox-backed)

### From spec.md — Definition of Done

1. `pr-pipeline.yml` `needs:` graph re-parents every gate stage to `needs: [tier-classification]`; no artificial serial lane edge remains.
2. `stage-e2e-smoke` re-parented to `needs: [tier-classification]` with its `e2e:run` label gate and `secrets: inherit` retained.
3. `secret-scan` still runs unconditionally (no `needs:`, no `if:`).
4. Job names and required status-check contexts unchanged; `apply-branch-protection.ps1` and its test are untouched and pass.
5. No new callee, no inline `steps:` in the orchestrator, nesting stays at one level.
6. `actionlint` / YAML validity passes for `pr-pipeline.yml`.
7. Green `pr-pipeline.yml` run produced against the branch head (S9 / `modified-workflow-needs-green-run`), with concurrent post-root scheduling visible in the run timeline.
8. `.github/workflows/README.md` updated to describe the fan-out topology and the fail-fast / runner-minute tradeoff.

### From user-story.md — Acceptance Criteria

A. After `tier-classification`, all independent TypeScript-lane and .NET-lane stages are schedulable in parallel; no artificial serial `needs:` chain remains in `pr-pipeline.yml`.
B. Every non-root stage has `needs: [tier-classification]` (or a justified genuine dependency), so the environment/tier gate still runs first.
C. Job names in `pr-pipeline.yml` are unchanged, and the required status-check contexts remain identical to the current set (`tier-classification`, `stage-1-format`, `stage-2-lint`, `stage-3-typecheck`, `stage-4-architecture`, `stage-5-test`, `stage-6-contract`, `stage-7-integration`).
D. `secret-scan` continues to run unconditionally; `stage-e2e-smoke` remains label-gated on `e2e:run`.
E. A green `pr-pipeline.yml` run against the branch head is produced, with the run timeline showing the gate stages starting concurrently after `tier-classification` rather than serially.
F. `tests/powershell/apply-branch-protection.Tests.ps1` continues to pass unchanged (confirming no status-check-name drift).

---

## Acceptance Criteria Evaluation

| # | Criterion | Status | Evidence | Verification command(s) | Notes |
|---|-----------|--------|----------|--------------------------|-------|
| 1 | DoD: every gate re-parented to root; no serial lane edge remains | PASS | `pr-pipeline.yml` lines 18-66: all gate stages `needs: [tier-classification]`; diff shows 11 edges re-parented from serial predecessors. | `git diff ff6aa00..736b420 -- .github/workflows/pr-pipeline.yml` | `stage-1-format`/`stage-1-dotnet-format` already on root in baseline. |
| 2 | DoD: e2e-smoke re-parented to root, label gate + secrets retained | PASS | `pr-pipeline.yml:62-66`: `needs: [tier-classification]`, `if: contains(...'e2e:run')`, `secrets: inherit`. | Read `pr-pipeline.yml` | Prior `needs: [stage-7-integration]` removed (artificial ordering). |
| 3 | DoD: secret-scan unconditional (no needs, no if) | PASS | `pr-pipeline.yml:68-69`: `secret-scan` has only `uses:`; no `needs:`/`if:`. | Read `pr-pipeline.yml` | Unchanged from baseline. |
| 4 | DoD: job names + contexts unchanged; branch-protection files untouched and pass | PASS | `git diff --name-only` for the two branch-protection paths is empty; Pester anchor EXIT_CODE 0. | `git diff --name-only ff6aa00..736b420 -- .github/scripts/apply-branch-protection.ps1 tests/powershell/apply-branch-protection.Tests.ps1`; `evidence/qa-gates/qa-apply-branch-protection-pester.md` | Job keys unchanged in diff. |
| 5 | DoD: no new callee, no inline steps, nesting stays one level | PASS | `git diff --name-only` shows no `_*.yml` changed; orchestrator jobs are `uses:`+`needs:`/`if:`/`secrets:` only. | `git diff --name-only ff6aa00..736b420 -- '.github/workflows/_*.yml'` (empty) | Invariants #7/#8 preserved. |
| 6 | DoD: actionlint / YAML validity passes | PASS | `evidence/qa-gates/qa-actionlint.md`: EXIT_CODE 0 (2026-06-01T14-06). | `actionlint .github/workflows/pr-pipeline.yml` | Confirms references resolve, no cycle. |
| 7 | DoD: green branch-head run with concurrent post-root scheduling | FAIL | `gh run list --workflow=pr-pipeline.yml --branch TMW-wt-2026-06-01-09-51` returned `[]`. | `gh run list ...`; `Test-ModifiedWorkflowNeedsGreenRun.ps1` => `IsBlocking:true` | Produced by orchestrator S9 gate after PR creation; not yet present. |
| 8 | DoD: README updated for fan-out topology + tradeoff | PASS | `README.md` diff replaces the orchestrator line with a fan-out description and the runner-minute tradeoff. | `git diff ff6aa00..736b420 -- .github/workflows/README.md` | Matches user-story.md tradeoff. |
| A | US: independent stages schedulable in parallel; no serial chain | PASS | Same as #1. | `git diff ...`; read `pr-pipeline.yml` | Schedulability is structural; concurrency realized at runtime (see E). |
| B | US: every non-root stage `needs: [tier-classification]` | PASS | All 13 gate stages + e2e-smoke on root; `tier-classification` is the only root. | Read `pr-pipeline.yml` | No justified additional dependency needed today. |
| C | US: job names + required contexts identical to current set | PASS | Job keys unchanged in diff; branch-protection test green and untouched. | `git diff ...`; `evidence/qa-gates/qa-apply-branch-protection-pester.md` | Same evidence as #4. |
| D | US: secret-scan unconditional; e2e-smoke label-gated | PASS | `secret-scan` no `needs:`/`if:`; `stage-e2e-smoke` retains `e2e:run` gate. | Read `pr-pipeline.yml` | Combines #2 and #3. |
| E | US: green branch-head run with concurrent post-root timeline | FAIL | Same as #7; no run exists. | `gh run list ...` | S9 gate; not yet present. |
| F | US: apply-branch-protection.Tests.ps1 passes unchanged | PASS | Pester EXIT_CODE 0; test file untouched. | `evidence/qa-gates/qa-apply-branch-protection-pester.md`; `git diff --name-only` | Regression anchor for no name drift. |

---

## Summary

**Overall Feature Readiness:** NEEDS REVISION (one outstanding S9 gate item; not a code defect)

**Criteria summary:**
- **PASS:** 12 criteria (DoD 1-6, 8; US A, B, C, D, F)
- **PARTIAL:** 0 criteria
- **UNVERIFIED:** 0 criteria
- **FAIL:** 2 criteria (DoD 7; US E — the same green branch-head run requirement expressed in both source files)

**Top gaps preventing PASS:**

1. No green `pr-pipeline.yml` run against branch head `736b420` exists yet (DoD 7 / US E). By policy design this run is produced by the orchestrator S9 gate after PR creation; it cannot be produced during local review. It is the only blocking gap and is a pre-merge runtime gate, not a defect in the authored `needs:`-graph change.

**Recommended follow-up verification steps:**

1. After PR creation, the orchestrator runs `pr-pipeline.yml` against the branch head (PR-context or `workflow_dispatch`) and confirms a `success` conclusion with the run timeline showing post-root concurrent scheduling. This closes DoD 7 / US E and satisfies `modified-workflow-needs-green-run`.
2. When interpreting that run, confirm `stage-e2e-smoke` status is `skipped` if the `e2e:run` label is absent (expected) and `success` if present.

---

## Acceptance Criteria Check-off

Per the acceptance-criteria tracking rules: PASS criteria represented as markdown checkboxes are checked off in the source files; FAIL criteria remain unchecked.

The source files already had all PASS criteria checked `[x]` (set during execution) and both green-run criteria unchecked `[ ]`. The reviewer verified each PASS criterion against branch evidence and confirms the existing checkbox states are correct. No checkbox state required modification: the two FAIL items (DoD 7, US E) are correctly left `[ ]`, and the 12 PASS items are correctly `[x]`.

### AC Status Summary

- Source: `spec.md` (Definition of Done), `user-story.md` (Acceptance Criteria)
- Total AC items: 14 (8 in spec.md DoD + 6 in user-story.md)
- Checked off (delivered): 12
- Remaining (unchecked): 2
- Items remaining:
  - spec.md DoD: "Green `pr-pipeline.yml` run produced against the branch head (S9 / `modified-workflow-needs-green-run`), with concurrent post-root scheduling visible in the run timeline."
  - user-story.md: "A green `pr-pipeline.yml` run against the branch head is produced, with the run timeline showing the gate stages starting concurrently after `tier-classification` rather than serially."

| Source File | Total AC | Checked (PASS) | Unchecked | Notes |
|-------------|----------|----------------|-----------|-------|
| `spec.md` (Definition of Done) | 8 | 7 | 1 | Checkbox-backed; item 7 (green run) remains `[ ]`. |
| `user-story.md` (Acceptance Criteria) | 6 | 5 | 1 | Checkbox-backed; item E (green run) remains `[ ]`. |

No source-file checkbox change was made because the existing states already correctly reflect verified delivery (12 PASS checked, 2 green-run FAIL unchecked).
