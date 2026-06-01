# Remediation Inputs: parallelize-ci-pipeline (Issue #46)

**Entry Timestamp:** 2026-06-01T14-30
**Feature Folder:** `docs/features/active/2026-06-01-parallelize-ci-pipeline-46`
**Base Branch:** `main` (`ff6aa007fefcd24ff18b96240525d7c9bafd7d18`)
**Head Branch:** `TMW-wt-2026-06-01-09-51` (`736b4202d118eb326f8a21f9456b4527c69f967b`)

## Pointer to Audit Artifacts That Produced These Findings

- `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/policy-audit.2026-06-01T14-30.md`
- `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/code-review.2026-06-01T14-30.md`
- `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/feature-audit.2026-06-01T14-30.md`

## Summary

The change is correctly scoped and statically validated. There is exactly one blocking finding: the `modified-workflow-needs-green-run` policy fires because the branch diff modifies `.github/workflows/**` and no green `pr-pipeline.yml` run against branch head `736b4202d118eb326f8a21f9456b4527c69f967b` is yet present. This maps to acceptance criteria spec.md DoD #7 and user-story.md #E (the same green-run requirement in both authoritative sources).

This is a runtime acceptance gate, not a code defect in the authored `needs:`-graph change. By the policy's own design (see `feature-review-workflow` SKILL and spec.md Risks & Mitigations), the authoritative green branch-head run is produced by the orchestrator at the S9 gate after PR creation. No source change is required to clear it; the remediation is to produce and record the green run.

## Enumerated Fix List

### F1 — Produce and record a green `pr-pipeline.yml` run against the branch head (Blocking)

- **Affected acceptance criteria:** spec.md DoD #7; user-story.md #E.
- **File paths involved:**
  - `.github/workflows/pr-pipeline.yml` (the modified workflow under test; do not edit further)
  - Evidence to record on completion: `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/` (new green-run evidence file, canonical path)
- **Expected behavior:** A `pr-pipeline.yml` run whose head SHA equals `736b4202d118eb326f8a21f9456b4527c69f967b` concludes with `success`. The run timeline shows the gate stages starting concurrently after `tier-classification` (visible fan-out), not serially. `stage-e2e-smoke` is `skipped` when the `e2e:run` label is absent (expected) or `success` when present.
- **How to produce it:** The orchestrator triggers the run at the S9 gate after PR creation, via PR-context (`pull_request` to `main`) or `workflow_dispatch` against the branch head. A green `workflow_dispatch` run against the branch head satisfies the rule equally to a PR-context run.
- **Verification commands:**
  - `gh run list --workflow=pr-pipeline.yml --branch TMW-wt-2026-06-01-09-51 --json headSha,conclusion,status,event` — confirm a row with `headSha == 736b4202...` and `conclusion == success`.
  - `pwsh -NoProfile -File ./scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 -ChangedFiles @('.github/workflows/pr-pipeline.yml','.github/workflows/README.md') -GreenRunEvidencePresent $true` — must return `IsBlocking:false` once green-run evidence is present.
  - Inspect the run's job graph/timeline to confirm post-root concurrent scheduling.

## Do Not Do

- Do not edit `.github/workflows/pr-pipeline.yml` further to "fix" this finding; the graph is already correct. The finding is cleared by producing the green run, not by changing the workflow.
- Do not rename any job key or status-check context (invariants #1/#2).
- Do not modify, add, remove, or merge any `_*.yml` callee.
- Do not edit `.github/scripts/apply-branch-protection.ps1` or `tests/powershell/apply-branch-protection.Tests.ps1`.
- Do not add inline `steps:` to the orchestrator or introduce a second level of reusable-workflow nesting.
- Do not weaken or skip the `modified-workflow-needs-green-run` policy or any required status check.
- Do not write evidence to non-canonical paths; green-run evidence goes under `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/`.

## Notes for the Handoff

There are no code-level remediation tasks. The single item (F1) is a runtime gate satisfied by the orchestrator S9 green branch-head run. If the orchestrator routes this through `atomic-planner`, the resulting `remediation-plan.2026-06-01T14-30.md` should consist of the green-run production and its evidence capture, not source edits. After the green run is recorded, a reaudit should re-evaluate DoD #7 / US #E to PASS and `blocking_count` should drop to 0.
