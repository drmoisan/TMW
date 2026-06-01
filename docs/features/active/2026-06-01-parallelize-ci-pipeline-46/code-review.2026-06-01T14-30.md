# Code Review: parallelize-ci-pipeline (Issue #46)

**Review Date:** 2026-06-01
**Reviewer:** feature-review agent
**Feature Folder:** `docs/features/active/2026-06-01-parallelize-ci-pipeline-46`
**Feature Folder Selection Rule:** Active folder whose issue-number suffix (`-46`) matches the canonical issue and the primary changed scoping docs (spec.md, user-story.md).
**Base Branch:** `main` (merge-base `ff6aa007fefcd24ff18b96240525d7c9bafd7d18`)
**Head Branch:** `TMW-wt-2026-06-01-09-51` (`736b4202d118eb326f8a21f9456b4527c69f967b`)
**Review Type:** Initial review

---

## Executive Summary

This change converts the PR CI orchestrator `.github/workflows/pr-pipeline.yml` from two long serial `needs:` lanes (a 7-job TypeScript lane and a 5-job .NET lane) into a fan-out graph where every non-root gate stage declares `needs: [tier-classification]`. Because each callee (`_*.yml`) is self-contained — performing its own `actions/checkout` and composite-action environment setup — the prior serial edges were artificial ordering rather than real data dependencies. After the change, GitHub Actions can schedule the independent stages concurrently once the single root gate is green, reducing total pipeline wall-clock time.

The diff is small and precise. Eleven gate stages are re-parented (`stage-2-lint`, `stage-3-typecheck`, `stage-4-architecture`, `stage-5-test`, `stage-6-contract`, `stage-7-integration`, `stage-2-dotnet-build`, `stage-3-dotnet-typecheck`, `stage-4-dotnet-architecture`, `stage-5-dotnet-test`, and `stage-e2e-smoke`); `stage-1-format` and `stage-1-dotnet-format` already pointed at `tier-classification` in baseline and are unchanged. `tier-classification` (root, no `needs:`) and `secret-scan` (no `needs:`, unconditional) are untouched. `stage-e2e-smoke` retains its `e2e:run` label guard and `secrets: inherit`. `.github/workflows/README.md` is updated with one description line covering the fan-out topology and the accepted fail-fast / runner-minute tradeoff. No production code, test code, or `_*.yml` callee changed.

**What changed:**
- `.github/workflows/pr-pipeline.yml`: +11/-11, `needs:` edges only (verified by `git diff`).
- `.github/workflows/README.md`: +1/-1, orchestrator topology description.
- Feature scoping docs and evidence under the feature folder.

**Top 3 risks:**
1. The authoritative green `pr-pipeline.yml` run against branch head `736b420` does not yet exist; runtime correctness of the new graph (no cycle, single root reachable, concurrent post-root scheduling) is confirmed statically by actionlint but not yet by a live run. This is the S9 gate.
2. Loss of per-lane fail-fast economy: an early gate failure (for example format) no longer short-circuits later same-lane stages, increasing concurrent runner-minute consumption. This is an explicitly accepted tradeoff (user-story.md), not a defect.
3. `stage-e2e-smoke` green status in a branch-head run depends on the `e2e:run` label being present on the PR; without the label it is skipped, which is correct behavior but should be confirmed in the S9 run interpretation.

**PR readiness recommendation:** **Conditional Go** — The change is correctly scoped and statically validated; merge is gated on the orchestrator S9 green branch-head run satisfying `modified-workflow-needs-green-run`.

---

## Findings Table

