# Green Branch-Head Run Evidence — pr-pipeline.yml (Issue #46)

- **Timestamp:** 2026-06-01T14:25Z
- **Command:** `gh workflow run pr-pipeline.yml --ref TMW-wt-2026-06-01-09-51` then
  `gh run view 26760839329 --json headSha,conclusion,status,event,jobs`
- **EXIT_CODE:** 0
- **Run ID:** 26760839329
- **Run URL:** https://github.com/drmoisan/TMW/actions/runs/26760839329
- **Event:** workflow_dispatch
- **Head SHA:** 04833fb3926080883d4ba7f02149ff1bb3373a26 (equals branch head)
- **Conclusion:** success

## Purpose

Satisfies the `modified-workflow-needs-green-run` policy
(`.claude/skills/feature-review-workflow/SKILL.md` line 74: a green
`workflow_dispatch` run against the branch head satisfies the rule) and the
orchestrator S9 CI green gate for the `needs:`-graph parallelization change to
`.github/workflows/pr-pipeline.yml`.

## Fan-out Verification (concurrent post-root scheduling)

`tier-classification` is the single root gate and runs first; every other gate
starts immediately after it, concurrently, instead of in two serial
per-language lanes.

| Job | Conclusion | Started | Completed |
|---|---|---|---|
| tier-classification / tier-classification | success | 14:21:36 | 14:22:02 |
| secret-scan / secret-scan | success | 14:21:38 | 14:22:09 |
| stage-1-format / stage-1-format-prettier | success | 14:22:05 | 14:23:35 |
| stage-2-lint / stage-2-lint-eslint | success | 14:22:07 | 14:23:37 |
| stage-3-typecheck / stage-3-typecheck-tsc | success | 14:22:05 | 14:23:35 |
| stage-4-architecture / stage-4-architecture | success | 14:22:07 | 14:23:49 |
| stage-5-test / stage-5-test-vitest | success | 14:22:05 | 14:23:43 |
| stage-6-contract / stage-6-contract | success | 14:22:05 | 14:23:18 |
| stage-7-integration / stage-7-integration-vitest | success | 14:22:05 | 14:22:20 |
| stage-1-dotnet-format / stage-1-dotnet-format | success | 14:22:05 | 14:22:44 |
| stage-2-dotnet-build / stage-2-dotnet-build | success | 14:22:05 | 14:23:48 |
| stage-3-dotnet-typecheck / stage-3-dotnet-typecheck | success | 14:22:05 | 14:22:19 |
| stage-4-dotnet-architecture / stage-4-dotnet-architecture | success | 14:22:06 | 14:23:20 |
| stage-5-dotnet-test / stage-5-dotnet-test | success | 14:22:06 | 14:24:24 |
| stage-e2e-smoke | skipped | 14:22:03 | 14:22:03 |

## Observations

- All 12 gate stages started within a ~2-second window (14:22:05–14:22:07),
  immediately after `tier-classification` completed at 14:22:02. This is the
  intended fan-out; under the prior serial graph each lane stage waited for its
  predecessor.
- Critical path: `tier-classification` (14:21:36) to the last gate stage
  (`stage-5-dotnet-test`, 14:24:24) ≈ 2 min 48 s. The prior serial graph's
  critical path was the longer per-language lane summed stage-by-stage.
- `stage-e2e-smoke` was skipped because the `e2e:run` label is absent (expected
  behavior preserved).
- `secret-scan` ran unconditionally and in parallel (expected behavior preserved).
- Job keys and required status-check contexts are unchanged from the prior set.
