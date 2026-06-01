# GitHub Actions Workflows

This directory contains the CI workflows for the repository. Every gate is structured as a **callable reusable workflow** invoked from an **orchestrator** workflow. The same callees are also directly dispatchable for targeted re-runs.

## Convention

- Every new CI gate ships as a file named `_<name>.yml`. The leading underscore marks the file as a callee.
- Every callee declares both triggers:
  - `on: workflow_call:` (so an orchestrator can invoke it via `uses:`)
  - `on: workflow_dispatch:` (so a maintainer can run the stage in isolation from the Actions UI or via `gh workflow run`)
- The orchestrator (`pr-pipeline.yml`) contains **no inline `steps:`**. Every job in the orchestrator is a `uses:` reference to a callee plus `needs:`, `if:`, and `secrets:` as needed.
- Cross-job filesystem sharing is **not** implicit. Any job that needs to publish data to another job must use `actions/upload-artifact` + `actions/download-artifact` explicitly.
- GitHub Actions caps **reusable-workflow nesting depth at 4 levels**. This repository uses one level of nesting (orchestrator -> callee), so the cap is not at risk; do not introduce additional levels without an explicit design review.

## Files

Orchestrator:

- `pr-pipeline.yml` — runs every gate below in PR runs (`pull_request` to `main`) and is also `workflow_dispatch`-able. After the `tier-classification` root gate completes, the independent gate stages **fan out and run concurrently** rather than in two serial per-language lanes; every non-root stage declares `needs: [tier-classification]` (plus any justified genuine dependency). This lowers total pipeline wall-clock time. The accepted tradeoff is the loss of per-lane fail-fast economy — when an early gate (for example format) fails, later stages in the same language no longer short-circuit and instead run concurrently — which increases concurrent runner-minute consumption. Wall-clock time is prioritized over runner-minute savings. Job keys and required status-check contexts are unchanged by this `needs:`-graph-only change.

Callees (one per gate):

| # | Callee | Purpose |
|---|---|---|
| 1 | `_tier-classification.yml` | Validates `quality-tiers.yml` covers every project |
| 2 | `_stage-1-format-prettier.yml` | Prettier format check (JS/TS/JSON/YAML/MD); see also `_stage-1-dotnet-format.yml` for C# (CSharpier) |
| 3 | `_stage-2-lint-eslint.yml` | ESLint v9 flat config with typescript-eslint (TS/JS only) |
| 4 | `_stage-3-typecheck-tsc.yml` | `tsc --noEmit` (TS only); .NET nullable analysis runs inside `_stage-3-dotnet-typecheck.yml` |
| 5 | `_stage-4-architecture.yml` | Architecture-boundary checks |
| 6 | `_stage-5-test-vitest.yml` | Vitest with V8 coverage (TS only); .NET unit tests run in `_stage-5-dotnet-test.yml` |
| 7 | `_stage-6-contract.yml` | Contract / schema diff (needs full history, `fetch-depth: 0`) |
| 8 | `_stage-7-integration-vitest.yml` | Vitest integration placeholder (TS only; currently no-op until integration tests exist) |
| 9 | `_stage-1-dotnet-format.yml` | .NET format |
| 10 | `_stage-2-dotnet-build.yml` | .NET build |
| 11 | `_stage-3-dotnet-typecheck.yml` | .NET nullable analysis explainer (real check runs inside the build) |
| 12 | `_stage-4-dotnet-architecture.yml` | .NET architecture boundaries |
| 13 | `_stage-5-dotnet-test.yml` | .NET unit tests |
| 14 | `_stage-e2e-smoke.yml` | Playwright E2E smoke (requires four Azure secrets — see below) |
| 15 | `_secret-scan.yml` | Gitleaks PR-diff scan |

Other workflows:

- `pre-merge-pipeline.yml` — pre-merge orchestration (out of scope for this refactor).

## Dispatch invocations (per-stage)

Use these to run an individual stage in isolation, for example to retry a flaky gate or to validate a workflow file edit without queuing the entire pipeline. Substitute `<branch>` with the branch you want to run against.

```
gh workflow run _tier-classification.yml             --ref <branch>
gh workflow run _stage-1-format-prettier.yml         --ref <branch>
gh workflow run _stage-2-lint-eslint.yml             --ref <branch>
gh workflow run _stage-3-typecheck-tsc.yml           --ref <branch>
gh workflow run _stage-4-architecture.yml            --ref <branch>
gh workflow run _stage-5-test-vitest.yml             --ref <branch>
gh workflow run _stage-6-contract.yml                --ref <branch>
gh workflow run _stage-7-integration-vitest.yml      --ref <branch>
gh workflow run _stage-1-dotnet-format.yml           --ref <branch>
gh workflow run _stage-2-dotnet-build.yml            --ref <branch>
gh workflow run _stage-3-dotnet-typecheck.yml        --ref <branch>
gh workflow run _stage-4-dotnet-architecture.yml     --ref <branch>
gh workflow run _stage-5-dotnet-test.yml             --ref <branch>
gh workflow run _stage-e2e-smoke.yml                 --ref <branch>
gh workflow run _secret-scan.yml                     --ref <branch>
```

