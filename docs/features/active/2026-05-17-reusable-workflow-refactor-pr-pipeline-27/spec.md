# 2026-05-17-reusable-workflow-refactor-pr-pipeline - Refactor Spec

- **Issue:** #27
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-18
- **Status:** Draft
- **Version:** 0.2

## Intent & Outcomes

The `pr-pipeline.yml` workflow file orchestrates all PR-time CI gates (stages 1–10, plus `secret-scan`, `benchmark-gate-self-validation`, and the `stage-e2e-smoke` job). GitHub Actions cannot run a single job of a multi-job workflow against a fresh ref: `workflow_dispatch` runs every job, and `gh run rerun --job` only replays the original SHA. The unblock applied on `feature/idempotency-and-benchmark-infra-23` (commits `d2c51bd`, `534b549`, `328026a`) addressed this for two stages by creating byte-identical standalone dispatch mirrors at `.github/workflows/stage-10-benchmark-regression.yml` and `.github/workflows/benchmark-gate-self-validation.yml`. That pattern is duplication by construction: every step change must be made in two places, with drift detected only by CI regression.

A cleaner structure is available via reusable workflows (`on: workflow_call`). Each stage becomes a callee file that lists both `workflow_call:` and `workflow_dispatch:` triggers. The orchestrating `pr-pipeline.yml` shrinks to a list of `uses:` lines and the `needs:` dependency graph. Each stage is then independently dispatchable against a branch ref via `gh workflow run <stage>.yml --ref <branch>`, and the duplicated mirror files are deleted.

This refactor is also the structural enabler for issue #26 (`orchestration-missing-ci-green-gate`): the proposed S9 "CI Green Required" gate must verify a *single* stage's status against a specific head SHA. With reusable workflows, each callee produces its own run id that S9 can query in isolation. Without the refactor, S9 must parse `gh pr checks --json` output and disambiguate jobs nested inside a single multi-job run.

## Invariants (must not change)

