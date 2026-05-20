# orchestration-missing-ci-green-gate - Spec

- **Issue:** #26
- **Issue URL:** https://github.com/drmoisan/TMW/issues/26
- **Owner:** drmoisan
- **Last Updated:** 2026-05-19
- **Status:** Implemented
- **Version:** 0.2
- **Work Mode:** full-bug

## Intent & Outcomes

Close the structural gap that allows the orchestrate skill to mark a feature DONE without observing a successful PR Pipeline run against the live PR head SHA. The orchestrator must consult GitHub Actions before writing DONE. Features that modify CI gates must be blocked at policy-audit time unless a green run of the modified gate exists against the branch head. Two new repo rules codify the baseline-provenance and `pwsh`-exit-code patterns implicated in the reproduction case (PR #30).

Outcomes:
- The orchestrate skill gains a new step `S9_ci_green` between `S8_create_pr` and DONE that verifies all required checks against the live PR head SHA.
- The checkpoint schema (`artifacts/orchestration/orchestrator-state.json`) is extended with a `ci_gate` object and top-level `last_verified_ci_sha` plus `step9_status` fields.
- The PR Creation Gate gains a fifth condition tying DONE to `ci_gate.conclusion == "success"` AND `ci_gate.head_sha == current head SHA`.
- The remediation loop (R1-R5) accepts failed-check logs as synthetic blocking findings; the existing `remediation_pass` cap of 3 applies; the third failure halts with `step9_status: "blocked_ci_loop_limit"`.
- The feature-review policy audit gains a rule "modified-workflow-needs-green-run" that blocks merge when the branch diff touches CI paths without evidence of a green run.
- Two new repo rule files exist (`.claude/rules/benchmark-baselines.md`, `.claude/rules/ci-workflows.md`).
- Pester unit coverage exists for the new `gh pr checks --json` parser and for the baseline-provenance validator.

## Invariants (must not change)

- The existing local mandatory toolchain loop remains unchanged in stages and order.
- Existing PR Creation Gate conditions 1-4 remain in force; the new condition is additive.
- Existing remediation-loop steps R1-R5 retain their semantics; CI-failure passes use the same pass counter and the same cap.
- `gh` CLI invocations remain the only sanctioned channel for querying GitHub Actions state.
- Behavior for features that do not modify CI paths is unchanged, except for the additive S9 verification which still applies (all features must observe a green PR Pipeline run before DONE).

## Scope (structural changes)

Edits:
- `.claude/skills/orchestrate/SKILL.md` — add S9 step definition, checkpoint schema fields, fifth PR-gate condition, and remediation-loop CI-failure handling.
- `.claude/skills/feature-review-workflow/SKILL.md` — add policy rule "modified-workflow-needs-green-run".

New files:
- `.claude/rules/benchmark-baselines.md` — runner-environment parity rule for performance baselines.
- `.claude/rules/ci-workflows.md` — explicit-exit rule for `pwsh` steps with deliberately-failing nested commands.
- New PowerShell validation script (path TBD at implementation time; expected under `scripts/orchestration/` or `scripts/ci/`) that parses `gh pr checks --json` output and emits the `ci_gate` object.
- New PowerShell baseline-provenance validator script (path TBD; expected under `scripts/benchmarks/` or `scripts/ci/`) that enforces the rule in `.claude/rules/benchmark-baselines.md`.
- New Pester test files covering both new scripts.

Bundled-mirror resync:
- For every edited `.claude/skills/**` file that already has a bundled mirror in this repo, keep the mirror byte-identical. The mirrors that exist in this repo are `.agents/skills/` and `.github/skills/`; there is no `.codex/` skills or rules mirror tree and no mirror-contract test suite. New `.claude/rules/*.md` files have no mirror target.

## Acceptance Criteria

- [x] AC1: `.claude/skills/orchestrate/SKILL.md` defines a new step `S9_ci_green` that runs after `S8_create_pr` and before any DONE transition. The step description requires invocation of `gh pr checks --required --json` (or an equivalent JSON-emitting command) against the live PR head SHA.

- [x] AC2: The orchestrator checkpoint schema documented in `.claude/skills/orchestrate/SKILL.md` is extended with a `ci_gate` object containing the fields `head_sha`, `pr_pipeline_run_id`, `pr_pipeline_run_url`, `conclusion`, and `verified_at`, plus top-level fields `last_verified_ci_sha` and `step9_status`. The `step9_status` enumeration includes at minimum `pending`, `passed`, `failed_remediation_required`, and `blocked_ci_loop_limit`.

- [x] AC3: The PR Creation Gate enumeration in `.claude/skills/orchestrate/SKILL.md` is extended with a fifth condition: `ci_gate.conclusion == "success"` AND `ci_gate.head_sha == current head SHA of the PR branch`. The skill text states explicitly that DONE is not written while either sub-condition is false.

- [x] AC4: `.claude/skills/orchestrate/SKILL.md` documents the remediation-loop expansion: a failed required check from S9 is converted to a synthetic blocking finding, the failed-check log is written as `remediation-inputs.<timestamp>.md`, and the existing R1-R5 loop processes that finding.

- [x] AC5: `.claude/skills/orchestrate/SKILL.md` documents that the existing `remediation_pass` cap of 3 applies to CI-failure passes. On the third CI failure pass the orchestrator records `step9_status: "blocked_ci_loop_limit"`, does not write DONE, and halts.

- [x] AC6: `.claude/skills/feature-review-workflow/SKILL.md` defines a policy rule "modified-workflow-needs-green-run". The rule states that if the branch diff modifies any path matching `.github/workflows/**`, `scripts/benchmarks/**`, or `.github/actions/**`, the policy audit emits a Blocking finding unless evidence of a green workflow run against the branch head is present in the remediation inputs.

- [x] AC7: `.claude/rules/benchmark-baselines.md` exists and requires runner-environment parity for performance baselines. The rule explicitly rejects baselines whose `HostEnvironmentInfo.ProcessorName` is `"Unknown processor"` and explicitly requires a sibling `baseline.provenance.json` file recording at minimum the runner class, host signature, and producing workflow run URL.

- [x] AC8: `.claude/rules/ci-workflows.md` exists and documents the `pwsh` deliberately-failing-nested-command pattern. The rule requires either an explicit `$LASTEXITCODE = 0` reset after the expected failure or an explicit `exit 0` on the success path for any step whose `run:` block intentionally invokes a failing nested command.

- [x] AC9: A PowerShell validation script exists that parses `gh pr checks --json` output and emits the `ci_gate` object defined in AC2. The script is invoked by S9.

- [x] AC10: Pester unit tests exist for the script in AC9. Tests cover at minimum: all required checks success (positive); one required check failed (negative); a required check still in progress (negative); malformed JSON input (error path); empty checks list (error path).

- [x] AC11: A PowerShell baseline-provenance validator script exists that enforces the rule in `.claude/rules/benchmark-baselines.md`. The script rejects baselines whose `HostEnvironmentInfo.ProcessorName` is `"Unknown processor"` and rejects baselines missing a sibling `baseline.provenance.json`.

- [x] AC12: Pester unit tests exist for the script in AC11. Tests cover at minimum: rejection of `ProcessorName == "Unknown processor"` (negative); rejection of missing sibling `baseline.provenance.json` (negative); acceptance of a runner-captured baseline with valid provenance (positive).

- [x] AC14: The full local mandatory toolchain loop (formatting, linting, type checking, architecture-boundary tests, unit tests, contract/schema checks, integration tests) passes in a single pass on the change branch.

- [ ] AC15: The PR Pipeline run against the change branch head SHA reports `success` for all required checks. The `ci_gate` checkpoint object on this very feature records the green run before DONE is written, demonstrating the new gate operating on itself.

## Non-Goals

- No replacement for `stage-10-benchmark-regression`. S9 is gate-agnostic; it only verifies that currently-required checks pass.
- No changes to branch-protection rules on `main`. S9 reads what `gh pr checks --required` already reflects.
- No changes to the local mandatory toolchain loop stages, order, or restart semantics.
- No changes to existing PR Creation Gate conditions 1-4.
- No retrofit of past features (e.g., feature #23 / PR #30) to the new schema. The new gate applies prospectively.
- No changes to the `gh` CLI version pinning or to the CI image used by the PR Pipeline.

## Dependencies / Touchpoints

- `.claude/skills/orchestrate/SKILL.md` and `.claude/skills/feature-review-workflow/SKILL.md` are the primary skill files. Edits must remain backward-compatible with any in-flight orchestrator state files that predate the schema change (treat missing `ci_gate` as `pending`).
- Bundled-mirror sync for the `.agents/skills/` and `.github/skills/` mirrors that exist in this repo. This repo does not enforce mirror parity via python/pester contract tests.
- `gh` CLI availability in the orchestration runtime. S9 assumes `gh auth status` succeeds and `gh pr checks --required --json` is available.
- Reproduction case: PR #30 (`feature/idempotency-and-benchmark-infra-23`). Used for evidence, not as a touchpoint to modify.

## Risks & Mitigations

- Risk: `gh pr checks --required --json` returns transient "in progress" states. Mitigation: S9 polls with a bounded interval and total timeout documented in the skill; an exhausted timeout records `step9_status: "failed_remediation_required"` and enters the remediation loop with a timeout log.
- Risk: A feature legitimately needs to land before its CI gate is fully wired (chicken-and-egg). Mitigation: the policy rule "modified-workflow-needs-green-run" accepts a green workflow_dispatch run against the branch head as evidence, not only a PR-context run.
- Risk: S9 is bypassed by direct push to a branch that already has a PR. Mitigation: S9 is keyed on PR head SHA; the gate fails closed if the PR head SHA does not match `last_verified_ci_sha`.
- Risk: The new schema fields collide with in-flight checkpoint files. Mitigation: missing fields are treated as `pending`; this is documented in the skill text.

## Technical Specifications

Checkpoint schema additions (illustrative):

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

PR Creation Gate (final form):
1. `blocking_findings_resolved: true`
2. AC verification artifact present
3. Mandatory toolchain passed locally
4. `next_step == S8_create_pr` (precondition to entering S9)
5. `ci_gate.conclusion == "success"` AND `ci_gate.head_sha == current head SHA of the PR branch`

Remediation-loop CI-failure handling:
- On `step9_status == failed_remediation_required`, the failed-check log from `gh run view <run-id> --log-failed` is written as `remediation-inputs.<timestamp>.md` in the active feature folder.
- The synthetic finding has severity "Blocking" and identifies the failing check by name and the failing job by URL.
- The `remediation_pass` counter is shared with local-finding passes; cap is 3.
- On the third CI-failure pass, `step9_status` is set to `blocked_ci_loop_limit` and the orchestrator halts.

Evidence locations:
- All evidence artifacts produced by this feature follow the canonical `<FEATURE>/evidence/<kind>/` layout per `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`.