Each isolated dispatch runs exactly one job; no downstream `needs:` chain is triggered because `needs:` lives only on the orchestrator.

To dispatch the full orchestrator manually:

```
gh workflow run pr-pipeline.yml --ref <branch>
```

## Branch-protection rename procedure

Branch protection on `main` references required status-check names. After this refactor, the names that show up in the GitHub status API change from the pre-refactor flat names to the reusable-workflow nested form `<caller-job-name> / <callee-job-name>`. An admin must update branch protection accordingly.

> **Verified status-check contexts.** The nested `<caller-job-name> / <callee-job-name>` form in the "Add (new)" column below is what GitHub actually reports for reusable-workflow jobs. This was confirmed against a live `pr-pipeline.yml` run (the checks reported by `gh pr checks` are `tier-classification / tier-classification`, `stage-1-format / stage-1-format-prettier`, and so on). The nested names are authoritative; branch-protection required contexts must match them exactly.
>
> **Known discrepancy — `apply-branch-protection.ps1` is stale.** The helper `.github/scripts/apply-branch-protection.ps1` (`Get-RequiredStatusCheckContextList`) still encodes the older flat names and only covers the TypeScript-lane subset (`tier-classification`, `stage-1-format`, `stage-2-lint`, `stage-3-typecheck`, `stage-4-architecture`, `stage-5-test`, `stage-6-contract`, `stage-7-integration`). Those flat names do not match the contexts GitHub now reports, so applying the ruleset with that list would require contexts that never report a result. Until the script (and its Pester test `tests/powershell/apply-branch-protection.Tests.ps1`) are reconciled to the full nested set in the table below, apply the required-check configuration manually via the admin procedure that follows. Reconciling the script is a separate code change tracked outside this documentation note.

Mapping (left = pre-refactor name to remove; right = post-refactor name to add):

| Remove (old) | Add (new) |
|---|---|
| `tier-classification` | `tier-classification / tier-classification` |
| `stage-1-format` | `stage-1-format / stage-1-format-prettier` |
| `stage-2-lint` | `stage-2-lint / stage-2-lint-eslint` |
| `stage-3-typecheck` | `stage-3-typecheck / stage-3-typecheck-tsc` |
| `stage-4-architecture` | `stage-4-architecture / stage-4-architecture` |
| `stage-5-test` | `stage-5-test / stage-5-test-vitest` |
| `stage-6-contract` | `stage-6-contract / stage-6-contract` |
| `stage-7-integration` | `stage-7-integration / stage-7-integration-vitest` |
| `stage-1-dotnet-format` | `stage-1-dotnet-format / stage-1-dotnet-format` |
| `stage-2-dotnet-build` | `stage-2-dotnet-build / stage-2-dotnet-build` |
| `stage-3-dotnet-typecheck` | `stage-3-dotnet-typecheck / stage-3-dotnet-typecheck` |
| `stage-4-dotnet-architecture` | `stage-4-dotnet-architecture / stage-4-dotnet-architecture` |
| `stage-5-dotnet-test` | `stage-5-dotnet-test / stage-5-dotnet-test` |
| `stage-e2e-smoke` | `stage-e2e-smoke / stage-e2e-smoke` |
| `secret-scan` | `secret-scan / secret-scan` |

Procedure (admin only):

1. Navigate to repository Settings -> Branches -> branch protection rule for `main`.
2. Under "Require status checks to pass before merging", remove each old name in the left column above.
3. Add each new name from the right column. The names appear in the picker only after the new pipeline has produced at least one run on a PR against `main`; if a name is missing, dispatch the orchestrator once first.
4. Save the rule.

Reproduce the same mapping in any PR description that introduces or changes a callee, so the merge reviewer can confirm branch protection is in sync.

## Secrets forwarding

Reusable workflows do **not** inherit caller secrets implicitly. Each callee that needs secrets must declare them under `on: workflow_call: secrets:`, and the orchestrator must forward them via `secrets:`.

Only `_stage-e2e-smoke.yml` consumes secrets in this pipeline. It declares the following as `required: true`:

- `AZURE_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `E2E_API_BASE_URL`

The orchestrator forwards them with `secrets: inherit` on the `stage-e2e-smoke` job. Adding a new callee that consumes secrets requires both sides of this contract.
