# Code Review: parallelize-ci-pipeline (Issue #46)

**Review Date:** 2026-06-01
**Reviewer:** feature-review agent
**Feature Folder:** `docs/features/active/2026-06-01-parallelize-ci-pipeline-46`
**Feature Folder Selection Rule:** Folder suffix `-46` matches the canonical issue number for this branch.
**Base Branch:** `main` (merge-base `ff6aa007fefcd24ff18b96240525d7c9bafd7d18`)
**Head Branch:** `TMW-wt-2026-06-01-09-51` (`04833fb3926080883d4ba7f02149ff1bb3373a26`)
**Review Type:** Post-remediation re-review

---

## Executive Summary

This branch parallelizes the PR CI orchestrator `.github/workflows/pr-pipeline.yml` by converting two serial per-language `needs:` lanes (a 7-job TypeScript lane and a 5-job .NET lane) into a fan-out. Every non-root gate stage is re-parented from its prior serial-lane predecessor to `needs: [tier-classification]`, so GitHub Actions can schedule the independent stages concurrently once the single root gate is green. The diff is small and surgical: 11 `needs:` lines change in `pr-pipeline.yml` and one description line changes in `.github/workflows/README.md`. No job is renamed, no callee (`_*.yml`) is added/removed/modified, no inline `steps:` are introduced, and reusable-workflow nesting stays at one level.

The reviewed evidence includes the live `git diff` against the merge-base, a re-run of `actionlint` (EXIT 0), a re-run of the Pester regression anchor `apply-branch-protection.Tests.ps1` (5/5 passed), the `modified-workflow-needs-green-run` validator (`IsBlocking:false`), and the green `workflow_dispatch` branch-head run (run 26760839329, head SHA `04833fb`, conclusion `success`) recorded in `evidence/qa-gates/green-run-branch-head.md`. The implementation quality is high for the scope: the change matches the spec's target graph exactly and preserves every stated invariant.

**What changed:**
`.github/workflows/pr-pipeline.yml` — `stage-2-lint` through `stage-7-integration` and `stage-2-dotnet-build` through `stage-5-dotnet-test` each move from `needs: [<prior-stage>]` to `needs: [tier-classification]`. `stage-e2e-smoke` moves from `needs: [stage-7-integration]` to `needs: [tier-classification]` while keeping its `if: contains(github.event.pull_request.labels.*.name, 'e2e:run')` guard and `secrets: inherit`. `stage-1-format`, `stage-1-dotnet-format`, and `tier-classification` are structurally unchanged (the two stage-1 jobs already depended only on the root; `tier-classification` is the root). `secret-scan` keeps no `needs:`. `.github/workflows/README.md` — the orchestrator bullet is rewritten from "chains every gate" to a description of the fan-out topology and the explicit fail-fast / runner-minute tradeoff.

**Top 3 risks:**
1. Loss of per-lane fail-fast economy increases concurrent runner-minute consumption when an early gate fails. This is an explicitly accepted tradeoff (user-story.md "Acknowledged Tradeoff"; README.md), not a defect.
2. Realized wall-clock savings depend on available runner concurrency in the repository/org; under heavy contention the fan-out may not fully parallelize. Documented in spec.md Dependencies/Touchpoints; not a code defect.
3. The `needs:` graph is evaluated only at GitHub Actions runtime, so no local unit test exercises it. This residual is mitigated by `actionlint` (resolves references, detects cycles) and the authoritative green branch-head run, which now exists.

**PR readiness recommendation:** **Go** — the change matches the spec's target graph exactly, preserves all invariants, passes static and regression checks, and the required green branch-head run is present and confirmed.

---

## Findings Table

