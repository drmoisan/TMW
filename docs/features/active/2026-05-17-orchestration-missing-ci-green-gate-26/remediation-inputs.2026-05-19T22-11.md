# Remediation Inputs — orchestration-missing-ci-green-gate (Issue #26)

- Date: 2026-05-19T22-11
- Base: main @ b25e678bd82312301eaad971b1a04173915e2314
- Head: cdba24d9ea33bd2901c88be9745331eb178a9b5d
- Source artifacts: policy-audit.2026-05-19T22-11.md, code-review.2026-05-19T22-11.md, feature-audit.2026-05-19T22-11.md
- AC source (full-bug): spec.md

## Why remediation is triggered

1. Blocking policy finding: `modified-workflow-needs-green-run` fires on this branch because the diff adds `scripts/benchmarks/Test-BaselineProvenance.ps1` (matches `scripts/benchmarks/**`) and no green workflow run against head SHA cdba24d is present.
2. AC15 is unmet (no PR / no green PR Pipeline run recorded against the head SHA).
3. AC13 is PARTIAL (the named python + pester mirror-contract test suite does not exist; absent mirror trees were not created).

Note: items 1 and 2 are not code defects. They are sequencing gates that clear once a PR is opened and a green run is recorded against the head SHA. The deliverable code is complete and passes the local toolchain.

## Enumerated fix list

### R1 — Clear the `modified-workflow-needs-green-run` Blocking finding (and AC15)
- Required action (orchestrator S8/S9 lifecycle): open the PR for `feature/orchestration-missing-ci-green-gate-26`, then run S9 to obtain a green PR Pipeline (or a green `workflow_dispatch` run) against head SHA cdba24d9ea33bd2901c88be9745331eb178a9b5d.
- Record the resulting `ci_gate` object (head_sha, pr_pipeline_run_id, pr_pipeline_run_url, conclusion=success, verified_at) in artifacts/orchestration/orchestrator-state.json and set `step9_status: "passed"` and `last_verified_ci_sha` to the head SHA.
- Place the green-run evidence (run URL + conclusion + matching head SHA) where the policy audit can cite it, then re-run the rule self-check.
- Expected behavior after fix: `scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 -ChangedFiles <branch diff> -GreenRunEvidencePresent $true` returns `IsBlocking=$false`.
- Verification commands:
  - `gh pr checks --required --json bucket,name,state,link,workflow` against the PR head SHA → all buckets `pass`.
  - `pwsh -NoProfile -Command "& ./scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 -ChangedFiles (git diff --name-only b25e678..<head>) -GreenRunEvidencePresent $true"` → IsBlocking=False.
  - Check off AC15 `[x]` in spec.md only after the green run against the head SHA is recorded.

### R2 — Resolve AC13 mirror-contract clause
- Required action: either (a) add the python + pester mirror-contract test suite that AC13 names (so the clause is demonstrable) and confirm it passes, or (b) if no such suite is intended to exist, correct the AC13 text/scope so it does not assert a non-existent test suite, and document the authoritative mirror set (only existing mirror trees are synced).
- Decision needed (do not guess): is `.codex/` expected to carry a skills/rules mirror tree at all? The current `.codex/` has `agents/`, `hooks/`, `prompts/` but no `skills/` or `rules/`. spec.md Scope lists `.codex/` as a resync target; the mirror map records it as absent. The remediation planner must surface this as an explicit decision rather than silently accepting either reading.
- Expected behavior after fix: AC13 is either fully demonstrable (suite exists and passes, mirrors complete) or its text matches the authoritative mirror policy with no dangling test-suite reference.
- Verification commands:
  - If suite added: run the python mirror-contract test (`pytest <path>`) and the pester mirror-contract test (`Invoke-Pester <path>`) → pass.
  - Re-verify SHA-256 parity for every source/mirror pair.

## Do-not-do list

- Do not weaken or remove the `modified-workflow-needs-green-run` rule, the S9 gate, or the fifth PR Creation Gate condition to make the Blocking finding disappear. The finding must be cleared by a real green run against the head SHA.
- Do not check off AC15 in spec.md until a green PR Pipeline (or workflow_dispatch) run against the head SHA is recorded in the ci_gate object.
- Do not fabricate a mirror-contract test that trivially passes; if AC13's named suite does not exist, escalate the scope decision rather than papering over it.
- Do not modify policy documents under `.claude/rules/` or `.github/instructions/` as part of remediation.
- Do not narrow scope to a subset of changed files or mark any changed language's coverage as out of scope.
- Do not introduce temp files in tests or add sleeps/retries to stabilize anything.

## Handoff

- `${spec}` = docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/remediation-inputs.2026-05-19T22-11.md (authoritative)
- `${file}` = docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/remediation-plan.2026-05-19T22-11.md (target plan)
- Delegate plan creation to `atomic_planner` to produce a deterministic atomic plan with phases and `[P#-T#]` IDs.
