# orchestration-missing-ci-green-gate (Issue #26)

- Date captured: 2026-05-17
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/orchestration-missing-ci-green-gate/ (Issue #26)

> Automation note: Keep the section headings below unchanged; the promotion tooling maps each of them into the GitHub bug issue template.

- Issue: #26
- Issue URL: https://github.com/drmoisan/TMW/issues/26
- Last Updated: 2026-05-17
- Work Mode: full-bug

## Summary

The orchestrate skill marks a feature DONE without ever observing a successful PR Pipeline run against the PR head SHA. Local feature-review cannot detect CI-only failure modes (workflow YAML semantics, runner-host performance baselines, runner-specific environment differences), so features that introduce or modify CI gates can ship with the gates themselves broken.

## Environment

- OS/version: Windows 11 / GitHub Actions windows-latest
- Python version: n/a (orchestration skill defect)
- Command/flags used: orchestrate skill end-to-end lifecycle (`/orchestrate`)
- Data source or fixture: feature `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23` (issue #23, PR #30)

## Steps to Reproduce

1. Run the orchestrate skill to completion on a feature that adds or modifies a `.github/workflows/**` file or any new CI gate.
2. Observe the orchestrator advance through S1–S8 and write `next_step: "DONE"` to `artifacts/orchestration/orchestrator-state.json` with `blocking_findings_resolved: true`.
3. Push the branch and open a PR; observe the PR Pipeline fail on stages introduced or modified by the feature.

Concrete reproduction case: PR #30 (`feature/idempotency-and-benchmark-infra-23`).
- `step10_status: "pending"` in the checkpoint, yet `next_step: "DONE"`.
- `stage-10-benchmark-regression` fails because `artifacts/benchmarks/baseline.json` was captured on a developer workstation (`HostEnvironmentInfo.ProcessorName: "Unknown processor"`) and compared against a `windows-latest` runner; the 5% p99 threshold cannot survive the host mismatch.
- `benchmark-gate-self-validation` fails because the workflow's `pwsh` step does not reset `$LASTEXITCODE` after a deliberately-failing negative test; the residual exit code 1 leaks to GitHub Actions even though the script's verification logic succeeded.

## Expected Behavior

The orchestrator's PR Creation Gate requires, as a non-negotiable condition, that the PR Pipeline run associated with the current head SHA report a `success` conclusion for all required checks. If any required check fails, the failure is treated as a synthetic blocking finding and re-enters the remediation loop with the failed-check log as `remediation-inputs.<timestamp>.md`. The orchestrator does not write `next_step: "DONE"` until `gh pr checks --required` reports success against the live head SHA.

Additionally, the feature-review policy audit blocks merge when the branch diff modifies `.github/workflows/**`, `scripts/benchmarks/**`, or `.github/actions/**` unless evidence of a green workflow run against the branch head is present in the remediation inputs.

## Actual Behavior

The PR Creation Gate enumerated in `.claude/skills/orchestrate/SKILL.md` requires only:
1. `blocking_findings_resolved: true` (local feature-review)
2. AC verification artifact
3. Mandatory toolchain passed (local toolchain inside the agent worktree)
4. `next_step == S8_create_pr`

None of the four conditions observe what GitHub Actions does on the runner. CI-only failures structurally escape the cycle. The remediation loop (R1–R5) re-audits the same local artifacts on each pass, so it cannot detect or repair CI-only failures either.

## Logs / Screenshots

- [x] Attached minimal logs or snippet
- Snippet (stage-10-benchmark-regression on PR #30):

```
id, p99_baseline_ns, p99_current_ns, p99_delta_pct, alloc_baseline_b, alloc_current_b, alloc_delta_pct, verdict
TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command, 8.8601, 18.4967, 108.76, 32, 32, 0.00, FAIL_LATENCY
TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath, 26.6209, 62.2922, 134.00, 248, 248, 0.00, FAIL_LATENCY
TaskMaster.Benchmarks.ClassifierBenchmarks.TrainingState_Update, 4.8464, 11.0046, 127.07, 0, 0, 0.00, FAIL_LATENCY
Error: Process completed with exit code 1.
```

- Snippet (benchmark-gate-self-validation on PR #30):

```
benchmark-gate-self-validation: latency gate caught synthetic regression and non-idempotent handler was detected as expected.
Error: Process completed with exit code 1.
```

## Impact / Severity

- [ ] Blocker
- [x] High
- [ ] Medium
- [ ] Low

Rationale: any feature whose deliverable is a CI gate can ship with the gate itself broken. The remediation loop cannot self-heal this class of defect. Direct evidence: feature #23 shipped a benchmark regression gate that fails on every subsequent PR regardless of code quality, and a self-validation gate whose own step semantics swallow the success signal.

## Suspected Cause / Notes

Root causes:
1. The PR Creation Gate is defined in terms of *local* audit outputs only. It does not consult `gh pr checks` or `gh run list` against the branch head.
2. The feature-review policy audit has no rule of the form "if the diff modifies a CI gate, require evidence of a green run of that gate on the branch."
3. There is no repo rule constraining benchmark baseline provenance (runner class, host signature, sibling provenance file). Baselines captured on developer workstations were allowed into the repository without challenge.
4. There is no repo rule covering the workflow pattern "pwsh step containing a deliberately-failing nested command." The exit-code leak was not detectable by any local tool because no local tool runs the workflow's `run:` block.

Files most relevant to remediation:
- `.claude/skills/orchestrate/SKILL.md` — add S9 step, head-SHA invariant, fifth PR-gate condition, checkpoint schema fields.
- `.claude/skills/feature-review-workflow/SKILL.md` — add policy rule "modified-workflow-needs-green-run".
- `.claude/rules/benchmark-baselines.md` (new) — runner-environment parity rule for performance baselines.
- `.claude/rules/ci-workflows.md` (new) — explicit-exit rule for `pwsh` steps with deliberately-failing nested commands.

## Proposed Fix / Validation Ideas

- [ ] Unit coverage areas
  - Pester tests for any new validation script that parses `gh pr checks --json` output.
  - Pester tests for a baseline-provenance validator that rejects `ProcessorName == "Unknown processor"` and missing sibling `baseline.provenance.json`.
- [ ] Integration scenario to retest
  - Synthetic feature branch that modifies `.github/workflows/pr-pipeline.yml` with a deliberately-breaking change; the policy audit must flag it as Blocking before merge.
  - Synthetic feature branch that commits a workstation-captured baseline; the policy audit must flag it as Blocking before merge.
  - End-to-end orchestration dry-run that pushes a branch whose PR Pipeline fails; the orchestrator must NOT mark DONE and must enter the remediation loop using the failed run log as input.
- [ ] Manual verification notes
  - Verify checkpoint schema gains `ci_gate.head_sha`, `ci_gate.pr_pipeline_run_id`, `ci_gate.conclusion`, `ci_gate.verified_at`, `last_verified_ci_sha`, and `step9_status`.
  - Verify that `remediation_pass` cap (3) applies to CI-failure passes the same as local-finding passes; on the third failure record `step9_status: "blocked_ci_loop_limit"` and halt.

Proposed S9 schema additions (illustrative):

```jsonc
{
  "completed_steps": [..., "S8_create_pr", "S9_ci_green"],
  "step9_status": "pending|passed|failed_remediation_required|blocked_ci_loop_limit",
  "ci_gate": {
    "head_sha": "<sha>",
    "pr_pipeline_run_id": "<id>",
    "pr_pipeline_run_url": "<url>",
    "conclusion": "success",
    "verified_at": "<iso8601>"
  },
  "last_verified_ci_sha": "<sha>"
}
```

PR Creation Gate gains a fifth condition: `ci_gate.conclusion == "success"` AND `ci_gate.head_sha == current head SHA of the PR branch`.

## Next Step

- [x] Promote to GitHub issue (bug-report template)
- [ ] Move to active fix folder / branch