The following per-job behavior contracts are observable from the current `pr-pipeline.yml` (issue #27) and MUST survive the refactor byte-for-byte:

- **Step content byte-identity.** Every `run:` block, `shell:` selector, `uses:` action reference (including pinned major version such as `actions/checkout@v4`, `actions/setup-dotnet@v4`, `actions/setup-node@v4`, `actions/upload-artifact@v4`), `with:` parameter, `env:` mapping, and `if:` guard moves verbatim from its current inline location into the corresponding `_*.yml` callee. The only permitted edits are (a) the surrounding `on: workflow_call:` / `on: workflow_dispatch:` triggers and (b) relocation of the `needs:` declaration from callee to caller.
- **Runner OS per job.** The runner declaration follows the job. Current matrix:
  - `windows-latest`: `tier-classification`, `stage-1-format`, `stage-2-lint`, `stage-3-typecheck`, `stage-4-architecture`, `stage-5-test`, `stage-7-integration`, `stage-1-dotnet-format`, `stage-2-dotnet-build`, `stage-3-dotnet-typecheck`, `stage-4-dotnet-architecture`, `stage-5-dotnet-test`, `stage-10-benchmark-regression`, `benchmark-gate-self-validation`, `secret-scan`.
  - `ubuntu-latest`: `stage-6-contract`, `stage-e2e-smoke`.
- **Permissions block.** `permissions: contents: read` remains the top-level default on both orchestrator and callees. No callee elevates permissions implicitly.
- **Secrets consumption surface.**
  - `stage-e2e-smoke` consumes `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `E2E_API_BASE_URL` from repository secrets. After refactor, the callee MUST declare these in its `on: workflow_call: secrets:` block and the caller MUST forward them via `secrets: inherit` or explicit per-secret mappings. No silent secret-loss.
  - `secret-scan` consumes `env.GH_TOKEN: ${{ github.token }}`. `github.token` is automatic, not a repository secret, but the `env:` mapping must be relocated to the callee unchanged.
- **`needs:` dependency graph.** The full pre-refactor graph is preserved on the caller side:
  - `stage-1-format` -> `stage-2-lint` -> `stage-3-typecheck` -> `stage-4-architecture` -> `stage-5-test` -> `stage-6-contract` -> `stage-7-integration` (Python/Node chain, all depend on `tier-classification` transitively).
  - `stage-1-dotnet-format` -> `stage-2-dotnet-build` -> `stage-3-dotnet-typecheck` -> `stage-4-dotnet-architecture` -> `stage-5-dotnet-test` (.NET chain, rooted at `tier-classification`).
  - `stage-e2e-smoke`, `stage-10-benchmark-regression`, `benchmark-gate-self-validation` all `needs: [stage-7-integration]`.
  - `secret-scan` has no `needs:` (runs in parallel with `tier-classification`).
- **Conditional execution.** `stage-e2e-smoke` retains its `if: contains(github.event.pull_request.labels.*.name, 'e2e:run')` guard verbatim on the caller-side `uses:` job (since `if:` is a caller-level construct on `uses:` jobs).
- **Pass/fail semantics.**
  - `benchmark-gate-self-validation` retains its negative-test exit-code reset (`exit 0` after the expected `dotnet test` non-zero exit on `NonIdempotentHandlerNegativeTests`). The composite step semantics — latency gate must pass, negative test must fail — are preserved.
  - `stage-10-benchmark-regression` retains its `upload-artifact@v4` `if: always()` step that publishes `artifacts/benchmarks/run/results/*-report-full.json` as `stage-10-benchmark-report`.
- **Workflow triggers on orchestrator.** `pr-pipeline.yml` continues to fire on `pull_request: branches: [main]` and `workflow_dispatch:` with the same semantics.

## Scope (structural changes)

Final state of `.github/workflows/`:

```
.github/workflows/
  pr-pipeline.yml                            # orchestrator: only `uses:` + `needs:` + `if:` + `secrets:`
  pre-merge-pipeline.yml                     # unchanged (out of scope; merge_group trigger, distinct lifecycle)
  benchmark-baseline-refresh.yml             # unchanged (already standalone, distinct lifecycle)
  _tier-classification.yml                   # workflow_call + workflow_dispatch
  _stage-1-format.yml
  _stage-2-lint.yml
  _stage-3-typecheck.yml
  _stage-4-architecture.yml
  _stage-5-test.yml
  _stage-6-contract.yml
  _stage-7-integration.yml
  _stage-1-dotnet-format.yml
  _stage-2-dotnet-build.yml
  _stage-3-dotnet-typecheck.yml
  _stage-4-dotnet-architecture.yml
  _stage-5-dotnet-test.yml
  _stage-e2e-smoke.yml
  _stage-10-benchmark-regression.yml
  _benchmark-gate-self-validation.yml
  _secret-scan.yml
  README.md                                  # NEW: callee/caller convention + per-stage dispatch invocations
```

Each `_*.yml` callee:

- Lists both `on: workflow_call:` and `on: workflow_dispatch:` so the same file serves orchestrated and standalone invocation.
- Owns its `steps:` and `runs-on:` declaration. The caller's `uses:` job is bodyless.
- Receives `inputs:` and `secrets:` explicitly (no implicit `secrets.*` inheritance for any secret it consumes; `_stage-e2e-smoke.yml` in particular must declare Azure secrets and the caller must pass `secrets: inherit` or explicit mappings).

`pr-pipeline.yml` after the refactor contains only `uses:` jobs with `needs:`, `if:`, and `secrets:` declarations as appropriate; no inline `steps:` remain.

The two duplicated standalone mirrors committed on `feature/idempotency-and-benchmark-infra-23` (`.github/workflows/stage-10-benchmark-regression.yml` and `.github/workflows/benchmark-gate-self-validation.yml`) are deleted; their dispatch roles are absorbed by the corresponding `_*.yml` callees' `workflow_dispatch:` trigger.

## Non-Goals

Explicitly out of scope for issue #27:

- **No changes to step logic.** Commands, scripts under `.github/scripts/`, composite actions under `.github/actions/`, and the BenchmarkDotNet invocation arguments remain untouched. Step relocation only.
- **No changes to coverage thresholds.** Line >= 85% / branch >= 75% per `.claude/rules/quality-tiers.md` remain in force; this refactor does not adjust them.
- **No changes to tier classification.** `quality-tiers.yml` at repo root and `.github/scripts/validate-quality-tiers.ps1` are not modified; the `tier-classification` job continues to invoke the same validator.
- **No changes to `benchmark-baseline-refresh.yml`.** That workflow has a distinct lifecycle (deliberate human-approved baseline updates) and is intentionally excluded from the callee/caller convention.
- **No changes to `pre-merge-pipeline.yml`.** It fires on `merge_group`, not `pull_request`, and is out of scope for this refactor.
- **No new gates, no new stages, no removal of existing stages.** The refactor is structural only; the gate inventory before and after is identical.
- **No production C# / TypeScript / Python code changes.** Repository application code is untouched.
- **No branch-protection automation.** The rule rename is performed manually by the maintainer and documented in the PR description; this refactor does not introduce a script to mutate branch-protection rules.

## Dependencies / Touchpoints

Current `.github/workflows/` contents (from `Glob` of `.github/workflows/*.yml`):

| File | Disposition |
|---|---|
| `pr-pipeline.yml` | Refactored to orchestrator-only (`uses:` + `needs:` + `if:` + `secrets:`). |
| `stage-10-benchmark-regression.yml` | **Deleted.** Standalone dispatch mirror; role absorbed by `_stage-10-benchmark-regression.yml`'s `workflow_dispatch:` trigger. |
| `benchmark-gate-self-validation.yml` | **Deleted.** Standalone dispatch mirror; role absorbed by `_benchmark-gate-self-validation.yml`'s `workflow_dispatch:` trigger. |
| `pre-merge-pipeline.yml` | **Unchanged.** Out of scope (distinct trigger: `merge_group`). |
| `benchmark-baseline-refresh.yml` | **Unchanged.** Out of scope (distinct lifecycle: deliberate baseline refresh). |
| `_tier-classification.yml` and the 16 `_stage-*.yml` / `_*-scan.yml` callees | **New.** Created as bodied callees extracted from `pr-pipeline.yml` jobs. |
| `.github/workflows/README.md` | **New.** Documents callee/caller convention, per-stage `gh workflow run` invocations, branch-protection rename procedure. |

External touchpoints:

- **Branch-protection rules** on `main` reference required-check names that will change shape from `<job-name>` to `<caller-job-name> / <callee-job-name>`. Rule maintainer (repository admin) must update the required-check list in the same change window.
- **Issue #26** (`orchestration-missing-ci-green-gate`) is the downstream consumer; this refactor is its structural precondition.
- **`.github/scripts/validate-quality-tiers.ps1`** and the composite actions under `.github/actions/` (`format`, `lint`, `typecheck`, `architecture`, `test`, `contract`, `schema-contract`, `integration`, `dotnet-format`, `dotnet-build`, `dotnet-architecture`, `dotnet-test`) are consumed unchanged by the new callees.

Required coordination: repository admin (for branch-protection rename); no other team coordination required since no application code is affected.

## Risks & Mitigations

- **Branch-protection required-check names will change.** Pre-refactor names like `stage-10-benchmark-regression` become `stage-10-benchmark-regression / <callee-job-name>`. Branch protection rules that pin required checks by exact string must be updated in the same change; failure to do so blocks all PR merges until corrected. Mitigation: the PR description enumerates the rename mapping explicitly and the merge is gated on admin confirmation.
- **Workspace is not shared between caller and callee.** Each callee job runs on a fresh runner and performs its own `actions/checkout@v4`. Audit finding (see Technical Specifications): no cross-job filesystem reliance exists in the current `pr-pipeline.yml`; every job already checks out independently, and the only cross-step artifact (`stage-10-benchmark-report` from `upload-artifact@v4`) is consumed only by post-run inspection, not by another job. No `download-artifact` is required by the refactor.
- **Secrets do not auto-flow.** Callees must declare each secret they consume; callers must pass `secrets: inherit` or explicit per-secret keys. `_stage-e2e-smoke.yml` is the case requiring explicit handling (Azure tenant/client/secret + `E2E_API_BASE_URL`). Mitigation: declare the four secrets explicitly in the callee's `on: workflow_call: secrets:` block; use `secrets: inherit` on the caller-side `uses:` job.
- **Reusable-workflow nesting depth cap is 4.** Trivially fine for this flat pipeline (depth 2) but documented in `.github/workflows/README.md` so a future "stage groups" abstraction does not exceed it.
- **Refactor scope is repository-wide CI.** Even though no production code changes, the impact surface is every PR's merge gate. Mitigation: ship on its own branch; run at least one representative PR cleanly against the refactored pipeline before merge.

## Technical Specifications

**Files to create (18 new):**

- `.github/workflows/_tier-classification.yml`
- `.github/workflows/_stage-1-format.yml`
- `.github/workflows/_stage-2-lint.yml`
- `.github/workflows/_stage-3-typecheck.yml`
- `.github/workflows/_stage-4-architecture.yml`
- `.github/workflows/_stage-5-test.yml`
- `.github/workflows/_stage-6-contract.yml`
- `.github/workflows/_stage-7-integration.yml`
- `.github/workflows/_stage-1-dotnet-format.yml`
- `.github/workflows/_stage-2-dotnet-build.yml`
- `.github/workflows/_stage-3-dotnet-typecheck.yml`
- `.github/workflows/_stage-4-dotnet-architecture.yml`
- `.github/workflows/_stage-5-dotnet-test.yml`
- `.github/workflows/_stage-e2e-smoke.yml`
- `.github/workflows/_stage-10-benchmark-regression.yml`
- `.github/workflows/_benchmark-gate-self-validation.yml`
- `.github/workflows/_secret-scan.yml`
- `.github/workflows/README.md`

**Files to delete (2):**

- `.github/workflows/stage-10-benchmark-regression.yml`
- `.github/workflows/benchmark-gate-self-validation.yml`

**Files to refactor (1):**

- `.github/workflows/pr-pipeline.yml` — strip all inline `steps:`; replace each job body with a `uses: ./.github/workflows/_<name>.yml` line, preserving `needs:`, `if:`, and adding `secrets: inherit` on `stage-e2e-smoke`.

**Data flow audit (cross-job filesystem reliance in current `pr-pipeline.yml`):**

Reviewed all 17 jobs in `pr-pipeline.yml`:

- Every job begins with `uses: actions/checkout@v4` (with `fetch-depth: 0` only for `stage-6-contract` and `secret-scan`); no job consumes a working-tree path produced by a previous job.
- `stage-10-benchmark-regression` calls `actions/upload-artifact@v4` to publish `stage-10-benchmark-report`, but no downstream job calls `actions/download-artifact`. The artifact is for post-run inspection only.
- No matrix-shared cache, no `actions/cache@v4` cross-job key reuse, no `outputs:` consumed via `needs.<job>.outputs.*`.

**Conclusion:** the refactor introduces no new `upload-artifact` / `download-artifact` pairs. Existing artifact uploads relocate verbatim into their callee.

**Branch-protection rename note (to be included in PR description):**

Required-check names change from `<job-name>` to `<caller-job-name> / <callee-job-name>`. Mapping example: `stage-10-benchmark-regression` becomes `stage-10-benchmark-regression / <job-id-defined-in-callee>`. The exact post-refactor name for each gate must be captured from the first successful run and applied to the branch-protection rule on `main` before merge.

**Public interfaces / contracts:**

- The `gh workflow run <file>.yml --ref <branch>` interface gains 17 new dispatch entry points (one per callee). No interface is removed; the two deleted mirrors map to `_stage-10-benchmark-regression.yml` and `_benchmark-gate-self-validation.yml` respectively.
- The orchestrator `pr-pipeline.yml` retains its `pull_request` and `workflow_dispatch` entry points.

**Logging / telemetry:** unchanged.

**Migration / backfill:** none. Branch-protection rename is the only externally visible migration.

## Test Strategy

**Regression / invariant validation (structural diff):**

- Produce a textual diff of each callee's `steps:` block against the corresponding pre-refactor inline job in `pr-pipeline.yml`. Diff MUST be empty except for indentation normalization. Diff result is the primary invariant evidence.
- Verify each callee's `runs-on:` matches the runner OS listed in Invariants above.
- Verify each callee declares the same `permissions:`, `env:`, `if:`, and `secrets:` surface as its pre-refactor inline counterpart.

**YAML / workflow-syntax verification:**

- If `actionlint` is available in the repo toolchain, run it across `.github/workflows/`. Otherwise perform structural diff verification: `yq` or PowerShell `ConvertFrom-Yaml` parse of every callee and the orchestrator to confirm valid YAML and a single `jobs:` map per file.
- Confirm every `uses:` in `pr-pipeline.yml` resolves to an existing `_<name>.yml` file in the same directory.

**Integration scenarios (from issue #27 test conditions):**

1. **Synthetic PR scenario.** Open a PR from the refactor branch against `main`. Every required check must report success identically to a known-green commit on the pre-refactor pipeline. Compare check names and outcomes one-to-one.
2. **Isolated dispatch scenario.** Run `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>`. Verify exactly one run id is produced, containing one job, with no `stage-7-integration` or other dependency triggered. Repeat for at least one other callee (`_stage-1-format.yml` recommended) to confirm the pattern is general.
3. **Orchestrator chaining scenario.** Run `gh workflow run pr-pipeline.yml --ref <branch>`. Verify the orchestrator chains all callees in the expected `needs:` order, matching the dependency graph in Invariants.
4. **Deliberate-failure surfacing scenario.** Introduce a temporary syntax error in one callee (e.g., a malformed `run:` line in `_stage-1-format.yml`) and confirm the failure surfaces in the orchestrator's check list under the new combined name `<caller-job-name> / <callee-job-name>`. Revert before merge.

**Toolchain commands relevant to this refactor:**

- YAML lint (if `actionlint` is present): `actionlint .github/workflows/*.yml`.
- Structural parse: `Get-ChildItem .github/workflows/_*.yml | ForEach-Object { (Get-Content $_.FullName -Raw) | ConvertFrom-Yaml | Out-Null }` (or `yq eval '.' <file>`).
- The seven-stage toolchain loop in `.claude/rules/general-code-change.md` is not directly applicable (no application code), but the synthetic-PR scenario above exercises the full pipeline end-to-end.

**Coverage impact:** No application-code coverage change. No new PowerShell or Pester surface (no helper scripts added). If a helper script is later added to share inputs/outputs across reusable workflows, it must ship with Pester coverage per `.claude/rules/powershell.md` (>= 85% line, >= 75% branch).

**Manual validation:**

- Branch-protection rule rename on `main` performed by repository admin using the mapping documented in the PR description.
- One representative PR run against the refactored pipeline must complete with the same pass/fail outcome as a known-green pre-refactor commit before merge.

## Definition of Done

Mirrored from issue #27 acceptance criteria:

- [ ] Every job currently defined inline in `pr-pipeline.yml` is extracted to its own `_*.yml` reusable workflow file.
- [ ] Each `_*.yml` declares both `on: workflow_call:` and `on: workflow_dispatch:`.
- [ ] `pr-pipeline.yml` contains no inline `steps:`; every job is a `uses: ./.github/workflows/_*.yml` block with appropriate `needs:`, `if:`, and `secrets:` declarations.
- [ ] Step content (commands, environment, `shell:`, `runs-on:`) is byte-identical to the pre-refactor inline definitions; diffs limited to relocation and the `workflow_call:`/`workflow_dispatch:` triggers.
- [ ] `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>` runs only that stage against the branch tip; no other stages are queued.
- [ ] A PR-pipeline run on a representative branch shows the same pass/fail outcome as the pre-refactor pipeline for each stage. No new failure modes introduced by the relocation.
- [ ] The two standalone duplicate workflows (`stage-10-benchmark-regression.yml`, `benchmark-gate-self-validation.yml`) are deleted in the same change.
- [ ] Branch-protection rule names are updated to match the new `<caller-job-name> / <callee-job-name>` display format. The old names are removed from the rule. Documented in the PR description.
- [ ] Each Azure-secret-consuming callee (currently only `_stage-e2e-smoke.yml`) declares its `secrets:` explicitly and the caller passes `secrets: inherit` or per-secret mappings. No silent secret-loss regression.
- [ ] `.github/workflows/README.md` exists and documents the callee/caller convention, the rule that any new gate ships as a `_*.yml` callee (not inline steps), per-stage `gh workflow run` invocations, and the branch-protection rename procedure.

## Seeded Test Conditions (from potential)

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
