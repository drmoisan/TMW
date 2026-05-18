# `reusable-workflow-refactor-pr-pipeline` — User Story

- Issue: #27
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-05-18

## Story Statement

- As the repository maintainer responsible for the PR-time CI pipeline, I want each stage in `pr-pipeline.yml` extracted into a reusable `_*.yml` workflow that declares both `workflow_call:` and `workflow_dispatch:`, so that I can re-run any single stage against a branch tip via `gh workflow run <stage>.yml --ref <branch>` without duplicating step definitions across mirror files.
- As an on-call CI debugger triaging a failing stage on a feature branch, I want one authoritative file per stage with no byte-identical mirror, so that any edit lands in one place and no drift between orchestrated and standalone invocations can accumulate.
- As the future implementer of issue #26 (`orchestration-missing-ci-green-gate`), I want each stage to produce its own GitHub Actions run id, so that the S9 "CI Green Required" gate can verify a single stage's status against a specific head SHA without parsing `gh pr checks --json` to disambiguate nested jobs inside a single multi-job run.

## Problem / Why

The current `pr-pipeline.yml` defines 17 inline jobs (tier-classification, the seven-stage Python/Node chain, the five-stage .NET chain, `stage-e2e-smoke`, `stage-10-benchmark-regression`, `benchmark-gate-self-validation`, and `secret-scan`). GitHub Actions has two relevant constraints:

1. `workflow_dispatch` on a multi-job workflow always runs every job in that workflow.
2. `gh run rerun --job <id>` only replays the original SHA, not a fresh branch tip.

The unblock applied on `feature/idempotency-and-benchmark-infra-23` worked around this by committing standalone dispatch mirrors at `.github/workflows/stage-10-benchmark-regression.yml` and `.github/workflows/benchmark-gate-self-validation.yml`. Those files are byte-identical to the corresponding inline jobs by construction; every step change must be made in two places, with drift detected only by CI regression rather than at edit time.

GitHub Actions reusable workflows (`on: workflow_call`) solve this directly. Each stage becomes a callee file that lists both `workflow_call:` and `workflow_dispatch:` triggers. The orchestrator `pr-pipeline.yml` shrinks to `uses:` lines plus the `needs:` dependency graph. Each stage gains independent dispatchability without duplication.

## Personas & Scenarios

- Persona: Repository maintainer (the CI pipeline owner).
  - Who they are: the engineer who owns the PR-time merge gates and the branch-protection rules on `main`.
  - What they care about: that every gate exists in exactly one place, that re-running a single stage against a branch tip takes one `gh` command, and that the pre/post refactor pass/fail outcomes are identical on a known-green commit.
  - Constraints: must not change step logic, coverage thresholds, tier classification, or `benchmark-baseline-refresh.yml`; must update branch-protection rules in the same change to avoid blocking all PR merges.
  - Goals and frustrations: wants the duplicated mirror files gone. Past frustration: a step edit to `pr-pipeline.yml`'s `stage-10-benchmark-regression` job silently desynchronized from `stage-10-benchmark-regression.yml` until the next standalone dispatch run.

- Persona: On-call CI debugger.
  - Who they are: any contributor (including the future implementer of issue #26) who needs to re-run a single failing stage against the current branch tip without queuing the full pipeline.
  - What they care about: that `gh workflow run _<stage>.yml --ref <branch>` produces a single isolated run with one job, no transitive `needs:` dependency triggered.
  - Constraints: cannot wait for a full PR pipeline (~20+ minutes) to re-validate a single five-minute stage; cannot edit two mirror files to test a fix.
  - Goals and frustrations: wants one authoritative file per stage and a documented per-stage dispatch command.

- Scenario: Re-running a single stage against a branch tip.
  - Trigger: a PR's `stage-10-benchmark-regression` fails on the current branch tip; the contributor pushes a fix and wants to re-run only stage 10.
  - Steps: contributor runs `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>`. GitHub Actions queues a single run with one job against the current branch tip.
  - Expected outcome: the dispatch produces one run id, one job, no transitive dependency on `stage-7-integration` or other stages.

- Scenario: Orchestrated PR run preserves pre-refactor behavior.
  - Trigger: a PR is opened against `main` from the refactor branch.
  - Steps: the orchestrator `pr-pipeline.yml` chains all 17 callees in the expected `needs:` order. Every required check produces the same pass/fail outcome as a known-green commit on the pre-refactor pipeline.
  - Expected outcome: no new failure modes introduced by the relocation; check-name shape changes from `<job-name>` to `<caller-job-name> / <callee-job-name>` and the branch-protection rule is updated to match in the same change.

- Scenario: Deliberate failure surfacing.
  - Trigger: a contributor introduces a syntax error in one callee (e.g., `_stage-1-format.yml`).
  - Steps: the orchestrator runs; the affected callee fails.
  - Expected outcome: the failure appears in the orchestrator's check list under the new combined name and is unambiguously traceable to the responsible callee file.

## Acceptance Criteria

- [ ] AC1: Every job currently defined inline in `pr-pipeline.yml` is extracted to its own `_*.yml` reusable workflow file.
- [ ] AC2: Each `_*.yml` declares both `on: workflow_call:` and `on: workflow_dispatch:`.
- [ ] AC3: `pr-pipeline.yml` contains no inline `steps:`; every job is a `uses: ./.github/workflows/_*.yml` block with appropriate `needs:`, `if:`, and `secrets:` declarations.
- [ ] AC4: Step content (commands, environment, `shell:`, `runs-on:`) is byte-identical to the pre-refactor inline definitions; diffs limited to relocation and the `workflow_call:`/`workflow_dispatch:` triggers.
- [ ] AC5: `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>` runs only that stage against the branch tip; no other stages are queued.
- [ ] AC6: A PR-pipeline run on a representative branch shows the same pass/fail outcome as the pre-refactor pipeline for each stage. No new failure modes introduced by the relocation.
- [ ] AC7: The two standalone duplicate workflows (`stage-10-benchmark-regression.yml`, `benchmark-gate-self-validation.yml`) are deleted in the same change.
- [ ] AC8: Branch-protection rule names are updated to match the new `<caller-job-name> / <callee-job-name>` display format. The old names are removed from the rule. Documented in the PR description.
- [ ] AC9: Each Azure-secret-consuming callee (currently only `_stage-e2e-smoke.yml`) declares its `secrets:` explicitly and the caller passes `secrets: inherit` or per-secret mappings. No silent secret-loss regression.
- [ ] AC10: `.github/workflows/README.md` exists and documents the callee/caller convention, the rule that any new gate ships as a `_*.yml` callee (not inline steps), per-stage `gh workflow run` invocations, and the branch-protection rename procedure.

## Non-Goals

- No changes to step logic. Commands, scripts under `.github/scripts/`, and composite actions under `.github/actions/` are not modified; the refactor is pure relocation.
- No changes to coverage thresholds (line >= 85%, branch >= 75% per `.claude/rules/quality-tiers.md` remain in force).
- No changes to tier classification (`quality-tiers.yml` and `validate-quality-tiers.ps1` untouched).
- No changes to `benchmark-baseline-refresh.yml` (distinct lifecycle: deliberate human-approved baseline updates).
- No changes to `pre-merge-pipeline.yml` (distinct trigger: `merge_group`, out of scope).
- No new gates, no removed gates. The gate inventory before and after is identical.
- No production C# / TypeScript / Python code changes.
- No branch-protection automation script. The rule rename is performed manually by a repository admin and documented in the PR description.
