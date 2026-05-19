# reusable-workflow-refactor-pr-pipeline (Issue #27)

- Date captured: 2026-05-17
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/reusable-workflow-refactor-pr-pipeline/ (Issue #27)

- Issue: #27
- Issue URL: https://github.com/drmoisan/TMW/issues/27
- Last Updated: 2026-05-17
- Work Mode: full-feature

## Problem / Why

The `pr-pipeline.yml` workflow file orchestrates all PR-time CI gates (stages 1–10, plus secret-scan, benchmark-gate-self-validation, and the e2e job). GitHub Actions cannot run a single job of a multi-job workflow against a fresh ref: `workflow_dispatch` runs every job, and `gh run rerun --job` only replays the original SHA. The unblock applied on `feature/idempotency-and-benchmark-infra-23` (commits `d2c51bd`, `534b549`, `328026a`) addressed this for two stages by creating byte-identical standalone dispatch mirrors at `.github/workflows/stage-10-benchmark-regression.yml` and `.github/workflows/benchmark-gate-self-validation.yml`. That pattern is duplication by construction: every step change must be made in two places, with drift detected only by CI regression.

A cleaner structure is available via reusable workflows (`on: workflow_call`). Each stage becomes a callee file that lists both `workflow_call:` and `workflow_dispatch:` triggers. The orchestrating `pr-pipeline.yml` shrinks to a list of `uses:` lines and the `needs:` dependency graph. Each stage is then independently dispatchable against a branch ref via `gh workflow run <stage>.yml --ref <branch>`, and the duplicated mirror files are deleted.

This refactor is also the structural enabler for issue #26 (`orchestration-missing-ci-green-gate`): the proposed S9 "CI Green Required" gate must verify a *single* stage's status against a specific head SHA. With reusable workflows, each callee produces its own run id that S9 can query in isolation. Without the refactor, S9 must parse `gh pr checks --json` output and disambiguate jobs nested inside a single multi-job run.

## Proposed Behavior

Final state of `.github/workflows/`:

```
.github/workflows/
  pr-pipeline.yml                            # orchestrator: only `uses:` + `needs:` + tier-classification
  _tier-classification.yml                   # workflow_call + workflow_dispatch (optional split)
  _stage-1-format.yml
  _stage-2-lint.yml
  _stage-3-typecheck.yml
  _stage-4-arch.yml
  _stage-5-unit.yml
  _stage-6-contract.yml
  _stage-7-integration.yml
  _stage-8-secret-scan.yml
  _stage-9-e2e.yml
  _stage-10-benchmark-regression.yml
  _benchmark-gate-self-validation.yml
  benchmark-baseline-refresh.yml             # already standalone; unchanged
```

Each `_*.yml` callee:

- Lists both `on: workflow_call:` and `on: workflow_dispatch:` so the same file serves orchestrated and standalone invocation.
- Owns its `steps:` and runner declaration. The caller's `uses:` job is bodyless.
- Receives `inputs:` and `secrets:` explicitly (no implicit `secrets.*` inheritance for any secret it consumes; e2e in particular must declare Azure secrets and the caller must pass `secrets: inherit` or explicit mappings).

`pr-pipeline.yml` after the refactor:

```yaml
name: PR Pipeline
on:
  pull_request:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

jobs:
  tier-classification:
    uses: ./.github/workflows/_tier-classification.yml
  stage-1-format:
    needs: [tier-classification]
    uses: ./.github/workflows/_stage-1-format.yml
  # ... and so on for stages 2–10, secret-scan, self-validation, e2e
```

The two duplicated standalone mirrors committed on `feature/idempotency-and-benchmark-infra-23` (`stage-10-benchmark-regression.yml` and `benchmark-gate-self-validation.yml`) are deleted as part of this refactor; their roles are absorbed by the corresponding `_*.yml` callees' `workflow_dispatch:` trigger.

## Acceptance Criteria (early draft)

- [ ] Every job currently defined inline in `pr-pipeline.yml` is extracted to its own `_*.yml` reusable workflow file.
- [ ] Each `_*.yml` declares both `on: workflow_call:` and `on: workflow_dispatch:`.
- [ ] `pr-pipeline.yml` contains no inline `steps:`; every job is a `uses: ./.github/workflows/_*.yml` block with appropriate `needs:` and `secrets:` declarations.
- [ ] Step content (commands, environment, `shell:`, `runs-on:`) is byte-identical to the pre-refactor inline definitions; diffs limited to relocation and the `workflow_call:`/`workflow_dispatch:` triggers.
- [ ] `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>` runs only that stage against the branch tip; no other stages are queued.
- [ ] A PR-Pipeline run on a representative branch shows the same pass/fail outcome as the pre-refactor pipeline for each stage. No new failure modes introduced by the relocation.
- [ ] The two standalone duplicate workflows (`stage-10-benchmark-regression.yml`, `benchmark-gate-self-validation.yml`) are deleted in the same change.
- [ ] Branch protection rule names are updated to match the new `<caller-job-name> / <callee-job-name>` display format. The old names are removed from the rule. Documented in the PR description.
- [ ] Each Azure-secret-consuming callee (currently only `_stage-9-e2e.yml`) declares its `secrets:` explicitly and the caller passes `secrets: inherit` or per-secret mappings. No silent secret-loss regression.
- [ ] Documentation under `.claude/skills/orchestrate/SKILL.md` (or a new `docs/` page) describes the callee/caller convention and the rule that any new gate ships as a `_*.yml` callee, not as inline steps.

## Constraints & Risks

- **Branch-protection required-check names will change.** Pre-refactor names like `stage-10-benchmark-regression` become `stage-10-benchmark-regression / <callee-job-name>`. Branch protection rules that pin required checks by exact string must be updated in the same change; failure to do so blocks all PR merges until corrected. This is the single highest-risk side effect.
- **Workspace is not shared between caller and callee.** Any current implicit reliance on filesystem state crossing job boundaries (e.g., a stage that reads a previous stage's working directory output) must be made explicit via `actions/upload-artifact` / `actions/download-artifact`. Most stages already check out independently so this should be limited, but it must be audited.
- **Secrets do not auto-flow.** Callees must declare each secret they consume; callers must pass `secrets: inherit` or explicit per-secret keys. `_stage-9-e2e.yml` is the obvious case (Azure tenant/client/secret + `E2E_API_BASE_URL`); silent secret-loss would produce confusing auth failures rather than CI errors.
- **Reusable-workflow nesting depth cap is 4.** Trivially fine for this flat pipeline but must be documented as the conventions ceiling so a future "stage groups" abstraction does not blow through it.
- **Refactor scope is repository-wide CI.** Even though no production C# code changes, the impact surface is every PR's merge gate. The change should ship on its own branch, behind a feature-review remediation cycle, and merge only after at least one representative PR has run cleanly against the refactored pipeline.

## Test Conditions to Consider

- [ ] Unit coverage areas
  - No new PowerShell or Pester surface; existing tests for scripts under `scripts/benchmarks/` and `scripts/powershell/` continue to pass unmodified.
  - If any helper script is added to share inputs/outputs across reusable workflows, it must ship with Pester coverage per `.claude/rules/powershell.md` (>= 85% line, >= 75% branch).
- [ ] Integration scenarios
  - Open a synthetic PR against `main` from the refactor branch. Every required check must report success identically to a known-green commit on the pre-refactor pipeline.
  - Run `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>`; verify a single isolated run id with one job, no `stage-7-integration` dependency triggered.
  - Run `gh workflow run pr-pipeline.yml --ref <branch>`; verify the orchestrator chains all callees in the expected `needs:` order.
  - Trigger a deliberately-failing stage (e.g., introduce a syntax error in one callee) and verify the failure surfaces in the orchestrator's check list under the new combined name.
- [ ] CLI/API examples
  - Document one-line `gh workflow run` invocations for each stage in `.github/workflows/README.md` (new file).
  - Document the branch-protection rule rename procedure with explicit pre/post check names.

## Next Step

- [ ] Promote to GitHub issue (feature request template)
- [ ] Create `docs/features/active/reusable-workflow-refactor-pr-pipeline/` folder from the template