| Severity | File | Location | Finding | Recommendation | Rationale | Evidence |
|---|---|---|---|---|---|---|
| Info | `.github/workflows/pr-pipeline.yml` | `needs:` edges (lines 18–66) | All 13 non-root gate stages now declare `needs: [tier-classification]`; `stage-e2e-smoke` retains its label guard and `secrets: inherit`; `secret-scan` retains no `needs:`. Matches spec.md target graph exactly. | None. | Confirms invariants #3–#8 and the intended fan-out. | Read of `pr-pipeline.yml`; `actionlint` EXIT 0; `evidence/qa-gates/qa-needs-graph.md` |
| Info | `.github/workflows/README.md` | Orchestrator bullet (line ~19) | Topology description updated to fan-out with the fail-fast / runner-minute tradeoff stated. | None. | Keeps documentation consistent with the new graph (general-code-change "update supporting documents"). | `git diff` of README.md |
| Info | `.github/scripts/apply-branch-protection.ps1`, `tests/powershell/apply-branch-protection.Tests.ps1` | n/a | Both untouched in the diff; the Pester anchor passes 5/5 unchanged, confirming no status-check-name drift (invariants #1/#2). | None. | Branch-protection contract is preserved. | Empty `git diff --name-only` for both paths; Pester 5/5 EXIT 0 |

No Blocker or Major findings. The single Blocker from the prior review (`modified-workflow-needs-green-run`) is resolved; see Verdict.

---

## Implementation Audit

**Instructions applied:** Only the relevant subsection is retained. No Python, TypeScript, C#, or new PowerShell implementation code changed in this diff; those language subsections are omitted as inapplicable. The change is YAML workflow orchestration plus a Markdown documentation edit.

### Workflow (YAML) implementation audit

#### What changed well

- The edit is the minimal change that achieves the goal. Only `needs:` values change; the structure, job keys, callee references, guards, and secrets passthrough are untouched. This is the simplest design that satisfies the requirement (general-code-change "Simplicity first").
- The fan-out is uniform and predictable: every non-root stage points at the single root gate, which makes the dependency graph trivially acyclic and easy to reason about. `actionlint` confirms all `needs:` references resolve and no cycle is introduced.
- The accepted tradeoff (loss of fail-fast economy for lower wall-clock time) is documented in `README.md` and `user-story.md`, so the behavior change is not silent.

#### Topology and contract notes

- `tier-classification` remains the single root (no `needs:`), preserving invariant #4 (environment/tier validation precedes all gates).
- `secret-scan` retains no `needs:` and runs unconditionally (invariant #5).
- `stage-e2e-smoke` retains `if: contains(github.event.pull_request.labels.*.name, 'e2e:run')` and `secrets: inherit` (invariant #6); only its artificial `needs: [stage-7-integration]` ordering edge was replaced with `needs: [tier-classification]`.
- Job keys (status-check contexts) are unchanged, so branch protection requires no reconfiguration (invariants #1/#2). The green branch-head run confirms the contexts emitted are the same set.

#### Error handling and logging

- Not applicable: no inline `run:`/`steps:` logic is added or modified. The `ci-workflows.md` deliberately-failing-nested-command rule does not apply because no `pwsh` step is added or changed.

---

## Test Quality Audit

This is a `needs:`-graph-only change with no coverable source, so there are no new unit tests (spec.md Test Strategy). Validation is static plus a runtime green run. The reviewed verification evidence is adequate for the scope.

### Reviewed test and QA artifacts

- `tests/powershell/apply-branch-protection.Tests.ps1` — asserts the required status-check context set; re-run unchanged during this re-review, 5/5 passed, EXIT 0. Serves as the regression anchor for invariant #2 (no status-check-name drift).
- `actionlint .github/workflows/pr-pipeline.yml` — re-run EXIT 0; confirms `needs:` references resolve to defined jobs and the graph is acyclic.
- `evidence/qa-gates/green-run-branch-head.md` — records the green `workflow_dispatch` run (run 26760839329, head SHA `04833fb`, success) with a per-job timeline showing all 12 gate stages starting within a ~2-second window after `tier-classification` completes, demonstrating post-root concurrent scheduling. `stage-e2e-smoke` skipped (label absent); `secret-scan` ran in parallel.
- `evidence/qa-gates/qa-needs-graph.md`, `evidence/qa-gates/qa-diff-scope.md`, `evidence/qa-gates/qa-actionlint.md`, `evidence/qa-gates/qa-apply-branch-protection-pester.md` — structural and scope confirmations consistent with the live diff.

### Quality assessment prompts

- **Determinism:** The branch-protection Pester test is deterministic (asserts a fixed context set; no clock/RNG/network dependency). The green-run timeline is a one-time runtime observation, appropriate for a runtime-only acceptance signal.
- **Isolation:** The regression anchor targets a single behavior (required-check context set). `actionlint` targets workflow validity in isolation.
- **Speed:** Pester run completed in under 1 second locally (719ms observed).
- **Diagnostics:** A status-check-name drift would fail the Pester anchor with a clear assertion; an unresolved `needs:` reference or cycle would fail `actionlint` with a specific message.

---

## Security / Correctness Checks

| Check | Status | Evidence |
|---|---|---|
| No secrets in code | PASS | No secrets added; `secret-scan` job and `secrets: inherit` on `stage-e2e-smoke` are unchanged. Diff is `needs:` edges plus one Markdown line. |
| No unsafe subprocess or command construction | N/A | No inline `run:`/`steps:` or command construction added or modified. |
| Input validation at boundaries | N/A | No runtime input handling changed; only the `needs:` dependency graph. |
| Error handling remains explicit | N/A | No `run:` script logic added; `ci-workflows.md` exit-code rule does not apply (no `pwsh` step added/modified). |
| Configuration / path handling is safe | PASS | `uses:` references and callee paths are unchanged; no new path handling introduced. |

---

## Research Log

No external research was required. All findings are grounded in the repository policy files, the live `git diff`, the workflow file contents, the re-run toolchain checks, the green-run evidence, and the feature scoping documents.

---

## Verdict

The change is ready for normal PR flow. It is a minimal, well-scoped `needs:`-graph refactor that matches the spec's target graph exactly and preserves every stated invariant (job names, status-check contexts, single root gate, unconditional `secret-scan`, label-gated `stage-e2e-smoke`, one-level nesting, no inline steps). Static validation (`actionlint` EXIT 0), the unchanged branch-protection regression anchor (Pester 5/5), and the diff-scope confinement all pass.

The single Blocker from the prior review — the absence of a green `pr-pipeline.yml` run against the branch head — is resolved. A green `workflow_dispatch` run (run 26760839329, head SHA `04833fb3926080883d4ba7f02149ff1bb3373a26`, conclusion `success`) is present and independently confirmed via `gh run list`, and the `modified-workflow-needs-green-run` validator now returns `IsBlocking:false`. There are zero remaining Blocker or Major findings. Recommendation: **Go**.
