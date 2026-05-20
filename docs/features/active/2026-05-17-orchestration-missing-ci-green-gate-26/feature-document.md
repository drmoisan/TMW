# orchestration-missing-ci-green-gate - Feature Document

- **Issue:** #26
- **Issue URL:** https://github.com/drmoisan/TMW/issues/26
- **Owner:** drmoisan
- **Last Updated:** 2026-05-19
- **Status:** Implemented
- **Work Mode:** full-bug

## Overview

The orchestrate skill currently advances a feature to `next_step: "DONE"` based solely on local audit signals: `blocking_findings_resolved == true`, presence of an acceptance-criteria verification artifact, a clean local toolchain run inside the agent worktree, and `next_step == S8_create_pr`. None of those conditions observe what GitHub Actions produces against the live PR head SHA. As a result, defects whose only failure surface is the runner environment (workflow YAML semantics, baseline provenance, runner-host performance variability, `pwsh` exit-code propagation) are not detectable by local feature-review and cannot be self-healed by the existing remediation loop (R1-R5), which re-audits the same local artifacts on every pass.

Direct evidence: PR #30 (`feature/idempotency-and-benchmark-infra-23`) was marked DONE locally while `stage-10-benchmark-regression` and `benchmark-gate-self-validation` failed on every PR head SHA. The benchmark baseline shipped with `HostEnvironmentInfo.ProcessorName: "Unknown processor"` (developer workstation provenance) and was compared against `windows-latest` runner output, producing deterministic latency regressions of 100-134%. The self-validation step swallowed its own success signal because a deliberately-failing nested `pwsh` command left `$LASTEXITCODE == 1` after the verification logic had already concluded successfully.

## Proposed Fix

Five coordinated changes close the gap:

1. **Add S9 to the orchestrate skill.** A new step `S9_ci_green` runs after `S8_create_pr` and before any DONE transition. S9 invokes `gh pr checks --required --json` against the live PR head SHA and writes the result to the checkpoint under a `ci_gate` object plus a top-level `last_verified_ci_sha` and `step9_status` field. The PR Creation Gate gains a fifth condition: `ci_gate.conclusion == "success"` AND `ci_gate.head_sha == current head SHA of the PR branch`.

2. **Expand the remediation loop to handle CI-only failures.** When S9 reports a failed required check, the orchestrator converts the failed-check log into a synthetic blocking finding and re-enters the existing R1-R5 loop with the log written as `remediation-inputs.<timestamp>.md`. The existing `remediation_pass` cap of 3 applies to CI-failure passes the same as local-finding passes. On the third consecutive CI failure the orchestrator records `step9_status: "blocked_ci_loop_limit"` and halts without writing DONE.

3. **Add a feature-review policy rule "modified-workflow-needs-green-run".** When the branch diff modifies any path matching `.github/workflows/**`, `scripts/benchmarks/**`, or `.github/actions/**`, the policy audit blocks merge unless evidence of a green workflow run against the branch head is present in the remediation inputs. This rule provides a second, independent line of defense for CI-gate-modifying features even before S9 runs.

4. **Add `.claude/rules/benchmark-baselines.md`.** Performance baselines require runner-environment parity. The rule rejects any baseline whose `HostEnvironmentInfo.ProcessorName` is `"Unknown processor"` and requires a sibling `baseline.provenance.json` file that records the runner class, host signature, and the workflow run URL that produced the baseline.

5. **Add `.claude/rules/ci-workflows.md`.** Document the `pwsh` deliberately-failing-nested-command pattern. Any workflow step whose `run:` block invokes a command expected to fail as part of negative-path verification must either reset `$LASTEXITCODE = 0` after the expected failure or emit an explicit `exit 0` on the success path. The rule is the textual artifact that local review can cite when reading workflow YAML.

## Validation Approach

- Pester unit coverage for the new validation script that parses `gh pr checks --json` output (positive case: all required checks success; negative cases: one failed, one in progress, malformed JSON, no checks reported).
- Pester unit coverage for the baseline-provenance validator (rejects `ProcessorName == "Unknown processor"`, rejects missing sibling `baseline.provenance.json`, accepts a runner-captured baseline with valid provenance).
- Synthetic integration scenarios:
  - A branch that modifies `.github/workflows/pr-pipeline.yml` with a deliberately-breaking change must be flagged as Blocking by the policy audit before merge.
  - A branch that commits a workstation-captured baseline must be flagged as Blocking by the policy audit before merge.
  - An end-to-end orchestration dry-run on a branch whose PR Pipeline fails must NOT write DONE and must enter the remediation loop using the failed run log as input.

## Out of Scope

- No changes to existing workflow YAML beyond what is required to demonstrate the new rules (the rules are textual; their enforcement against real workflows is incremental).
- No replacement for or modification of `stage-10-benchmark-regression`. The orchestration gate is independent of which checks are required; it only verifies that all currently-required checks pass.
- No changes to branch-protection rules on `main`. S9 reads from `gh pr checks --required` which reflects the existing branch-protection configuration.
- No changes to the local mandatory toolchain loop. The new S9 step runs after the toolchain loop, not as part of it.

## References

- Source issue: `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/issue.md`
- Reproduction case: PR #30, branch `feature/idempotency-and-benchmark-infra-23`, feature folder `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/`.
- Skill to modify: `.claude/skills/orchestrate/SKILL.md`
- Skill to modify: `.claude/skills/feature-review-workflow/SKILL.md`
- New rule files: `.claude/rules/benchmark-baselines.md`, `.claude/rules/ci-workflows.md`