| Severity | File | Location | Finding | Recommendation | Rationale | Evidence |
|---|---|---|---|---|---|---|
| Blocker | `.github/workflows/pr-pipeline.yml` | whole file (workflow change) | No green `pr-pipeline.yml` run against branch head `736b420` is present, so `modified-workflow-needs-green-run` fires. | Produce the orchestrator S9 green branch-head run (PR-context or `workflow_dispatch`) before merge; confirm post-root concurrent scheduling in the timeline. | Workflow changes are not exercised by any local test; the green run is the only authoritative runtime check. By policy design this run is produced after PR creation. | `Test-ModifiedWorkflowNeedsGreenRun.ps1` => `IsBlocking:true`; `gh run list ... => []`; `evidence/qa-gates/qa-greenrun-handoff.md` |
| Info | `.github/workflows/pr-pipeline.yml` | line 64 | `stage-e2e-smoke` retains `if: contains(...'e2e:run')`; it is skipped on PRs without the label. | None; intended behavior (invariant #6). | Reviewer interpreting the S9 run must not treat a skipped e2e-smoke as a failure when the label is absent. | `pr-pipeline.yml:62-66`; spec.md invariant #6 |
| Info | `.github/workflows/pr-pipeline.yml` | lines 14-16, 42-44 | `stage-1-format` and `stage-1-dotnet-format` already had `needs: [tier-classification]` in baseline; they correctly do not appear in the diff. | None. | Confirms the diff is minimal and the fan-out invariant (every non-root stage on the root) holds for the full graph, not just the edited lines. | `git show ff6aa00:.github/workflows/pr-pipeline.yml`; current `pr-pipeline.yml:14-16` |

No Major or Minor findings. The single Blocker is the expected, policy-designed S9 green-run gate, not a defect in the authored change.

---

## Implementation Audit

This change touches no Python, TypeScript, PowerShell, or C# source. The only edited executable artifact is a GitHub Actions orchestrator workflow (YAML); the language-specific implementation subsections are not applicable and are omitted. The relevant review is of the workflow `needs:` graph itself.

### Workflow (GitHub Actions) audit

#### What changed well

- The change is the minimal edit that achieves the stated goal: only `needs:` values change. No job is added, removed, merged, or renamed; no inline `steps:` are introduced (invariant #8 preserved); reusable-workflow nesting stays at one level (invariant #7).
- The fan-out is uniform and correct: every non-root gate now depends only on `tier-classification`, and `tier-classification` remains the single root (no `needs:`), so the environment/tier gate provably precedes all gates (invariant #4). Confirmed by reading the full file, not only the diff hunks.
- `secret-scan` is correctly left with no `needs:` and no `if:` guard (invariant #5), so it continues to run unconditionally.
- `stage-e2e-smoke` re-parenting preserves both its `e2e:run` label gate and `secrets: inherit` (invariant #6). The prior `needs: [stage-7-integration]` edge was correctly identified as artificial ordering; e2e-smoke is self-contained and does not consume integration output.

#### Graph safety notes

- No dependency cycle is possible: all gates point at a single root that itself has no `needs:`. actionlint confirms references resolve and no cycle exists (EXIT_CODE 0).
- Job keys (status-check contexts) are unchanged, so branch-protection required-check contexts do not drift (invariants #1/#2). The branch-protection script and its test are untouched, confirmed by an empty `git diff --name-only` for those two paths.

#### Documentation

- `README.md` accurately describes the new topology and states the accepted runner-minute-versus-wall-clock tradeoff, matching user-story.md "Acknowledged Tradeoff." The "Branch-protection rename procedure" elsewhere in the README correctly remains dormant because job names/contexts do not change (spec.md Non-Goals).

---

## Test Quality Audit

No automated test exercises a workflow `needs:` graph; GitHub Actions evaluates it only at runtime. Per spec.md Test Strategy, no new unit tests are introduced, and that is the correct disposition for this change type. Validation is static plus a runtime green run.

### Reviewed test and QA artifacts

- `evidence/qa-gates/qa-actionlint.md` — `actionlint .github/workflows/pr-pipeline.yml`, EXIT_CODE 0 (2026-06-01T14-06). Proves the `needs:` references resolve to defined jobs and no cycle is introduced.
- `evidence/qa-gates/qa-apply-branch-protection-pester.md` — `Invoke-Pester ... apply-branch-protection.Tests.ps1 -CI`, EXIT_CODE 0. Regression anchor for invariant #2 (no status-check-name drift), run unchanged.
- `evidence/qa-gates/qa-needs-graph.md` — structural confirmation that each job key's `needs:` matches the required end-state. Independently re-verified by reading `pr-pipeline.yml`.
- `evidence/qa-gates/qa-diff-scope.md` — confirms the diff is confined to the two permitted non-doc files.
- `evidence/qa-gates/qa-greenrun-handoff.md` — documents that the authoritative green branch-head run is produced by the orchestrator S9 gate after PR creation (the chicken-and-egg case the policy anticipates).

### Quality assessment prompts

- **Determinism:** The static checks (actionlint, structural graph read) are fully deterministic. The Pester anchor is deterministic and unchanged.
- **Isolation:** Each evidence gate targets one verifiable property (resolves/no-cycle, name-drift, graph shape, scope).
- **Speed:** Static checks are fast; the only slow item is the runtime green run, which is the intended S9 acceptance signal.
- **Diagnostics:** A failed S9 run would identify the failing gate by job key, which is preserved by this change.

---

## Security / Correctness Checks

| Check | Status | Evidence |
|---|---|---|
| No secrets in code | ✅ PASS | Only `needs:` edges and one Markdown line changed; no secret literals. `secrets: inherit` on `stage-e2e-smoke` is pre-existing and unchanged. |
| No unsafe subprocess or command construction | ✅ PASS | No `run:` step added or modified; orchestrator contains only `uses:`/`needs:`/`if:`/`secrets:` (invariant #8). |
| Input validation at boundaries | N/A | No code boundary changed. |
| Error handling remains explicit | ✅ PASS | `ci-workflows.md` deliberately-failing-nested-command rule does not apply — no inline `pwsh` step added or modified. |
| Configuration / path handling is safe | ✅ PASS | `needs:` targets reference existing defined job keys; actionlint confirms resolution and acyclicity. |

---

## Research Log

No external research was required. All conclusions derive from the branch diff, the full current `pr-pipeline.yml`, the feature scoping docs, the recorded evidence artifacts, and the `Test-ModifiedWorkflowNeedsGreenRun.ps1` validator output.

---

## Verdict

The change is a correctly scoped, minimal `needs:`-graph refactor that preserves every stated invariant: job keys and required status-check contexts are unchanged, the single root gate is preserved, `secret-scan` remains unconditional, `stage-e2e-smoke` keeps its label gate and secrets, no callee or inline step is touched, and nesting stays at one level. Static validation (actionlint), the branch-protection regression anchor (Pester), structural graph verification, and diff-scope confinement all pass. The only outstanding item is the authoritative green `pr-pipeline.yml` run against the branch head, which `modified-workflow-needs-green-run` requires and which the orchestrator produces at the S9 gate after PR creation.

The change is ready for PR creation. It is not yet ready to merge until the S9 green branch-head run exists and shows post-root concurrent scheduling. Recommendation: **Conditional Go**.
